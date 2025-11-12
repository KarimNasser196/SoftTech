// lib/screens/representative_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/models/representative.dart';
import 'package:soundtry/models/representative_transaction.dart';
import 'package:soundtry/providers/representative_provider.dart';
import 'package:soundtry/screens/add_representative_screen.dart';
import 'package:soundtry/screens/add_payment_screen.dart';
import 'package:soundtry/screens/withdraw_credit_screen.dart';
import 'package:soundtry/services/account_statement_pdf.dart';
import 'package:intl/intl.dart';

class RepresentativeDetailsScreen extends StatefulWidget {
  final Representative representative;

  const RepresentativeDetailsScreen({super.key, required this.representative});

  @override
  State<RepresentativeDetailsScreen> createState() =>
      _RepresentativeDetailsScreenState();
}

class _RepresentativeDetailsScreenState
    extends State<RepresentativeDetailsScreen> {
  bool _isLoading = true;
  late Representative _currentRepresentative;
  DateTime? _startDate;
  DateTime? _endDate;
  List<RepresentativeTransaction> _transactions = []; // ⭐ الأصلية
  List<RepresentativeTransaction> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _currentRepresentative = widget.representative;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final provider =
        Provider.of<RepresentativeProvider>(context, listen: false);
    await provider.loadRepresentatives();

    final updatedRep =
        provider.getRepresentativeById(widget.representative.id!);
    if (updatedRep != null) {
      _currentRepresentative = updatedRep;
    }

    final transactions =
        await provider.getTransactions(widget.representative.id!);

    setState(() {
      _transactions = transactions;
      _applyDateFilter(); // ⭐ تطبيق الفلتر
      _isLoading = false;
    });
  }

  void _applyDateFilter() {
    if (_startDate == null && _endDate == null) {
      _filteredTransactions = _transactions; // ⭐ من الأصلية
      return;
    }

    _filteredTransactions = _transactions.where((tx) {
      // ⭐ من الأصلية
      if (_startDate != null && tx.dateTime.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null) {
        final endOfDay = DateTime(
            _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        if (tx.dateTime.isAfter(endOfDay)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _showDateFilterDialog() async {
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('اختر الفترة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  tempStartDate == null
                      ? 'من تاريخ: غير محدد'
                      : 'من: ${DateFormat('yyyy-MM-dd').format(tempStartDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tempStartDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() => tempStartDate = date);
                  }
                },
              ),
              ListTile(
                title: Text(
                  tempEndDate == null
                      ? 'إلى تاريخ: غير محدد'
                      : 'إلى: ${DateFormat('yyyy-MM-dd').format(tempEndDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tempEndDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() => tempEndDate = date);
                  }
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.today),
                    label: const Text('اليوم'),
                    onPressed: () {
                      final today = DateTime.now();
                      setDialogState(() {
                        tempStartDate =
                            DateTime(today.year, today.month, today.day);
                        tempEndDate = today;
                      });
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('إلغاء الفلتر'),
                    onPressed: () {
                      setDialogState(() {
                        tempStartDate = null;
                        tempEndDate = null;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تطبيق'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _startDate = tempStartDate;
        _endDate = tempEndDate;
        _applyDateFilter(); // ⭐ هنا هيفلتر من _transactions الأصلية
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRepresentative.name),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: (_startDate != null || _endDate != null)
                  ? Colors.yellow
                  : Colors.white,
            ),
            onPressed: _showDateFilterDialog,
            tooltip: 'فلتر حسب التاريخ',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddRepresentativeScreen(
                    representative: _currentRepresentative,
                  ),
                ),
              );
              if (result == true && mounted) {
                await _loadData();
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildAccountSummary(),
                  _buildActionButtons(),
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: _filteredTransactions.isEmpty
                        ? _buildEmptyState()
                        : _buildTransactionsTable(),
                  ),
                ],
              ),
      ),
    );
  }

  // ⭐ ملخص الحساب
  Widget _buildAccountSummary() {
    final numberFormat = NumberFormat('#,##0.00', 'ar');
    final hasDebt = _currentRepresentative.remainingDebt > 0;
    final hasCredit = _currentRepresentative.remainingDebt < 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasDebt
              ? [Colors.red.shade50, Colors.red.shade100]
              : hasCredit
                  ? [Colors.blue.shade50, Colors.blue.shade100]
                  : [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // الصف الأول
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: _currentRepresentative.type == 'مندوب'
                    ? Colors.blue.shade100
                    : Colors.green.shade100,
                child: Icon(
                  _currentRepresentative.type == 'مندوب'
                      ? Icons.person
                      : Icons.people,
                  size: 36,
                  color: _currentRepresentative.type == 'مندوب'
                      ? Colors.blue
                      : Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentRepresentative.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _currentRepresentative.type == 'مندوب'
                            ? Colors.blue.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _currentRepresentative.type,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _currentRepresentative.type == 'مندوب'
                              ? Colors.blue.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                    if (_currentRepresentative.phone != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.phone,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            _currentRepresentative.phone!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // ⭐⭐⭐ المتبقي/المستحق بشكل بارز
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasDebt
                      ? Colors.red
                      : hasCredit
                          ? Colors.blue
                          : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (hasDebt
                              ? Colors.red
                              : hasCredit
                                  ? Colors.blue
                                  : Colors.green)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      hasDebt
                          ? 'المتبقي'
                          : hasCredit
                              ? 'مستحق له'
                              : 'الحساب',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      numberFormat
                          .format(_currentRepresentative.remainingDebt.abs()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      hasDebt
                          ? 'دين'
                          : hasCredit
                              ? 'مستحق'
                              : 'مسدد',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // الإحصائيات
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  'إجمالي الديون',
                  numberFormat.format(_currentRepresentative.totalDebt),
                  Icons.shopping_cart,
                  Colors.orange,
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: _buildStat(
                  'إجمالي المدفوع',
                  numberFormat.format(_currentRepresentative.totalPaid),
                  Icons.payment,
                  Colors.green,
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: _buildStat(
                  'المعاملات',
                  _filteredTransactions.length.toString(),
                  Icons.receipt_long,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
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
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _showAddDirectDebtDialog() async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دين مباشر'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ *',
                  prefixIcon: Icon(Icons.money),
                  suffixText: 'جنيه',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'مبلغ غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (result == true) {
      final provider =
          Provider.of<RepresentativeProvider>(context, listen: false);
      final success = await provider.addDirectDebt(
        representativeId: _currentRepresentative.id!,
        amount: double.parse(amountController.text),
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم إضافة الدين' : 'فشل'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) await _loadData();
      }
    }
  }

  Future<void> _showAddCreditDialog() async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إيداع رصيد'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ *',
                  prefixIcon: Icon(Icons.add_card),
                  suffixText: 'جنيه',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'مبلغ غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('إيداع'),
          ),
        ],
      ),
    );

    if (result == true) {
      final provider =
          Provider.of<RepresentativeProvider>(context, listen: false);
      final success = await provider.addCreditToAccount(
        representativeId: _currentRepresentative.id!,
        amount: double.parse(amountController.text),
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم إيداع الرصيد بنجاح' : 'فشل الإيداع'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) await _loadData();
      }
    }
  }

  Widget _buildActionButtons() {
    final hasDebt = _currentRepresentative.hasDebt;
    final hasCredit = _currentRepresentative.remainingDebt < 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          // ⭐⭐⭐ زر إيداع رصيد - جديد
          SizedBox(
            width: (MediaQuery.of(context).size.width - 56) / 2,
            child: ElevatedButton.icon(
              onPressed: () => _showAddCreditDialog(),
              icon: const Icon(Icons.add_card),
              label: const Text('إيداع رصيد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // ⭐ زر إضافة دين مباشر
          SizedBox(
            width: (MediaQuery.of(context).size.width - 56) / 2,
            child: ElevatedButton.icon(
              onPressed: () => _showAddDirectDebtDialog(),
              icon: const Icon(Icons.money_off),
              label: const Text('إضافة دين'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          if (hasDebt)
            SizedBox(
              width: (MediaQuery.of(context).size.width - 56) / 2,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPaymentScreen(
                        representative: _currentRepresentative,
                      ),
                    ),
                  );
                  if (result == true && mounted) await _loadData();
                },
                icon: const Icon(Icons.payment),
                label: const Text('دفعة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

          if (hasCredit)
            SizedBox(
              width: (MediaQuery.of(context).size.width - 56) / 2,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WithdrawCreditScreen(
                        representative: _currentRepresentative,
                      ),
                    ),
                  );
                  if (result == true && mounted) await _loadData();
                },
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('سحب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

          SizedBox(
            width: (MediaQuery.of(context).size.width - 56) / 2,
            child: ElevatedButton.icon(
              onPressed: _printStatement,
              icon: const Icon(Icons.print),
              label: const Text('كشف حساب'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            (_startDate != null || _endDate != null)
                ? 'لا توجد معاملات في هذه الفترة'
                : 'لا توجد معاملات',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteTransaction(RepresentativeTransaction tx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من حذف ${tx.getTypeInArabic()}؟',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'سيتم إعادة حساب الأرصدة تلقائياً',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'هذا الإجراء لا يمكن التراجع عنه',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider =
          Provider.of<RepresentativeProvider>(context, listen: false);
      final success = await provider.deleteTransaction(tx.id!);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('تم الحذف بنجاح'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
          await _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('فشل الحذف'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ⭐⭐⭐ جدول المعاملات
  Widget _buildTransactionsTable() {
    final numberFormat = NumberFormat('#,##0.00', 'ar');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: DataTable(
                columnSpacing: 25,
                headingRowHeight: 56,
                dataRowMaxHeight: 90,
                headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                columns: const [
                  DataColumn(
                      label: Text('النوع',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15))),
                  DataColumn(
                      label: Text('المبلغ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15))),
                  DataColumn(
                      label: Text('المدفوع',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15))),
                  DataColumn(
                      label: Text('المتبقي بعدها',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15))),
                  DataColumn(
                      label: Text('التفاصيل',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15))),
                  DataColumn(
                      label: Text('التاريخ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15))),
                  // ⭐ عمود جديد
                  DataColumn(
                      label: Text('إجراءات',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15))),
                ],
                rows: _filteredTransactions.map((tx) {
                  Color iconColor;
                  IconData icon;
                  Color rowColor;

                  switch (tx.type) {
                    case 'بيع':
                      iconColor = Colors.blue;
                      icon = Icons.shopping_cart;
                      rowColor = Colors.blue.shade50;
                      break;
                    case 'دفعة':
                      iconColor = Colors.green;
                      icon = Icons.payment;
                      rowColor = Colors.green.shade50;
                      break;
                    case 'مرتجع':
                      iconColor = Colors.orange;
                      icon = Icons.keyboard_return;
                      rowColor = Colors.orange.shade50;
                      break;
                    case 'سحب مستحقات':
                      iconColor = Colors.purple;
                      icon = Icons.account_balance_wallet;
                      rowColor = Colors.purple.shade50;
                      break;
                    case 'دين مباشر':
                      iconColor = Colors.red;
                      icon = Icons.money_off;
                      rowColor = Colors.red.shade50;
                      break;
                    case 'إيداع رصيد': // ⭐⭐⭐ جديد
                      iconColor = Colors.teal;
                      icon = Icons.add_card;
                      rowColor = Colors.teal.shade50;
                      break;
                    default:
                      iconColor = Colors.grey;
                      icon = Icons.info;
                      rowColor = Colors.grey.shade50;
                  }

                  final hasDebtAfter = tx.remainingDebt > 0;
                  final hasCreditAfter = tx.remainingDebt < 0;

                  return DataRow(
                    color: WidgetStateProperty.all(rowColor),
                    cells: [
                      // النوع
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: iconColor.withValues(alpha: 0.2),
                              child: Icon(icon, color: iconColor, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tx.getTypeInArabic(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: iconColor,
                                  ),
                                ),
                                if (tx.invoiceNumber != null)
                                  Text(
                                    'فاتورة: ${tx.invoiceNumber}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // المبلغ
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            numberFormat.format(tx.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ),

                      // المدفوع
                      DataCell(
                        tx.paidAmount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  numberFormat.format(tx.paidAmount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              )
                            : const Text('-', style: TextStyle(fontSize: 14)),
                      ),

                      // ⭐ المتبقي بعدها (مع تمييز المستحق)
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              numberFormat.format(tx.remainingDebt.abs()),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: hasDebtAfter
                                    ? Colors.red.shade700
                                    : hasCreditAfter
                                        ? Colors.blue.shade700
                                        : Colors.green.shade700,
                              ),
                            ),
                            Text(
                              hasDebtAfter
                                  ? 'دين'
                                  : hasCreditAfter
                                      ? 'مستحق'
                                      : 'مسدد',
                              style: TextStyle(
                                fontSize: 10,
                                color: hasDebtAfter
                                    ? Colors.red.shade700
                                    : hasCreditAfter
                                        ? Colors.blue.shade700
                                        : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // التفاصيل
                      DataCell(
                        InkWell(
                          onTap: () {
                            if (tx.productsSummary != null ||
                                tx.notes != null) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('تفاصيل ${tx.getTypeInArabic()}'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (tx.productsSummary != null) ...[
                                          const Text(
                                            'المنتجات:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            tx.productsSummary!,
                                            style:
                                                const TextStyle(fontSize: 13),
                                          ),
                                        ],
                                        if (tx.notes != null) ...[
                                          const SizedBox(height: 16),
                                          const Text(
                                            'ملاحظات:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            tx.notes!,
                                            style:
                                                const TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('إغلاق'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 250),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (tx.productsSummary != null)
                                  Text(
                                    tx.productsSummary!,
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (tx.notes != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.note,
                                          size: 12, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          tx.notes!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (tx.productsSummary != null ||
                                    tx.notes != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'اضغط للمزيد...',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // التاريخ

                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('yyyy-MM-dd').format(tx.dateTime),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('HH:mm').format(tx.dateTime),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        // ⭐⭐⭐ إخفاء زرار الحذف من المبيعات والمرتجعات
                        (tx.type == 'بيع' || tx.type == 'مرتجع')
                            ? const SizedBox.shrink() // لا يظهر شيء
                            : IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 20),
                                onPressed: () => _confirmDeleteTransaction(tx),
                                tooltip: 'حذف',
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ⭐⭐⭐ طباعة كشف الحساب
  void _printStatement() async {
    await AccountStatementPDF.generate(
      context: context,
      representative: _currentRepresentative,
      transactions: _filteredTransactions,
    );
  }
}
