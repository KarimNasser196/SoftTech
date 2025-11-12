// lib/screens/invoice_screen.dart (OPTIMIZED - أكبر عدد منتجات)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';

class InvoiceScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');
    final timeFormat = DateFormat('hh:mm a', 'ar');

    return Scaffold(
      appBar: AppBar(
        title: const Text('الفاتورة'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(context),
            tooltip: 'طباعة',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header - مُحسّن بمسافات أصغر
                Container(
                  padding: const EdgeInsets.all(14), // ⭐ كان 18
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Riad Soft Company',
                              style: TextStyle(
                                fontSize: 22, // ⭐ كان 24
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4), // ⭐ كان 6
                            const Text(
                              '01019187734',
                              style: TextStyle(
                                fontSize: 13, // ⭐ كان 14
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8), // ⭐ كان 10
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4), // ⭐ كان 10, 5
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black, width: 1.5),
                              ),
                              child: const Text(
                                'فاتورة مبيعات',
                                style: TextStyle(
                                  fontSize: 13, // ⭐ كان 14
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          SizedBox(
                            width: 110, // ⭐ كان 120
                            height: 50, // ⭐ كان 55
                            child: Image.asset(
                              'assets/barcode.jpg',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    invoice.invoiceNumber,
                                    style: const TextStyle(fontSize: 9),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Invoice Info - مُحسّن
                Container(
                  padding: const EdgeInsets.all(12), // ⭐ كان 16
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow('رقم الفاتورة:',
                                invoice.invoiceNumber, 12), // ⭐ كان 13
                          ),
                          Expanded(
                            child: _buildInfoRow('العميل:',
                                invoice.customerName, 12), // ⭐ كان 13
                          ),
                        ],
                      ),
                      const SizedBox(height: 8), // ⭐ كان 10
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                                'التاريخ:',
                                dateFormat.format(invoice.invoiceDate),
                                12), // ⭐ كان 13
                          ),
                          Expanded(
                            child: _buildInfoRow(
                                'الوقت:',
                                timeFormat.format(invoice.invoiceDate),
                                12), // ⭐ كان 13
                          ),
                        ],
                      ),
                      // ⭐⭐⭐ عرض "ملاحظات:" دائماً مع مساحة للكتابة اليدوية
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ملاحظات:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              invoice.notes ?? '', // ⭐ إذا فارغة تظهر مساحة
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Items Table - مُحسّن لأكبر عدد منتجات
                Padding(
                  padding: const EdgeInsets.all(12), // ⭐ كان 16
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Table(
                        border: TableBorder.all(
                            color: Colors.grey[400]!, width: 1.5),
                        columnWidths: const {
                          0: FlexColumnWidth(0.5), // ⭐ كان 0.6
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(0.9), // ⭐ كان 1
                          3: FlexColumnWidth(1.3), // ⭐ كان 1.5
                          4: FlexColumnWidth(1.3), // ⭐ كان 1.5
                        },
                        children: [
                          // Header
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                            ),
                            children: const [
                              _TableHeader('#'),
                              _TableHeader('المنتج'),
                              _TableHeader('الكمية'),
                              _TableHeader('السعر'),
                              _TableHeader('الإجمالي'),
                            ],
                          ),
                          // Items - عرض جميع المنتجات
                          ...invoice.items.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final item = entry.value;
                            return TableRow(
                              decoration: BoxDecoration(
                                color: index.isEven
                                    ? Colors.grey[50]
                                    : Colors.white,
                              ),
                              children: [
                                _TableCell(index.toString(),
                                    fontSize: 11,
                                    minHeight: 26), // ⭐ كان 12, 32
                                _TableCell(item.productName,
                                    fontSize: 11, minHeight: 26), // ⭐
                                _TableCell(item.quantity.toString(),
                                    fontSize: 11, minHeight: 26), // ⭐
                                _TableCell(item.unitPrice.toStringAsFixed(2),
                                    fontSize: 11, minHeight: 26), // ⭐
                                _TableCell('${item.total.toStringAsFixed(2)} ج',
                                    bold: true,
                                    fontSize: 11,
                                    minHeight: 26), // ⭐
                              ],
                            );
                          }),
                          // ⭐⭐⭐ 3 صفوف فارغة للكتابة اليدوية
                          ...List.generate(3, (rowIndex) {
                            // ⭐ كان 2
                            return TableRow(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                              ),
                              children: const [
                                _TableCell('',
                                    fontSize: 11, minHeight: 28), // ⭐ كان 32
                                _TableCell('',
                                    align: TextAlign.right,
                                    fontSize: 11,
                                    minHeight: 28), // ⭐
                                _TableCell('',
                                    fontSize: 11, minHeight: 28), // ⭐
                                _TableCell('',
                                    fontSize: 11, minHeight: 28), // ⭐
                                _TableCell('',
                                    fontSize: 11, minHeight: 28), // ⭐
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                // Totals - مُحسّن بخطوط أصغر
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12), // ⭐ كان 16
                  padding: const EdgeInsets.all(12), // ⭐ كان 16
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                  child: Column(
                    children: [
                      _buildTotalRow('المجموع الفرعي:', invoice.subtotal, 12,
                          false), // ⭐ كان 14
                      if (invoice.discount > 0) ...[
                        const SizedBox(height: 6), // ⭐ كان 8
                        _buildTotalRow('الخصم الإجمالي:', invoice.discount, 12,
                            false, // ⭐ كان 14
                            isDiscount: true),
                      ],
                      if (invoice.tax > 0) ...[
                        const SizedBox(height: 6), // ⭐ كان 8
                        _buildTotalRow(
                            'الضريبة:', invoice.tax, 12, false), // ⭐ كان 14
                      ],
                      const SizedBox(height: 8), // ⭐ كان 10
                      const Divider(color: Colors.black, thickness: 2),
                      const SizedBox(height: 8), // ⭐ كان 10
                      _buildTotalRow('الإجمالي النهائي:', invoice.finalTotal,
                          14, true), // ⭐ كان 16
                    ],
                  ),
                ),

                const SizedBox(height: 12), // ⭐ كان 16

                // Warranty - مُحسّن
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12), // ⭐ كان 16
                  padding: const EdgeInsets.all(12), // ⭐ كان 14
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWarrantyItem(
                          '• ضمان الاوريجنال لمدة شهر من تاريخ الشراء',
                          11), // ⭐ كان 13
                      _buildWarrantyItem(
                          '• ضمان جميع الفلاشات 6 شهور من تاريخ الشراء',
                          11), // ⭐
                      _buildWarrantyItem(
                          '• جميع الاكسسوارات بدون ضمان (ضمان تجربة فقط)',
                          11), // ⭐
                      _buildWarrantyItem(
                          '• فترة اختبار المنتج يومان من الاستلام', 11), // ⭐
                    ],
                  ),
                ),

                const SizedBox(height: 16), // ⭐ كان 20
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _printInvoice(context),
        icon: const Icon(Icons.print),
        label: const Text('طباعة'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2), // ⭐ كان 3
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4), // ⭐ كان 6
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyItem(String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3), // ⭐ كان 5
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.4, // ⭐ كان 1.5
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTotalRow(
      String label, double amount, double fontSize, bool isFinal,
      {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} جنيه',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.red[700] : Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _printInvoice(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('جاري تجهيز الفاتورة للطباعة...'),
            ],
          ),
        ),
      );

      await InvoiceService.printInvoice(invoice);
      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم فتح نافذة الطباعة'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الطباعة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6), // ⭐ كان 8
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12, // ⭐ كان 13
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final TextAlign align;
  final bool bold;
  final double fontSize;
  final double minHeight;

  const _TableCell(
    this.text, {
    this.align = TextAlign.center,
    this.bold = false,
    this.fontSize = 11, // ⭐ كان 12
    this.minHeight = 26, // ⭐ كان 24
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6), // ⭐ كان 8
      constraints: BoxConstraints(minHeight: minHeight),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }
}
