// lib/models/kochuhyo_data.dart

import 'dart:convert';
import 'dart:typed_data';

/// 寸法文字列（例: "100x200x50・5本"）を解析するクラス
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

/// 工注票の全データを保持するクラス
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