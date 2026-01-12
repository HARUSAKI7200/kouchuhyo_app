// lib/screens/print_preview_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kouchuhyo_app/models/kochuhyo_data.dart';

class PrintPreviewScreen extends StatelessWidget {
  final KochuhyoData data;

  const PrintPreviewScreen({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('印刷プレビュー (A4縦に2セット)'),
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(data),
        initialPageFormat: PdfPageFormat.a4,
        canChangePageFormat: true,
        canChangeOrientation: true,
        dynamicLayout: true,
      ),
    );
  }

  Future<Uint8List> _generatePdf(KochuhyoData data) async {
    final doc = pw.Document();

    // ▼▼▼ 修正: ファイル名を NotoSerifJP (明朝) に戻す ▼▼▼
    final fontData = await rootBundle.load("assets/fonts/NotoSerifJP-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final fontBoldData = await rootBundle.load("assets/fonts/NotoSerifJP-Bold.ttf");
    final ttfBold = pw.Font.ttf(fontBoldData);

    final baseTheme = pw.ThemeData.withFont(base: ttf, bold: ttfBold);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: baseTheme,
        margin: const pw.EdgeInsets.all(0.5 * PdfPageFormat.cm),
        build: (pw.Context context) {
          final singleSetContent = _buildSingleSetContentArea(context, data, ttfBold, ttf);

          final availableHeightForTwoSets = PdfPageFormat.a4.height - (1.0 * PdfPageFormat.cm) ;
          final singleSetHeight = availableHeightForTwoSets / 2;

          return pw.Column(
            children: [
              pw.Container(
                width: PdfPageFormat.a4.width - (1.0 * PdfPageFormat.cm),
                height: singleSetHeight,
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
                padding: const pw.EdgeInsets.all(0.2 * PdfPageFormat.cm),
                child: singleSetContent,
              ),
              pw.Container(
                width: PdfPageFormat.a4.width - (1.0 * PdfPageFormat.cm),
                height: singleSetHeight,
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
                padding: const pw.EdgeInsets.all(0.2 * PdfPageFormat.cm),
                child: singleSetContent,
              ),
            ]
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildSingleSetContentArea(pw.Context context, KochuhyoData data, pw.Font ttfBold, pw.Font ttfRegular) {
    const double oneCm = 1 * PdfPageFormat.cm;
    final baseFontSize = oneCm * 0.28;
    
    // ▼▼▼ 修正: fontWeight: bold を削除 (ttfBold自体が太字なので不要) ▼▼▼
    final mainTextStyle = pw.TextStyle(fontSize: baseFontSize, font: ttfBold); 
    final boldTextStyle = pw.TextStyle(font: ttfBold, fontSize: baseFontSize);
    final headerTextStyle = pw.TextStyle(font: ttfBold, fontSize: baseFontSize * 1.2);
    final titleTextStyle = pw.TextStyle(font: ttfBold, fontSize: baseFontSize * 2.0);
    final materialStyle = pw.TextStyle(font: ttfBold, fontSize: baseFontSize * 1.1, color: PdfColors.red);
    
    const double tableCellPadding = 1.0;
    const double sectionSpacing = 0.5 * PdfPageFormat.mm;

    // ▼▼▼ 修正: copyWith時も fontWeight を指定しない ▼▼▼
    final commonContentTextStyle = mainTextStyle.copyWith(fontSize: baseFontSize * 1.15);
    final commonContentBoldStyle = boldTextStyle.copyWith(fontSize: baseFontSize * 1.15);

    final shippingDateTextStyle = pw.TextStyle(font: ttfBold, fontSize: baseFontSize * 1.8);
    final issueDateTextStyle = pw.TextStyle(font: ttfBold, fontSize: baseFontSize * 1.2);
    final serialNumberTextStyle = pw.TextStyle(font: ttfBold, fontSize: baseFontSize * 1.8);

    final pw.Widget dimensionsTable = pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2), 1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1), 3: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(tableCellPadding), child: pw.Text('内寸', style: boldTextStyle.copyWith(fontSize: baseFontSize * 1.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(tableCellPadding), child: pw.Text(data.innerLength, style: boldTextStyle.copyWith(fontSize: baseFontSize * 1.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(tableCellPadding), child: pw.Text(data.innerWidth, style: boldTextStyle.copyWith(fontSize: baseFontSize * 1.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(tableCellPadding), child: pw.Text(data.innerHeight, style: boldTextStyle.copyWith(fontSize: baseFontSize * 1.5))),
          ]
        ),
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(tableCellPadding), child: pw.Text('外寸', style: boldTextStyle)),
            pw.Padding(padding: const pw.EdgeInsets.all(tableCellPadding), child: pw.Text(data.outerLength, style: boldTextStyle)),
            pw.Padding(padding: const pw.EdgeInsets.all(tableCellPadding), child: pw.Text(data.outerWidth, style: boldTextStyle)),
            pw.Padding(padding: const pw.EdgeInsets.all(tableCellPadding), child: pw.Text(data.outerHeight, style: boldTextStyle)),
          ]
        ),
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(tableCellPadding), child: pw.Text('立米', style: boldTextStyle)),
            pw.Padding(padding: const pw.EdgeInsets.all(tableCellPadding), child: pw.Text(data.packagingVolume, style: boldTextStyle)),
            pw.Padding(padding: const pw.EdgeInsets.all(tableCellPadding), child: pw.Text('m³', style: boldTextStyle)),
            pw.Padding(padding: const pw.EdgeInsets.all(tableCellPadding), child: pw.Text('', style: boldTextStyle)),
          ]
        ),
      ]
    );

    pw.Widget _buildDrawing(Uint8List? imageBytes, String placeholder, double height) {
      return pw.Container(
          height: height,
          width: double.infinity,
          margin: pw.EdgeInsets.only(bottom: sectionSpacing),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
          child: imageBytes != null
              ? pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain)
              : pw.Center(child: pw.Text(placeholder, style: mainTextStyle)),
        );
    }

    pw.Widget _buildBasicInfoItem(
      String label,
      String value, {
      pw.TextStyle? valueStyle,
      bool isMaterial = false,
      double labelWidth = 40,
      bool scaleDown = false,
    }) {
      final labelStyle = mainTextStyle.copyWith(
        color: PdfColors.black,
        fontSize: baseFontSize * 1.5,
      );
      final valueTextStyle = (isMaterial ? materialStyle : (valueStyle ?? boldTextStyle)).copyWith(fontSize: baseFontSize * 1.5);

      if (scaleDown) {
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('$label:', style: labelStyle),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: pw.FittedBox(
                fit: pw.BoxFit.scaleDown,
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(value, style: valueTextStyle),
              ),
            ),
          ],
        );
      }

      return pw.Align(
        alignment: pw.Alignment.topLeft,
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label:',
                style: labelStyle,
              ),
              pw.TextSpan(
                text: value,
                style: valueTextStyle,
              ),
            ],
          ),
        ),
      );
    }

    pw.Widget _buildRightColumnInfoItem(
      String label,
      String value, {
      pw.TextStyle? valueStyle,
      bool isMaterial = false,
    }) {
      return pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: mainTextStyle.copyWith(
                color: PdfColors.black,
                fontSize: baseFontSize * 1.5,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: (isMaterial ? materialStyle : (valueStyle ?? boldTextStyle)).copyWith(fontSize: baseFontSize * 1.5),
            ),
          ],
        ),
      );
    }

    List<pw.Widget> _buildCombinedDimensionItems(KochuhyoData data, pw.TextStyle textStyle, pw.TextStyle boldStyle) {
      final List<pw.Widget> widgets = [];
      // sectionSpacing は既に定義済み

      widgets.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: '滑材: ', style: boldStyle),
                    pw.TextSpan(text: '${data.skidWidth} × ${data.skidThickness}・${data.skidQuantity}本', style: textStyle),
                  ]
                )
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'H(${data.hFixingMethod}): ', style: boldStyle),
                    pw.TextSpan(text: '${data.hWidth} × ${data.hThickness}', style: textStyle),
                  ]
                )
              ),
            ),
          ],
        )
      );
      widgets.add(pw.SizedBox(height: sectionSpacing));

      widgets.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: '${data.suriGetaType}: ', style: boldStyle),
                    pw.TextSpan(
                      text: '${data.suriGetaWidth} × ${data.suriGetaThickness}' +
                          (data.suriGetaType == 'ゲタ' ? ' ×${data.getaQuantity}本' : ''),
                      style: textStyle
                    ),
                  ]
                )
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: '床板: ', style: boldStyle),
                    pw.TextSpan(
                      text: '${data.floorBoardThickness}${data.isFloorBoardShort ? " (地板短め)" : ""}',
                      style: textStyle
                    ),
                  ]
                )
              ),
            ),
          ],
        )
      );
      widgets.add(pw.SizedBox(height: sectionSpacing));

      widgets.add(
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: '負荷床材: ', style: boldStyle),
              pw.TextSpan(text: '${data.loadBearingMaterialWidth} × ${data.loadBearingMaterialThickness}・${data.loadBearingMaterialQuantity}本', style: textStyle),
            ]
          )
        )
      );
      widgets.add(pw.SizedBox(height: sectionSpacing));

      List<pw.Widget> rootStopRowsToAdd = [];
      for (int i = 0; i < data.rootStops.length; i += 2) {
        pw.Widget? rootStop1Widget;
        pw.Widget? rootStop2Widget;

        if (i < data.rootStops.length) {
          final rawVal1 = data.rootStops[i];
          if (rawVal1.isNotEmpty) {
            final parsedRootStop1 = DimensionParser(rawVal1);
            if (parsedRootStop1.l.isNotEmpty || parsedRootStop1.w.isNotEmpty || parsedRootStop1.t.isNotEmpty || parsedRootStop1.qty.isNotEmpty) {
              rootStop1Widget = pw.Expanded(
                flex: 1,
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: '根止め: ', style: boldStyle),
                      pw.TextSpan(text: '${parsedRootStop1.l} × ${parsedRootStop1.w} × ${parsedRootStop1.t}・${parsedRootStop1.qty}本', style: textStyle),
                    ]
                  )
                ),
              );
            }
          }
        }

        if (i + 1 < data.rootStops.length) {
          final rawVal2 = data.rootStops[i + 1];
          if (rawVal2.isNotEmpty) {
            final parsedRootStop2 = DimensionParser(rawVal2);
            if (parsedRootStop2.l.isNotEmpty || parsedRootStop2.w.isNotEmpty || parsedRootStop2.t.isNotEmpty || parsedRootStop2.qty.isNotEmpty) {
              rootStop2Widget = pw.Expanded(
                flex: 1,
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: '根止め: ', style: boldStyle),
                      pw.TextSpan(text: '${parsedRootStop2.l} × ${parsedRootStop2.w} × ${parsedRootStop2.t}・${parsedRootStop2.qty}本', style: textStyle),
                    ]
                  )
                ),
              );
            }
          }
        }

        if (rootStop1Widget != null || rootStop2Widget != null) {
          rootStopRowsToAdd.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                rootStop1Widget ?? pw.Expanded(flex: 1, child: pw.Container()),
                pw.SizedBox(width: sectionSpacing * 4),
                rootStop2Widget ?? pw.Expanded(flex: 1, child: pw.Container()),
              ],
            )
          );
          rootStopRowsToAdd.add(pw.SizedBox(height: sectionSpacing));
        }
      }
      widgets.addAll(rootStopRowsToAdd);
      return widgets;
    }

    List<pw.Widget> _buildKonpozaiItems(KochuhyoData data, pw.TextStyle textStyle, pw.TextStyle boldStyle) {
      final List<pw.Widget> widgets = [];
      // sectionSpacing は既に定義済み

      widgets.add(
        pw.Align(
          alignment: pw.Alignment.topLeft,
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: 'ハリ: ', style: boldStyle),
                pw.TextSpan(text: '${data.hariWidth} × ${data.hariThickness}・${data.hariQuantity}本', style: textStyle),
              ]
            )
          ),
        )
      );
      widgets.add(pw.SizedBox(height: sectionSpacing));

      widgets.add(
        pw.Align(
          alignment: pw.Alignment.topLeft,
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: '押さえ材${data.pressingMaterialHasMolding ? " (盛材有)" : ""}: ', style: boldStyle),
                pw.TextSpan(text: '${data.pressingMaterialLength} × ${data.pressingMaterialWidth} × ${data.pressingMaterialThickness}・${data.pressingMaterialQuantity}本', style: textStyle),
              ]
            )
          ),
        )
      );
      widgets.add(pw.SizedBox(height: sectionSpacing));

      widgets.add(
        pw.Align(
          alignment: pw.Alignment.topLeft,
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: 'トップ材: ', style: boldStyle),
                pw.TextSpan(text: '${data.topMaterialLength} × ${data.topMaterialWidth} × ${data.topMaterialThickness}・${data.topMaterialQuantity}本', style: textStyle),
              ]
            )
          ),
        )
      );
      widgets.add(pw.SizedBox(height: sectionSpacing));

      return widgets;
    }

    List<pw.Widget> _buildGawaTsumaItems(KochuhyoData data, pw.TextStyle textStyle, pw.TextStyle boldStyle) {
      final List<pw.Widget> widgets = [];
      // sectionSpacing は既に定義済み

      widgets.add(
        pw.Align(
          alignment: pw.Alignment.topLeft,
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: '外板: ', style: boldStyle),
                pw.TextSpan(text: '${data.sideBoardThickness}', style: textStyle),
              ]
            )
          ),
        )
      );
      widgets.add(pw.SizedBox(height: sectionSpacing));

      widgets.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: '上かまち: ', style: boldStyle),
                    pw.TextSpan(text: '${data.upperKamachiWidth} × ${data.upperKamachiThickness}', style: textStyle),
                  ]
                )
              ),
            ),
            pw.SizedBox(width: sectionSpacing * 2),
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: '下かまち: ', style: boldStyle),
                    pw.TextSpan(text: '${data.lowerKamachiWidth} × ${data.lowerKamachiThickness}', style: textStyle),
                  ]
                )
              ),
            ),
            pw.SizedBox(width: sectionSpacing * 2),
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: '支柱: ', style: boldStyle),
                    pw.TextSpan(text: '${data.pillarWidth} × ${data.pillarThickness}', style: textStyle),
                  ]
                )
              ),
            ),
          ],
        )
      );
      widgets.add(pw.SizedBox(height: sectionSpacing));

      widgets.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'はり受${data.beamReceiverEmbed ? " (埋める)" : ""}: ', style: boldStyle),
                    pw.TextSpan(text: '${data.beamReceiverWidth} × ${data.beamReceiverThickness}', style: textStyle),
                  ]
                )
              ),
            ),
            pw.SizedBox(width: sectionSpacing * 2),
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'そえ柱${data.bracePillarShortEnds ? " (両端短め)" : ""}: ', style: boldStyle),
                    pw.TextSpan(text: '${data.bracePillarWidth} × ${data.bracePillarThickness}', style: textStyle),
                  ]
                )
              ),
            ),
          ],
        )
      );
      widgets.add(pw.SizedBox(height: sectionSpacing));

      return widgets;
    }

    List<pw.Widget> _buildTenjoItems(KochuhyoData data, pw.TextStyle textStyle, pw.TextStyle boldStyle) {
      final List<pw.Widget> widgets = [];
      // sectionSpacing は既に定義済み

      widgets.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: '上板: ', style: boldStyle),
                    pw.TextSpan(text: '${data.ceilingUpperBoardThickness}', style: textStyle),
                  ]
                )
              ),
            ),
            pw.SizedBox(width: sectionSpacing * 2),
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: '下板: ', style: boldStyle),
                    pw.TextSpan(text: '${data.ceilingLowerBoardThickness}', style: textStyle),
                  ]
                )
              ),
            ),
          ],
        )
      );
      widgets.add(pw.SizedBox(height: sectionSpacing));

      return widgets;
    }

    List<pw.Widget> _buildAdditionalPartsItems(KochuhyoData data, pw.TextStyle textStyle, pw.TextStyle boldStyle) {
      final List<pw.Widget> widgets = [];
      // sectionSpacing は既に定義済み
      for (int i = 0; i < data.additionalParts.length; i++) {
        final part = data.additionalParts[i];
        if (part['name']!.isNotEmpty && (DimensionParser(part['dims']!).l.isNotEmpty || DimensionParser(part['dims']!).w.isNotEmpty || DimensionParser(part['dims']!).t.isNotEmpty || DimensionParser(part['dims']!).qty.isNotEmpty)) {
          final parsedPart = DimensionParser(part['dims']!);
          widgets.add(
            pw.RichText( 
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(text: '${part['name']!}: ', style: boldStyle),
                  pw.TextSpan(text: '${parsedPart.l} × ${parsedPart.w} × ${parsedPart.t}・${parsedPart.qty}本', style: textStyle),
                ]
              )
            ),
          );
          widgets.add(pw.SizedBox(height: sectionSpacing));
        }
      }
      return widgets;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Stack(
          children: [
            pw.Center(
              child: pw.Stack(
                alignment: pw.Alignment.bottomCenter,
                children: <pw.Widget>[
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 0.5),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: <pw.Widget>[
                        pw.Text('工', style: titleTextStyle),
                        pw.SizedBox(width: 10 * PdfPageFormat.mm),
                        pw.Text('注', style: titleTextStyle),
                        pw.SizedBox(width: 10 * PdfPageFormat.mm),
                        pw.Text('票', style: titleTextStyle),
                      ],
                    ),
                  ),
                  pw.Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: pw.Container(
                      height: 0.75,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),
            // 左上に配置: 出荷日 & 時間指定
            pw.Align(
              alignment: pw.Alignment.topLeft,
              child: pw.Row(
                children: [
                   pw.Text('出荷日: ${data.shippingDate}', style: shippingDateTextStyle),
                   if (data.shippingTime.isNotEmpty) ...[
                     pw.SizedBox(width: 10),
                     pw.Text('時間指定: ${data.shippingTime}', style: shippingDateTextStyle),
                   ]
                ]
              )
            ),
            
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Padding(
                padding: pw.EdgeInsets.only(right: (PdfPageFormat.a4.width / 2 - (1.0 * PdfPageFormat.cm)) / 2 ),
                child: pw.Text('発行日: ${data.issueDate}', style: issueDateTextStyle),
              ),
            ),
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Text('整理番号: ${data.serialNumber}', style: serialNumberTextStyle),
            )
          ]
        ),
        pw.SizedBox(height: sectionSpacing * 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 3.0 * PdfPageFormat.cm,
              child: _buildBasicInfoItem('工番', data.kobango, labelWidth: 15 * PdfPageFormat.mm),
            ),
            pw.SizedBox(width: sectionSpacing * 2),
            pw.SizedBox(
              width: 3.5 * PdfPageFormat.cm,
              child: _buildBasicInfoItem('仕向先', data.shihomeisaki, labelWidth: 18 * PdfPageFormat.mm),
            ),
            pw.SizedBox(width: sectionSpacing * 2),
            // ▼▼▼ 品名を自動縮小 (scaleDown: true) ▼▼▼
            pw.SizedBox(
              width: 4.5 * PdfPageFormat.cm,
              child: _buildBasicInfoItem('品名', data.hinmei, labelWidth: 15 * PdfPageFormat.mm, scaleDown: true),
            ),
            pw.SizedBox(width: sectionSpacing * 2),
            pw.SizedBox(
              width: 3.0 * PdfPageFormat.cm,
              child: _buildBasicInfoItem('重量', '${data.weight} KG', labelWidth: 15 * PdfPageFormat.mm),
            ),
             pw.SizedBox(width: sectionSpacing * 2),
            pw.SizedBox(
              width: 3.5 * PdfPageFormat.cm,
              child: _buildBasicInfoItem('出荷形態', data.shippingType, labelWidth: 20 * PdfPageFormat.mm),
            ),
            pw.SizedBox(width: sectionSpacing * 2),
            pw.SizedBox(
              width: 3.0 * PdfPageFormat.cm,
              child: _buildBasicInfoItem('形状', data.packingForm, labelWidth: 15 * PdfPageFormat.mm),
            ),
            pw.Expanded(child: pw.Container()),
          ],
        ),
        pw.Divider(height: sectionSpacing * 2, thickness: 0.5),
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded( // 左列
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start, // 左列全体を左寄せに
                  children: [
                    dimensionsTable,
                    pw.SizedBox(height: sectionSpacing * 2),
                    // ★★★ 図面エリアの高さを 3.4cm に戻す ★★★
                    _buildDrawing(data.koshitaImageBytes, '腰下図面なし', 3.4 * PdfPageFormat.cm),
                    pw.Text('腰下・負荷床材・根止め', style: headerTextStyle),
                    pw.SizedBox(height: sectionSpacing),
                    ..._buildCombinedDimensionItems(data, commonContentTextStyle, commonContentBoldStyle),
                    pw.SizedBox(height: sectionSpacing * 2),
                    pw.Text('梱包材', style: headerTextStyle),
                    pw.SizedBox(height: sectionSpacing),
                    ..._buildKonpozaiItems(data, commonContentTextStyle, commonContentBoldStyle),
                  ]
                ),
              ),
              pw.SizedBox(width: sectionSpacing * 4),
              pw.Expanded( // 右列
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start, // 左列全体を左寄せに
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(child: _buildRightColumnInfoItem('形式', data.formType)),
                        pw.Expanded(child: _buildRightColumnInfoItem('材質', data.material, isMaterial: true)),
                      ],
                    ),
                    pw.SizedBox(height: sectionSpacing),
                    pw.Row(
                      children: [
                        pw.Expanded(child: _buildRightColumnInfoItem('乾燥剤', data.desiccantAmount)),
                        pw.Expanded(child: _buildRightColumnInfoItem('数量', '${data.quantity} C/S')),
                      ],
                    ),
                    pw.SizedBox(height: sectionSpacing * 2),
                    // ★★★ 図面エリアの高さを 2.8cm に戻す ★★★
                    _buildDrawing(data.gawaTsumaImageBytes, '側・妻図面なし', 2.8 * PdfPageFormat.cm),
                    pw.Text('側・妻', style: headerTextStyle),
                    pw.SizedBox(height: sectionSpacing),
                    ..._buildGawaTsumaItems(data, commonContentTextStyle, commonContentBoldStyle),
                    pw.SizedBox(height: sectionSpacing * 2),
                    pw.Text('天井', style: headerTextStyle),
                    pw.SizedBox(height: sectionSpacing),
                    ..._buildTenjoItems(data, commonContentTextStyle, commonContentBoldStyle),
                    pw.SizedBox(height: sectionSpacing * 2),
                    pw.Text('追加部材', style: headerTextStyle),
                    pw.SizedBox(height: sectionSpacing),
                    ..._buildAdditionalPartsItems(data, commonContentTextStyle, commonContentBoldStyle),
                    pw.Expanded(child: pw.Container()), // 残りのスペースを埋める
                  ]
                ),
              ),
            ],
          )
        ),
      ],
    );
  }
}