// lib/screens/add_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/models/representative.dart';
import 'package:soundtry/providers/representative_provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class AddPaymentScreen extends StatefulWidget {
  final Representative representative;

  const AddPaymentScreen({super.key, required this.representative});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _payFullAmount = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _showDateTimePicker = false;

  @override
  void initState() {
    super.initState();
    if (widget.representative.remainingDebt > 0) {
      _amountController.text =
          widget.representative.remainingDebt.toStringAsFixed(2);
      _payFullAmount = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00', 'ar');

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة دفعة', style: TextStyle(fontSize: 22)),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          toolbarHeight: 60,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _buildContent(numberFormat),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(NumberFormat numberFormat) {
    return Column(
      mainAxisSize: MainAxisSize.min, // ⭐ تغيير من max إلى min
      children: [
        _buildRepresentativeInfo(numberFormat),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildAmountField()),
            const SizedBox(width: 15),
            Expanded(child: _buildPayFullAmountButton()),
          ],
        ),
        const SizedBox(height: 20),
        _buildNotesField(),
        const SizedBox(height: 20),
        _buildDateTimeSection(),
        const SizedBox(height: 20),
        _buildCalculationCard(numberFormat),
        const SizedBox(height: 15),
        _buildSaveButton(),
        const SizedBox(height: 20), // ⭐ مسافة إضافية في الأسفل
      ],
    );
  }

  Widget _buildDateTimeSection() {
    if (!_showDateTimePicker) {
      return Card(
        elevation: 2,
        child: InkWell(
          onTap: () {
            setState(() {
              _showDateTimePicker = true;
            });
          },
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, color: Colors.indigo, size: 24),
                SizedBox(width: 12),
                Text(
                  'تحديد تاريخ ووقت مخصص',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.indigo, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'تاريخ ووقت الدفعة', // أو 'تاريخ ووقت السحب'
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _showDateTimePicker = false;
                      _selectedDate = null;
                      _selectedTime = null;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.indigo,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'التاريخ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(_selectedDate!)
                                      : 'الآن',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
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
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.indigo,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الوقت',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedTime != null
                                      ? _selectedTime!.format(context)
                                      : 'الآن',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
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
              ],
            ),
            if (_selectedDate != null || _selectedTime != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                      _selectedTime = null;
                      _showDateTimePicker = false; // ⭐ إضافة هذا السطر
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text(
                    'استخدام الوقت الحالي',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRepresentativeInfo(NumberFormat numberFormat) {
    final hasDebt = widget.representative.remainingDebt > 0;
    final hasCredit = widget.representative.remainingDebt < 0;

    return Card(
      elevation: 2,
      color: hasDebt
          ? Colors.red.shade50
          : hasCredit
              ? Colors.blue.shade50
              : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: widget.representative.type == 'مندوب'
                      ? Colors.blue.shade100
                      : Colors.green.shade100,
                  child: Icon(
                    widget.representative.type == 'مندوب'
                        ? Icons.person
                        : Icons.people,
                    size: 26,
                    color: widget.representative.type == 'مندوب'
                        ? Colors.blue
                        : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.representative.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.representative.type,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasDebt
                        ? Colors.red
                        : hasCredit
                            ? Colors.blue
                            : Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        hasDebt
                            ? 'المتبقي'
                            : hasCredit
                                ? 'مستحق له'
                                : 'مسدد',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        numberFormat
                            .format(widget.representative.remainingDebt.abs()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  'إجمالي الديون',
                  numberFormat.format(widget.representative.totalDebt),
                  Icons.shopping_cart,
                  Colors.orange,
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                _buildInfoItem(
                  'المدفوع',
                  numberFormat.format(widget.representative.totalPaid),
                  Icons.payment,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPayFullAmountButton() {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _payFullAmount = !_payFullAmount;
          if (_payFullAmount) {
            _amountController.text =
                widget.representative.remainingDebt.toStringAsFixed(2);
          }
        });
      },
      icon: Icon(
        _payFullAmount ? Icons.check_circle : Icons.circle_outlined,
        size: 18,
      ),
      label: const Text(
        'دفع الكل',
        style: TextStyle(fontSize: 16),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _payFullAmount ? Colors.green : Colors.grey,
        side: BorderSide(
          color: _payFullAmount ? Colors.green : Colors.grey,
          width: _payFullAmount ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'المبلغ المدفوع *',
        labelStyle: const TextStyle(fontSize: 16),
        hintText: '0.00',
        prefixIcon: const Icon(Icons.payments, size: 20),
        suffixText: 'جنيه',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.green.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      style: const TextStyle(fontSize: 16),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      onChanged: (value) {
        setState(() {
          _payFullAmount = false;
        });
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'الرجاء إدخال المبلغ';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'الرجاء إدخال مبلغ صحيح';
        }
        // ⭐ إزالة التحقق من تجاوز المبلغ
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'ملاحظات (اختياري)',
        labelStyle: const TextStyle(fontSize: 12),
        hintText: 'أي ملاحظات إضافية',
        prefixIcon: const Icon(Icons.notes, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      style: const TextStyle(fontSize: 14),
      maxLines: 2,
    );
  }

  Widget _buildCalculationCard(NumberFormat numberFormat) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final remaining = widget.representative.remainingDebt - amount;

    return Card(
      elevation: 2,
      color: remaining > 0
          ? Colors.orange.shade50
          : remaining < 0
              ? Colors.blue.shade50 // ⭐ لون للمستحقات
              : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text('ملخص الدفعة',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            _buildCalculationRow(
                'المتبقي الحالي',
                numberFormat.format(widget.representative.remainingDebt),
                Colors.red),
            const SizedBox(height: 6),
            _buildCalculationRow(
                'المبلغ المدفوع', numberFormat.format(amount), Colors.green),
            const Divider(height: 12),

            // ⭐ تعديل عرض النتيجة
            if (remaining > 0)
              _buildCalculationRow('المتبقي بعد الدفع',
                  numberFormat.format(remaining), Colors.orange, isBold: true)
            else if (remaining < 0)
              _buildCalculationRow('مستحق له بعد الدفع',
                  numberFormat.format(remaining.abs()), Colors.blue,
                  isBold: true)
            else
              _buildCalculationRow('الحساب', 'مسدد بالكامل', Colors.green,
                  isBold: true),

            // ⭐ رسالة تحذير جديدة
            if (remaining < 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'المبلغ أكبر من الدين، سيتم تسجيل ${numberFormat.format(remaining.abs())} كمستحقات له',
                        style: TextStyle(
                            color: Colors.blue.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (remaining == 0) ...[
              Container(
                padding: const EdgeInsets.all(6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade700, size: 18),
                    const SizedBox(width: 6),
                    Text('سيتم سداد المديونية بالكامل',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, Color color,
      {bool isBold = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '$value جنيه',
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _savePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save, size: 20),
        label: const Text(
          'تسجيل الدفعة',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);

      // ⭐⭐⭐ حساب التاريخ والوقت النهائي
      DateTime finalDateTime;
      if (_selectedDate != null || _selectedTime != null) {
        final date = _selectedDate ?? DateTime.now();
        final time = _selectedTime ?? TimeOfDay.now();
        finalDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      } else {
        finalDateTime = DateTime.now();
      }
      final provider =
          Provider.of<RepresentativeProvider>(context, listen: false);

      final success = await provider.addPayment(
        representativeId: widget.representative.id!,
        amount: amount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        paymentDateTime: finalDateTime,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تسجيل الدفعة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ، الرجاء المحاولة مرة أخرى'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
