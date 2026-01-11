// lib/screens/drawing_screen.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:kouchuhyo_app/widgets/drawing_canvas.dart';
import 'package:collection/collection.dart';
import 'dart:math' as math;

class DrawingScreen extends StatefulWidget {
  final List<DrawingElement> initialElements;
  final String backgroundImagePath;
  final String title;

  const DrawingScreen({
    super.key,
    required this.initialElements,
    required this.backgroundImagePath,
    required this.title,
  });

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late final ValueNotifier<List<DrawingElement>> _elementsNotifier;
  late final ValueNotifier<DrawingElement?> _previewElementNotifier;

  DrawingTool _selectedTool = DrawingTool.pen;
  final GlobalKey _canvasKey = GlobalKey();
  
  DrawingElement? _movingElement;
  Offset _panStartOffset = Offset.zero;

  static const double _rectangleWidth = 30.0;
  static const double _rectangleHeight = 30.0;

  Rect? _imageBounds;
  late Image _backgroundImage;
  double _imageAspectRatio = 4 / 3;

  static const double _snapKoshitaY = 333.0;
  static const double _snapKoshitaXMin = 240.0;
  static const double _snapKoshitaXMax = 1028.0;
  static const double _snapThreshold = 8.0;

  @override
  void initState() {
    super.initState();
    _elementsNotifier = ValueNotifier(widget.initialElements.map((e) => e.clone()).toList());
    _previewElementNotifier = ValueNotifier(null);

    _backgroundImage = Image.asset(widget.backgroundImagePath);
    _resolveImageAspectRatio();
  }

  @override
  void dispose() {
    _elementsNotifier.dispose();
    _previewElementNotifier.dispose();
    super.dispose();
  }

  void _resolveImageAspectRatio() {
    final imageProvider = _backgroundImage.image;
    final stream = imageProvider.resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _imageAspectRatio = info.image.width / info.image.height;
        });
      }
    }));
  }

  Offset _clampPosition(Offset position) {
    if (_imageBounds == null) return position;
    return Offset(
      position.dx.clamp(_imageBounds!.left, _imageBounds!.right),
      position.dy.clamp(_imageBounds!.top, _imageBounds!.bottom),
    );
  }

  Offset _maybeSnapPosition(Offset position, {required bool isRectangleTool, Rect? movingRect}) {
    if (widget.backgroundImagePath != 'assets/koshita_base.jpg') {
      return position;
    }

    double snappedX = position.dx;
    double snappedY = position.dy;
    
    final previewRect = isRectangleTool
        ? Rect.fromLTWH(position.dx - _rectangleWidth, position.dy - _rectangleHeight, _rectangleWidth, _rectangleHeight)
        : (movingRect ?? Rect.fromLTWH(position.dx - _rectangleWidth / 2, position.dy - _rectangleHeight / 2, _rectangleWidth, _rectangleHeight));


    final fixedSnapY = _snapKoshitaY * (_imageBounds!.height / 478.0);
    final isWithinFixedXRange = (position.dx >= _snapKoshitaXMin * (_imageBounds!.width / 1263.0) && position.dx <= _snapKoshitaXMax * (_imageBounds!.width / 1263.0));
    
    if (isWithinFixedXRange && (previewRect.bottom - fixedSnapY).abs() < _snapThreshold) {
      snappedY = fixedSnapY;
    } else if (isWithinFixedXRange && (previewRect.top - fixedSnapY).abs() < _snapThreshold) {
       snappedY = fixedSnapY + _rectangleHeight;
    }


    if (isRectangleTool || movingRect != null) {
      for (final element in _elementsNotifier.value) {
        if (element is Rectangle) {
          final rect = element.rect;

          if (previewRect.left < rect.right + _snapThreshold && previewRect.right > rect.left - _snapThreshold) {
            if ((previewRect.top - rect.bottom).abs() < _snapThreshold) {
              snappedY = rect.bottom + _rectangleHeight;
            }
            if ((previewRect.bottom - rect.top).abs() < _snapThreshold) {
              snappedY = rect.top;
            }
          }

          if (previewRect.top < rect.bottom + _snapThreshold && previewRect.bottom > rect.top - _snapThreshold) {
            if ((previewRect.left - rect.right).abs() < _snapThreshold) {
              snappedX = rect.right + _rectangleWidth;
            }
            if ((previewRect.right - rect.left).abs() < _snapThreshold) {
              snappedX = rect.left;
            }
          }
        }
      }
    }
    
    return Offset(snappedX, snappedY);
  }

  // ▼▼▼ `onPanDown`、`onPanStart`、`onPanUpdate`のロジックを修正 ▼▼▼
  void _onPanDown(DragDownDetails details) {
    if (_imageBounds == null || !_imageBounds!.contains(details.localPosition)) return;
    
    _panStartOffset = _clampPosition(details.localPosition);
    
    // ペンツールが選択されている場合は、onPanDownで描画を開始する
    if (_selectedTool == DrawingTool.pen) {
       _elementsNotifier.value = [
        ..._elementsNotifier.value,
        DrawingPath(id: DateTime.now().millisecondsSinceEpoch, points: [_panStartOffset], paint: _createPaintForTool()),
      ];
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_imageBounds == null || !_imageBounds!.contains(details.localPosition)) return;

    final pos = _clampPosition(details.localPosition);
    
    // 【修正箇所】テキスト要素のみを移動可能にする
    _movingElement = _elementsNotifier.value.firstWhereOrNull((e) => e is DrawingText && e.contains(pos));

    if (_movingElement != null) {
      _panStartOffset = pos;
      return; // 移動処理が開始されたら新規描画は行わない
    }

    if (_selectedTool == DrawingTool.rectangle) {
      final snappedPos = _maybeSnapPosition(pos, isRectangleTool: true);
      _previewElementNotifier.value = Rectangle(
        id: 0,
        start: Offset(snappedPos.dx - _rectangleWidth, snappedPos.dy - _rectangleHeight),
        end: snappedPos,
        paint: Paint()
          ..color = Colors.blue.withOpacity(0.5)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );
    }
    
    // ペンツールはonPanDownで始点を追加済みなので、ここでは何もしない
    if (_selectedTool == DrawingTool.line) {
      _elementsNotifier.value = [
        ..._elementsNotifier.value,
        StraightLine(id: DateTime.now().millisecondsSinceEpoch, start: _panStartOffset, end: pos, paint: _createPaintForTool()),
      ];
    }
    if (_selectedTool == DrawingTool.dimension) {
      _elementsNotifier.value = [
        ..._elementsNotifier.value,
        DimensionLine(id: DateTime.now().millisecondsSinceEpoch, start: _panStartOffset, end: pos, paint: _createPaintForTool()),
      ];
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_imageBounds == null || !_imageBounds!.contains(details.localPosition)) {
      return;
    }
    
    if (_movingElement != null) {
      final newPos = _clampPosition(details.localPosition);
      
      final Rect? movingRect = (_movingElement is Rectangle) ? (_movingElement as Rectangle).rect : null;
      
      final snappedPos = _maybeSnapPosition(
        newPos, 
        isRectangleTool: _movingElement is Rectangle, 
        movingRect: movingRect,
      );
      
      final delta = snappedPos - _panStartOffset;
      _movingElement!.move(delta);
      _panStartOffset = snappedPos;

      _elementsNotifier.value = List.from(_elementsNotifier.value);
      return;
    }
    
    if (_selectedTool == DrawingTool.eraser) {
      final elementsToRemove = <DrawingElement>[];
      for (final element in _elementsNotifier.value) {
        if (element.contains(details.localPosition)) {
          elementsToRemove.add(element);
        }
      }
      if (elementsToRemove.isNotEmpty) {
        final currentElements = List<DrawingElement>.from(_elementsNotifier.value);
        for (final element in elementsToRemove) {
          currentElements.removeWhere((e) => e.id == element.id);
        }
        _elementsNotifier.value = currentElements;
      }
      return;
    }

    if (_selectedTool == DrawingTool.rectangle) {
      final currentPreview = _previewElementNotifier.value;
      if (currentPreview is Rectangle) {
        final pos = _maybeSnapPosition(_clampPosition(details.localPosition), isRectangleTool: true);
        currentPreview.start = Offset(pos.dx - _rectangleWidth, pos.dy - _rectangleHeight);
        currentPreview.end = pos;
        _previewElementNotifier.value = currentPreview.clone();
      }
      return;
    }
    
    final currentElements = _elementsNotifier.value;
    if (currentElements.isNotEmpty && currentElements.last is DrawingElementWithPoints) {
      final currentElement = currentElements.last as DrawingElementWithPoints;
      if (currentElement.updatePosition(_clampPosition(details.localPosition))) {
        _elementsNotifier.value = List<DrawingElement>.from(currentElements);
      }
    }
  }
  // ▲▲▲ `onPanDown`、`onPanStart`、`onPanUpdate`のロジックを修正 ▲▲▲

  void _onPanEnd(DragEndDetails details) {
    if (_movingElement != null) {
      _movingElement = null;
      _panStartOffset = Offset.zero;
      return;
    }

    if (_selectedTool == DrawingTool.rectangle) {
      final currentPreview = _previewElementNotifier.value;
      if (currentPreview is Rectangle) {
        final finalRect = Rectangle(
          id: DateTime.now().millisecondsSinceEpoch,
          start: currentPreview.start,
          end: currentPreview.end,
          paint: _createPaintForTool(),
        );
        _elementsNotifier.value = [..._elementsNotifier.value, finalRect];
        _previewElementNotifier.value = null;
      }
      return;
    }
  }

  // ▼▼▼ `onTapCanvas`にペンツールの点描画ロジックを追加 ▼▼▼
  void _onTapCanvas(TapUpDetails details) {
    if (_imageBounds == null || !_imageBounds!.contains(details.localPosition)) return;
    
    final tappedPoint = _clampPosition(details.localPosition);

    if (_selectedTool == DrawingTool.rectangle) {
      final snappedPos = _maybeSnapPosition(tappedPoint, isRectangleTool: true);
      final finalRect = Rectangle(
        id: DateTime.now().millisecondsSinceEpoch,
        start: Offset(snappedPos.dx - _rectangleWidth, snappedPos.dy - _rectangleHeight),
        end: snappedPos,
        paint: _createPaintForTool(),
      );
      _elementsNotifier.value = [..._elementsNotifier.value, finalRect];
      return;
    }
    
    if (_selectedTool == DrawingTool.pen) {
        // タップで点を描画する
        _elementsNotifier.value = [
          ..._elementsNotifier.value,
          DrawingPath(id: DateTime.now().millisecondsSinceEpoch, points: [tappedPoint, tappedPoint], paint: _createPaintForTool()),
        ];
    } else if (_selectedTool == DrawingTool.text) {
      _addNewText(tappedPoint);
    }
  }
  // ▲▲▲ `onTapCanvas`にペンツールの点描画ロジックを追加 ▲▲▲

  Paint _createPaintForTool() {
    switch (_selectedTool) {
      case DrawingTool.pen:
        return Paint()
          ..color = Colors.black
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = ui.StrokeCap.round;
      case DrawingTool.eraser:
        return Paint()
          ..color = Colors.transparent
          ..strokeWidth = 12.0
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.stroke
          ..strokeCap = ui.StrokeCap.round;
      case DrawingTool.line:
      case DrawingTool.rectangle:
      case DrawingTool.dimension:
        return Paint()..color = Colors.black..strokeWidth = 2.0..style = PaintingStyle.stroke;
      case DrawingTool.text:
        return Paint()..color = Colors.black;
    }
  }

  void _addNewText(Offset position) {
    final textController = TextEditingController();
    showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('テキストを追加'),
              content: TextField(controller: textController, autofocus: true, decoration: const InputDecoration(hintText: '注釈や数値を入力...')),
              actions: [
                TextButton(child: const Text('キャンセル'), onPressed: () => Navigator.of(context).pop()),
                TextButton(child: const Text('OK'), onPressed: () => Navigator.of(context).pop(textController.text)),
              ],
            )).then((result) {
      if (result != null && result.isNotEmpty) {
        final newText = DrawingText(id: DateTime.now().millisecondsSinceEpoch, text: result, position: position, paint: _createPaintForTool());
        _elementsNotifier.value = [..._elementsNotifier.value, newText];
      }
    });
  }


  void _saveDrawing() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || _imageBounds == null) return;
    const pixelRatio = 3.0;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final srcRect = Rect.fromLTWH(
      _imageBounds!.left * pixelRatio,
      _imageBounds!.top * pixelRatio,
      _imageBounds!.width * pixelRatio,
      _imageBounds!.height * pixelRatio,
    );
    final dstRect = Rect.fromLTWH(0, 0, srcRect.width, srcRect.height);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, dstRect);
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(dstRect.width.toInt(), dstRect.height.toInt());
    final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();

    if (pngBytes != null && mounted) {
      Navigator.of(context).pop({'elements': _elementsNotifier.value, 'imageBytes': pngBytes});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () {
                if (_elementsNotifier.value.isNotEmpty) {
                  final currentElements = List<DrawingElement>.from(_elementsNotifier.value);
                  currentElements.removeLast();
                  _elementsNotifier.value = currentElements;
                }
              }),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveDrawing),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Container(
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildToolButton(DrawingTool.pen, Icons.edit, '自由線'),
                _buildToolButton(DrawingTool.line, Icons.show_chart, '直線'),
                _buildToolButton(DrawingTool.rectangle, Icons.crop_square, '四角'),
                _buildToolButton(DrawingTool.dimension, Icons.straighten, '寸法線'),
                _buildToolButton(DrawingTool.text, Icons.text_fields, 'テキスト'),
                _buildToolButton(DrawingTool.eraser, Icons.cleaning_services, '消しゴム'),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LayoutBuilder(
            builder: (context, constraints) {
              final layoutAspectRatio = constraints.maxWidth / constraints.maxHeight;
              double imageWidth;
              double imageHeight;
              if (layoutAspectRatio > _imageAspectRatio) {
                imageHeight = constraints.maxHeight;
                imageWidth = imageHeight * _imageAspectRatio;
              } else {
                imageWidth = constraints.maxWidth;
                imageHeight = imageWidth / _imageAspectRatio;
              }
              final offsetX = (constraints.maxWidth - imageWidth) / 2;
              final offsetY = 0.0;
              _imageBounds = Rect.fromLTWH(offsetX, offsetY, imageWidth, imageHeight);

              return RepaintBoundary(
                key: _canvasKey,
                child: Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    Positioned.fromRect(
                      rect: _imageBounds!,
                      child: _backgroundImage,
                    ),
                    DrawingCanvas(
                      elementsNotifier: _elementsNotifier,
                      previewElementNotifier: _previewElementNotifier,
                      selectedTool: _selectedTool,
                      onPanDown: _onPanDown,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      onTap: _onTapCanvas,
                    ),
                  ],
                ),
              );
            },
          ),
      ),
    );
  }

  Widget _buildToolButton(DrawingTool tool, IconData icon, String label) {
    final isSelected = _selectedTool == tool;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTool = tool;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.blue : Colors.grey[700]),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(color: isSelected ? Colors.blue : Colors.grey[700], fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}