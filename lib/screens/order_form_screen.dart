// lib/screens/order_form_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:kouchuhyo_app/widgets/drawing_canvas.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kouchuhyo_app/screens/drawing_screen.dart';
import 'dart:math';
import 'package:kouchuhyo_app/screens/print_preview_screen.dart';

// ★★★【追加】寸法文字列を解析するためのクラス ★★★
class DimensionParser {
  final String rawString;
  String l = '';
  String w = '';
  String t = '';
  String qty = '';

  DimensionParser(this.rawString) {
    _parse();
  }

  void _parse() {
    if (rawString.isEmpty) return;

    String remainingString = rawString;

    final qtyMatch = RegExp(r'[xXх×・]\s*(\d+)\s*本$').firstMatch(remainingString);
    if (qtyMatch != null) {
      qty = qtyMatch.group(1)!;
      remainingString = remainingString.substring(0, qtyMatch.start).trim();
    } else {
      final qtyOnlyMatch = RegExp(r'^(\d+)\s*本$').firstMatch(remainingString);
        if (qtyOnlyMatch != null) {
            qty = qtyOnlyMatch.group(1)!;
            remainingString = "";
        }
    }

    final lMatch = RegExp(r'[lL]\s*(\d+(?:\.\d+)?)').firstMatch(remainingString);
    if (lMatch != null) {
      l = lMatch.group(1)!;
      remainingString = remainingString.replaceFirst(lMatch.group(0)!, '').trim();
    }

    final wMatch = RegExp(r'[wW]\s*(\d+(?:\.\d+)?)').firstMatch(remainingString);
    if (wMatch != null) {
      w = wMatch.group(1)!;
      remainingString = remainingString.replaceFirst(wMatch.group(0)!, '').trim();
    }

    final tMatch = RegExp(r'[tT]\s*(\d+(?:\.\d+)?)').firstMatch(remainingString);
    if (tMatch != null) {
      t = tMatch.group(1)!;
      remainingString = remainingString.replaceFirst(tMatch.group(0)!, '').trim();
    }

    remainingString = remainingString.replaceAll(RegExp(r'\s*[xXх×]\s*'), ' ').trim();
    final remainingParts = remainingString.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

    if (l.isEmpty && remainingParts.isNotEmpty) {
      l = RegExp(r'^\d+(?:\.\d+)?$').hasMatch(remainingParts[0]) ? remainingParts.removeAt(0) : '';
    }
    if (w.isEmpty && remainingParts.isNotEmpty) {
      w = RegExp(r'^\d+(?:\.\d+)?$').hasMatch(remainingParts[0]) ? remainingParts.removeAt(0) : '';
    }
    if (t.isEmpty && remainingParts.isNotEmpty) {
      t = RegExp(r'^\d+(?:\.\d+)?$').hasMatch(remainingParts[0]) ? remainingParts.removeAt(0) : '';
    }
    if (l.isEmpty && w.isEmpty && t.isEmpty && qty.isEmpty) {
        final tOnlyMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*t$').firstMatch(rawString.toLowerCase());
        if (tOnlyMatch != null) {
            t = tOnlyMatch.group(1)!;
        }
    }
  }
}


class KochuhyoData {
  // 基本情報
  final String shippingDate, issueDate, serialNumber, kobango, shihomeisaki, hinmei;
  final String productLength, productWidth, productHeight;
  final String weight, quantity;
  final String shippingType, packingForm, formType, material;
  final String desiccantPeriod, desiccantCoefficientValue, desiccantAmount;
  // 寸法
  final String innerLength, innerWidth, innerHeight;
  final String outerLength, outerWidth, outerHeight, packagingVolume;
  // 腰下
  final String skid, h, hFixingMethod, suriGetaType, suriGeta, getaQuantity, floorBoard;
  final bool isFloorBoardShort;
  final String skidWidth, skidThickness, skidQuantity;
  final String hWidth, hThickness;
  final String suriGetaWidth, suriGetaThickness;
  final String floorBoardThickness;
  final String loadBearingMaterialWidth, loadBearingMaterialThickness, loadBearingMaterialQuantity;
  // 荷重計算
  final String loadBearingMaterial, allowableLoadUniform, loadCalculationMethod, twoPointLoadDetails, finalAllowableLoad;
  // 根止め (5行分)
  final List<String> rootStops;
  // 側・妻
  final String sideBoard, kamachiType, upperKamachi, lowerKamachi, pillar;
  final String beamReceiver, bracePillar;
  final bool beamReceiverEmbed, bracePillarShortEnds;
  final String sideBoardThickness;
  final String upperKamachiWidth, upperKamachiThickness;
  final String lowerKamachiWidth, lowerKamachiThickness;
  final String pillarWidth, pillarThickness;
  final String beamReceiverWidth, beamReceiverThickness;
  final String bracePillarWidth, bracePillarThickness;
  // 天井
  final String ceilingUpperBoard, ceilingLowerBoard;
  final String ceilingUpperBoardThickness;
  final String ceilingLowerBoardThickness;
  // 梱包材
  final String hari, pressingMaterial, topMaterial;
  final bool pressingMaterialHasMolding;
  final String hariWidth, hariThickness, hariQuantity;
  final String pressingMaterialLength, pressingMaterialWidth, pressingMaterialThickness, pressingMaterialQuantity;
  final String topMaterialLength, topMaterialWidth, topMaterialThickness, topMaterialQuantity;
  // 追加部材 (5行分)
  final List<Map<String, String>> additionalParts;
  // 図面
  final Uint8List? koshitaImageBytes;
  final Uint8List? gawaTsumaImageBytes;
  final List<Map<String, dynamic>> koshitaDrawingElements;
  final List<Map<String, dynamic>> gawaTsumaDrawingElements;

  KochuhyoData({
    required this.shippingDate, required this.issueDate, required this.serialNumber, required this.kobango,
    required this.shihomeisaki, required this.hinmei,
    required this.productLength, required this.productWidth, required this.productHeight,
    required this.weight, required this.quantity,
    required this.shippingType, required this.packingForm, required this.formType, required this.material,
    required this.desiccantPeriod, required this.desiccantCoefficientValue, required this.desiccantAmount,
    required this.innerLength, required this.innerWidth, required this.innerHeight,
    required this.outerLength, required this.outerWidth, required this.outerHeight, required this.packagingVolume,
    required this.skid, required this.h, required this.hFixingMethod, required this.suriGetaType,
    required this.suriGeta, required this.getaQuantity, required this.floorBoard,
    required this.isFloorBoardShort,
    required this.skidWidth, required this.skidThickness, required this.skidQuantity,
    required this.hWidth, required this.hThickness,
    required this.suriGetaWidth, required this.suriGetaThickness,
    required this.floorBoardThickness,
    required this.loadBearingMaterialWidth, required this.loadBearingMaterialThickness, required this.loadBearingMaterialQuantity,
    required this.loadBearingMaterial, required this.allowableLoadUniform, required this.loadCalculationMethod,
    required this.twoPointLoadDetails, required this.finalAllowableLoad, required this.rootStops,
    required this.sideBoard, required this.kamachiType, required this.upperKamachi, required this.lowerKamachi,
    required this.pillar, required this.beamReceiver, required this.bracePillar,
    required this.sideBoardThickness,
    required this.upperKamachiWidth, required this.upperKamachiThickness,
    required this.lowerKamachiWidth, required this.lowerKamachiThickness,
    required this.pillarWidth, required this.pillarThickness,
    required this.beamReceiverWidth, required this.beamReceiverThickness,
    required this.bracePillarWidth, required this.bracePillarThickness,
    required this.beamReceiverEmbed, required this.bracePillarShortEnds,
    required this.ceilingUpperBoard, required this.ceilingLowerBoard,
    required this.ceilingUpperBoardThickness, required this.ceilingLowerBoardThickness,
    required this.hari, required this.pressingMaterial, required this.topMaterial,
    required this.hariWidth, required this.hariThickness, required this.hariQuantity,
    required this.pressingMaterialLength, required this.pressingMaterialWidth, required this.pressingMaterialThickness, required this.pressingMaterialQuantity,
    required this.topMaterialLength, required this.topMaterialWidth, required this.topMaterialThickness, required this.topMaterialQuantity,
    required this.pressingMaterialHasMolding, required this.additionalParts,
    this.koshitaImageBytes, this.gawaTsumaImageBytes,
    required this.koshitaDrawingElements,
    required this.gawaTsumaDrawingElements,
  });

  Map<String, dynamic> toJson() {
    final koshitaImageBase64 = koshitaImageBytes != null ? base64Encode(koshitaImageBytes!) : null;
    final gawaTsumaImageBase64 = gawaTsumaImageBytes != null ? base64Encode(gawaTsumaImageBytes!) : null;

    return {
      'shippingDate': shippingDate,
      'issueDate': issueDate,
      'serialNumber': serialNumber,
      'kobango': kobango,
      'shihomeisaki': shihomeisaki,
      'hinmei': hinmei,
      'productLength': productLength,
      'productWidth': productWidth,
      'productHeight': productHeight,
      'weight': weight,
      'quantity': quantity,
      'shippingType': shippingType,
      'packingForm': packingForm,
      'formType': formType,
      'material': material,
      'desiccantPeriod': desiccantPeriod,
      'desiccantCoefficientValue': desiccantCoefficientValue,
      'desiccantAmount': desiccantAmount,
      'innerLength': innerLength,
      'innerWidth': innerWidth,
      'innerHeight': innerHeight,
      'outerLength': outerLength,
      'outerWidth': outerWidth,
      'outerHeight': outerHeight,
      'packagingVolume': packagingVolume,
      'skid': skid,
      'h': h,
      'hFixingMethod': hFixingMethod,
      'suriGetaType': suriGetaType,
      'suriGeta': suriGeta,
      'getaQuantity': getaQuantity,
      'floorBoard': floorBoard,
      'isFloorBoardShort': isFloorBoardShort,
      'loadBearingMaterial': loadBearingMaterial,
      'allowableLoadUniform': allowableLoadUniform,
      'loadCalculationMethod': loadCalculationMethod,
      'twoPointLoadDetails': twoPointLoadDetails,
      'finalAllowableLoad': finalAllowableLoad,
      'rootStops': rootStops,
      'sideBoard': sideBoard,
      'kamachiType': kamachiType,
      'upperKamachi': upperKamachi,
      'lowerKamachi': lowerKamachi,
      'pillar': pillar,
      'beamReceiver': beamReceiver,
      'bracePillar': bracePillar,
      'beamReceiverEmbed': beamReceiverEmbed,
      'bracePillarShortEnds': bracePillarShortEnds,
      'ceilingUpperBoard': ceilingUpperBoard,
      'ceilingLowerBoard': ceilingLowerBoard,
      'hari': hari,
      'pressingMaterial': pressingMaterial,
      'topMaterial': topMaterial,
      'pressingMaterialHasMolding': pressingMaterialHasMolding,
      'additionalParts': additionalParts,
      'koshitaImageBytes': koshitaImageBase64,
      'gawaTsumaImageBytes': gawaTsumaImageBase64,
      'skidWidth': skidWidth,
      'skidThickness': skidThickness,
      'skidQuantity': skidQuantity,
      'hWidth': hWidth,
      'hThickness': hThickness,
      'suriGetaWidth': suriGetaWidth,
      'suriGetaThickness': suriGetaThickness,
      'floorBoardThickness': floorBoardThickness,
      'loadBearingMaterialWidth': loadBearingMaterialWidth,
      'loadBearingMaterialThickness': loadBearingMaterialThickness,
      'loadBearingMaterialQuantity': loadBearingMaterialQuantity,
      'sideBoardThickness': sideBoardThickness,
      'upperKamachiWidth': upperKamachiWidth,
      'upperKamachiThickness': upperKamachiThickness,
      'lowerKamachiWidth': lowerKamachiWidth,
      'lowerKamachiThickness': lowerKamachiThickness,
      'pillarWidth': pillarWidth,
      'pillarThickness': pillarThickness,
      'beamReceiverWidth': beamReceiverWidth,
      'beamReceiverThickness': beamReceiverThickness,
      'bracePillarWidth': bracePillarWidth,
      'bracePillarThickness': bracePillarThickness,
      'ceilingUpperBoardThickness': ceilingUpperBoardThickness,
      'ceilingLowerBoardThickness': ceilingLowerBoardThickness,
      'hariWidth': hariWidth,
      'hariThickness': hariThickness,
      'hariQuantity': hariQuantity,
      'pressingMaterialLength': pressingMaterialLength,
      'pressingMaterialWidth': pressingMaterialWidth,
      'pressingMaterialThickness': pressingMaterialThickness,
      'pressingMaterialQuantity': pressingMaterialQuantity,
      'topMaterialLength': topMaterialLength,
      'topMaterialWidth': topMaterialWidth,
      'topMaterialThickness': topMaterialThickness,
      'topMaterialQuantity': topMaterialQuantity,
      'koshitaDrawingElements': koshitaDrawingElements,
      'gawaTsumaDrawingElements': gawaTsumaDrawingElements,
    };
  }

  factory KochuhyoData.fromJson(Map<String, dynamic> json) {
    return KochuhyoData(
      shippingDate: json['shippingDate'] ?? '',
      issueDate: json['issueDate'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      kobango: json['kobango'] ?? '',
      shihomeisaki: json['shihomeisaki'] ?? '',
      hinmei: json['hinmei'] ?? '',
      productLength: json['productLength'] ?? '',
      productWidth: json['productWidth'] ?? '',
      productHeight: json['productHeight'] ?? '',
      weight: json['weight'] ?? '',
      quantity: json['quantity'] ?? '',
      shippingType: json['shippingType'] ?? '',
      packingForm: json['packingForm'] ?? '',
      formType: json['formType'] ?? '',
      material: json['material'] ?? '',
      desiccantPeriod: json['desiccantPeriod'] ?? '',
      desiccantCoefficientValue: json['desiccantCoefficientValue'] ?? '',
      desiccantAmount: json['desiccantAmount'] ?? '',
      innerLength: json['innerLength'] ?? '',
      innerWidth: json['innerWidth'] ?? '',
      innerHeight: json['innerHeight'] ?? '',
      outerLength: json['outerLength'] ?? '',
      outerWidth: json['outerWidth'] ?? '',
      outerHeight: json['outerHeight'] ?? '',
      packagingVolume: json['packagingVolume'] ?? '',
      skid: json['skid'] ?? '',
      h: json['h'] ?? '',
      hFixingMethod: json['hFixingMethod'] ?? '',
      suriGetaType: json['suriGetaType'] ?? '',
      suriGeta: json['suriGeta'] ?? '',
      getaQuantity: json['getaQuantity'] ?? '',
      floorBoard: json['floorBoard'] ?? '',
      isFloorBoardShort: json['isFloorBoardShort'] ?? false,
      loadBearingMaterial: json['loadBearingMaterial'] ?? '',
      allowableLoadUniform: json['allowableLoadUniform'] ?? '',
      loadCalculationMethod: json['loadCalculationMethod'] ?? '',
      twoPointLoadDetails: json['twoPointLoadDetails'] ?? '',
      finalAllowableLoad: json['finalAllowableLoad'] ?? '',
      rootStops: List<String>.from(json['rootStops'] ?? []),
      sideBoard: json['sideBoard'] ?? '',
      kamachiType: json['kamachiType'] ?? '',
      upperKamachi: json['upperKamachi'] ?? '',
      lowerKamachi: json['lowerKamachi'] ?? '',
      pillar: json['pillar'] ?? '',
      beamReceiver: json['beamReceiver'] ?? '',
      bracePillar: json['bracePillar'] ?? '',
      beamReceiverEmbed: json['beamReceiverEmbed'] ?? false,
      bracePillarShortEnds: json['bracePillarShortEnds'] ?? false,
      ceilingUpperBoard: json['ceilingUpperBoard'] ?? '',
      ceilingLowerBoard: json['ceilingLowerBoard'] ?? '',
      hari: json['hari'] ?? '',
      pressingMaterial: json['pressingMaterial'] ?? '',
      topMaterial: json['topMaterial'] ?? '',
      pressingMaterialHasMolding: json['pressingMaterialHasMolding'] ?? false,
      additionalParts: (json['additionalParts'] as List<dynamic>?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList() ?? [],
      koshitaImageBytes: json['koshitaImageBytes'] != null ? base64Decode(json['koshitaImageBytes']) : null,
      gawaTsumaImageBytes: json['gawaTsumaImageBytes'] != null ? base64Decode(json['gawaTsumaImageBytes']) : null,
      skidWidth: json['skidWidth'] ?? '',
      skidThickness: json['skidThickness'] ?? '',
      skidQuantity: json['skidQuantity'] ?? '',
      hWidth: json['hWidth'] ?? '',
      hThickness: json['hThickness'] ?? '',
      suriGetaWidth: json['suriGetaWidth'] ?? '',
      suriGetaThickness: json['suriGetaThickness'] ?? '',
      floorBoardThickness: json['floorBoardThickness'] ?? '',
      loadBearingMaterialWidth: json['loadBearingMaterialWidth'] ?? '',
      loadBearingMaterialThickness: json['loadBearingMaterialThickness'] ?? '',
      loadBearingMaterialQuantity: json['loadBearingMaterialQuantity'] ?? '',
      sideBoardThickness: json['sideBoardThickness'] ?? '',
      upperKamachiWidth: json['upperKamachiWidth'] ?? '',
      upperKamachiThickness: json['upperKamachiThickness'] ?? '',
      lowerKamachiWidth: json['lowerKamachiWidth'] ?? '',
      lowerKamachiThickness: json['lowerKamachiThickness'] ?? '',
      pillarWidth: json['pillarWidth'] ?? '',
      pillarThickness: json['pillarThickness'] ?? '',
      beamReceiverWidth: json['beamReceiverWidth'] ?? '',
      beamReceiverThickness: json['beamReceiverThickness'] ?? '',
      bracePillarWidth: json['bracePillarWidth'] ?? '',
      bracePillarThickness: json['bracePillarThickness'] ?? '',
      ceilingUpperBoardThickness: json['ceilingUpperBoardThickness'] ?? '',
      ceilingLowerBoardThickness: json['ceilingLowerBoardThickness'] ?? '',
      hariWidth: json['hariWidth'] ?? '',
      hariThickness: json['hariThickness'] ?? '',
      hariQuantity: json['hariQuantity'] ?? '',
      pressingMaterialLength: json['pressingMaterialLength'] ?? '',
      pressingMaterialWidth: json['pressingMaterialWidth'] ?? '',
      pressingMaterialThickness: json['pressingMaterialThickness'] ?? '',
      pressingMaterialQuantity: json['pressingMaterialQuantity'] ?? '',
      topMaterialLength: json['topMaterialLength'] ?? '',
      topMaterialWidth: json['topMaterialWidth'] ?? '',
      topMaterialThickness: json['topMaterialThickness'] ?? '',
      topMaterialQuantity: json['topMaterialQuantity'] ?? '',
      koshitaDrawingElements: (json['koshitaDrawingElements'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [],
      gawaTsumaDrawingElements: (json['gawaTsumaDrawingElements'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [],
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const _CollapsibleSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
  });

  @override
  __CollapsibleSectionState createState() => __CollapsibleSectionState();
}

class __CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggleExpanded,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                      color: Colors.blueAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '--- ${widget.title} ---',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
            child: widget.child,
          ),
      ],
    );
  }
}

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
  final FocusNode _desiccantCoefficientFocusNode = FocusNode();
  final FocusNode _materialFocusNode = FocusNode();
  final FocusNode _shippingTypeFocusNode = FocusNode();
  final FocusNode _formTypeFocusNode = FocusNode();
  final FocusNode _packingFormFocusNode = FocusNode();
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
   final FocusNode _hFixingMethodFocusNode = FocusNode();
  String? _selectedSuriGetaType;
   final FocusNode _suriGetaTypeFocusNode = FocusNode();
  final TextEditingController _suriGetaWidthController = TextEditingController();
  final TextEditingController _suriGetaThicknessController = TextEditingController();
  final TextEditingController _getaQuantityController = TextEditingController();
  final TextEditingController _floorBoardThicknessController = TextEditingController();
  bool _isJitaMijikame = false;
  final TextEditingController _loadBearingMaterialWidthController = TextEditingController();
  final TextEditingController _loadBearingMaterialThicknessController = TextEditingController();
  final TextEditingController _loadBearingMaterialQuantityController = TextEditingController();
  String? _loadCalculationMethod;
   final FocusNode _loadCalculationMethodFocusNode = FocusNode();
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
  final FocusNode _kamachiTypeFocusNode = FocusNode();
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
      if (_focusNodes['outerLength']!.hasFocus) {
        _isOuterLengthManuallyEdited = true;
      }
    });
    _outerWidthController.addListener(() {
      if (_focusNodes['outerWidth']!.hasFocus) {
        _isOuterWidthManuallyEdited = true;
      }
    });
    _outerHeightController.addListener(() {
      if (_focusNodes['outerHeight']!.hasFocus) {
        _isOuterHeightManuallyEdited = true;
      }
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
    _l_A_Controller.addListener(() {
      if (_l_A_Controller.text.isNotEmpty) _clearTwoPointInputs(scenario: 'B');
      _calculateTwoPointLoad();
    });
    _l0Controller.addListener(() {
      if (_l0Controller.text.isNotEmpty) _clearTwoPointInputs(scenario: 'B');
      _calculateTwoPointLoad();
    });
    _l_B_Controller.addListener(() {
      if (_l_B_Controller.text.isNotEmpty) _clearTwoPointInputs(scenario: 'A');
      _calculateTwoPointLoad();
    });
    _l1Controller.addListener(() {
      if (_l1Controller.text.isNotEmpty) _clearTwoPointInputs(scenario: 'A');
      _calculateTwoPointLoad();
    });
    _l2Controller.addListener(() {
      if (_l2Controller.text.isNotEmpty) _clearTwoPointInputs(scenario: 'A');
      _calculateTwoPointLoad();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerAllCalculations());
  }

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
      if (data.outerLength.isNotEmpty) {
        _isOuterLengthManuallyEdited = true;
      }
      if (data.outerWidth.isNotEmpty) {
        _isOuterWidthManuallyEdited = true;
      }
      if (data.outerHeight.isNotEmpty) {
        _isOuterHeightManuallyEdited = true;
      }

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

      final skidSize = '${data.skidWidth}×${data.skidThickness}';
      if (_skidSizeOptions.contains(skidSize)) {
        _selectedSkidSize = skidSize;
      }
      final hSize = '${data.hWidth}×${data.hThickness}';
      if (_hSizeOptions.contains(hSize)) {
        _selectedHSize = hSize;
      }
      final suriGetaSize = '${data.suriGetaWidth}×${data.suriGetaThickness}';
      if (_suriGetaSizeOptions.contains(suriGetaSize)) {
        _selectedSuriGetaSize = suriGetaSize;
      }
      final loadBearingMaterialSize = '${data.loadBearingMaterialWidth}×${data.loadBearingMaterialThickness}';
      if (_loadBearingMaterialSizeOptions.contains(loadBearingMaterialSize)) {
        _selectedLoadBearingMaterialSize = loadBearingMaterialSize;
      }
      final beamReceiverSize = '${data.beamReceiverWidth}×${data.beamReceiverThickness}';
      if (_beamReceiverSizeOptions.contains(beamReceiverSize)) {
        _selectedBeamReceiverSize = beamReceiverSize;
      }
      final bracePillarSize = '${data.bracePillarWidth}×${data.bracePillarThickness}';
      if (_bracePillarSizeOptions.contains(bracePillarSize)) {
        _selectedBracePillarSize = bracePillarSize;
      }
      final hariSize = '${data.hariWidth}×${data.hariThickness}';
      if (_hariSizeOptions.contains(hariSize)) {
        _selectedHariSize = hariSize;
      }
  }

  @override
  void dispose() {
    _focusNodes.forEach((_, node) => node.dispose());
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
      if (!_isOuterLengthManuallyEdited) {
        _outerLengthController.text = outerLength.toStringAsFixed(0);
      }
      if (!_isOuterWidthManuallyEdited) {
        _outerWidthController.text = outerWidth.toStringAsFixed(0);
      }
      if (!_isOuterHeightManuallyEdited) {
        _outerHeightController.text = roundedOuterHeight.toStringAsFixed(0);
      }
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
      if (roundedAmount == roundedAmount.truncate()) {
        _desiccantResultDisplayController.text = roundedAmount.toStringAsFixed(0);
      } else {
        _desiccantResultDisplayController.text = roundedAmount.toStringAsFixed(1);
      }
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
        if (_loadCalculationMethod == '等分布荷重') {
            _loadBearingMaterialQuantityController.text = '';
        }
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
        if (_wUniform > 0 && totalWeight > 0) {
          quantity = (totalWeight / _wUniform).ceil();
        }
        _loadBearingMaterialQuantityController.text = quantity.toString();
      }
    });
  }
  void _calculateCentralLoad() {
    if (_loadCalculationMethod != '中央集中荷重') {
      return;
    }
    final lCm = _calculateSpanLength();
    final bMm = double.tryParse(_loadBearingMaterialWidthController.text) ?? 0.0;
    final hMm = double.tryParse(_loadBearingMaterialThicknessController.text) ?? 0.0;
    if (lCm <= 0 || bMm <= 0 || hMm <= 0) {
      setState(() {
        _allowableLoadDisplayController.text = '計算不可';
      });
      return;
    }
    final bCm = bMm / 10.0;
    final hCm = hMm / 10.0;
    const fb = 107;
    final wKg = (2 * bCm * (hCm * hCm) * fb) / (3 * lCm);
    setState(() {
       _allowableLoadDisplayController.text = wKg.toStringAsFixed(1);
    });
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
        if (_loadCalculationMethod != '等分布荷重') {
           _loadBearingMaterialQuantityController.text = '';
        }
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
    } 
    else if (l_B > 0 && (l1 > 0 || l2 > 0)) {
        if (l2 > l1) {
            final temp = l1;
            l1 = l2;
            l2 = temp;
        }
        final denominator = 4 * (l_B - l1 + l2) * l1;
        if (denominator > 0) {
            multiplier = (l_B * l_B) / denominator;
        }
    }
    if (multiplier <= 0) {
      setState(() {
        _multiplierDisplayController.text = '計算不可';
        _allowableLoadFinalDisplayController.text = '';
        _loadBearingMaterialQuantityController.text = '';
      });
      return;
    }
    if (multiplier > 2.0) {
      multiplier = 2.0;
    }
    final wFinal = _wUniform * multiplier;
    final totalWeight = double.tryParse(_weightController.text) ?? 0.0;
    int quantity = 0;
    if (wFinal > 0 && totalWeight > 0) {
      quantity = (totalWeight / wFinal).ceil();
    }
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
      if (!await historyDir.exists()) {
        await historyDir.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${historyDir.path}/history_$timestamp.json');
      await file.writeAsString(jsonEncode(data.toJson()));
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('履歴の保存に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ▼▼▼【変更】別名で保存のロジック（既存フォルダ選択機能） ▼▼▼
  void _saveAsNewTemplate() async {
    final data = _collectData();
    final jsonString = jsonEncode(data.toJson());
    
    final productNameController = TextEditingController();
    final defaultFileName = _hinmeiController.text;
    final templateNameController = TextEditingController(text: defaultFileName);

    // 既存のフォルダリストを取得
    final directory = await getApplicationDocumentsDirectory();
    final List<Directory> folders = [];
    if (await directory.exists()) {
      final entities = directory.listSync();
      for (var entity in entities) {
        if (entity is Directory && !entity.path.endsWith('/history')) {
          folders.add(entity);
        }
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
                    onChanged: (value) {
                      if (selectedFolder != null) {
                        setState(() { selectedFolder = null; });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: '新規製品名 (フォルダ名)',
                      hintText: '例: 製品A',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: templateNameController,
                    decoration: const InputDecoration(
                      labelText: 'テンプレート名 (ファイル名)',
                      hintText: '例: 基本パターン',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    final productName = selectedFolder ?? productNameController.text;
                    if (productName.isNotEmpty && templateNameController.text.isNotEmpty) {
                      Navigator.of(context).pop({
                        'product': productName,
                        'template': templateNameController.text,
                      });
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('製品名とテンプレート名を入力してください。'), backgroundColor: Colors.red),
                      );
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
        if (!await productDir.exists()) {
          await productDir.create(recursive: true);
        }

        final path = '${productDir.path}/$templateName.json';
        final file = File(path);
        await file.writeAsString(jsonString);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('製品「$productName」にテンプレート「$templateName」を保存しました。'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('保存に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('上書き保存', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final data = _collectData();
    final jsonString = jsonEncode(data.toJson());

    try {
      final file = File(widget.templatePath!);
      await file.writeAsString(jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('テンプレートを上書き保存しました。'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上書き保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTwoPointLoad = _loadCalculationMethod == '2点集中荷重';

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('工注票', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text('工 注 票', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                
                _CollapsibleSection(
                  title: '基本情報セクション',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildLabeledDateInput('出荷日', 'shippingDate', _shippingDateController, _selectDate)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildLabeledDateInput('発行日', 'issueDate', _issueDateController, _selectDate)),
                        ],
                      ),
                      _buildLabeledTextField('整理番号', 'serialNumber', _serialNumberController, hintText: 'A-100'),
                      _buildLabeledTextField('工番', 'kobango', _kobangoController),
                      _buildLabeledTextField('仕向先', 'shihomeisaki', _shihomeisakiController),
                      _buildLabeledTextField('品名', 'hinmei', _hinmeiController),
                      // ▼▼▼【変更】製品サイズの表示方法を修正 ▼▼▼
                      _buildLabeledTripleInputRow('製品サイズ',
                        'productLength', _productLengthController, '長',
                        'productWidth', _productWidthController, '幅',
                        'productHeight', _productHeightController, '高'
                      ),
                      _buildLabeledDropdown(
                        '材質', 
                        'material',
                        _selectedMaterial, 
                        _materialOptions,
                        (value) => setState(() => _selectedMaterial = value),
                        '材質を選択'
                      ),
                      _buildLabeledTextField('重量', 'weight', _weightController, keyboardType: TextInputType.number, unit: 'KG'),
                      _buildLabeledTextField('数量', 'quantity', _quantityController, keyboardType: TextInputType.number, unit: 'C/S'),
                      
                      _buildVerticalInputGroup(
                        "乾燥剤",
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildLabeledTextField('期間', 'desiccantPeriod',_desiccantPeriodController,
                                keyboardType: TextInputType.number, hintText: '期間', unit: 'ヶ月', showLabel: false),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: _buildDropdownBase<double>(
                                 focusNode: _focusNodes['desiccantCoefficient']!,
                                 value: _selectedDesiccantCoefficient,
                                 hint: '係数',
                                 items: _desiccantCoefficients.entries.map((entry) {
                                    return DropdownMenuItem<double>(value: entry.value, child: Text(entry.key, style: const TextStyle(fontSize: 14)));
                                  }).toList(),
                                 onChanged: (value) {
                                  setState(() => _selectedDesiccantCoefficient = value);
                                  _calculateDesiccant();
                                  _nextFocus('desiccantCoefficient');
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('=', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _buildLabeledTextField('結果', 'desiccantResult',_desiccantResultDisplayController,
                                 readOnly: true, hintText: '結果', unit: 'kg', showLabel: false),
                            ),
                          ],
                        )
                      ),

                      const SizedBox(height: 16),
                      _buildRadioGroup("出荷形態", "shippingType", _selectedShippingType, ['国内', '輸出'], (val) => setState(()=> _selectedShippingType = val)),
                      const SizedBox(height: 16),
                      _buildRadioGroup("形式", "formType", _selectedFormType, _formTypeOptions, (val) {
                          setState(() => _selectedFormType = val);
                          _triggerAllCalculations();
                      }),
                      const SizedBox(height: 16),
                      _buildRadioGroup("形状", "packingForm", _selectedPackingForm, ['密閉', 'すかし'], (val) => setState(()=> _selectedPackingForm = val)),
                    ],
                  ),
                ),
                
                _CollapsibleSection(
                  title: '寸法セクション',
                  child: Column(
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
                      _buildLabeledTextField('梱包明細: 容積', 'packagingVolume',_packagingVolumeDisplayController, readOnly: true, unit: 'm³'),
                    ],
                  )
                ),

                // ( ... 以下、腰下セクション以降のUI定義は変更ありません ... )
                
                _CollapsibleSection(
                  title: '腰下セクション',
                  child: Column(
                    children: [
                       _buildVerticalInputGroup(
                        '滑材',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTripleInputRowWithUnit(
                              'skidWidth', _skidWidthController, '幅',
                              'skidThickness', _skidThicknessController, '厚',
                              'skidQuantity', _skidQuantityController, '本',
                            ),
                            const SizedBox(height: 8),
                            _buildDimensionDropdown(
                              selectedValue: _selectedSkidSize,
                              options: _skidSizeOptions,
                              onChanged: (newValue) {
                                setState(() { _selectedSkidSize = newValue; });
                                _updateDimensionsFromDropdown(newValue, _skidWidthController, _skidThicknessController);
                              },
                              hintText: '滑材サイズを選択',
                            ),
                          ],
                        ),
                      ),
                      
                      _buildVerticalInputGroup(
                        'H',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(flex: 3, child: _buildDoubleInputRowWithUnit('hWidth', _hWidthController, '幅', 'hThickness', _hThicknessController, '厚さ')),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('止め方', style: TextStyle(fontSize: 12)),
                                      _buildRadioGroup(null, 'hFixingMethod', _hFixingMethod, ['釘', 'ボルト'], (value) => setState(() => _hFixingMethod = value)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildDimensionDropdown(
                              selectedValue: _selectedHSize,
                              options: _hSizeOptions,
                              onChanged: (newValue) {
                                setState(() { _selectedHSize = newValue; });
                                _updateDimensionsFromDropdown(newValue, _hWidthController, _hThicknessController);
                              },
                              hintText: 'Hサイズを選択',
                            ),
                          ],
                        )
                      ),
                      
                      _buildVerticalInputGroup(
                        'すり材 or ゲタ',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                           _buildRadioGroup(null, "suriGetaType", _selectedSuriGetaType, ['すり材', 'ゲタ'], (val){
                               setState(() { _selectedSuriGetaType = val; _triggerAllCalculations(); });
                           }),
                            Row(
                              children: [
                                Expanded(child: _buildLabeledTextField('幅', 'suriGetaWidth', _suriGetaWidthController, keyboardType: TextInputType.number, hintText: '幅', unit: 'mm', showLabel: false)),
                                const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
                                Expanded(child: _buildLabeledTextField('厚さ', 'suriGetaThickness', _suriGetaThicknessController, keyboardType: TextInputType.number, hintText: '厚さ', unit: 'mm', showLabel: false)),
                                const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('・')),
                                Expanded(
                                  child: _buildLabeledTextField('本数', 'getaQuantity', _getaQuantityController,
                                    keyboardType: TextInputType.number, hintText: '本数', unit: '本',
                                    enabled: _selectedSuriGetaType == 'ゲタ', showLabel: false),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildDimensionDropdown(
                              selectedValue: _selectedSuriGetaSize,
                              options: _suriGetaSizeOptions,
                              onChanged: (newValue) {
                                setState(() { _selectedSuriGetaSize = newValue; });
                                _updateDimensionsFromDropdown(newValue, _suriGetaWidthController, _suriGetaThicknessController);
                              },
                              hintText: 'すり材/ゲタ サイズを選択',
                            ),
                          ],
                        ),
                      ),
                      
                      _buildVerticalInputGroup(
                        '床板',
                        Row(
                          children: [
                            Expanded(
                              child: _buildLabeledTextField('床板', 'floorBoardThickness', _floorBoardThicknessController, keyboardType: TextInputType.number, unit: 'mm', showLabel: false),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _isJitaMijikame,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _isJitaMijikame = value ?? false;
                                    });
                                  },
                                ),
                                GestureDetector(
                                  onTap: () {
                                     setState(() {
                                      _isJitaMijikame = !_isJitaMijikame;
                                    });
                                  },
                                  child: const Text('地板短め'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      _buildVerticalInputGroup(
                        '負荷床材',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildLabeledTextField('', 'loadBearingMaterialWidth', _loadBearingMaterialWidthController, hintText: '幅', keyboardType: TextInputType.number, showLabel: false, unit: 'mm')),
                                const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
                                Expanded(child: _buildLabeledTextField('', 'loadBearingMaterialThickness', _loadBearingMaterialThicknessController, hintText: '厚さ', keyboardType: TextInputType.number, showLabel: false, unit: 'mm')),
                                const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('・')),
                                Expanded(child: _buildLabeledTextField(
                                  '', 
                                  'loadBearingMaterialQuantity', 
                                  _loadBearingMaterialQuantityController, 
                                  hintText: '本', 
                                  keyboardType: TextInputType.number, 
                                  showLabel: false, 
                                  unit: '本',
                                  enabled: _loadCalculationMethod != '2点集中荷重', 
                                )),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildDimensionDropdown(
                              selectedValue: _selectedLoadBearingMaterialSize,
                              options: _loadBearingMaterialSizeOptions,
                              onChanged: (newValue) {
                                setState(() { _selectedLoadBearingMaterialSize = newValue; });
                                _updateDimensionsFromDropdown(newValue, _loadBearingMaterialWidthController, _loadBearingMaterialThicknessController);
                              },
                              hintText: '負荷床材サイズを選択',
                            ),
                          ],
                        )
                      ),
                      
                      if (_loadCalculationMethod == '等分布荷重')
                        _buildVerticalInputGroup(
                          '許容荷重W[等分布]',
                          _buildLabeledTextField('', 'allowableLoad', _allowableLoadDisplayController, readOnly: true, unit: 'kg/本', showLabel: false),
                        ),
                      if (_loadCalculationMethod == '中央集中荷重')
                        _buildVerticalInputGroup(
                          '許容荷重W[中央集中]',
                          _buildLabeledTextField('', 'allowableLoad', _allowableLoadDisplayController, readOnly: true, unit: 'kg/本', showLabel: false),
                        ),
                        
                      _buildRadioGroup(
                        "計算方法",
                        "loadCalculationMethod",
                        _loadCalculationMethod,
                        ['非計算', '等分布荷重', '中央集中荷重', '2点集中荷重'],
                        (val) {
                          setState(() {
                            _loadCalculationMethod = val;
                            _allowableLoadDisplayController.clear();
                            _multiplierDisplayController.clear();
                            _allowableLoadFinalDisplayController.clear();
                            if (val != '等分布荷重') {
                               _loadBearingMaterialQuantityController.clear();
                            }
                            if (val != '非計算') {
                              _triggerAllCalculations();
                            }
                          });
                        }
                      ),
                      
                      if (isTwoPointLoad)
                        Container(
                          margin: const EdgeInsets.only(top: 8.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4.0)
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('2点集中荷重 詳細入力', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                              const SizedBox(height: 12),
                              Text('シナリオA: 均等配置', style: TextStyle(fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  Expanded(child: _buildVerticalInputGroup("l", _buildLabeledTextField('l', 'l_A', _l_A_Controller, keyboardType: TextInputType.number, unit: 'cm', showLabel: false))),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildVerticalInputGroup("l0", _buildLabeledTextField('l0', 'l0', _l0Controller, keyboardType: TextInputType.number, unit: 'cm', showLabel: false))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('シナリオB: 不均等配置', style: TextStyle(fontWeight: FontWeight.bold)),
                               Row(
                                children: [
                                  Expanded(child: _buildVerticalInputGroup("l", _buildLabeledTextField('l', 'l_B', _l_B_Controller, keyboardType: TextInputType.number, unit: 'cm', showLabel: false))),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildVerticalInputGroup("l1", _buildLabeledTextField('l1', 'l1', _l1Controller, keyboardType: TextInputType.number, unit: 'cm', showLabel: false))),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildVerticalInputGroup("l2", _buildLabeledTextField('l2', 'l2', _l2Controller, keyboardType: TextInputType.number, unit: 'cm', showLabel: false))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                               _buildVerticalInputGroup(
                                '倍率',
                                 TextField(
                                   controller: _multiplierDisplayController, 
                                   readOnly: true, 
                                   decoration: InputDecoration(
                                     border: const OutlineInputBorder(), 
                                     isDense: true, 
                                     contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                     filled: true,
                                     fillColor: Colors.grey[200],
                                  ),
                                 ),
                              ),
                              _buildVerticalInputGroup(
                                '最終許容荷重(kg/本)',
                                 TextField(
                                   controller: _allowableLoadFinalDisplayController, 
                                   readOnly: true, 
                                   decoration: InputDecoration(
                                     border: const OutlineInputBorder(), 
                                     isDense: true, 
                                     contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                     filled: true,
                                     fillColor: Colors.grey[200],
                                   ),
                                 ),
                              ),
                            ],
                          ),
                        ),

                      _buildVerticalInputGroup(
                        '根止め', 
                        Column(
                          children: [
                            for (int i = 0; i < 5; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: _buildQuadInputRow(
                                  'rootStopLength_$i', _rootStopLengthControllers[i], 'L',
                                  'rootStopWidth_$i', _rootStopWidthControllers[i], 'W',
                                  'rootStopThickness_$i', _rootStopThicknessControllers[i], 'T',
                                  'rootStopQuantity_$i', _rootStopQuantityControllers[i], '本'
                                ),
                              ),
                          ]
                        )
                      ),
                      
                      const SizedBox(height: 16),
                      _buildDrawingPreview(
                        title: '図面手書き入力 (腰下ベース)',
                        onTap: _navigateToKoshitaDrawingScreen,
                        imageBytes: _koshitaImageBytes,
                        placeholder: 'タップして腰下ベースを描く',
                      ),
                    ],
                  ),
                ),

                _CollapsibleSection(
                  title: '側ツマセクション',
                  child: Column(
                    children: [
                      _buildVerticalInputGroup(
                        '外板',
                        _buildLabeledTextField('外板', 'sideBoardThickness', _sideBoardThicknessController, keyboardType: TextInputType.number, unit: 'mm', showLabel: false),
                      ),
                       _buildRadioGroup("かまち種類", "kamachiType", _selectedKamachiType, ['かまち25', 'かまち40'], _updateKamachiDimensions),
                      _buildVerticalInputGroup('上かまち', _buildDoubleInputRowWithUnit(
                          'upperKamachiWidth', _upperKamachiWidthController, '幅',
                          'upperKamachiThickness', _upperKamachiThicknessController, '厚さ')),
                      _buildVerticalInputGroup('下かまち', _buildDoubleInputRowWithUnit(
                          'lowerKamachiWidth', _lowerKamachiWidthController, '幅',
                          'lowerKamachiThickness', _lowerKamachiThicknessController, '厚さ')),
                      _buildVerticalInputGroup('支柱', _buildDoubleInputRowWithUnit(
                          'pillarWidth', _pillarWidthController, '幅',
                          'pillarThickness', _pillarThicknessController, '厚さ')),
                      
                      _buildVerticalInputGroup(
                        'はり受',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDimensionWithCheckbox(
                              null,
                              'beamReceiverWidth', _beamReceiverWidthController,
                              'beamReceiverThickness', _beamReceiverThicknessController,
                              '埋める', _beamReceiverEmbed, (value) => setState(() => _beamReceiverEmbed = value!)
                            ),
                             const SizedBox(height: 8),
                            _buildDimensionDropdown(
                              selectedValue: _selectedBeamReceiverSize,
                              options: _beamReceiverSizeOptions,
                              onChanged: (newValue) {
                                setState(() { _selectedBeamReceiverSize = newValue; });
                                _updateDimensionsFromDropdown(newValue, _beamReceiverWidthController, _beamReceiverThicknessController);
                              },
                              hintText: 'はり受サイズを選択',
                            ),
                          ],
                        )
                      ),
                       _buildVerticalInputGroup(
                        'そえ柱',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDimensionWithCheckbox(
                              null,
                              'bracePillarWidth', _bracePillarWidthController,
                              'bracePillarThickness', _bracePillarThicknessController,
                              '両端短め', _bracePillarShortEnds, (value) => setState(() => _bracePillarShortEnds = value!)
                            ),
                            const SizedBox(height: 8),
                            _buildDimensionDropdown(
                              selectedValue: _selectedBracePillarSize,
                              options: _bracePillarSizeOptions,
                              onChanged: (newValue) {
                                setState(() { _selectedBracePillarSize = newValue; });
                                _updateDimensionsFromDropdown(newValue, _bracePillarWidthController, _bracePillarThicknessController);
                              },
                              hintText: 'そえ柱サイズを選択',
                            ),
                          ],
                        )
                      ),
                      
                      const SizedBox(height: 16),
                      _buildDrawingPreview(
                        title: '図面手書き入力 (側・妻)',
                        onTap: _navigateToGawaTsumaDrawingScreen,
                        imageBytes: _gawaTsumaImageBytes,
                        placeholder: 'タップして側・妻を描く',
                      ),
                    ],
                  )
                ),
                
                _CollapsibleSection(
                  title: '天井セクション',
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildVerticalInputGroup(
                          '上板',
                          _buildLabeledTextField('上板', 'ceilingUpperBoardThickness', _ceilingUpperBoardThicknessController, keyboardType: TextInputType.number, unit: 'mm', showLabel: false),
                        )
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildVerticalInputGroup(
                          '下板',
                           _buildLabeledTextField('下板', 'ceilingLowerBoardThickness', _ceilingLowerBoardThicknessController, keyboardType: TextInputType.number, unit: 'mm', showLabel: false),
                        )
                      ),
                    ],
                  ),
                ),
                
                _CollapsibleSection(
                  title: '梱包材セクション',
                  child: Column(
                    children: [
                      _buildVerticalInputGroup(
                        'ハリ',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             _buildTripleInputRowWithUnit(
                              'hariWidth', _hariWidthController, '幅',
                              'hariThickness', _hariThicknessController, '厚',
                              'hariQuantity', _hariQuantityController, '本',
                            ),
                            const SizedBox(height: 8),
                             _buildDimensionDropdown(
                              selectedValue: _selectedHariSize,
                              options: _hariSizeOptions,
                              onChanged: (newValue) {
                                setState(() { _selectedHariSize = newValue; });
                                _updateDimensionsFromDropdown(newValue, _hariWidthController, _hariThicknessController);
                              },
                              hintText: 'ハリ サイズを選択',
                            ),
                          ],
                        ),
                      ),
                      _buildVerticalInputGroup('押さえ材', Column(
                        children: [
                          _buildQuadInputRow(
                            'pressingMaterialLength', _pressingMaterialLengthController, 'L',
                            'pressingMaterialWidth', _pressingMaterialWidthController, 'W',
                            'pressingMaterialThickness', _pressingMaterialThicknessController, 'T',
                            'pressingMaterialQuantity', _pressingMaterialQuantityController, '本'
                          ),
                          _buildCheckboxOption('盛り材が有', _pressingMaterialHasMolding, (value) => setState(() => _pressingMaterialHasMolding = value!)),
                        ],
                      )),
                      _buildVerticalInputGroup('トップ材', _buildQuadInputRow(
                        'topMaterialLength', _topMaterialLengthController, 'L',
                        'topMaterialWidth', _topMaterialWidthController, 'W',
                        'topMaterialThickness', _topMaterialThicknessController, 'T',
                        'topMaterialQuantity', _topMaterialQuantityController, '本'
                      )),
                    ],
                  ),
                ),

                _CollapsibleSection(
                  title: '追加部材セクション (5行)',
                  child: Column(
                    children: [
                       for (int i = 0; i < 5; i++)
                        _buildAdditionalPartRow(i,
                          'additionalPartName_$i', _additionalPartNameControllers[i],
                          'additionalPartLength_$i', _additionalPartLengthControllers[i],
                          'additionalPartWidth_$i', _additionalPartWidthControllers[i],
                          'additionalPartThickness_$i', _additionalPartThicknessControllers[i],
                          'additionalPartQuantity_$i', _additionalPartQuantityControllers[i]
                        ),
                    ],
                  )
                ),

                const SizedBox(height: 32),
                Center(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      
                      ElevatedButton(
                        onPressed: _saveAsNewTemplate,
                        child: const Text('別名で保存'),
                      ),

                      ElevatedButton.icon(
                        onPressed: _navigateToPreviewScreen,
                        icon: const Icon(Icons.print),
                        label: const Text('印刷プレビュー'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDimensionDropdown({
    required String? selectedValue,
    required List<String> options,
    required void Function(String?) onChanged,
    required String hintText,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.only(top: 4.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        hint: Text(hintText, style: const TextStyle(fontSize: 14)),
        isExpanded: true,
        items: options.map((size) {
          return DropdownMenuItem<String>(
            value: size,
            child: Text(size, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }

   Widget _buildLabeledTextField(String label, String key, TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    bool enabled = true,
    String? hintText,
    String? unit,
    bool showLabel = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showLabel) SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 14))),
          if (showLabel) const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              readOnly: readOnly,
              enabled: enabled,
              focusNode: _focusNodes[key],
              onSubmitted: (_) => _nextFocus(key),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: hintText,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                filled: true,
                fillColor: readOnly ? Colors.grey[200] : Colors.transparent,
              ),
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 8),
            Text(unit, style: TextStyle(color: Colors.grey[700])),
          ]
        ],
      ),
    );
  }
  Widget _buildLabeledDateInput(String label, String key, TextEditingController controller, Function(TextEditingController, String) onSelect) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(
            onTap: () => onSelect(controller, key),
            child: AbsorbPointer(
              child: TextField(
                controller: controller,
                readOnly: true,
                focusNode: _focusNodes[key],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'yyyy/MM/dd',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
  Widget _buildLabeledDropdown<T>(String label, String key, T? value, List<String> items, ValueChanged<String?> onChanged, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 80, child: Text(label)),
          const SizedBox(width: 8),
          Expanded(
            child: _buildDropdownBase<String>(
              focusNode: _focusNodes[key]!,
              value: value as String?,
              hint: hint,
              items: items.map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 14)),
              )).toList(),
              onChanged: (val) {
                onChanged(val);
                _nextFocus(key);
              }
            )
          ),
        ],
      ),
    );
  }
  Widget _buildDropdownBase<T>({
    required FocusNode focusNode,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      focusNode: focusNode,
      value: value,
      isDense: true,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      hint: Text(hint),
      items: items,
      onChanged: onChanged,
    );
  }
  Widget _buildRadioGroup(String? title, String groupKey, String? groupValue, List<String> options, ValueChanged<String?> onChanged) {
    Widget radioList = Row(
      children: options.map((option) => Expanded(
        child: Row(
          children: [
            Radio<String>(
              value: option,
              groupValue: groupValue,
              onChanged: (val) {
                onChanged(val);
                _nextFocus(groupKey);
              },
              visualDensity: VisualDensity.compact,
              focusNode: _focusNodes[groupKey],
            ),
            Flexible(child: Text(option, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
          ],
        ),
      )).toList(),
    );
    if (title == null) return radioList;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        radioList,
      ],
    );
  }
  Widget _buildVerticalInputGroup(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
  Widget _buildDrawingPreview({
    required String title,
    required VoidCallback onTap,
    required Uint8List? imageBytes,
    required String placeholder,
  }) {
    const double previewHeight = 250.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            height: previewHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.grey.shade100,
            ),
            child: imageBytes == null
                ? Center(child: Text(placeholder, style: TextStyle(color: Colors.grey.shade700)))
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Text('画像表示エラー')),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
  Widget _buildRadioOption(String value, String? groupValue, ValueChanged<String?> onChanged) {
    return Expanded(
      child: Row(
        children: [
          Radio<String>(value: value, groupValue: groupValue, onChanged: onChanged, visualDensity: VisualDensity.compact),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
  Widget _buildCheckboxOption(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged, visualDensity: VisualDensity.compact),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
  Widget _buildFormTypeRadioButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _formTypeOptions.map((key) {
        return SizedBox(
          height: 36,
          child: Row(
            children: [
              Radio<String>(
                value: key,
                groupValue: _selectedFormType,
                onChanged: (String? value) {
                  setState(() => _selectedFormType = value);
                  _triggerAllCalculations();
                  _nextFocus('formType');
                },
                visualDensity: VisualDensity.compact,
                focusNode: _focusNodes['formType'],
              ),
              Text(key, style: const TextStyle(fontSize: 14)),
            ],
          ),
        );
      }).toList(),
    );
  }
  Widget _buildDoubleInputRowWithUnit(
    String key1, TextEditingController ctrl1, String hint1,
    String key2, TextEditingController ctrl2, String hint2
  ) {
     return Row(
      children: [
        Expanded(child: _buildLabeledTextField('', key1, ctrl1, hintText: hint1, keyboardType: TextInputType.number, showLabel: false, unit: 'mm')),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
        Expanded(child: _buildLabeledTextField('', key2, ctrl2, hintText: hint2, keyboardType: TextInputType.number, showLabel: false, unit: 'mm')),
      ],
    );
  }

  // ▼▼▼【変更】製品サイズ表示用に1行表示オプションを追加 ▼▼▼
  Widget _buildTripleInputRow(String title,
    String key1, TextEditingController ctrl1, String hint1,
    String key2, TextEditingController ctrl2, String hint2,
    String key3, TextEditingController ctrl3, String hint3,
    {bool isReadOnly = false, bool showTitleAsLabel = false}
  ) {
    final inputRow = Row(
      children: [
        Expanded(child: _buildLabeledTextField('', key1, ctrl1, hintText: hint1, keyboardType: TextInputType.number, readOnly: isReadOnly, showLabel: false, unit: 'mm')),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
        Expanded(child: _buildLabeledTextField('', key2, ctrl2, hintText: hint2, keyboardType: TextInputType.number, readOnly: isReadOnly, showLabel: false, unit: 'mm')),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
        Expanded(child: _buildLabeledTextField('', key3, ctrl3, hintText: hint3, keyboardType: TextInputType.number, readOnly: isReadOnly, showLabel: false, unit: 'mm')),
      ],
    );

    if (showTitleAsLabel) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 80, child: Text(title, style: const TextStyle(fontSize: 14))),
            const SizedBox(width: 8),
            Expanded(child: inputRow),
          ],
        ),
      );
    }
    return _buildVerticalInputGroup(title, inputRow);
  }

  // ▼▼▼【変更】製品サイズ表示用に1行表示版の呼び出しを追加 ▼▼▼
  Widget _buildLabeledTripleInputRow(String title,
    String key1, TextEditingController ctrl1, String hint1,
    String key2, TextEditingController ctrl2, String hint2,
    String key3, TextEditingController ctrl3, String hint3,
  ) {
    return _buildTripleInputRow(
      title,
      key1, ctrl1, hint1,
      key2, ctrl2, hint2,
      key3, ctrl3, hint3,
      showTitleAsLabel: true,
    );
  }

  Widget _buildTripleInputRowWithUnit(
    String key1, TextEditingController ctrl1, String hint1,
    String key2, TextEditingController ctrl2, String hint2,
    String key3, TextEditingController ctrl3, String hint3,
    {bool isQuantityReadOnly = false}
  ) {
    return Row(
      children: [
        Expanded(child: _buildLabeledTextField('', key1, ctrl1, hintText: hint1, keyboardType: TextInputType.number, showLabel: false, unit: 'mm')),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
        Expanded(child: _buildLabeledTextField('', key2, ctrl2, hintText: hint2, keyboardType: TextInputType.number, showLabel: false, unit: 'mm')),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('・')),
        Expanded(child: _buildLabeledTextField('', key3, ctrl3, hintText: hint3, keyboardType: TextInputType.number, readOnly: isQuantityReadOnly, showLabel: false, unit: '本')),
      ],
    );
  }
  Widget _buildQuadInputRow(
    String key1, TextEditingController ctrl1, String hint1,
    String key2, TextEditingController ctrl2, String hint2,
    String key3, TextEditingController ctrl3, String hint3,
    String key4, TextEditingController ctrl4, String hint4,
  ) {
    return Row(
      children: [
        Expanded(child: _buildLabeledTextField('', key1, ctrl1, hintText: hint1, keyboardType: TextInputType.number, showLabel: false, unit: 'mm')),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
        Expanded(child: _buildLabeledTextField('', key2, ctrl2, hintText: hint2, keyboardType: TextInputType.number, showLabel: false, unit: 'mm')),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
        Expanded(child: _buildLabeledTextField('', key3, ctrl3, hintText: hint3, keyboardType: TextInputType.number, showLabel: false, unit: 'mm')),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('・')),
        Expanded(child: _buildLabeledTextField('', key4, ctrl4, hintText: hint4, keyboardType: TextInputType.number, showLabel: false, unit: '本')),
      ],
    );
  }
  Widget _buildDimensionWithRadioInput(
    String label,
    String key1, TextEditingController dim1Ctrl, String hint1,
    String key2, TextEditingController dim2Ctrl, String hint2,
    String radioLabel, List<String> radioOptions, String? groupValue, ValueChanged<String?> onChanged,
    String radioGroupKey
  ) {
    return _buildVerticalInputGroup(label, Row(
        children: [
          Expanded(flex: 3, child: _buildDoubleInputRowWithUnit(key1, dim1Ctrl, hint1, key2, dim2Ctrl, hint2)),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(radioLabel, style: const TextStyle(fontSize: 12)),
                _buildRadioGroup(null, radioGroupKey, groupValue, radioOptions, onChanged),
              ],
            ),
          ),
        ],
      ));
  }
  Widget _buildDimensionWithCheckbox(
    String? label,
    String key1, TextEditingController dim1Ctrl,
    String key2, TextEditingController ctrl2,
    String checkboxLabel, bool checkboxValue, ValueChanged<bool?> onChanged
  ) {
    final content = Row(
      children: [
        Expanded(flex: 2, child: _buildDoubleInputRowWithUnit(key1, dim1Ctrl, '幅', key2, ctrl2, '厚さ')),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: _buildCheckboxOption(checkboxLabel, checkboxValue, onChanged)),
      ],
    );
    if (label != null) {
      return _buildVerticalInputGroup(label, content);
    }
    return content;
  }
  Widget _buildAdditionalPartRow(int rowIndex,
    String nameKey, TextEditingController nameCtrl,
    String lenKey, TextEditingController lenCtrl,
    String widthKey, TextEditingController widthCtrl,
    String thicknessKey, TextEditingController thicknessCtrl,
    String quantityKey, TextEditingController quantityCtrl
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: TextField(controller: nameCtrl, focusNode: _focusNodes[nameKey], onSubmitted: (_) => _nextFocus(nameKey), textInputAction: TextInputAction.next, decoration: InputDecoration(hintText: '部材名', border: OutlineInputBorder(), isDense: true))),
          const SizedBox(width: 8),
          Expanded(child: _buildLabeledTextField('', lenKey, lenCtrl, hintText: 'L', keyboardType: TextInputType.number, showLabel: false, unit: 'mm')),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
          Expanded(child: _buildLabeledTextField('', widthKey, widthCtrl, hintText: 'W', keyboardType: TextInputType.number, showLabel: false, unit: 'mm')),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('×')),
          Expanded(child: _buildLabeledTextField('', thicknessKey, thicknessCtrl, hintText: 'T', keyboardType: TextInputType.number, showLabel: false, unit: 'mm')),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('・')),
          Expanded(child: _buildLabeledTextField('', quantityKey, quantityCtrl, hintText: '数', keyboardType: TextInputType.number, showLabel: false, unit: '本')),
        ],
      ),
    );
  }
}