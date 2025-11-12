// lib/services/invoice_service.dart (WITH LOCAL FONTS + MULTI-PAGE - يعمل بدون إنترنت)

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';

class InvoiceService {
  static Future<pw.Document> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // ⭐⭐⭐ تحميل الخط المحلي من assets بدلاً من الإنترنت
    pw.Font? arabicFont;
    pw.Font? arabicFontBold;

    try {
      // ⭐ تحميل الخط من المجلد المحلي
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final fontBoldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');

      arabicFont = pw.Font.ttf(fontData);
      arabicFontBold = pw.Font.ttf(fontBoldData);

      if (kDebugMode) {
        print('✅ تم تحميل الخط العربي المحلي بنجاح');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ خطأ في تحميل الخط المحلي: $e');
        print('⚠️ تأكد من وجود الملفات في assets/fonts/');
      }

      // ⭐ إذا فشل، حاول استخدام خط جوجل (يحتاج إنترنت)
      try {
        arabicFont = await PdfGoogleFonts.cairoRegular();
        arabicFontBold = await PdfGoogleFonts.cairoBold();
        if (kDebugMode) {
          print('✅ تم تحميل خط جوجل (يحتاج إنترنت)');
        }
      } catch (e2) {
        if (kDebugMode) {
          print('❌ خطأ في تحميل خط جوجل: $e2');
          print('⚠️ سيتم استخدام الخط الافتراضي');
        }
      }
    }

    // تحميل صورة الباركود
    pw.ImageProvider? barcodeImage;
    try {
      final bytes = await rootBundle.load('assets/barcode.jpg');
      barcodeImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      if (kDebugMode) {
        print('Error loading barcode image: $e');
      }
    }

    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');
    final timeFormat = DateFormat('hh:mm a', 'ar');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(15), // ⭐ تصغير الهوامش
        textDirection: pw.TextDirection.rtl,
        theme: arabicFont != null && arabicFontBold != null
            ? pw.ThemeData.withFont(
                base: arabicFont,
                bold: arabicFontBold,
              )
            : pw.ThemeData.base(),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(10), // ⭐ كان 12
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 2),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Riad Soft Company',
                          style: pw.TextStyle(
                            fontSize: 18, // ⭐ كان 20
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textDirection: pw.TextDirection.ltr,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '01019187734',
                          style: pw.TextStyle(
                            fontSize: 11, // ⭐ كان 13
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textDirection: pw.TextDirection.ltr,
                        ),
                        pw.SizedBox(height: 3),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3), // ⭐ كان 8, 4
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                                color: PdfColors.black, width: 1.5),
                          ),
                          child: pw.Text(
                            'فاتورة مبيعات',
                            style: pw.TextStyle(
                              fontSize: 10, // ⭐ كان 12
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    children: [
                      if (barcodeImage != null)
                        pw.Container(
                            width: 110, // ⭐ كان 130
                            height: 90, // ⭐ كان 110
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Column(
                              children: [
                                pw.Image(barcodeImage,
                                    width: 100,
                                    height: 45,
                                    fit: pw.BoxFit.contain),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  "الموقع",
                                  style: const pw.TextStyle(
                                      fontSize: 6, color: PdfColors.black),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ],
                            ))
                      else
                        pw.Container(
                          width: 90, // ⭐ كان 100
                          height: 40, // ⭐ كان 45
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                                color: PdfColors.black, width: 1.5),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              invoice.invoiceNumber,
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 6), // ⭐ كان 8

            // Invoice Info
            pw.Container(
              padding: const pw.EdgeInsets.all(8), // ⭐ كان 10
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 2),
                ),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildInfoRow('رقم الفاتورة:',
                            invoice.invoiceNumber, 8), // ⭐ كان 9
                      ),
                      pw.Expanded(
                        child:
                            _buildInfoRow('العميل:', invoice.customerName, 8),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3), // ⭐ كان 4
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildInfoRow('التاريخ:',
                            dateFormat.format(invoice.invoiceDate), 8),
                      ),
                      pw.Expanded(
                        child: _buildInfoRow('الوقت:',
                            timeFormat.format(invoice.invoiceDate), 8),
                      ),
                    ],
                  ),
                  // ⭐⭐⭐ عرض "ملاحظات:" دائماً مع صندوق فارغ للكتابة اليدوية
                  pw.SizedBox(height: 6), // ⭐ كان 8
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ملاحظات:',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(width: 4), // ⭐ كان 6
                      pw.Expanded(
                        child: pw.Text(
                          invoice.notes ?? '',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 6), // ⭐ كان 8

            // Items Table - محسّن لأكبر عدد منتجات
            pw.Table(
              border: pw.TableBorder.all(
                  width: 1, color: PdfColors.grey400), // ⭐ كان 1.2
              columnWidths: {
                0: const pw.FlexColumnWidth(1.1),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(0.7),
                3: const pw.FlexColumnWidth(2.7),
                4: const pw.FlexColumnWidth(0.5),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    _buildTableHeader('الإجمالي', 9), // ⭐ كان 11
                    _buildTableHeader('السعر', 9),
                    _buildTableHeader('الكمية', 9),
                    _buildTableHeader('المنتج', 9),
                    _buildTableHeader('#', 9),
                  ],
                ),

                // Items
                ...invoice.items.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: index.isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      _buildTableCell('${item.total.toStringAsFixed(2)} ج',
                          bold: true,
                          fontSize: 8,
                          minHeight: 18), // ⭐ كان 10, 22
                      _buildTableCell(item.unitPrice.toStringAsFixed(2),
                          fontSize: 8, minHeight: 18),
                      _buildTableCell(item.quantity.toString(),
                          fontSize: 8, minHeight: 18),
                      _buildTableCell(item.productName,
                          align: pw.TextAlign.right,
                          fontSize: 8,
                          minHeight: 18),
                      _buildTableCell(index.toString(),
                          fontSize: 8, minHeight: 18),
                    ],
                  );
                }),

                // ⭐⭐⭐ 2 صف فارغ فقط (بدلاً من 3)
                ...List.generate(4, (rowIndex) {
                  return pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey50,
                    ),
                    children: [
                      _buildTableCell('',
                          fontSize: 8, minHeight: 20), // ⭐ كان 24
                      _buildTableCell('', fontSize: 8, minHeight: 20),
                      _buildTableCell('', fontSize: 8, minHeight: 20),
                      _buildTableCell('', fontSize: 8, minHeight: 20),
                      _buildTableCell('', fontSize: 8, minHeight: 20),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 6), // ⭐ كان 8

            // Totals
            pw.Container(
              padding: const pw.EdgeInsets.all(10), // ⭐ كان 12
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey400, width: 2),
              ),
              child: pw.Column(
                children: [
                  _buildTotalRow('المجموع الفرعي:', invoice.subtotal, 9,
                      false), // ⭐ كان 11
                  if (invoice.discount > 0) ...[
                    pw.SizedBox(height: 4), // ⭐ كان 6
                    _buildTotalRow(
                        'الخصم الإجمالي:', invoice.discount, 9, false,
                        isDiscount: true),
                  ],
                  if (invoice.tax > 0) ...[
                    pw.SizedBox(height: 4),
                    _buildTotalRow('الضريبة:', invoice.tax, 9, false),
                  ],
                  pw.SizedBox(height: 6), // ⭐ كان 8
                  pw.Container(height: 1.5, color: PdfColors.black),
                  pw.SizedBox(height: 6),
                  _buildTotalRow('الإجمالي النهائي:', invoice.finalTotal, 11,
                      true), // ⭐ كان 13
                ],
              ),
            ),

            pw.SizedBox(height: 6), // ⭐ كان 8

            // Warranty
            pw.Container(
              padding: const pw.EdgeInsets.all(8), // ⭐ كان 10

              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• ضمان الاوريجنال لمدة شهر من تاريخ الشراء',
                      style: const pw.TextStyle(
                          fontSize: 10, height: 1.3)), // ⭐ كان 9
                  pw.SizedBox(height: 2), // ⭐ كان 3
                  pw.Text('• ضمان جميع الفلاشات 6 شهور من تاريخ الشراء',
                      style: const pw.TextStyle(fontSize: 10, height: 1.3)),
                  pw.SizedBox(height: 2),
                  pw.Text('• جميع الاكسسوارات بدون ضمان (ضمان تجربة فقط)',
                      style: const pw.TextStyle(fontSize: 10, height: 1.3)),
                  pw.SizedBox(height: 2),
                  pw.Text('• فترة اختبار المنتج يومان من الاستلام',
                      style: const pw.TextStyle(fontSize: 10, height: 1.3)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildInfoRow(String label, String value, double fontSize) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text, double fontSize) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4), // ⭐ كان 6
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
    bool bold = false,
    double fontSize = 8,
    double minHeight = 18,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4), // ⭐ كان 6
      constraints: pw.BoxConstraints(minHeight: minHeight),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTotalRow(
      String label, double amount, double fontSize, bool isFinal,
      {bool isDiscount = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          '${amount.toStringAsFixed(2)} جنيه',
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
            color: isDiscount ? PdfColors.red700 : PdfColors.black,
          ),
        ),
      ],
    );
  }

  static Future<void> printInvoice(Invoice invoice) async {
    try {
      final pdf = await generateInvoicePdf(invoice);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'فاتورة_${invoice.invoiceNumber}.pdf',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error printing invoice: $e');
      }
      rethrow;
    }
  }

  static Future<void> saveInvoice(Invoice invoice, String path) async {
    try {
      final pdf = await generateInvoicePdf(invoice);
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving invoice: $e');
      }
      rethrow;
    }
  }
}
