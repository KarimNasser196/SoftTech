// lib/screens/maintenance_screen.dart (محدث مع طباعة إيصال الاستلام)
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:soundtry/models/maintenance_department.dart';
import 'package:soundtry/screens/maintenance_departments_screen.dart';
import 'package:soundtry/services/database_helper.dart';
import '../providers/maintenance_provider.dart';
import '../models/maintenance_record.dart';
import 'add_maintenance_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  String _remainingFilter = 'الكل';
  final List<String> _remainingFilterOptions = [
    'الكل',
    'يوجد متبقي',
    'لا يوجد متبقي',
  ];
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  String _dateFilter = 'الكل';
  String _financialFilter = 'الكل';
  bool _showFinancialStats = false;
  DateTime? _financialStartDate;
  DateTime? _financialEndDate;
  int? _selectedDepartmentId;
  List<MaintenanceDepartment> _departments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final db = DatabaseHelper.instance;
    final data = await db.getMaintenanceDepartments();
    setState(() {
      _departments = data.map((d) => MaintenanceDepartment.fromMap(d)).toList();
    });
  }

  void _showAdvancedPrintDialog(BuildContext context) {
    DateTime? startDate;
    DateTime? endDate;
    String selectedStatus = 'الكل';
    int? selectedDepartment;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('خيارات الطباعة'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('من تاريخ',
                            style: TextStyle(fontSize: 14)),
                        subtitle: Text(
                          startDate != null
                              ? DateFormat('yyyy-MM-dd').format(startDate!)
                              : 'غير محدد',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.calendar_today, size: 20),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => startDate = date);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('إلى تاريخ',
                            style: TextStyle(fontSize: 14)),
                        subtitle: Text(
                          endDate != null
                              ? DateFormat('yyyy-MM-dd').format(endDate!)
                              : 'غير محدد',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.calendar_today, size: 20),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: startDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => endDate = date);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'الحالة',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: [
                    'الكل',
                    'قيد الإصلاح',
                    'جاهز للاستلام',
                    'تم التسليم',
                    'ملغي',
                    'مرفوض',
                  ].map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedStatus = value!);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'القسم',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('الكل')),
                    ..._departments.map((dept) {
                      return DropdownMenuItem(
                        value: dept.id,
                        child: Text(dept.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => selectedDepartment = value);
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label:
                          const Text('اليوم', style: TextStyle(fontSize: 12)),
                      selected: false,
                      onSelected: (_) {
                        setState(() {
                          final now = DateTime.now();
                          startDate = DateTime(now.year, now.month, now.day);
                          endDate = now;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('هذا الأسبوع',
                          style: TextStyle(fontSize: 12)),
                      selected: false,
                      onSelected: (_) {
                        setState(() {
                          final now = DateTime.now();
                          int daysToSubtract = (now.weekday + 1) % 7;
                          startDate =
                              now.subtract(Duration(days: daysToSubtract));
                          endDate = now;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('هذا الشهر',
                          style: TextStyle(fontSize: 12)),
                      selected: false,
                      onSelected: (_) {
                        setState(() {
                          final now = DateTime.now();
                          startDate = DateTime(now.year, now.month, 1);
                          endDate = now;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _printFilteredReport(
                  context,
                  startDate: startDate,
                  endDate: endDate,
                  status: selectedStatus == 'الكل' ? null : selectedStatus,
                  departmentId: selectedDepartment,
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('طباعة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printFilteredReport(
    BuildContext context, {
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? departmentId,
  }) async {
    final provider = Provider.of<MaintenanceProvider>(context, listen: false);
    var records = provider.maintenanceRecords;

    if (startDate != null) {
      records =
          records.where((r) => r.receivedDate.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      final end =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      records = records.where((r) => r.receivedDate.isBefore(end)).toList();
    }
    if (status != null) {
      records = records.where((r) => r.status == status).toList();
    }
    if (departmentId != null) {
      records = records.where((r) => r.departmentId == departmentId).toList();
    }

    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد سجلات تطابق الفلاتر المحددة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // ⭐⭐⭐ تحميل الخط المحلي من assets
      pw.Font? arabicFont;
      pw.Font? arabicBoldFont;

      try {
        final fontData =
            await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        final fontBoldData =
            await rootBundle.load('assets/fonts/Cairo-Bold.ttf');

        arabicFont = pw.Font.ttf(fontData);
        arabicBoldFont = pw.Font.ttf(fontBoldData);

        debugPrint('✅ تم تحميل الخط العربي المحلي لتقرير الصيانة');
      } catch (e) {
        debugPrint('❌ خطأ في تحميل الخط المحلي: $e');

        // احتياطي: محاولة استخدام خط جوجل
        try {
          arabicFont = await PdfGoogleFonts.cairoRegular();
          arabicBoldFont = await PdfGoogleFonts.cairoBold();
          debugPrint('✅ تم تحميل خط جوجل (يحتاج إنترنت)');
        } catch (e2) {
          debugPrint('❌ خطأ في تحميل خط جوجل: $e2');
          rethrow;
        }
      }

      final pdf = pw.Document();

      String departmentName = 'الكل';
      if (departmentId != null) {
        final dept = _departments.firstWhere((d) => d.id == departmentId);
        departmentName = dept.name;
      }

      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(15),
          build: (context) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'تقرير الصيانة',
                    style: pw.TextStyle(fontSize: 12, font: arabicBoldFont),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 8, font: arabicFont),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'الحالة: ${status ?? 'الكل'}',
                        style: pw.TextStyle(fontSize: 8, font: arabicFont),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Text(
                        'القسم: $departmentName',
                        style: pw.TextStyle(fontSize: 8, font: arabicFont),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Text(
                        'عدد السجلات: ${records.length}',
                        style: pw.TextStyle(
                            fontSize: 8,
                            font: arabicBoldFont,
                            color: PdfColors.blue700),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            ...List.generate(records.length, (index) {
              final record = records[index];
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 5),
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(3)),
                  color: index.isEven ? PdfColors.grey50 : PdfColors.white,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '[${index + 1}] ${record.repairCode}',
                          style:
                              pw.TextStyle(fontSize: 8, font: arabicBoldFont),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: _getPdfStatusColor(record.status),
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(3)),
                          ),
                          child: pw.Text(
                            record.status,
                            style: pw.TextStyle(
                              fontSize: 8,
                              font: arabicFont,
                              color: PdfColors.white,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ),
                        pw.Text(
                          DateFormat('yyyy-MM-dd').format(record.receivedDate),
                          style: pw.TextStyle(
                            fontSize: 8,
                            font: arabicFont,
                            color: PdfColors.grey700,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      children: [
                        if (record.departmentName != null) ...[
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.purple50,
                              borderRadius:
                                  pw.BorderRadius.all(pw.Radius.circular(3)),
                            ),
                            child: pw.Text(
                              record.departmentName!,
                              style: pw.TextStyle(
                                fontSize: 7,
                                font: arabicFont,
                                color: PdfColors.purple700,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ),
                          pw.SizedBox(width: 6),
                        ],
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'العميل: ${record.customerName}',
                            style: pw.TextStyle(fontSize: 8, font: arabicFont),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'الهاتف: ${record.customerPhone}',
                            style: pw.TextStyle(fontSize: 8, font: arabicFont),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'الجهاز: ${record.deviceType}',
                      style: pw.TextStyle(fontSize: 8, font: arabicFont),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'العطل: ${record.problemDescription}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        font: arabicFont,
                        color: PdfColors.grey800,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      maxLines: 2,
                    ),
                    if (record.cost > 0 && status != 'قيد الإصلاح') ...[
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'التكلفة: ${record.cost.toStringAsFixed(2)} جنيه',
                            style: pw.TextStyle(
                              fontSize: 7,
                              font: arabicFont,
                              color: PdfColors.orange700,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            'المدفوع: ${record.paidAmount.toStringAsFixed(2)} جنيه',
                            style: pw.TextStyle(
                              fontSize: 7,
                              font: arabicFont,
                              color: PdfColors.green700,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            'الباقي: ${record.remainingAmount.toStringAsFixed(2)} جنيه',
                            style: pw.TextStyle(
                              fontSize: 7,
                              font: arabicBoldFont,
                              color: record.remainingAmount > 0
                                  ? PdfColors.red700
                                  : PdfColors.green700,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfStat(
                    'إجمالي السجلات',
                    records.length.toString(),
                    arabicFont!,
                    arabicBoldFont!,
                  ),
                  if (status != 'قيد الإصلاح') ...[
                    _buildPdfStat(
                      'إجمالي التكلفة',
                      '${records.fold<double>(0, (sum, r) => sum + r.cost).toStringAsFixed(2)} جنيه',
                      arabicFont,
                      arabicBoldFont,
                    ),
                    _buildPdfStat(
                      'إجمالي المدفوع',
                      '${records.fold<double>(0, (sum, r) => sum + r.paidAmount).toStringAsFixed(2)} جنيه',
                      arabicFont,
                      arabicBoldFont,
                    ),
                    _buildPdfStat(
                      'إجمالي المتبقي',
                      '${records.fold<double>(0, (sum, r) => sum + r.remainingAmount).toStringAsFixed(2)} جنيه',
                      arabicFont,
                      arabicBoldFont,
                    ),
                  ]
                ],
              ),
            ),
          ],
          footer: (context) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 5),
            child: pw.Text(
              'صفحة ${context.pageNumber} من ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 8,
                font: arabicFont,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name:
            'تقرير_صيانة_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء التقرير بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfStat(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style:
              pw.TextStyle(fontSize: 8, font: font, color: PdfColors.grey700),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8,
            font: boldFont,
            color: PdfColors.green900,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

// ⭐⭐⭐ استبدل دالة _printReceiptReceipt بهذا الكود (مع الخط المحلي)

  Future<void> _printReceiptReceipt(
      BuildContext context, MaintenanceRecord record) async {
    try {
      // ⭐⭐⭐ تحميل الخط المحلي من assets
      pw.Font? arabicFont;
      pw.Font? arabicBoldFont;

      try {
        final fontData =
            await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        final fontBoldData =
            await rootBundle.load('assets/fonts/Cairo-Bold.ttf');

        arabicFont = pw.Font.ttf(fontData);
        arabicBoldFont = pw.Font.ttf(fontBoldData);

        debugPrint('✅ تم تحميل الخط العربي المحلي لإيصال الصيانة');
      } catch (e) {
        debugPrint('❌ خطأ في تحميل الخط المحلي: $e');

        // احتياطي: محاولة استخدام خط جوجل
        try {
          arabicFont = await PdfGoogleFonts.cairoRegular();
          arabicBoldFont = await PdfGoogleFonts.cairoBold();
          debugPrint('✅ تم تحميل خط جوجل (يحتاج إنترنت)');
        } catch (e2) {
          debugPrint('❌ خطأ في تحميل خط جوجل: $e2');
          rethrow;
        }
      }

      final pdf = pw.Document();

      // حساب 35% من ارتفاع صفحة A4
      double pageHeight = PdfPageFormat.a4.height * 0.37;
      double pageWidth = PdfPageFormat.a4.width;

      // إنشاء format مخصص للإيصال
      final receiptFormat = PdfPageFormat(
        pageWidth,
        pageHeight,
        marginAll: 8,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: receiptFormat,
          textDirection: pw.TextDirection.rtl,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.SizedBox(height: 4),
                // رأس الإيصال
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue700, width: 1.5),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Riad Soft Company',
                        style: pw.TextStyle(
                          fontSize: 14,
                          font: arabicBoldFont,
                          color: PdfColors.blue900,
                        ),
                        textDirection: pw.TextDirection.ltr,
                      ),
                      pw.Text(
                        '01019187734',
                        style: pw.TextStyle(
                          fontSize: 12,
                          font: arabicBoldFont,
                          color: PdfColors.blue700,
                        ),
                        textDirection: pw.TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),

                // عنوان الإيصال
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'إيصال استلام جهاز',
                      style: pw.TextStyle(
                        fontSize: 11,
                        font: arabicBoldFont,
                        color: PdfColors.blue900,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),

                // معلومات الإيصال
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // كود الصيانة والتاريخ
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Row(
                            children: [
                              pw.Text(
                                'كود: ',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  font: arabicFont,
                                  color: PdfColors.grey700,
                                ),
                                textDirection: pw.TextDirection.rtl,
                              ),
                              pw.Text(
                                record.repairCode,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  font: arabicBoldFont,
                                  color: PdfColors.black,
                                ),
                                textDirection: pw.TextDirection.rtl,
                              ),
                            ],
                          ),
                          pw.Text(
                            DateFormat('yyyy/MM/dd HH:mm', 'ar')
                                .format(record.receivedDate),
                            style: pw.TextStyle(
                              fontSize: 12,
                              font: arabicBoldFont,
                              color: PdfColors.black,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),

                      // اسم العميل
                      _buildCompactRow(
                        'العميل:',
                        record.customerName,
                        arabicFont!,
                        arabicBoldFont!,
                      ),
                      pw.SizedBox(height: 3),

                      // نوع الجهاز
                      _buildCompactRow(
                        'الجهاز:',
                        record.deviceType,
                        arabicFont,
                        arabicBoldFont,
                      ),
                      pw.SizedBox(height: 3),

                      // وصف العطل
                      _buildCompactRow(
                        'العطل:',
                        record.problemDescription,
                        arabicFont,
                        arabicBoldFont,
                        isMultiline: true,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),

                // التكاليف
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(3)),
                    border: pw.Border.all(color: PdfColors.green600, width: 1),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      // التكلفة
                      pw.Column(
                        children: [
                          pw.Text(
                            'التكلفة',
                            style: pw.TextStyle(
                              fontSize: 10,
                              font: arabicFont,
                              color: PdfColors.grey700,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            '${record.cost.toStringAsFixed(0)} ج',
                            style: pw.TextStyle(
                              fontSize: 12,
                              font: arabicBoldFont,
                              color: PdfColors.orange800,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),

                      pw.Container(
                        height: 20,
                        width: 0.5,
                        color: PdfColors.grey400,
                      ),

                      // المدفوع
                      pw.Column(
                        children: [
                          pw.Text(
                            'المدفوع',
                            style: pw.TextStyle(
                              fontSize: 10,
                              font: arabicFont,
                              color: PdfColors.grey700,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            '${record.paidAmount.toStringAsFixed(0)} ج',
                            style: pw.TextStyle(
                              fontSize: 12,
                              font: arabicBoldFont,
                              color: PdfColors.green700,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),

                      pw.Container(
                        height: 20,
                        width: 0.5,
                        color: PdfColors.grey400,
                      ),

                      // المتبقي
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: record.remainingAmount > 0
                              ? PdfColors.red50
                              : PdfColors.green100,
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'المتبقي',
                              style: pw.TextStyle(
                                fontSize: 10,
                                font: arabicFont,
                                color: record.remainingAmount > 0
                                    ? PdfColors.red800
                                    : PdfColors.green800,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                            pw.Text(
                              '${record.remainingAmount.toStringAsFixed(0)} ج',
                              style: pw.TextStyle(
                                fontSize: 12,
                                font: arabicBoldFont,
                                color: record.remainingAmount > 0
                                    ? PdfColors.red800
                                    : PdfColors.green800,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),

                // الشروط والأحكام
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.yellow50,
                    border:
                        pw.Border.all(color: PdfColors.orange600, width: 0.8),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Center(
                        child: pw.Text(
                          'شروط وملاحظات هامة',
                          style: pw.TextStyle(
                            fontSize: 10,
                            font: arabicBoldFont,
                            color: PdfColors.red800,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                      pw.SizedBox(height: 3),

                      // الشرط الأول
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '1.',
                            style: pw.TextStyle(
                              fontSize: 8,
                              font: arabicBoldFont,
                              color: PdfColors.red700,
                            ),
                          ),
                          pw.SizedBox(width: 2),
                          pw.Expanded(
                            child: pw.Text(
                              'هذا الايصال هو اثبات حقك  لدى  الشركة فلا  يجوز  الاستلام بدونه تماما ',
                              style: pw.TextStyle(
                                fontSize: 8,
                                font: arabicFont,
                                color: PdfColors.black,
                                height: 1.2,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 2),

                      // الشرط الثاني
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '2.',
                            style: pw.TextStyle(
                              fontSize: 8,
                              font: arabicBoldFont,
                              color: PdfColors.red700,
                            ),
                          ),
                          pw.SizedBox(width: 2),
                          pw.Expanded(
                            child: pw.Text(
                              'يعتبر  هذا  الايصال لاغي بتاريخ ${DateFormat('yyyy/MM/dd').format(record.receivedDate.add(const Duration(days: 30)))} في حالة عدم الاستلام خلال هذه المدة ',
                              style: pw.TextStyle(
                                fontSize: 8,
                                font: arabicFont,
                                color: PdfColors.black,
                                height: 1.2,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // طباعة الإيصال
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'إيصال_${record.repairCode}.pdf',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الإيصال بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// دالة مساعدة لبناء صف مضغوط
  pw.Widget _buildCompactRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont, {
    bool isMultiline = false,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            font: font,
            color: PdfColors.grey700,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              font: boldFont,
              color: PdfColors.black,
            ),
            textDirection: pw.TextDirection.rtl,
            maxLines: isMultiline ? 2 : 1,
          ),
        ),
      ],
    );
  }

  PdfColor _getPdfStatusColor(String status) {
    switch (status) {
      case 'قيد الإصلاح':
        return PdfColors.orange;
      case 'جاهز للاستلام':
        return PdfColors.green;
      case 'تم التسليم':
        return PdfColors.grey;
      case 'ملغي':
        return PdfColors.red;
      case 'مرفوض':
        return PdfColors.deepPurple;
      default:
        return PdfColors.blue;
    }
  }

  final List<String> _dateFilterOptions = [
    'الكل',
    'اليوم',
    'الأمس',
    'هذا الأسبوع',
    'هذا الشهر',
    'تاريخ محدد',
  ];

  final List<String> _financialFilterOptions = [
    'الكل',
    'اليوم',
    'هذا الأسبوع',
    'هذا الشهر',
    'فترة مخصصة',
  ];

  Future<void> _selectFinancialDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _financialStartDate != null && _financialEndDate != null
          ? DateTimeRange(start: _financialStartDate!, end: _financialEndDate!)
          : null,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
      helpText: 'اختر نطاق التاريخ للإيرادات',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      saveText: 'حفظ',
      errorFormatText: 'صيغة التاريخ غير صحيحة',
      errorInvalidText: 'تاريخ غير صالح',
      errorInvalidRangeText: 'نطاق التاريخ غير صالح',
      fieldStartHintText: 'من تاريخ',
      fieldEndHintText: 'إلى تاريخ',
      fieldStartLabelText: 'تاريخ البداية',
      fieldEndLabelText: 'تاريخ النهاية',
    );

    if (picked != null && mounted) {
      setState(() {
        _financialFilter = 'فترة مخصصة';
        _financialStartDate = picked.start;
        _financialEndDate = picked.end;
      });
    }
  }

  Widget _buildStatisticsBar(BuildContext context) {
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, _) {
        Map<String, double> financialStats;

        if (_financialFilter == 'فترة مخصصة' &&
            _financialStartDate != null &&
            _financialEndDate != null) {
          financialStats = provider.getFinancialStatisticsByDateRange(
            _financialStartDate!,
            _financialEndDate!,
          );
        } else {
          financialStats = provider.getFinancialStatistics(_financialFilter);
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[500]!],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'إجمالي السجلات',
                      '${provider.totalRecords}',
                      Icons.list_alt,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'قيد الإصلاح',
                      '${provider.pendingRecords}',
                      Icons.pending,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'جاهز للاستلام',
                      '${provider.readyForPickup}',
                      Icons.check_circle,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'تم التسليم',
                      '${provider.completedRecords}',
                      Icons.done_all,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'ملغي',
                      '${provider.cancelledRecords}',
                      Icons.cancel,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'مرفوض',
                      '${provider.rejectedRecords}',
                      Icons.block,
                    ),
                  ),
                  if (_showFinancialStats) ...[
                    Expanded(
                      child: _buildFinancialStatItem(
                        'الإيرادات',
                        financialStats['revenue']!,
                        Icons.attach_money,
                      ),
                    ),
                    Expanded(
                      child: _buildFinancialStatItem(
                        'المتبقي',
                        financialStats['remaining']!,
                        Icons.pending_actions,
                      ),
                    ),
                    Expanded(
                      child: _buildFinancialStatItem(
                        'المتبقي (بعد التسليم)',
                        financialStats['remainingAfterDelivery']!,
                        Icons.account_balance_wallet,
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: _showFinancialStats
                          ? 'إخفاء الإحصائيات المالية'
                          : 'إظهار الإحصائيات المالية',
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _showFinancialStats = !_showFinancialStats;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _showFinancialStats
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _showFinancialStats
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showFinancialStats) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_list,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'فترة الإيرادات:',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _financialFilter,
                            dropdownColor: Colors.blue[700],
                            underline: Container(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            items: _financialFilterOptions.map((filter) {
                              return DropdownMenuItem(
                                value: filter,
                                child: Text(filter),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              if (value == 'فترة مخصصة') {
                                await _selectFinancialDateRange(context);
                              } else {
                                setState(() {
                                  _financialFilter = value!;
                                  _financialStartDate = null;
                                  _financialEndDate = null;
                                });
                              }
                            },
                          ),
                          if (_financialFilter == 'فترة مخصصة' &&
                              _financialStartDate != null &&
                              _financialEndDate != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${DateFormat('yyyy/MM/dd').format(_financialStartDate!)} - ${DateFormat('yyyy/MM/dd').format(_financialEndDate!)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _financialFilter = 'الكل';
                                        _financialStartDate = null;
                                        _financialEndDate = null;
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
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
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialStatItem(
    String label,
    double value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${value.toStringAsFixed(2)} ج',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStatistics(BuildContext context) {
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, _) {
        final todayStats = provider.getTodayStatistics();
        return Container(
          padding: const EdgeInsets.all(12),
          color: Colors.green[50],
          child: Row(
            children: [
              Icon(Icons.today, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'إحصائيات اليوم: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
              const SizedBox(width: 16),
              _buildMiniStat(
                  'إجمالي السجلات', todayStats['received']!, Colors.blue),
              const SizedBox(width: 12),
              _buildMiniStat(
                  'قيد الإصلاح', todayStats['inProgress']!, Colors.orange),
              const SizedBox(width: 12),
              _buildMiniStat(
                  'جاهز للاستلام', todayStats['ready']!, Colors.green),
              const SizedBox(width: 12),
              _buildMiniStat(
                  'تم التسليم', todayStats['delivered']!, Colors.grey),
              const SizedBox(width: 12),
              _buildMiniStat('ملغي', todayStats['cancelled']!, Colors.grey),
              const SizedBox(width: 12),
              _buildMiniStat('مرفوض', todayStats['rejected']!, Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<MaintenanceRecord> _applyDateFilter(List<MaintenanceRecord> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_dateFilter) {
      case 'اليوم':
        return records.where((r) {
          final date = DateTime(
            r.receivedDate.year,
            r.receivedDate.month,
            r.receivedDate.day,
          );
          return date == today;
        }).toList();

      case 'الأمس':
        final yesterday = today.subtract(const Duration(days: 1));
        return records.where((r) {
          final date = DateTime(
            r.receivedDate.year,
            r.receivedDate.month,
            r.receivedDate.day,
          );
          return date == yesterday;
        }).toList();

      case 'هذا الأسبوع':
        int daysToSubtract = (now.weekday + 1) % 7;
        final weekStart = today.subtract(Duration(days: daysToSubtract));
        final weekStartNormalized = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        );

        return records.where((r) {
          final recordDate = DateTime(
            r.receivedDate.year,
            r.receivedDate.month,
            r.receivedDate.day,
          );
          return recordDate.isAfter(
                  weekStartNormalized.subtract(const Duration(seconds: 1))) &&
              recordDate.isBefore(today.add(const Duration(days: 1)));
        }).toList();

      case 'تاريخ محدد':
        if (_selectedDate != null) {
          final targetDate = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          );
          return records.where((r) {
            final date = DateTime(
              r.receivedDate.year,
              r.receivedDate.month,
              r.receivedDate.day,
            );
            return date == targetDate;
          }).toList();
        }
        return records;

      default:
        return records;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد الإصلاح':
        return Colors.orange;
      case 'جاهز للاستلام':
        return Colors.green;
      case 'تم التسليم':
        return Colors.grey;
      case 'ملغي':
        return Colors.red;
      case 'مرفوض':
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
  }

  void _showRecordDetails(MaintenanceRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMaintenanceScreen(record: record),
      ),
    );
  }

  void _showStatusUpdateDialog(MaintenanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحديث الحالة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('قيد الإصلاح'),
              leading: Radio<String>(
                value: 'قيد الإصلاح',
                groupValue: record.status,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateStatus(record.id!, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('جاهز للاستلام'),
              leading: Radio<String>(
                value: 'جاهز للاستلام',
                groupValue: record.status,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateStatus(record.id!, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('تم التسليم'),
              leading: Radio<String>(
                value: 'تم التسليم',
                groupValue: record.status,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateStatus(record.id!, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('ملغي'),
              leading: Radio<String>(
                value: 'ملغي',
                groupValue: record.status,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateStatus(record.id!, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('مرفوض'),
              leading: Radio<String>(
                value: 'مرفوض',
                groupValue: record.status,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateStatus(record.id!, value!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    try {
      final provider = Provider.of<MaintenanceProvider>(context, listen: false);
      await provider.updateStatus(id, newStatus);
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة الصيانة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade800,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddMaintenanceScreen(),
                ),
              ),
              icon: const Icon(Icons.add, size: 24),
              label: const Text(
                'استلام جهاز',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            icon: const Icon(Icons.folder_special, size: 26),
            label: const Text(
              'إدارة الأقسام',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MaintenanceDepartmentsScreen(),
                ),
              );
              _loadDepartments();
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          _buildStatisticsBar(context),
          _buildDailyStatistics(context),
          _buildToolbar(context),
          Container(
            color: Colors.blue,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.list), text: 'الكل'),
                Tab(icon: Icon(Icons.build), text: 'قيد الإصلاح'),
                Tab(icon: Icon(Icons.check_circle), text: 'جاهز للاستلام'),
                Tab(icon: Icon(Icons.done_all), text: 'تم التسليم'),
                Tab(icon: Icon(Icons.cancel), text: 'ملغي'),
                Tab(icon: Icon(Icons.block), text: 'مرفوض'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecordsList(null),
                _buildRecordsList('قيد الإصلاح'),
                _buildRecordsList('جاهز للاستلام'),
                _buildRecordsList('تم التسليم'),
                _buildRecordsList('ملغي'),
                _buildRecordsList('مرفوض'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'بحث (الاسم، رقم الهاتف، نوع الجهاز، كود الصيانة...)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  value: _selectedDepartmentId,
                  decoration: InputDecoration(
                    labelText: 'القسم',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.folder),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('الكل')),
                    ..._departments.map((dept) {
                      return DropdownMenuItem(
                        value: dept.id,
                        child: Text(
                          dept.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartmentId = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _dateFilter,
                  decoration: InputDecoration(
                    labelText: 'التاريخ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.calendar_today),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _dateFilterOptions.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(
                        filter,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value == 'تاريخ محدد') {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _dateFilter = value!;
                          _selectedDate = date;
                        });
                      }
                    } else {
                      setState(() {
                        _dateFilter = value!;
                        _selectedDate = null;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _remainingFilter,
                  decoration: InputDecoration(
                    labelText: 'المتبقي',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _remainingFilterOptions.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(
                        filter,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _remainingFilter = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAdvancedPrintDialog(context),
                icon: const Icon(Icons.print),
                label: const Text('طباعة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(String? status) {
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var records = status == null
            ? provider.maintenanceRecords
            : provider.getRecordsByStatus(status);

        if (_searchQuery.isNotEmpty) {
          records = provider.searchRecords(_searchQuery);
          if (status != null) {
            records = records.where((r) => r.status == status).toList();
          }
        }

        if (_selectedDepartmentId != null) {
          records = records
              .where((r) => r.departmentId == _selectedDepartmentId)
              .toList();
        }

        records = _applyDateFilter(records);

        if (_remainingFilter == 'يوجد متبقي') {
          records = records.where((r) => r.remainingAmount > 0).toList();
        } else if (_remainingFilter == 'لا يوجد متبقي') {
          records = records.where((r) => r.remainingAmount == 0).toList();
        }

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty ||
                          _dateFilter != 'الكل' ||
                          _selectedDepartmentId != null
                      ? 'لا توجد نتائج'
                      : 'لا توجد سجلات صيانة',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(7),
          child: Card(
            elevation: 4,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 70,
                ),
                child: DataTable(
                  columnSpacing: 20,
                  horizontalMargin: 16,
                  headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
                  columns: const [
                    DataColumn(label: Text('رقم الطلب')),
                    DataColumn(label: Text('كود الصيانة')),
                    DataColumn(label: Text('القسم')),
                    DataColumn(label: Text('العميل')),
                    DataColumn(label: Text('رقم الهاتف')),
                    DataColumn(label: Text('الجهاز')),
                    DataColumn(label: Text('العطل')),
                    DataColumn(label: Text('تاريخ الاستلام')),
                    DataColumn(label: Text('الحالة')),
                    DataColumn(label: Text('إجراءات')),
                  ],
                  rows: records.reversed.map((record) {
                    Color statusColor = _getStatusColor(record.status);
                    return DataRow(
                      cells: [
                        DataCell(Text('#${record.id}')),
                        DataCell(
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: record.repairCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'تم نسخ الكود: ${record.repairCode}'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    record.repairCode,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.copy,
                                      size: 12, color: Colors.blue[700]),
                                ],
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              record.departmentName ?? 'غير محدد',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.purple[700],
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Text(
                              record.customerName,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        DataCell(
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: record.customerPhone),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'تم نسخ الرقم: ${record.customerPhone}'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.phone,
                                      size: 14, color: Colors.green[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    record.customerPhone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              record.deviceType,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: Text(
                              record.problemDescription,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            DateFormat('yyyy-MM-dd HH:mm')
                                .format(record.receivedDate),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              record.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ⭐ زر طباعة الإيصال
                              Tooltip(
                                message: 'طباعة إيصال الاستلام',
                                child: InkWell(
                                  onTap: () =>
                                      _printReceiptReceipt(context, record),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.green[200]!),
                                    ),
                                    child: Icon(
                                      Icons.print,
                                      size: 18,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'عرض التفاصيل',
                                child: InkWell(
                                  onTap: () => _showRecordDetails(record),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.blue[200]!),
                                    ),
                                    child: Icon(
                                      Icons.visibility,
                                      size: 18,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'تحديث الحالة',
                                child: InkWell(
                                  onTap: () => _showStatusUpdateDialog(record),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.orange[200]!),
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
