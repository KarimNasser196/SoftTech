// lib/screens/withdraw_credit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/models/representative.dart';
import 'package:soundtry/providers/representative_provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class WithdrawCreditScreen extends StatefulWidget {
  final Representative representative;

  const WithdrawCreditScreen({super.key, required this.representative});

  @override
  State<WithdrawCreditScreen> createState() => _WithdrawCreditScreenState();
}

class _WithdrawCreditScreenState extends State<WithdrawCreditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _withdrawFullAmount = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _showDateTimePicker = false;

  @override
  void initState() {
    super.initState();
    if (widget.representative.remainingDebt < 0) {
      _amountController.text =
          widget.representative.remainingDebt.abs().toStringAsFixed(2);
      _withdrawFullAmount = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00', 'ar');

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سحب مستحقات', style: TextStyle(fontSize: 22)),
          centerTitle: true,
          backgroundColor: Colors.blue,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRepresentativeInfo(numberFormat),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildAmountField()),
            const SizedBox(width: 15),
            Expanded(child: _buildWithdrawFullAmountButton()),
          ],
        ),
        const SizedBox(height: 15),
        _buildNotesField(),
        const SizedBox(height: 15),
        // ⭐⭐⭐ إضافة قسم التاريخ والوقت
        _buildDateTimeSection(),
        const SizedBox(height: 15),
        _buildCalculationCard(numberFormat),
        const SizedBox(height: 15),
        _buildSaveButton(),
        const SizedBox(height: 10),
      ],
    );
  }

  // ⭐⭐⭐ Widget جديد للتاريخ والوقت
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
                      'تاريخ ووقت السحب',
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
    final creditAmount = widget.representative.remainingDebt.abs();

    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
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
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'المستحق له',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        numberFormat.format(creditAmount),
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
            fontSize: 16,
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

  Widget _buildWithdrawFullAmountButton() {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _withdrawFullAmount = !_withdrawFullAmount;
          if (_withdrawFullAmount) {
            _amountController.text =
                widget.representative.remainingDebt.abs().toStringAsFixed(2);
          }
        });
      },
      icon: Icon(
        _withdrawFullAmount ? Icons.check_circle : Icons.circle_outlined,
        size: 18,
      ),
      label: const Text(
        'سحب الكل',
        style: TextStyle(fontSize: 16),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _withdrawFullAmount ? Colors.blue : Colors.grey,
        side: BorderSide(
          color: _withdrawFullAmount ? Colors.blue : Colors.grey,
          width: _withdrawFullAmount ? 2 : 1,
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
        labelText: 'المبلغ المسحوب *',
        labelStyle: const TextStyle(fontSize: 16),
        hintText: '0.00',
        prefixIcon: const Icon(Icons.money_off, size: 20),
        suffixText: 'جنيه',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.blue.shade50,
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
          _withdrawFullAmount = false;
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
        final creditAmount = widget.representative.remainingDebt.abs();
        if (amount > creditAmount) {
          return 'المبلغ أكبر من المستحقات';
        }
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'ملاحظات (اختياري)',
        labelStyle: const TextStyle(fontSize: 16),
        hintText: 'أي ملاحظات إضافية',
        prefixIcon: const Icon(Icons.notes, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 14),
      maxLines: 2,
    );
  }

  Widget _buildCalculationCard(NumberFormat numberFormat) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final currentCredit = widget.representative.remainingDebt.abs();
    final remaining = currentCredit - amount;

    return Card(
      elevation: 2,
      color: remaining > 0 ? Colors.blue.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'ملخص العملية',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
            _buildCalculationRow(
              'المستحق الحالي',
              numberFormat.format(currentCredit),
              Colors.blue,
            ),
            const SizedBox(height: 6),
            _buildCalculationRow(
              'المبلغ المسحوب',
              numberFormat.format(amount),
              Colors.orange,
            ),
            const Divider(height: 12),
            _buildCalculationRow(
              'المتبقي له بعد السحب',
              numberFormat.format(remaining.clamp(0, double.infinity)),
              remaining > 0 ? Colors.blue : Colors.green,
              isBold: true,
            ),
            if (remaining <= 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade700, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'سيتم سحب المستحقات بالكامل',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
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
        onPressed: _isLoading ? null : _saveWithdrawal,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
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
          'تسجيل السحب',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _saveWithdrawal() async {
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

      final success = await provider.withdrawCredit(
        representativeId: widget.representative.id!,
        amount: amount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        withdrawalDateTime: finalDateTime, // ⭐ تمرير التاريخ المخصص
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تسجيل السحب بنجاح'),
              backgroundColor: Colors.blue,
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
