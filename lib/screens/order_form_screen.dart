// lib/screens/order_form_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

// ▼▼▼ 自作パッケージのインポート ▼▼▼
import 'package:kouchuhyo_app/models/kochuhyo_data.dart'; // データモデル
import 'package:kouchuhyo_app/widgets/order_form_widgets.dart'; // 共通UI部品
import 'package:kouchuhyo_app/widgets/drawing_canvas.dart';
import 'package:kouchuhyo_app/screens/drawing_screen.dart';
import 'package:kouchuhyo_app/screens/print_preview_screen.dart';

class OrderFormScreen extends StatefulWidget {
  final KochuhyoData? templateData;
  final String? templatePath;

  const OrderFormScreen({
    super.key,
    this.templateData,
    this.templatePath,
  });

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  // ▼▼▼ 状態管理 (Controllers & FocusNodes) ▼▼▼
  final Map<String, FocusNode> _focusNodes = {};
  late List<String> _orderedFocusNodeKeys;
  
  final TextEditingController _shippingDateController = TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController(text: 'A-');
  final TextEditingController _kobangoController = TextEditingController();
  final TextEditingController _shihomeisakiController = TextEditingController();
  final TextEditingController _hinmeiController = TextEditingController();
  
  final TextEditingController _productLengthController = TextEditingController();
  final TextEditingController _productWidthController = TextEditingController();
  final TextEditingController _productHeightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  
  String? _selectedMaterial;
  final List<String> _materialOptions = const ['LVL', '熱処理'];
  
  final TextEditingController _desiccantPeriodController = TextEditingController();
  final TextEditingController _desiccantResultDisplayController = TextEditingController();
  double? _selectedDesiccantCoefficient;
  final Map<String, double> _desiccantCoefficients = {
    '0.12 (地域Aなど)': 0.12, '0.048 (地域Bなど)': 0.048,
    '0.026 (地域Cなど)': 0.026, '0.013 (地域Dなど)': 0.013,
  };
  
  final TextEditingController _innerLengthController = TextEditingController();
  final TextEditingController _innerWidthController = TextEditingController();
  final TextEditingController _innerHeightController = TextEditingController();
  final TextEditingController _outerLengthController = TextEditingController();
  final TextEditingController _outerWidthController = TextEditingController();
  final TextEditingController _outerHeightController = TextEditingController();
  final TextEditingController _packagingVolumeDisplayController = TextEditingController();
  
  String? _selectedShippingType;
  String? _selectedPackingForm;
  String? _selectedFormType;
  final List<String> _formTypeOptions = const [
    'わく組（合板）', '外さんわく組（合板）', '普通木箱（合板）', '腰下付（合板）', '腰下',
  ];
  
  final TextEditingController _skidWidthController = TextEditingController();
  final TextEditingController _skidThicknessController = TextEditingController();
  final TextEditingController _skidQuantityController = TextEditingController();
  final TextEditingController _hWidthController = TextEditingController();
  final TextEditingController _hThicknessController = TextEditingController();
  String? _hFixingMethod;
  String? _selectedSuriGetaType;
  final TextEditingController _suriGetaWidthController = TextEditingController();
  final TextEditingController _suriGetaThicknessController = TextEditingController();
  final TextEditingController _getaQuantityController = TextEditingController();
  final TextEditingController _floorBoardThicknessController = TextEditingController();
  bool _isJitaMijikame = false;
  
  final TextEditingController _loadBearingMaterialWidthController = TextEditingController();
  final TextEditingController _loadBearingMaterialThicknessController = TextEditingController();
  final TextEditingController _loadBearingMaterialQuantityController = TextEditingController();
  String? _loadCalculationMethod;
  double _wUniform = 0.0;
  final TextEditingController _allowableLoadDisplayController = TextEditingController();
  
  final TextEditingController _l_A_Controller = TextEditingController();
  final TextEditingController _l0Controller = TextEditingController();
  final TextEditingController _l_B_Controller = TextEditingController();
  final TextEditingController _l1Controller = TextEditingController();
  final TextEditingController _l2Controller = TextEditingController();
  final TextEditingController _multiplierDisplayController = TextEditingController();
  final TextEditingController _allowableLoadFinalDisplayController = TextEditingController();
  
  final List<TextEditingController> _rootStopLengthControllers = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _rootStopWidthControllers = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _rootStopThicknessControllers = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _rootStopQuantityControllers = List.generate(5, (_) => TextEditingController());
  
  final TextEditingController _sideBoardThicknessController = TextEditingController();
  String? _selectedKamachiType;
  final TextEditingController _upperKamachiWidthController = TextEditingController();
  final TextEditingController _upperKamachiThicknessController = TextEditingController();
  final TextEditingController _lowerKamachiWidthController = TextEditingController();
  final TextEditingController _lowerKamachiThicknessController = TextEditingController();
  final TextEditingController _pillarWidthController = TextEditingController();
  final TextEditingController _pillarThicknessController = TextEditingController();
  final TextEditingController _beamReceiverWidthController = TextEditingController();
  final TextEditingController _beamReceiverThicknessController = TextEditingController();
  bool _beamReceiverEmbed = false;
  final TextEditingController _bracePillarWidthController = TextEditingController();
  final TextEditingController _bracePillarThicknessController = TextEditingController();
  bool _bracePillarShortEnds = false;
  
  final TextEditingController _ceilingUpperBoardThicknessController = TextEditingController();
  final TextEditingController _ceilingLowerBoardThicknessController = TextEditingController();
  
  final TextEditingController _hariWidthController = TextEditingController();
  final TextEditingController _hariThicknessController = TextEditingController();
  final TextEditingController _hariQuantityController = TextEditingController();
  final TextEditingController _pressingMaterialLengthController = TextEditingController();
  final TextEditingController _pressingMaterialWidthController = TextEditingController();
  final TextEditingController _pressingMaterialThicknessController = TextEditingController();
  final TextEditingController _pressingMaterialQuantityController = TextEditingController();
  bool _pressingMaterialHasMolding = false;
  final TextEditingController _topMaterialLengthController = TextEditingController();
  final TextEditingController _topMaterialWidthController = TextEditingController();
  final TextEditingController _topMaterialThicknessController = TextEditingController();
  final TextEditingController _topMaterialQuantityController = TextEditingController();
  
  final List<TextEditingController> _additionalPartNameControllers = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _additionalPartLengthControllers = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _additionalPartWidthControllers = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _additionalPartThicknessControllers = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _additionalPartQuantityControllers = List.generate(5, (_) => TextEditingController());
  
  // 選択肢オプション
  String? _selectedSkidSize;
  final List<String> _skidSizeOptions = const ['85×40', '85×55', '70×70', '85×85', '100×100', '105×105'];
  String? _selectedHSize;
  final List<String> _hSizeOptions = const ['85×40', '85×55', '70×70', '85×85', '100×100', '105×105'];
  String? _selectedSuriGetaSize;
  final List<String> _suriGetaSizeOptions = const ['85×25', '85×40', '85×55', '70×70', '85×85', '100×100', '105×105'];
  String? _selectedLoadBearingMaterialSize;
  final List<String> _loadBearingMaterialSizeOptions = const ['85×25', '85×40', '85×55', '70×70', '85×85', '100×100', '105×105'];
  String? _selectedBeamReceiverSize;
  final List<String> _beamReceiverSizeOptions = const ['85×25', '85×40'];
  String? _selectedBracePillarSize;
  final List<String> _bracePillarSizeOptions = const ['85×25', '85×40'];
  String? _selectedHariSize;
  final List<String> _hariSizeOptions = const ['85×40', '85×55', '70×70', '85×85', '100×100', '105×105'];
  
  List<DrawingElement> _koshitaDrawingElements = [];
  List<DrawingElement> _gawaTsumaDrawingElements = [];
  Uint8List? _koshitaImageBytes;
  Uint8List? _gawaTsumaImageBytes;

  bool _isOuterLengthManuallyEdited = false;
  bool _isOuterWidthManuallyEdited = false;
  bool _isOuterHeightManuallyEdited = false;

  @override
  void initState() {
    super.initState();
    if (widget.templateData != null) {
      _applyTemplate(widget.templateData!);
    } else {
      _selectedSuriGetaType = 'すり材';
      _issueDateController.text = DateFormat('yyyy/MM/dd').format(DateTime.now());
      _loadCalculationMethod = '非計算';
    }
    _initFocusNodes();

    _outerLengthController.addListener(() {
      if (_focusNodes['outerLength']!.hasFocus) _isOuterLengthManuallyEdited = true;
    });
    _outerWidthController.addListener(() {
      if (_focusNodes['outerWidth']!.hasFocus) _isOuterWidthManuallyEdited = true;
    });
    _outerHeightController.addListener(() {
      if (_focusNodes['outerHeight']!.hasFocus) _isOuterHeightManuallyEdited = true;
    });

    final calculationListeners = [
      _innerLengthController, _innerWidthController, _innerHeightController,
      _desiccantPeriodController, _skidThicknessController,
      _suriGetaThicknessController, _getaQuantityController,
      _ceilingUpperBoardThicknessController, _ceilingLowerBoardThicknessController,
      _floorBoardThicknessController, _upperKamachiThicknessController,
      _weightController, _skidWidthController, _loadBearingMaterialWidthController,
      _loadBearingMaterialThicknessController,
      _outerLengthController, _outerWidthController, _outerHeightController,
    ];
    for (var controller in calculationListeners) {
      controller.addListener(_triggerAllCalculations);
    }
    
    // 2点集中荷重計算用リスナー
    void clearB() { if (_l_A_Controller.text.isNotEmpty || _l0Controller.text.isNotEmpty) _clearTwoPointInputs(scenario: 'B'); _calculateTwoPointLoad(); }
    void clearA() { if (_l_B_Controller.text.isNotEmpty || _l1Controller.text.isNotEmpty || _l2Controller.text.isNotEmpty) _clearTwoPointInputs(scenario: 'A'); _calculateTwoPointLoad(); }
    
    _l_A_Controller.addListener(clearB);
    _l0Controller.addListener(clearB);
    _l_B_Controller.addListener(clearA);
    _l1Controller.addListener(clearA);
    _l2Controller.addListener(clearA);

    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerAllCalculations());
  }

  // ▼▼▼ ロジック: データ適用 ▼▼▼
  void _applyTemplate(KochuhyoData data) {
    _shippingDateController.text = data.shippingDate;
    _issueDateController.text = data.issueDate;
    _serialNumberController.text = data.serialNumber;
    _kobangoController.text = data.kobango;
    _shihomeisakiController.text = data.shihomeisaki;
    _hinmeiController.text = data.hinmei;
    _productLengthController.text = data.productLength;
    _productWidthController.text = data.productWidth;
    _productHeightController.text = data.productHeight;
    _weightController.text = data.weight;
    _quantityController.text = data.quantity;
    _selectedShippingType = data.shippingType;
    _selectedPackingForm = data.packingForm;
    _selectedFormType = data.formType;
    _selectedMaterial = data.material;
    _desiccantPeriodController.text = data.desiccantPeriod;
    _selectedDesiccantCoefficient = double.tryParse(data.desiccantCoefficientValue);
    _innerLengthController.text = data.innerLength;
    _innerWidthController.text = data.innerWidth;
    _innerHeightController.text = data.innerHeight;

    _outerLengthController.text = data.outerLength;
    _outerWidthController.text = data.outerWidth;
    _outerHeightController.text = data.outerHeight;
    if (data.outerLength.isNotEmpty) _isOuterLengthManuallyEdited = true;
    if (data.outerWidth.isNotEmpty) _isOuterWidthManuallyEdited = true;
    if (data.outerHeight.isNotEmpty) _isOuterHeightManuallyEdited = true;

    _skidWidthController.text = data.skidWidth;
    _skidThicknessController.text = data.skidThickness;
    _skidQuantityController.text = data.skidQuantity;
    _hWidthController.text = data.hWidth;
    _hThicknessController.text = data.hThickness;
    _hFixingMethod = data.hFixingMethod;
    _selectedSuriGetaType = data.suriGetaType;
    _suriGetaWidthController.text = data.suriGetaWidth;
    _suriGetaThicknessController.text = data.suriGetaThickness;
    _getaQuantityController.text = data.getaQuantity;
    _floorBoardThicknessController.text = data.floorBoardThickness;
    _isJitaMijikame = data.isFloorBoardShort;
    _loadBearingMaterialWidthController.text = data.loadBearingMaterialWidth;
    _loadBearingMaterialThicknessController.text = data.loadBearingMaterialThickness;
    _loadBearingMaterialQuantityController.text = data.loadBearingMaterialQuantity;
    _loadCalculationMethod = data.loadCalculationMethod;
    _sideBoardThicknessController.text = data.sideBoardThickness;
    _selectedKamachiType = data.kamachiType;
    _upperKamachiWidthController.text = data.upperKamachiWidth;
    _upperKamachiThicknessController.text = data.upperKamachiThickness;
    _lowerKamachiWidthController.text = data.lowerKamachiWidth;
    _lowerKamachiThicknessController.text = data.lowerKamachiThickness;
    _pillarWidthController.text = data.pillarWidth;
    _pillarThicknessController.text = data.pillarThickness;
    _beamReceiverWidthController.text = data.beamReceiverWidth;
    _beamReceiverThicknessController.text = data.beamReceiverThickness;
    _beamReceiverEmbed = data.beamReceiverEmbed;
    _bracePillarWidthController.text = data.bracePillarWidth;
    _bracePillarThicknessController.text = data.bracePillarThickness;
    _bracePillarShortEnds = data.bracePillarShortEnds;
    _ceilingUpperBoardThicknessController.text = data.ceilingUpperBoardThickness;
    _ceilingLowerBoardThicknessController.text = data.ceilingLowerBoardThickness;
    _hariWidthController.text = data.hariWidth;
    _hariThicknessController.text = data.hariThickness;
    _hariQuantityController.text = data.hariQuantity;
    _pressingMaterialLengthController.text = data.pressingMaterialLength;
    _pressingMaterialWidthController.text = data.pressingMaterialWidth;
    _pressingMaterialThicknessController.text = data.pressingMaterialThickness;
    _pressingMaterialQuantityController.text = data.pressingMaterialQuantity;
    _pressingMaterialHasMolding = data.pressingMaterialHasMolding;
    _topMaterialLengthController.text = data.topMaterialLength;
    _topMaterialWidthController.text = data.topMaterialWidth;
    _topMaterialThicknessController.text = data.topMaterialThickness;
    _topMaterialQuantityController.text = data.topMaterialQuantity;
    _koshitaImageBytes = data.koshitaImageBytes;
    _gawaTsumaImageBytes = data.gawaTsumaImageBytes;
    _koshitaDrawingElements = data.koshitaDrawingElements
        .map((json) => DrawingElement.fromJson(json))
        .toList();
    _gawaTsumaDrawingElements = data.gawaTsumaDrawingElements
        .map((json) => DrawingElement.fromJson(json))
        .toList();

    for (int i = 0; i < data.rootStops.length && i < _rootStopLengthControllers.length; i++) {
      final parser = DimensionParser(data.rootStops[i]);
      _rootStopLengthControllers[i].text = parser.l;
      _rootStopWidthControllers[i].text = parser.w;
      _rootStopThicknessControllers[i].text = parser.t;
      _rootStopQuantityControllers[i].text = parser.qty;
    }

    for (int i = 0; i < data.additionalParts.length && i < _additionalPartNameControllers.length; i++) {
      final part = data.additionalParts[i];
      _additionalPartNameControllers[i].text = part['name'] ?? '';
      final parser = DimensionParser(part['dims'] ?? '');
      _additionalPartLengthControllers[i].text = parser.l;
      _additionalPartWidthControllers[i].text = parser.w;
      _additionalPartThicknessControllers[i].text = parser.t;
      _additionalPartQuantityControllers[i].text = parser.qty;
    }

    // ドロップダウンの初期値設定
    if (_skidSizeOptions.contains('${data.skidWidth}×${data.skidThickness}')) {
      _selectedSkidSize = '${data.skidWidth}×${data.skidThickness}';
    }
    if (_hSizeOptions.contains('${data.hWidth}×${data.hThickness}')) {
      _selectedHSize = '${data.hWidth}×${data.hThickness}';
    }
    if (_suriGetaSizeOptions.contains('${data.suriGetaWidth}×${data.suriGetaThickness}')) {
      _selectedSuriGetaSize = '${data.suriGetaWidth}×${data.suriGetaThickness}';
    }
    if (_loadBearingMaterialSizeOptions.contains('${data.loadBearingMaterialWidth}×${data.loadBearingMaterialThickness}')) {
      _selectedLoadBearingMaterialSize = '${data.loadBearingMaterialWidth}×${data.loadBearingMaterialThickness}';
    }
    if (_beamReceiverSizeOptions.contains('${data.beamReceiverWidth}×${data.beamReceiverThickness}')) {
      _selectedBeamReceiverSize = '${data.beamReceiverWidth}×${data.beamReceiverThickness}';
    }
    if (_bracePillarSizeOptions.contains('${data.bracePillarWidth}×${data.bracePillarThickness}')) {
      _selectedBracePillarSize = '${data.bracePillarWidth}×${data.bracePillarThickness}';
    }
    if (_hariSizeOptions.contains('${data.hariWidth}×${data.hariThickness}')) {
      _selectedHariSize = '${data.hariWidth}×${data.hariThickness}';
    }
  }

  @override
  void dispose() {
    _focusNodes.forEach((_, node) => node.dispose());
    // 全てのコントローラーを破棄
    final allControllers = [
      _shippingDateController, _issueDateController, _serialNumberController, _kobangoController,
      _shihomeisakiController, _hinmeiController,
      _productLengthController, _productWidthController, _productHeightController,
      _weightController, _quantityController,
      _desiccantPeriodController, _desiccantResultDisplayController,
      _innerLengthController, _innerWidthController, _innerHeightController,
      _outerLengthController, _outerWidthController, _outerHeightController,
      _packagingVolumeDisplayController, _skidWidthController, _skidThicknessController,
      _skidQuantityController, _hWidthController, _hThicknessController,
      _suriGetaWidthController, _suriGetaThicknessController, _getaQuantityController,
      _floorBoardThicknessController, _loadBearingMaterialWidthController,
      _loadBearingMaterialThicknessController, _loadBearingMaterialQuantityController,
      _allowableLoadDisplayController, _l_A_Controller, _l0Controller, _l_B_Controller, _l1Controller, _l2Controller,
      _multiplierDisplayController, _allowableLoadFinalDisplayController,
      ..._rootStopLengthControllers, ..._rootStopWidthControllers, ..._rootStopThicknessControllers, ..._rootStopQuantityControllers,
      _sideBoardThicknessController, _upperKamachiWidthController,
      _upperKamachiThicknessController, _lowerKamachiWidthController, _lowerKamachiThicknessController,
      _pillarWidthController, _pillarThicknessController, _beamReceiverWidthController,
      _beamReceiverThicknessController, _bracePillarWidthController, _bracePillarThicknessController,
      _ceilingUpperBoardThicknessController, _ceilingLowerBoardThicknessController,
      _hariWidthController, _hariThicknessController, _hariQuantityController,
      _pressingMaterialLengthController, _pressingMaterialWidthController,
      _pressingMaterialThicknessController, _pressingMaterialQuantityController,
      _topMaterialLengthController, _topMaterialWidthController, _topMaterialThicknessController,
      _topMaterialQuantityController,
      ..._additionalPartNameControllers, ..._additionalPartLengthControllers,
      ..._additionalPartWidthControllers, ..._additionalPartThicknessControllers,
      ..._additionalPartQuantityControllers
    ];
    for (var controller in allControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // ▼▼▼ フォーカス管理 ▼▼▼
  void _initFocusNodes() {
    _orderedFocusNodeKeys = [
      'shippingDate', 'issueDate', 'serialNumber', 'kobango', 'shihomeisaki', 'hinmei',
      'productLength', 'productWidth', 'productHeight',
      'material', 'weight', 'quantity', 'desiccantPeriod', 'desiccantCoefficient', 'shippingType', 
      'formType', 'packingForm', 'innerLength', 'innerWidth', 'innerHeight',
      'outerLength', 'outerWidth', 'outerHeight', 'skidWidth', 'skidThickness', 'skidQuantity',
      'hWidth', 'hThickness', 'hFixingMethod', 'suriGetaType', 'suriGetaWidth', 'suriGetaThickness', 'getaQuantity',
      'floorBoardThickness', 'loadBearingMaterialWidth', 'loadBearingMaterialThickness', 'loadBearingMaterialQuantity',
      'loadCalculationMethod', 'l_A', 'l0', 'l_B', 'l1', 'l2', 
      ...List.generate(5, (i) => ['rootStopLength_$i', 'rootStopWidth_$i', 'rootStopThickness_$i', 'rootStopQuantity_$i']).expand((x) => x),
      'sideBoardThickness', 'kamachiType', 'upperKamachiWidth', 'upperKamachiThickness',
      'lowerKamachiWidth', 'lowerKamachiThickness', 'pillarWidth', 'pillarThickness',
      'beamReceiverWidth', 'beamReceiverThickness', 'bracePillarWidth', 'bracePillarThickness',
      'ceilingUpperBoardThickness', 'ceilingLowerBoardThickness', 'hariWidth', 'hariThickness', 'hariQuantity',
      'pressingMaterialLength', 'pressingMaterialWidth', 'pressingMaterialThickness', 'pressingMaterialQuantity',
      'topMaterialLength', 'topMaterialWidth', 'topMaterialThickness', 'topMaterialQuantity',
      ...List.generate(5, (i) => ['additionalPartName_$i', 'additionalPartLength_$i', 'additionalPartWidth_$i', 'additionalPartThickness_$i', 'additionalPartQuantity_$i']).expand((x) => x),
    ];
    for (var key in _orderedFocusNodeKeys) {
      _focusNodes[key] = FocusNode();
    }
  }

  void _nextFocus(String currentKey) {
    final currentIndex = _orderedFocusNodeKeys.indexOf(currentKey);
    if (currentIndex != -1 && currentIndex < _orderedFocusNodeKeys.length - 1) {
      final nextKey = _orderedFocusNodeKeys[currentIndex + 1];
      final nextNode = _focusNodes[nextKey];
      if (nextNode != null) {
        if (nextKey.startsWith('l_') && _loadCalculationMethod != '2点集中荷重') {
          _nextFocus(nextKey);
          return;
        }
        FocusScope.of(context).requestFocus(nextNode);
      }
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _selectDate(TextEditingController controller, String currentKey) async {
    DateTime? picked = await showDatePicker(
      context: context, initialDate: DateTime.now(),
      firstDate: DateTime(2000), lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => controller.text = DateFormat('yyyy/MM/dd').format(picked));
      _nextFocus(currentKey);
    } else {
      _nextFocus(currentKey);
    }
  }

  // ▼▼▼ 計算ロジック ▼▼▼
  void _triggerAllCalculations() {
    _calculateOuterDimensions();
    _calculatePackagingVolume();
    _calculateDesiccant();
    _calculateUniformLoad();
    _calculateCentralLoad();
    _calculateTwoPointLoad();
  }

  void _calculateOuterDimensions() {
    final innerLength = double.tryParse(_innerLengthController.text) ?? 0.0;
    final innerWidth = double.tryParse(_innerWidthController.text) ?? 0.0;
    final innerHeight = double.tryParse(_innerHeightController.text) ?? 0.0;
    final upperKamachiThickness = double.tryParse(_upperKamachiThicknessController.text) ?? 0.0;
    double horizontalAddition = 0.0;
    if (upperKamachiThickness == 25.0) {
      horizontalAddition = 80.0;
    } else if (upperKamachiThickness == 40.0) {
      horizontalAddition = 110.0;
    }
    double suriGetaOrGetaThickness = 0.0;
    if (_selectedSuriGetaType == 'すり材' || _selectedSuriGetaType == 'ゲタ') {
        suriGetaOrGetaThickness = double.tryParse(_suriGetaThicknessController.text) ?? 0.0;
    }
    final skidThickness = double.tryParse(_skidThicknessController.text) ?? 0.0;
    final ceilingUpperBoardThickness = double.tryParse(_ceilingUpperBoardThicknessController.text) ?? 0.0;
    final ceilingLowerBoardThickness = double.tryParse(_ceilingLowerBoardThicknessController.text) ?? 0.0;
    final outerLength = innerLength + horizontalAddition;
    final outerWidth = innerWidth + horizontalAddition;
    final outerHeight = innerHeight + suriGetaOrGetaThickness + skidThickness + ceilingUpperBoardThickness + ceilingLowerBoardThickness + 10.0;
    final roundedOuterHeight = (outerHeight / 10).ceil() * 10.0;
    
    setState(() {
      if (!_isOuterLengthManuallyEdited) _outerLengthController.text = outerLength.toStringAsFixed(0);
      if (!_isOuterWidthManuallyEdited) _outerWidthController.text = outerWidth.toStringAsFixed(0);
      if (!_isOuterHeightManuallyEdited) _outerHeightController.text = roundedOuterHeight.toStringAsFixed(0);
    });
  }

  void _calculatePackagingVolume() {
    final outerLength = double.tryParse(_outerLengthController.text) ?? 0.0;
    final outerWidth = double.tryParse(_outerWidthController.text) ?? 0.0;
    final outerHeight = double.tryParse(_outerHeightController.text) ?? 0.0;
    final volume = (outerLength / 1000.0) * (outerWidth / 1000.0) * (outerHeight / 1000.0);
    _packagingVolumeDisplayController.text = volume.toStringAsFixed(3);
  }

  void _calculateDesiccant() {
    final length = double.tryParse(_innerLengthController.text) ?? 0.0;
    final width = double.tryParse(_innerWidthController.text) ?? 0.0;
    final height = double.tryParse(_innerHeightController.text) ?? 0.0;
    final period = double.tryParse(_desiccantPeriodController.text) ?? 0.0;
    final coefficient = _selectedDesiccantCoefficient ?? 0.0;
    if (length <= 0 || width <= 0 || height <= 0 || period <= 0 || coefficient <= 0) {
      _desiccantResultDisplayController.text = '';
      return;
    }
    final surfaceAreaMm2 = (2 * (length * width + length * height + width * height));
    final surfaceAreaM2 = surfaceAreaMm2 / (1000 * 1000);
    final amount = surfaceAreaM2 * 0.15 * period * coefficient * 1.1;
    final roundedAmount = (amount / 0.5).ceil() * 0.5;
    setState(() {
      _desiccantResultDisplayController.text = (roundedAmount == roundedAmount.truncate()) 
        ? roundedAmount.toStringAsFixed(0) 
        : roundedAmount.toStringAsFixed(1);
    });
  }

  double _calculateSpanLength() {
    final innerWidthMm = double.tryParse(_innerWidthController.text) ?? 0.0;
    final skidWidthMm = double.tryParse(_skidWidthController.text) ?? 0.0;
    double lCm = 0.0;
    if (_selectedFormType == '腰下付（合板）') {
      lCm = (innerWidthMm - (skidWidthMm * 2)) / 10.0;
    } else if (_selectedFormType?.contains('わく組') ?? false) {
      if (_selectedKamachiType == 'かまち25') {
        if (skidWidthMm == 70.0) lCm = (innerWidthMm - 90.0) / 10.0;
        else if (skidWidthMm == 85.0) lCm = (innerWidthMm - 120.0) / 10.0;
      } else if (_selectedKamachiType == 'かまち40') {
        if (skidWidthMm == 85.0) lCm = (innerWidthMm - 90.0) / 10.0;
        else if (skidWidthMm == 100.0) lCm = (innerWidthMm - 120.0) / 10.0;
      }
    }
    return lCm;
  }

  void _calculateUniformLoad() {
    if (_loadCalculationMethod != '等分布荷重') {
      if (_loadCalculationMethod != '中央集中荷重') _allowableLoadDisplayController.text = '';
      return;
    }
    final lCm = _calculateSpanLength();
    final bMm = double.tryParse(_loadBearingMaterialWidthController.text) ?? 0.0;
    final hMm = double.tryParse(_loadBearingMaterialThicknessController.text) ?? 0.0;
    if (lCm <= 0 || bMm <= 0 || hMm <= 0) {
      setState(() {
        _wUniform = 0;
        _allowableLoadDisplayController.text = '計算不可';
        if (_loadCalculationMethod == '等分布荷重') _loadBearingMaterialQuantityController.text = '';
      });
      return;
    }
    final bCm = bMm / 10.0;
    final hCm = hMm / 10.0;
    const fb = 107;
    final wKg = (4 * bCm * (hCm * hCm) * fb) / (3 * lCm);
    setState(() {
      _wUniform = wKg;
      _allowableLoadDisplayController.text = _wUniform.toStringAsFixed(1);
      if (_loadCalculationMethod == '等分布荷重') {
        final totalWeight = double.tryParse(_weightController.text) ?? 0.0;
        int quantity = 0;
        if (_wUniform > 0 && totalWeight > 0) quantity = (totalWeight / _wUniform).ceil();
        _loadBearingMaterialQuantityController.text = quantity.toString();
      }
    });
  }

  void _calculateCentralLoad() {
    if (_loadCalculationMethod != '中央集中荷重') return;
    final lCm = _calculateSpanLength();
    final bMm = double.tryParse(_loadBearingMaterialWidthController.text) ?? 0.0;
    final hMm = double.tryParse(_loadBearingMaterialThicknessController.text) ?? 0.0;
    if (lCm <= 0 || bMm <= 0 || hMm <= 0) {
      setState(() { _allowableLoadDisplayController.text = '計算不可'; });
      return;
    }
    final bCm = bMm / 10.0;
    final hCm = hMm / 10.0;
    const fb = 107;
    final wKg = (2 * bCm * (hCm * hCm) * fb) / (3 * lCm);
    setState(() { _allowableLoadDisplayController.text = wKg.toStringAsFixed(1); });
  }

  void _clearTwoPointInputs({required String scenario}) {
    if (scenario == 'A') {
      _l_A_Controller.clear();
      _l0Controller.clear();
    } else if (scenario == 'B') {
      _l_B_Controller.clear();
      _l1Controller.clear();
      _l2Controller.clear();
    }
  }

  void _calculateTwoPointLoad() {
    if (_loadCalculationMethod != '2点集中荷重') {
      setState(() {
        _multiplierDisplayController.text = '';
        _allowableLoadFinalDisplayController.text = '';
        if (_loadCalculationMethod != '等分布荷重') _loadBearingMaterialQuantityController.text = '';
      });
      return;
    }
    final l_A = double.tryParse(_l_A_Controller.text) ?? 0.0;
    final l0 = double.tryParse(_l0Controller.text) ?? 0.0;
    final l_B = double.tryParse(_l_B_Controller.text) ?? 0.0;
    double l1 = double.tryParse(_l1Controller.text) ?? 0.0;
    double l2 = double.tryParse(_l2Controller.text) ?? 0.0;
    double multiplier = 0;
    if (l_A > 0 && l0 > 0) {
      multiplier = l_A / (4 * l0);
    } else if (l_B > 0 && (l1 > 0 || l2 > 0)) {
        if (l2 > l1) { final temp = l1; l1 = l2; l2 = temp; }
        final denominator = 4 * (l_B - l1 + l2) * l1;
        if (denominator > 0) multiplier = (l_B * l_B) / denominator;
    }
    if (multiplier <= 0) {
      setState(() {
        _multiplierDisplayController.text = '計算不可';
        _allowableLoadFinalDisplayController.text = '';
        _loadBearingMaterialQuantityController.text = '';
      });
      return;
    }
    if (multiplier > 2.0) multiplier = 2.0;
    final wFinal = _wUniform * multiplier;
    final totalWeight = double.tryParse(_weightController.text) ?? 0.0;
    int quantity = 0;
    if (wFinal > 0 && totalWeight > 0) quantity = (totalWeight / wFinal).ceil();
    setState(() {
      _multiplierDisplayController.text = multiplier.toStringAsFixed(2);
      _allowableLoadFinalDisplayController.text = wFinal.toStringAsFixed(1);
      _loadBearingMaterialQuantityController.text = quantity.toString();
    });
  }

  void _updateKamachiDimensions(String? value) {
    setState(() {
      _selectedKamachiType = value;
      String width = '';
      String thickness = '';
      if (value == 'かまち25') {
        width = '85'; thickness = '25';
      } else if (value == 'かまち40') {
        width = '85'; thickness = '40';
      }
      _upperKamachiWidthController.text = width;
      _upperKamachiThicknessController.text = thickness;
      _lowerKamachiWidthController.text = width;
      _lowerKamachiThicknessController.text = thickness;
      _pillarWidthController.text = width;
      _pillarThicknessController.text = thickness;
    });
    _triggerAllCalculations();
  }

  void _updateDimensionsFromDropdown(String? selectedValue, TextEditingController widthController, TextEditingController thicknessController) {
    if (selectedValue == null) return;
    final parts = selectedValue.split('×');
    if (parts.length == 2) {
      setState(() {
        widthController.text = parts[0];
        thicknessController.text = parts[1];
      });
      _triggerAllCalculations();
    }
  }

  // ▼▼▼ 画面遷移 & 保存 ▼▼▼
  void _navigateToKoshitaDrawingScreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DrawingScreen(
          initialElements: _koshitaDrawingElements,
          backgroundImagePath: 'assets/koshita_base.jpg',
          title: '腰下ベース',
        ),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _koshitaDrawingElements = result['elements'] as List<DrawingElement>? ?? _koshitaDrawingElements;
        _koshitaImageBytes = result['imageBytes'] as Uint8List?;
      });
    }
  }

  void _navigateToGawaTsumaDrawingScreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DrawingScreen(
          initialElements: _gawaTsumaDrawingElements,
          backgroundImagePath: 'assets/gawa_tsuma_base.jpg',
          title: '側・妻',
        ),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _gawaTsumaDrawingElements = result['elements'] as List<DrawingElement>? ?? _gawaTsumaDrawingElements;
        _gawaTsumaImageBytes = result['imageBytes'] as Uint8List?;
      });
    }
  }

  KochuhyoData _collectData() {
    String twoPointLoadDetails = '';
    if (_loadCalculationMethod == '2点集中荷重') {
      if (_l_A_Controller.text.isNotEmpty) {
        twoPointLoadDetails = '均等(l=${_l_A_Controller.text}, l0=${_l0Controller.text})';
      } else if (_l_B_Controller.text.isNotEmpty) {
        twoPointLoadDetails = '不均等(l=${_l_B_Controller.text}, l1=${_l1Controller.text}, l2=${_l2Controller.text})';
      }
      twoPointLoadDetails += ' 倍率:${_multiplierDisplayController.text}';
    }

    return KochuhyoData(
      shippingDate: _shippingDateController.text,
      issueDate: _issueDateController.text,
      serialNumber: _serialNumberController.text,
      kobango: _kobangoController.text,
      shihomeisaki: _shihomeisakiController.text,
      hinmei: _hinmeiController.text,
      productLength: _productLengthController.text,
      productWidth: _productWidthController.text,
      productHeight: _productHeightController.text,
      weight: _weightController.text,
      quantity: _quantityController.text,
      shippingType: _selectedShippingType ?? '未選択',
      packingForm: _selectedPackingForm ?? '未選択',
      formType: _selectedFormType ?? '未選択',
      material: _selectedMaterial ?? '未選択',
      desiccantPeriod: _desiccantPeriodController.text,
      desiccantCoefficientValue: _selectedDesiccantCoefficient?.toString() ?? '未選択',
      desiccantAmount: '${_desiccantResultDisplayController.text}${_desiccantResultDisplayController.text.isNotEmpty ? " kg" : ""}',
      innerLength: _innerLengthController.text,
      innerWidth: _innerWidthController.text,
      innerHeight: _innerHeightController.text,
      outerLength: _outerLengthController.text,
      outerWidth: _outerWidthController.text,
      outerHeight: _outerHeightController.text,
      packagingVolume: _packagingVolumeDisplayController.text,
      skid: '${_skidWidthController.text}w x ${_skidThicknessController.text}t x ${_skidQuantityController.text}本',
      h: '${_hWidthController.text}w x ${_hThicknessController.text}t',
      hFixingMethod: _hFixingMethod ?? '未選択',
      suriGetaType: _selectedSuriGetaType ?? '未選択',
      suriGeta: '${_suriGetaWidthController.text}w x ${_suriGetaThicknessController.text}t',
      getaQuantity: _getaQuantityController.text,
      floorBoard: '${_floorBoardThicknessController.text}t',
      isFloorBoardShort: _isJitaMijikame,
      loadBearingMaterial: '${_loadBearingMaterialWidthController.text}w x ${_loadBearingMaterialThicknessController.text}t x ${_loadBearingMaterialQuantityController.text}本',
      allowableLoadUniform: _allowableLoadDisplayController.text,
      loadCalculationMethod: _loadCalculationMethod ?? '未選択',
      twoPointLoadDetails: twoPointLoadDetails,
      finalAllowableLoad: _allowableLoadFinalDisplayController.text,
      rootStops: List.generate(5, (i) => 'L${_rootStopLengthControllers[i].text} x W${_rootStopWidthControllers[i].text} x T${_rootStopThicknessControllers[i].text}・${_rootStopQuantityControllers[i].text}本'),
      sideBoard: '${_sideBoardThicknessController.text}t',
      kamachiType: _selectedKamachiType ?? '未選択',
      upperKamachi: '${_upperKamachiWidthController.text}w x ${_upperKamachiThicknessController.text}t',
      lowerKamachi: '${_lowerKamachiWidthController.text}w x ${_lowerKamachiThicknessController.text}t',
      pillar: '${_pillarWidthController.text}w x ${_pillarThicknessController.text}t',
      beamReceiver: '${_beamReceiverWidthController.text}w x ${_beamReceiverThicknessController.text}t',
      bracePillar: '${_bracePillarWidthController.text}w x ${_bracePillarThicknessController.text}t',
      beamReceiverEmbed: _beamReceiverEmbed,
      bracePillarShortEnds: _bracePillarShortEnds,
      ceilingUpperBoard: '${_ceilingUpperBoardThicknessController.text}t',
      ceilingLowerBoard: '${_ceilingLowerBoardThicknessController.text}t',
      hari: '${_hariWidthController.text}w x ${_hariThicknessController.text}t x ${_hariQuantityController.text}本',
      pressingMaterial: 'L${_pressingMaterialLengthController.text} x W${_pressingMaterialWidthController.text} x T${_pressingMaterialThicknessController.text}・${_pressingMaterialQuantityController.text}本',
      pressingMaterialHasMolding: _pressingMaterialHasMolding,
      topMaterial: 'L${_topMaterialLengthController.text} x W${_topMaterialWidthController.text} x T${_topMaterialThicknessController.text}・${_topMaterialQuantityController.text}本',
      additionalParts: List.generate(5, (i) => {
        'name': _additionalPartNameControllers[i].text,
        'dims': 'L${_additionalPartLengthControllers[i].text} x W${_additionalPartWidthControllers[i].text} x T${_additionalPartThicknessControllers[i].text}・${_additionalPartQuantityControllers[i].text}本',
      }),
      koshitaImageBytes: _koshitaImageBytes,
      gawaTsumaImageBytes: _gawaTsumaImageBytes,
      skidWidth: _skidWidthController.text,
      skidThickness: _skidThicknessController.text,
      skidQuantity: _skidQuantityController.text,
      hWidth: _hWidthController.text,
      hThickness: _hThicknessController.text,
      suriGetaWidth: _suriGetaWidthController.text,
      suriGetaThickness: _suriGetaThicknessController.text,
      floorBoardThickness: _floorBoardThicknessController.text,
      loadBearingMaterialWidth: _loadBearingMaterialWidthController.text,
      loadBearingMaterialThickness: _loadBearingMaterialThicknessController.text,
      loadBearingMaterialQuantity: _loadBearingMaterialQuantityController.text,
      sideBoardThickness: _sideBoardThicknessController.text,
      upperKamachiWidth: _upperKamachiWidthController.text,
      upperKamachiThickness: _upperKamachiThicknessController.text,
      lowerKamachiWidth: _lowerKamachiWidthController.text,
      lowerKamachiThickness: _lowerKamachiThicknessController.text,
      pillarWidth: _pillarWidthController.text,
      pillarThickness: _pillarThicknessController.text,
      beamReceiverWidth: _beamReceiverWidthController.text,
      beamReceiverThickness: _beamReceiverThicknessController.text,
      bracePillarWidth: _bracePillarWidthController.text,
      bracePillarThickness: _bracePillarThicknessController.text,
      ceilingUpperBoardThickness: _ceilingUpperBoardThicknessController.text,
      ceilingLowerBoardThickness: _ceilingLowerBoardThicknessController.text,
      hariWidth: _hariWidthController.text,
      hariThickness: _hariThicknessController.text,
      hariQuantity: _hariQuantityController.text,
      pressingMaterialLength: _pressingMaterialLengthController.text,
      pressingMaterialWidth: _pressingMaterialWidthController.text,
      pressingMaterialThickness: _pressingMaterialThicknessController.text,
      pressingMaterialQuantity: _pressingMaterialQuantityController.text,
      topMaterialLength: _topMaterialLengthController.text,
      topMaterialWidth: _topMaterialWidthController.text,
      topMaterialThickness: _topMaterialThicknessController.text,
      topMaterialQuantity: _topMaterialQuantityController.text,
      koshitaDrawingElements: _koshitaDrawingElements.map((e) => e.toJson()).toList(),
      gawaTsumaDrawingElements: _gawaTsumaDrawingElements.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> _navigateToPreviewScreen() async {
    final data = _collectData();
    await _saveToHistory(data);
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PrintPreviewScreen(data: data),
      ));
    }
  }

  Future<void> _saveToHistory(KochuhyoData data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${directory.path}/history');
      if (!await historyDir.exists()) await historyDir.create(recursive: true);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${historyDir.path}/history_$timestamp.json');
      await file.writeAsString(jsonEncode(data.toJson()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('履歴の保存に失敗しました: $e'), backgroundColor: Colors.red));
    }
  }

  void _saveAsNewTemplate() async {
    final data = _collectData();
    final jsonString = jsonEncode(data.toJson());
    final productNameController = TextEditingController();
    final defaultFileName = _hinmeiController.text;
    final templateNameController = TextEditingController(text: defaultFileName);

    final directory = await getApplicationDocumentsDirectory();
    final List<Directory> folders = [];
    if (await directory.exists()) {
      final entities = directory.listSync();
      for (var entity in entities) {
        if (entity is Directory && !entity.path.endsWith('/history')) folders.add(entity);
      }
    }
    final folderNames = folders.map((f) => f.path.split(Platform.pathSeparator).last).toList()..sort();
    String? selectedFolder;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('新規テンプレートとして保存'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedFolder,
                    hint: const Text('既存の製品フォルダを選択'),
                    items: folderNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedFolder = value;
                        productNameController.clear();
                      });
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  const Center(child: Text('または')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: productNameController,
                    onChanged: (value) { if (selectedFolder != null) setState(() { selectedFolder = null; }); },
                    decoration: const InputDecoration(labelText: '新規製品名 (フォルダ名)', hintText: '例: 製品A', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: templateNameController,
                    decoration: const InputDecoration(labelText: 'テンプレート名 (ファイル名)', hintText: '例: 基本パターン', border: OutlineInputBorder()),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('キャンセル')),
                TextButton(
                  onPressed: () {
                    final productName = selectedFolder ?? productNameController.text;
                    if (productName.isNotEmpty && templateNameController.text.isNotEmpty) {
                      Navigator.of(context).pop({'product': productName, 'template': templateNameController.text});
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('製品名とテンプレート名を入力してください。'), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final productName = result['product']!;
      final templateName = result['template']!;
      try {
        final productDir = Directory('${directory.path}/$productName');
        if (!await productDir.exists()) await productDir.create(recursive: true);
        final path = '${productDir.path}/$templateName.json';
        final file = File(path);
        await file.writeAsString(jsonString);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('製品「$productName」にテンプレート「$templateName」を保存しました。'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _overwriteTemplate() async {
    if (widget.templatePath == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('上書き保存の確認'),
        content: const Text('現在の内容でこのテンプレートを上書きします。\nよろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('上書き保存', style: TextStyle(color: Colors.blue))),
        ],
      ),
    );
    if (confirmed != true) return;
    final data = _collectData();
    try {
      final file = File(widget.templatePath!);
      await file.writeAsString(jsonEncode(data.toJson()));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('テンプレートを上書き保存しました。'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('上書き保存に失敗しました: $e'), backgroundColor: Colors.red));
    }
  }

  // ▼▼▼ 画面構築 (タブ構成) ▼▼▼
  @override
  Widget build(BuildContext context) {
    bool isTwoPointLoad = _loadCalculationMethod == '2点集中荷重';

    final tabs = [
      const Tab(text: '基本情報'),
      const Tab(text: '寸法'),
      const Tab(text: '腰下'),
      const Tab(text: '側・妻'),
      const Tab(text: '天井'),
      const Tab(text: '梱包材'),
      const Tab(text: '追加部材'),
    ];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DefaultTabController(
        length: tabs.length,
        initialIndex: 0,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('工注票', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            bottom: TabBar(
              tabs: tabs,
              isScrollable: true,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueAccent,
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildBasicInfoTab()),
                      SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildDimensionsTab()),
                      SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildKoshitaTab(isTwoPointLoad)),
                      SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildGawaTsumaTab()),
                      SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildTenjoTab()),
                      SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildKonpozaiTab()),
                      SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildAdditionalPartsTab()),
                    ],
                  ),
                ),
                _buildBottomButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, -3))],
      ),
      child: Center(
        child: Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          alignment: WrapAlignment.center,
          children: [
            if (widget.templatePath != null)
              ElevatedButton.icon(
                onPressed: _overwriteTemplate,
                icon: const Icon(Icons.save),
                label: const Text('上書き保存'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
              ),
            ElevatedButton(onPressed: _saveAsNewTemplate, child: const Text('別名で保存')),
            ElevatedButton.icon(
              onPressed: _navigateToPreviewScreen,
              icon: const Icon(Icons.print),
              label: const Text('印刷プレビュー'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ▼▼▼ タブ内コンテンツ構築 ▼▼▼

  Widget _buildBasicInfoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: LabeledDateInput(label: '出荷日', controller: _shippingDateController, focusNode: _focusNodes['shippingDate'], onTap: () => _selectDate(_shippingDateController, 'shippingDate'))),
            const SizedBox(width: 16),
            Expanded(child: LabeledDateInput(label: '発行日', controller: _issueDateController, focusNode: _focusNodes['issueDate'], onTap: () => _selectDate(_issueDateController, 'issueDate'))),
          ],
        ),
        LabeledTextField(label: '整理番号', controller: _serialNumberController, hintText: 'A-100', focusNode: _focusNodes['serialNumber'], onSubmitted: () => _nextFocus('serialNumber')),
        LabeledTextField(label: '工番', controller: _kobangoController, focusNode: _focusNodes['kobango'], onSubmitted: () => _nextFocus('kobango')),
        LabeledTextField(label: '仕向先', controller: _shihomeisakiController, focusNode: _focusNodes['shihomeisaki'], onSubmitted: () => _nextFocus('shihomeisaki')),
        LabeledTextField(label: '品名', controller: _hinmeiController, focusNode: _focusNodes['hinmei'], onSubmitted: () => _nextFocus('hinmei')),
        _buildLabeledTripleInputRow('製品サイズ',
          'productLength', _productLengthController, '長',
          'productWidth', _productWidthController, '幅',
          'productHeight', _productHeightController, '高'
        ),
        LabeledDropdown<String>(
          label: '材質',
          value: _selectedMaterial,
          items: _materialOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) { setState(() => _selectedMaterial = value); _nextFocus('material'); },
          hint: '材質を選択',
          focusNode: _focusNodes['material'],
        ),
        LabeledTextField(label: '重量', controller: _weightController, keyboardType: TextInputType.number, unit: 'KG', focusNode: _focusNodes['weight'], onSubmitted: () => _nextFocus('weight')),
        LabeledTextField(label: '数量', controller: _quantityController, keyboardType: TextInputType.number, unit: 'C/S', focusNode: _focusNodes['quantity'], onSubmitted: () => _nextFocus('quantity')),
        
        VerticalInputGroup("乾燥剤", Row(children: [
          Expanded(flex: 2, child: LabeledTextField(label: '期間', controller: _desiccantPeriodController, keyboardType: TextInputType.number, hintText: '期間', unit: 'ヶ月', showLabel: false, focusNode: _focusNodes['desiccantPeriod'], onSubmitted: () => _nextFocus('desiccantPeriod'))),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: LabeledDropdown<double>(
            label: '',
            value: _selectedDesiccantCoefficient,
            items: _desiccantCoefficients.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: (value) { setState(() => _selectedDesiccantCoefficient = value); _calculateDesiccant(); _nextFocus('desiccantCoefficient'); },
            hint: '係数',
            focusNode: _focusNodes['desiccantCoefficient'],
          )),
          const SizedBox(width: 8),
          const Text('=', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: LabeledTextField(label: '結果', controller: _desiccantResultDisplayController, readOnly: true, hintText: '結果', unit: 'kg', showLabel: false)),
        ])),
        const SizedBox(height: 16),
        RadioGroup(title: "出荷形態", groupValue: _selectedShippingType, options: const ['国内', '輸出'], onChanged: (val) { setState(() => _selectedShippingType = val); _nextFocus('shippingType'); }, focusNode: _focusNodes['shippingType']),
        const SizedBox(height: 16),
        RadioGroup(title: "形式", groupValue: _selectedFormType, options: _formTypeOptions, onChanged: (val) { setState(() => _selectedFormType = val); _triggerAllCalculations(); _nextFocus('formType'); }, focusNode: _focusNodes['formType']),
        const SizedBox(height: 16),
        RadioGroup(title: "形状", groupValue: _selectedPackingForm, options: const ['密閉', 'すかし'], onChanged: (val) { setState(() => _selectedPackingForm = val); _nextFocus('packingForm'); }, focusNode: _focusNodes['packingForm']),
      ],
    );
  }

  Widget _buildDimensionsTab() {
    return Column(
      children: [
        _buildTripleInputRow('内寸',
          'innerLength', _innerLengthController, '長',
          'innerWidth', _innerWidthController, '幅',
          'innerHeight', _innerHeightController, '高'
        ),
        _buildTripleInputRow('外寸',
          'outerLength', _outerLengthController, '長',
          'outerWidth', _outerWidthController, '幅',
          'outerHeight', _outerHeightController, '高',
        ),
        LabeledTextField(label: '梱包明細: 容積', controller: _packagingVolumeDisplayController, readOnly: true, unit: 'm³'),
      ],
    );
  }

  Widget _buildKoshitaTab(bool isTwoPointLoad) {
    return Column(
      children: [
         VerticalInputGroup('滑材', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildTripleInputRowWithUnit(
              'skidWidth', _skidWidthController, '幅',
              'skidThickness', _skidThicknessController, '厚',
              'skidQuantity', _skidQuantityController, '本',
            ),
            const SizedBox(height: 8),
            DimensionDropdown(selectedValue: _selectedSkidSize, options: _skidSizeOptions, onChanged: (v) { setState(() { _selectedSkidSize = v; }); _updateDimensionsFromDropdown(v, _skidWidthController, _skidThicknessController); }, hintText: '滑材サイズを選択'),
          ])),
        
        VerticalInputGroup('H', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(flex: 3, child: _buildDoubleInputRowWithUnit('hWidth', _hWidthController, '幅', 'hThickness', _hThicknessController, '厚さ')),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('止め方', style: TextStyle(fontSize: 12)),
                RadioGroup(groupValue: _hFixingMethod, options: const ['釘', 'ボルト'], onChanged: (v) => setState(() => _hFixingMethod = v), focusNode: _focusNodes['hFixingMethod']),
              ])),
            ]),
            const SizedBox(height: 8),
            DimensionDropdown(selectedValue: _selectedHSize, options: _hSizeOptions, onChanged: (v) { setState(() { _selectedHSize = v; }); _updateDimensionsFromDropdown(v, _hWidthController, _hThicknessController); }, hintText: 'Hサイズを選択'),
        ])),
        
        VerticalInputGroup('すり材 or ゲタ', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
             RadioGroup(groupValue: _selectedSuriGetaType, options: const ['すり材', 'ゲタ'], onChanged: (v) { setState(() { _selectedSuriGetaType = v; _triggerAllCalculations(); }); }, focusNode: _focusNodes['suriGetaType']),
              Row(children: [
                Expanded(child: LabeledTextField(controller: _suriGetaWidthController, keyboardType: TextInputType.number, hintText: '幅', unit: 'mm', showLabel: false, focusNode: _focusNodes['suriGetaWidth'], onSubmitted: () => _nextFocus('suriGetaWidth'))),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
                Expanded(child: LabeledTextField(controller: _suriGetaThicknessController, keyboardType: TextInputType.number, hintText: '厚さ', unit: 'mm', showLabel: false, focusNode: _focusNodes['suriGetaThickness'], onSubmitted: () => _nextFocus('suriGetaThickness'))),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('・')),
                Expanded(child: LabeledTextField(controller: _getaQuantityController, keyboardType: TextInputType.number, hintText: '本数', unit: '本', enabled: _selectedSuriGetaType == 'ゲタ', showLabel: false, focusNode: _focusNodes['getaQuantity'], onSubmitted: () => _nextFocus('getaQuantity'))),
              ]),
              const SizedBox(height: 8),
              DimensionDropdown(selectedValue: _selectedSuriGetaSize, options: _suriGetaSizeOptions, onChanged: (v) { setState(() { _selectedSuriGetaSize = v; }); _updateDimensionsFromDropdown(v, _suriGetaWidthController, _suriGetaThicknessController); }, hintText: 'すり材/ゲタ サイズを選択'),
        ])),
        
        VerticalInputGroup('床板', Row(children: [
            Expanded(child: LabeledTextField(controller: _floorBoardThicknessController, keyboardType: TextInputType.number, unit: 'mm', showLabel: false, focusNode: _focusNodes['floorBoardThickness'], onSubmitted: () => _nextFocus('floorBoardThickness'))),
            Row(mainAxisSize: MainAxisSize.min, children: [
                Checkbox(value: _isJitaMijikame, onChanged: (v) => setState(() => _isJitaMijikame = v ?? false)),
                GestureDetector(onTap: () => setState(() => _isJitaMijikame = !_isJitaMijikame), child: const Text('地板短め')),
            ]),
        ])),
        
        VerticalInputGroup('負荷床材', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: LabeledTextField(controller: _loadBearingMaterialWidthController, hintText: '幅', keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes['loadBearingMaterialWidth'], onSubmitted: () => _nextFocus('loadBearingMaterialWidth'))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
              Expanded(child: LabeledTextField(controller: _loadBearingMaterialThicknessController, hintText: '厚さ', keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes['loadBearingMaterialThickness'], onSubmitted: () => _nextFocus('loadBearingMaterialThickness'))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('・')),
              Expanded(child: LabeledTextField(controller: _loadBearingMaterialQuantityController, hintText: '本', keyboardType: TextInputType.number, showLabel: false, unit: '本', enabled: _loadCalculationMethod != '2点集中荷重', focusNode: _focusNodes['loadBearingMaterialQuantity'], onSubmitted: () => _nextFocus('loadBearingMaterialQuantity'))),
            ]),
            const SizedBox(height: 8),
            DimensionDropdown(selectedValue: _selectedLoadBearingMaterialSize, options: _loadBearingMaterialSizeOptions, onChanged: (v) { setState(() { _selectedLoadBearingMaterialSize = v; }); _updateDimensionsFromDropdown(v, _loadBearingMaterialWidthController, _loadBearingMaterialThicknessController); }, hintText: '負荷床材サイズを選択'),
        ])),
        
        if (_loadCalculationMethod == '等分布荷重' || _loadCalculationMethod == '中央集中荷重')
          VerticalInputGroup(_loadCalculationMethod == '等分布荷重' ? '許容荷重W[等分布]' : '許容荷重W[中央集中]', 
            LabeledTextField(controller: _allowableLoadDisplayController, readOnly: true, unit: 'kg/本', showLabel: false)),
          
        RadioGroup(title: "計算方法", groupValue: _loadCalculationMethod, options: const ['非計算', '等分布荷重', '中央集中荷重', '2点集中荷重'], onChanged: (val) {
          setState(() {
            _loadCalculationMethod = val;
            _allowableLoadDisplayController.clear();
            _multiplierDisplayController.clear();
            _allowableLoadFinalDisplayController.clear();
            if (val != '等分布荷重') _loadBearingMaterialQuantityController.clear();
            if (val != '非計算') _triggerAllCalculations();
          });
          _nextFocus('loadCalculationMethod');
        }, focusNode: _focusNodes['loadCalculationMethod']),
        
        if (isTwoPointLoad) Container(
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4.0)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('2点集中荷重 詳細入力', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              const SizedBox(height: 12),
              const Text('シナリオA: 均等配置', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(children: [
                Expanded(child: VerticalInputGroup("l", LabeledTextField(controller: _l_A_Controller, keyboardType: TextInputType.number, unit: 'cm', showLabel: false, focusNode: _focusNodes['l_A'], onSubmitted: () => _nextFocus('l_A')))),
                const SizedBox(width: 8),
                Expanded(child: VerticalInputGroup("l0", LabeledTextField(controller: _l0Controller, keyboardType: TextInputType.number, unit: 'cm', showLabel: false, focusNode: _focusNodes['l0'], onSubmitted: () => _nextFocus('l0')))),
              ]),
              const SizedBox(height: 12),
              const Text('シナリオB: 不均等配置', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(children: [
                Expanded(child: VerticalInputGroup("l", LabeledTextField(controller: _l_B_Controller, keyboardType: TextInputType.number, unit: 'cm', showLabel: false, focusNode: _focusNodes['l_B'], onSubmitted: () => _nextFocus('l_B')))),
                const SizedBox(width: 8),
                Expanded(child: VerticalInputGroup("l1", LabeledTextField(controller: _l1Controller, keyboardType: TextInputType.number, unit: 'cm', showLabel: false, focusNode: _focusNodes['l1'], onSubmitted: () => _nextFocus('l1')))),
                const SizedBox(width: 8),
                Expanded(child: VerticalInputGroup("l2", LabeledTextField(controller: _l2Controller, keyboardType: TextInputType.number, unit: 'cm', showLabel: false, focusNode: _focusNodes['l2'], onSubmitted: () => _nextFocus('l2')))),
              ]),
              const SizedBox(height: 12),
              const Divider(),
              VerticalInputGroup('倍率', LabeledTextField(controller: _multiplierDisplayController, readOnly: true, showLabel: false)),
              VerticalInputGroup('最終許容荷重(kg/本)', LabeledTextField(controller: _allowableLoadFinalDisplayController, readOnly: true, showLabel: false)),
            ]),
        ),

        VerticalInputGroup('根止め', Column(children: [
            for (int i = 0; i < 5; i++) Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: _buildQuadInputRow(
                'rootStopLength_$i', _rootStopLengthControllers[i], 'L',
                'rootStopWidth_$i', _rootStopWidthControllers[i], 'W',
                'rootStopThickness_$i', _rootStopThicknessControllers[i], 'T',
                'rootStopQuantity_$i', _rootStopQuantityControllers[i], '本'
              ),
            ),
        ])),
        
        const SizedBox(height: 16),
        DrawingPreview(title: '図面手書き入力 (腰下ベース)', onTap: _navigateToKoshitaDrawingScreen, imageBytes: _koshitaImageBytes, placeholder: 'タップして腰下ベースを描く'),
      ],
    );
  }

  Widget _buildGawaTsumaTab() {
    return Column(
      children: [
        VerticalInputGroup('外板', LabeledTextField(controller: _sideBoardThicknessController, keyboardType: TextInputType.number, unit: 'mm', showLabel: false, focusNode: _focusNodes['sideBoardThickness'], onSubmitted: () => _nextFocus('sideBoardThickness'))),
        RadioGroup(title: "かまち種類", groupValue: _selectedKamachiType, options: const ['かまち25', 'かまち40'], onChanged: _updateKamachiDimensions, focusNode: _focusNodes['kamachiType']),
        VerticalInputGroup('上かまち', _buildDoubleInputRowWithUnit('upperKamachiWidth', _upperKamachiWidthController, '幅', 'upperKamachiThickness', _upperKamachiThicknessController, '厚さ')),
        VerticalInputGroup('下かまち', _buildDoubleInputRowWithUnit('lowerKamachiWidth', _lowerKamachiWidthController, '幅', 'lowerKamachiThickness', _lowerKamachiThicknessController, '厚さ')),
        VerticalInputGroup('支柱', _buildDoubleInputRowWithUnit('pillarWidth', _pillarWidthController, '幅', 'pillarThickness', _pillarThicknessController, '厚さ')),
        
        VerticalInputGroup('はり受', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
             _buildDimensionWithCheckbox(null, 'beamReceiverWidth', _beamReceiverWidthController, 'beamReceiverThickness', _beamReceiverThicknessController, '埋める', _beamReceiverEmbed, (v) => setState(() => _beamReceiverEmbed = v!)),
             const SizedBox(height: 8),
             DimensionDropdown(selectedValue: _selectedBeamReceiverSize, options: _beamReceiverSizeOptions, onChanged: (v) { setState(() { _selectedBeamReceiverSize = v; }); _updateDimensionsFromDropdown(v, _beamReceiverWidthController, _beamReceiverThicknessController); }, hintText: 'はり受サイズを選択'),
        ])),
         VerticalInputGroup('そえ柱', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildDimensionWithCheckbox(null, 'bracePillarWidth', _bracePillarWidthController, 'bracePillarThickness', _bracePillarThicknessController, '両端短め', _bracePillarShortEnds, (v) => setState(() => _bracePillarShortEnds = v!)),
            const SizedBox(height: 8),
            DimensionDropdown(selectedValue: _selectedBracePillarSize, options: _bracePillarSizeOptions, onChanged: (v) { setState(() { _selectedBracePillarSize = v; }); _updateDimensionsFromDropdown(v, _bracePillarWidthController, _bracePillarThicknessController); }, hintText: 'そえ柱サイズを選択'),
        ])),
        
        const SizedBox(height: 16),
        DrawingPreview(title: '図面手書き入力 (側・妻)', onTap: _navigateToGawaTsumaDrawingScreen, imageBytes: _gawaTsumaImageBytes, placeholder: 'タップして側・妻を描く'),
      ],
    );
  }

  Widget _buildTenjoTab() {
    return Row(children: [
        Expanded(child: VerticalInputGroup('上板', LabeledTextField(controller: _ceilingUpperBoardThicknessController, keyboardType: TextInputType.number, unit: 'mm', showLabel: false, focusNode: _focusNodes['ceilingUpperBoardThickness'], onSubmitted: () => _nextFocus('ceilingUpperBoardThickness')))),
        const SizedBox(width: 16),
        Expanded(child: VerticalInputGroup('下板', LabeledTextField(controller: _ceilingLowerBoardThicknessController, keyboardType: TextInputType.number, unit: 'mm', showLabel: false, focusNode: _focusNodes['ceilingLowerBoardThickness'], onSubmitted: () => _nextFocus('ceilingLowerBoardThickness')))),
    ]);
  }

  Widget _buildKonpozaiTab() {
    return Column(children: [
        VerticalInputGroup('ハリ', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
             _buildTripleInputRowWithUnit('hariWidth', _hariWidthController, '幅', 'hariThickness', _hariThicknessController, '厚', 'hariQuantity', _hariQuantityController, '本'),
             const SizedBox(height: 8),
             DimensionDropdown(selectedValue: _selectedHariSize, options: _hariSizeOptions, onChanged: (v) { setState(() { _selectedHariSize = v; }); _updateDimensionsFromDropdown(v, _hariWidthController, _hariThicknessController); }, hintText: 'ハリ サイズを選択'),
        ])),
        VerticalInputGroup('押さえ材', Column(children: [
            _buildQuadInputRow(
              'pressingMaterialLength', _pressingMaterialLengthController, 'L',
              'pressingMaterialWidth', _pressingMaterialWidthController, 'W',
              'pressingMaterialThickness', _pressingMaterialThicknessController, 'T',
              'pressingMaterialQuantity', _pressingMaterialQuantityController, '本'
            ),
            Row(children: [Checkbox(value: _pressingMaterialHasMolding, onChanged: (v) => setState(() => _pressingMaterialHasMolding = v!)), const Text('盛り材が有')]),
        ])),
        VerticalInputGroup('トップ材', _buildQuadInputRow(
          'topMaterialLength', _topMaterialLengthController, 'L',
          'topMaterialWidth', _topMaterialWidthController, 'W',
          'topMaterialThickness', _topMaterialThicknessController, 'T',
          'topMaterialQuantity', _topMaterialQuantityController, '本'
        )),
    ]);
  }

  Widget _buildAdditionalPartsTab() {
    return Column(children: [
         for (int i = 0; i < 5; i++) _buildAdditionalPartRow(i),
    ]);
  }

  // ▼▼▼ レイアウトヘルパー (Common UIを利用) ▼▼▼
  Widget _buildTripleInputRow(String title, String k1, TextEditingController c1, String h1, String k2, TextEditingController c2, String h2, String k3, TextEditingController c3, String h3) {
    return VerticalInputGroup(title, Row(children: [
        Expanded(child: LabeledTextField(controller: c1, hintText: h1, keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes[k1], onSubmitted: () => _nextFocus(k1))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
        Expanded(child: LabeledTextField(controller: c2, hintText: h2, keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes[k2], onSubmitted: () => _nextFocus(k2))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
        Expanded(child: LabeledTextField(controller: c3, hintText: h3, keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes[k3], onSubmitted: () => _nextFocus(k3))),
    ]));
  }

  Widget _buildLabeledTripleInputRow(String title, String k1, TextEditingController c1, String h1, String k2, TextEditingController c2, String h2, String k3, TextEditingController c3, String h3) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(width: 80, child: Text(title, style: const TextStyle(fontSize: 14))),
        const SizedBox(width: 8),
        Expanded(child: Row(children: [
            Expanded(child: LabeledTextField(controller: c1, hintText: h1, keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes[k1], onSubmitted: () => _nextFocus(k1))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
            Expanded(child: LabeledTextField(controller: c2, hintText: h2, keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes[k2], onSubmitted: () => _nextFocus(k2))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
            Expanded(child: LabeledTextField(controller: c3, hintText: h3, keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes[k3], onSubmitted: () => _nextFocus(k3))),
        ])),
    ]));
  }

  Widget _buildDoubleInputRowWithUnit(String k1, TextEditingController c1, String h1, String k2, TextEditingController c2, String h2) {
     return Row(children: [
        Expanded(child: LabeledTextField(controller: c1, hintText: h1, keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes[k1], onSubmitted: () => _nextFocus(k1))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
        Expanded(child: LabeledTextField(controller: c2, hintText: h2, keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes[k2], onSubmitted: () => _nextFocus(k2))),
    ]);
  }

  Widget _buildTripleInputRowWithUnit(String k1, TextEditingController c1, String h1, String k2, TextEditingController c2, String h2, String k3, TextEditingController c3, String h3) {
    return Row(children: [
        Expanded(child: LabeledTextField(controller: c1, hintText: h1, keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes[k1], onSubmitted: () => _nextFocus(k1))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
        Expanded(child: LabeledTextField(controller: c2, hintText: h2, keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes[k2], onSubmitted: () => _nextFocus(k2))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('・')),
        Expanded(child: LabeledTextField(controller: c3, hintText: h3, keyboardType: TextInputType.number, showLabel: false, unit: '本', focusNode: _focusNodes[k3], onSubmitted: () => _nextFocus(k3))),
    ]);
  }

  Widget _buildQuadInputRow(String k1, TextEditingController c1, String h1, String k2, TextEditingController c2, String h2, String k3, TextEditingController c3, String h3, String k4, TextEditingController c4, String h4) {
    return Row(children: [
        Expanded(child: LabeledTextField(controller: c1, hintText: h1, keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes[k1], onSubmitted: () => _nextFocus(k1))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
        Expanded(child: LabeledTextField(controller: c2, hintText: h2, keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes[k2], onSubmitted: () => _nextFocus(k2))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
        Expanded(child: LabeledTextField(controller: c3, hintText: h3, keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes[k3], onSubmitted: () => _nextFocus(k3))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('・')),
        Expanded(child: LabeledTextField(controller: c4, hintText: h4, keyboardType: TextInputType.number, showLabel: false, unit: '本', focusNode: _focusNodes[k4], onSubmitted: () => _nextFocus(k4))),
    ]);
  }

  Widget _buildDimensionWithCheckbox(String? label, String k1, TextEditingController c1, String k2, TextEditingController c2, String checkboxLabel, bool checkboxValue, ValueChanged<bool?> onChanged) {
    final content = Row(children: [
        Expanded(flex: 2, child: _buildDoubleInputRowWithUnit(k1, c1, '幅', k2, c2, '厚さ')),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: Row(children: [Checkbox(value: checkboxValue, onChanged: onChanged), Flexible(child: Text(checkboxLabel, overflow: TextOverflow.ellipsis))])),
    ]);
    return label != null ? VerticalInputGroup(label, content) : content;
  }

  Widget _buildAdditionalPartRow(int i) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(children: [
          SizedBox(width: 80, child: TextField(controller: _additionalPartNameControllers[i], focusNode: _focusNodes['additionalPartName_$i'], onSubmitted: (_) => _nextFocus('additionalPartName_$i'), textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: '部材名', border: OutlineInputBorder(), isDense: true))),
          const SizedBox(width: 8),
          Expanded(child: LabeledTextField(controller: _additionalPartLengthControllers[i], hintText: 'L', keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes['additionalPartLength_$i'], onSubmitted: () => _nextFocus('additionalPartLength_$i'))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
          Expanded(child: LabeledTextField(controller: _additionalPartWidthControllers[i], hintText: 'W', keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes['additionalPartWidth_$i'], onSubmitted: () => _nextFocus('additionalPartWidth_$i'))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
          Expanded(child: LabeledTextField(controller: _additionalPartThicknessControllers[i], hintText: 'T', keyboardType: TextInputType.number, showLabel: false, unit: 'mm', focusNode: _focusNodes['additionalPartThickness_$i'], onSubmitted: () => _nextFocus('additionalPartThickness_$i'))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('・')),
          Expanded(child: LabeledTextField(controller: _additionalPartQuantityControllers[i], hintText: '数', keyboardType: TextInputType.number, showLabel: false, unit: '本', focusNode: _focusNodes['additionalPartQuantity_$i'], onSubmitted: () => _nextFocus('additionalPartQuantity_$i'))),
    ]));
  }
}