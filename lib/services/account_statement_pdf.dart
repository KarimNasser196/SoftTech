// lib/services/account_statement_pdf.dart (WITH LOCAL FONTS - يعمل بدون إنترنت)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ⭐ إضافة هذا
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:soundtry/models/representative.dart';
import 'package:soundtry/models/representative_transaction.dart';
import 'package:intl/intl.dart';

class AccountStatementPDF {
  static Future<void> generate({
    required BuildContext context,
    required Representative representative,
    required List<RepresentativeTransaction> transactions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final numberFormat = NumberFormat('#,##0.00', 'ar');
    final dateFormat = DateFormat('yyyy-MM-dd', 'ar');

    // ⭐⭐⭐ تحميل الخط المحلي من assets بدلاً من الإنترنت
    pw.Font? arabicFont;
    pw.Font? arabicBoldFont;

    try {
      // ⭐ تحميل الخط من المجلد المحلي
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final fontBoldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');

      arabicFont = pw.Font.ttf(fontData);
      arabicBoldFont = pw.Font.ttf(fontBoldData);

      debugPrint('✅ تم تحميل الخط العربي المحلي لكشف الحساب');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الخط المحلي: $e');

      // ⭐ إذا فشل، حاول استخدام خط جوجل (يحتاج إنترنت)
      try {
        arabicFont = await PdfGoogleFonts.cairoRegular();
        arabicBoldFont = await PdfGoogleFonts.cairoBold();
        debugPrint('✅ تم تحميل خط جوجل (يحتاج إنترنت)');
      } catch (e2) {
        debugPrint('❌ خطأ في تحميل خط جوجل: $e2');
        debugPrint('⚠️ سيتم استخدام الخط الافتراضي');
      }
    }

    final hasDebt = representative.remainingDebt > 0;
    final hasCredit = representative.remainingDebt < 0;

    // ترتيب المعاملات من الأقدم للأحدث
    final sortedTransactions =
        List<RepresentativeTransaction>.from(transactions)
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // إنشاء صفوف الجدول مع حساب الرصيد التراكمي
    List<List<String>> tableRows = [];
    double runningBalance = 0.0;

    for (var tx in sortedTransactions) {
      double debitAmount = 0; // مدين
      double creditAmount = 0; // دائن
      String description = '';

      // داخل حلقة المعاملات
      if (tx.type == 'بيع') {
        debitAmount = tx.amount;
        creditAmount = tx.paidAmount;
        runningBalance += (tx.amount - tx.paidAmount);
        description = 'فاتورة بيع';
        if (tx.productsSummary != null && tx.productsSummary!.isNotEmpty) {
          // ⭐⭐⭐ إصلاح الأقواس
          if (tx.productsSummary != null && tx.productsSummary!.isNotEmpty) {
            if (tx.productsSummary != null && tx.productsSummary!.isNotEmpty) {
              if (tx.productsSummary != null &&
                  tx.productsSummary!.isNotEmpty) {
                if (tx.productsSummary != null &&
                    tx.productsSummary!.isNotEmpty) {
                  // تحويل من "جهاز(5)" إلى "جهاز ×5"
                  String formattedProducts = tx.productsSummary!
                      .replaceAll('(', ' ×')
                      .replaceAll(')', '');
                  description += ': $formattedProducts';
                }
              }
            }
          }
        }
      } else if (tx.type == 'دفعة') {
        creditAmount = tx.amount;
        runningBalance -= tx.amount;
        description = 'دفعة نقدية';
        if (tx.notes != null && tx.notes!.isNotEmpty) {
          description += ' - ${tx.notes}';
        }
      } else if (tx.type == 'مرتجع') {
        creditAmount = tx.amount;
        runningBalance -= tx.amount;
        description = 'مرتجع بضاعة';
        if (tx.productsSummary != null && tx.productsSummary!.isNotEmpty) {
          if (tx.productsSummary != null && tx.productsSummary!.isNotEmpty) {
            if (tx.productsSummary != null && tx.productsSummary!.isNotEmpty) {
              if (tx.productsSummary != null &&
                  tx.productsSummary!.isNotEmpty) {
                if (tx.productsSummary != null &&
                    tx.productsSummary!.isNotEmpty) {
                  // تحويل من "جهاز(5)" إلى "جهاز ×5"
                  String formattedProducts = tx.productsSummary!
                      .replaceAll('(', ' ×')
                      .replaceAll(')', '');
                  description += ': $formattedProducts';
                }
              }
            }
          }
        }
      } else if (tx.type == 'سحب مستحقات') {
        debitAmount = tx.amount;
        runningBalance += tx.amount;
        description = 'سحب مستحقات';
        if (tx.notes != null && tx.notes!.isNotEmpty) {
          description += ' - ${tx.notes}';
        }
      } else if (tx.type == 'دين مباشر') {
        debitAmount = tx.amount;
        runningBalance += tx.amount;
        description = 'دين مباشر';
        if (tx.notes != null && tx.notes!.isNotEmpty) {
          description += ' - ${tx.notes}';
        }
      } else if (tx.type == 'إيداع رصيد') {
        creditAmount = tx.amount;
        runningBalance -= tx.amount;
        description = 'إيداع رصيد';
        if (tx.notes != null && tx.notes!.isNotEmpty) {
          description += ' - ${tx.notes}';
        }
      }

      // إضافة الصف للجدول
      tableRows.add([
        dateFormat.format(tx.dateTime),
        description,
        debitAmount > 0 ? numberFormat.format(debitAmount) : '-',
        creditAmount > 0 ? numberFormat.format(creditAmount) : '-',
        numberFormat.format(runningBalance.abs()),
        runningBalance > 0
            ? 'مدين'
            : runningBalance < 0
                ? 'دائن'
                : 'متوازن',
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: arabicFont != null && arabicBoldFont != null
            ? pw.ThemeData.withFont(
                base: arabicFont,
                bold: arabicBoldFont,
              )
            : pw.ThemeData.base(),
        margin: const pw.EdgeInsets.all(15),
        build: (pw.Context context) {
          return [
            // ========== رأس التقرير المصغر ==========
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue900, width: 1.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  // شريط العنوان
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue900,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(4),
                        topRight: pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'كشف حساب',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ),
                  ),

                  // معلومات العميل - مصغرة
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    color: PdfColors.grey100,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            // بيانات العميل
                            pw.Row(
                              children: [
                                pw.Text(
                                  'الاسم: ',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                                pw.Text(
                                  representative.name,
                                  style: const pw.TextStyle(fontSize: 10),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                                pw.SizedBox(width: 15),
                                pw.Text(
                                  'النوع: ',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: representative.type == 'مندوب'
                                        ? PdfColors.blue100
                                        : PdfColors.green100,
                                    borderRadius: pw.BorderRadius.circular(3),
                                  ),
                                  child: pw.Text(
                                    representative.type,
                                    style: const pw.TextStyle(fontSize: 9),
                                    textDirection: pw.TextDirection.rtl,
                                  ),
                                ),
                              ],
                            ),

                            // تاريخ الطباعة
                            pw.Text(
                              'التاريخ: ${dateFormat.format(DateTime.now())}',
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey700,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ],
                        ),

                        // ⭐⭐⭐ إضافة معلومات الفترة
                        if (startDate != null || endDate != null) ...[
                          pw.SizedBox(height: 5),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue50,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text(
                                  'الفترة: ',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                                pw.Text(
                                  startDate != null
                                      ? 'من ${dateFormat.format(startDate)} '
                                      : 'من البداية ',
                                  style: const pw.TextStyle(fontSize: 9),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                                pw.Text(
                                  endDate != null
                                      ? 'إلى ${dateFormat.format(endDate)}'
                                      : 'حتى الآن',
                                  style: const pw.TextStyle(fontSize: 9),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // ========== جدول العمليات المصغر ==========
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey600,
                width: 0.3,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(60), // التاريخ
                1: const pw.FlexColumnWidth(4), // البيان
                2: const pw.FixedColumnWidth(55), // مدين
                3: const pw.FixedColumnWidth(55), // دائن
                4: const pw.FixedColumnWidth(60), // الرصيد
                5: const pw.FixedColumnWidth(40), // الحالة
              },
              children: [
                // رأس الجدول
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue900,
                  ),
                  children: [
                    _buildHeaderCell('التاريخ'),
                    _buildHeaderCell('البيان'),
                    _buildHeaderCell('مدين'),
                    _buildHeaderCell('دائن'),
                    _buildHeaderCell('الرصيد'),
                    _buildHeaderCell('الحالة'),
                  ],
                ),
                // صفوف البيانات
                ...tableRows.map((row) => pw.TableRow(
                      children: row.asMap().entries.map((entry) {
                        final index = entry.key;
                        final value = entry.value;

                        // تلوين خلية الحالة
                        PdfColor? cellColor;
                        if (index == 5) {
                          // عمود الحالة
                          if (value == 'مدين') {
                            cellColor = PdfColors.red50;
                          } else if (value == 'دائن') {
                            cellColor = PdfColors.blue50;
                          } else {
                            cellColor = PdfColors.green50;
                          }
                        }

                        return _buildDataCell(value, cellColor: cellColor);
                      }).toList(),
                    )),
              ],
            ),

            pw.SizedBox(height: 5),

            // ========== الملخص المالي المصغر ==========
            pw.Container(
              child: pw.Column(
                children: [
                  // تفاصيل الملخص
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSummaryBox(
                          'إجمالي المشتريات',
                          numberFormat.format(representative.totalDebt),
                        ),
                        _buildVerticalDivider(),
                        _buildSummaryBox(
                          'إجمالي المدفوعات',
                          numberFormat.format(representative.totalPaid),
                        ),
                        _buildVerticalDivider(),
                        _buildSummaryBox(
                          hasDebt
                              ? 'الرصيد المستحق'
                              : hasCredit
                                  ? 'رصيد دائن'
                                  : 'الحساب متوازن',
                          numberFormat
                              .format(representative.remainingDebt.abs()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // طباعة التقرير
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'كشف_حساب_${representative.name}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
  }

  // دالة لبناء خلية رأس الجدول - مصغرة
  static pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            color: PdfColors.white,
          ),
          textDirection: pw.TextDirection.rtl,
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  // دالة لبناء خلية البيانات - مصغرة
  static pw.Widget _buildDataCell(String text, {PdfColor? cellColor}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      color: cellColor,
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
        maxLines: 3,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  // دالة لبناء صندوق الملخص - مصغرة
  static pw.Widget _buildSummaryBox(
    String label,
    String value,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: pw.Text(
            '$value جنيه',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ),
      ],
    );
  }

  // دالة للفاصل العمودي - مصغرة
  static pw.Widget _buildVerticalDivider() {
    return pw.Container(
      height: 35,
      width: 1,
      color: PdfColors.grey400,
    );
  }
}
