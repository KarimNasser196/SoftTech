// lib/screens/representatives_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/models/representative.dart';
import 'package:soundtry/providers/representative_provider.dart';
import 'package:soundtry/screens/representative_details_screen.dart';
import 'package:soundtry/screens/add_representative_screen.dart';
import 'package:intl/intl.dart';

class RepresentativesScreen extends StatefulWidget {
  const RepresentativesScreen({super.key});

  @override
  State<RepresentativesScreen> createState() => _RepresentativesScreenState();
}

class _RepresentativesScreenState extends State<RepresentativesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Representative> _filteredList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RepresentativeProvider>(context, listen: false)
          .loadRepresentatives();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RepresentativeProvider>(
        builder: (context, provider, child) {
          _filteredList = _searchController.text.isEmpty
              ? provider.representatives
              : provider.searchRepresentatives(_searchController.text);

          return Column(
            children: [
              _buildHeader(provider),
              _buildFiltersAndSearch(provider),
              Expanded(
                child: _filteredList.isEmpty
                    ? _buildEmptyState()
                    : _buildRepresentativesTable(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ⭐ الهيدر مع الإحصائيات المحدثة
  Widget _buildHeader(RepresentativeProvider provider) {
    final numberFormat = NumberFormat('#,##0.00', 'ar');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة المندوبين والعملاء',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'عرض وإدارة جميع المندوبين والعملاء',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddRepresentativeScreen(),
                    ),
                  );
                  if (result == true && mounted) {
                    Provider.of<RepresentativeProvider>(context, listen: false)
                        .loadRepresentatives();
                  }
                },
                icon: const Icon(Icons.add, size: 22),
                label: const Text(
                  ' تسجيل عميل او مندوب جديد',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
                backgroundColor: Colors.blue,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ⭐⭐⭐ الإحصائيات الجديدة المفصلة
          // الصف الأول - الأشخاص
          Row(
            children: [
              Expanded(
                child: _buildDetailedStatCard(
                  'المندوبين',
                  provider.totalMandoubs,
                  provider.mandoubsWithDebt,
                  provider.mandoubsWithCredit,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailedStatCard(
                  'العملاء',
                  provider.totalCustomers,
                  provider.customersWithDebt,
                  provider.customersWithCredit,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // الصف الثاني - المبالغ المالية
          Row(
            children: [
              Expanded(
                child: _buildFinancialCard(
                  'إجمالي الديون',
                  provider.totalDebtsAmount,
                  'عدد المديونين',
                  provider.totalDebtorsCount,
                  Icons.trending_down,
                  Colors.red,
                  numberFormat,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinancialCard(
                  'إجمالي المستحقات',
                  provider.totalCreditsAmount,
                  'عدد المستحقين',
                  provider.totalCreditorsCount,
                  Icons.account_balance_wallet,
                  Colors.blue,
                  numberFormat,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinancialCard(
                  'إجمالي المدفوع',
                  provider.totalPaid,
                  'حسابات مسددة',
                  provider.totalSettledCount,
                  Icons.check_circle,
                  Colors.green,
                  numberFormat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ⭐ بطاقة إحصائيات مفصلة للأشخاص
  Widget _buildDetailedStatCard(
    String title,
    int total,
    int withDebt,
    int withCredit,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                title == 'المندوبين' ? Icons.person : Icons.people,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  total.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'مديونين',
                  withDebt.toString(),
                  Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  'مستحقين',
                  withCredit.toString(),
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  'مسدد',
                  (total - withDebt - withCredit).toString(),
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ⭐ بطاقة صغيرة للإحصائيات الفرعية
  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
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
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ بطاقة المعلومات المالية
  Widget _buildFinancialCard(
    String mainLabel,
    double mainValue,
    String countLabel,
    int countValue,
    IconData icon,
    Color color,
    NumberFormat numberFormat,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            numberFormat.format(mainValue.abs()),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            mainLabel,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  countValue.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  countLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ الفلاتر والبحث
  Widget _buildFiltersAndSearch(RepresentativeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // الفلاتر
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'الكل', label: Text('الكل')),
                    ButtonSegment(value: 'مندوب', label: Text('مندوبين')),
                    ButtonSegment(value: 'عميل', label: Text('عملاء')),
                  ],
                  selected: {provider.filterType},
                  onSelectionChanged: (Set<String> selection) {
                    provider.setFilterType(selection.first);
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('المديونين فقط'),
                selected: provider.showOnlyWithDebt,
                onSelected: (_) => provider.toggleShowOnlyWithDebt(),
                selectedColor: Colors.red.shade100,
              ),
              const SizedBox(width: 8),
              // ⭐ فلتر جديد للمستحقين
              FilterChip(
                label: const Text('المستحقين فقط'),
                selected: provider.showOnlyWithCredit,
                onSelected: (_) => provider.toggleShowOnlyWithCredit(),
                selectedColor: Colors.blue.shade100,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو رقم الهاتف...',
              prefixIcon: const Icon(Icons.search, color: Colors.blue),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
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
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا يوجد مندوبين أو عملاء',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          const Text(
            'اضغط على زر "إضافة جديد" للبدء',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // الجدول - نفس الكود السابق بدون تغيير
  Widget _buildRepresentativesTable() {
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
                columnSpacing: 30,
                headingRowHeight: 56,
                // ignore: deprecated_member_use
                dataRowHeight: 70,
                headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                columns: const [
                  DataColumn(
                    label: Text(
                      'الاسم والنوع',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'رقم الهاتف',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'إجمالي الديون',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'إجمالي المدفوع',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'المتبقي',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'إجراءات',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
                rows: _filteredList.map((rep) {
                  final hasDebt = rep.remainingDebt > 0;
                  final hasCredit = rep.remainingDebt < 0;

                  return DataRow(
                    color: WidgetStateProperty.all(
                      hasDebt
                          ? Colors.red.shade50
                          : hasCredit
                              ? Colors.blue.shade50
                              : Colors.green.shade50,
                    ),
                    cells: [
                      // الاسم والنوع
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 180),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: rep.type == 'مندوب'
                                    ? Colors.blue.shade100
                                    : Colors.green.shade100,
                                child: Icon(
                                  rep.type == 'مندوب'
                                      ? Icons.person
                                      : Icons.people,
                                  color: rep.type == 'مندوب'
                                      ? Colors.blue
                                      : Colors.green,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      rep.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: rep.type == 'مندوب'
                                            ? Colors.blue.shade100
                                            : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        rep.type,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: rep.type == 'مندوب'
                                              ? Colors.blue.shade700
                                              : Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // رقم الهاتف
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 120),
                          child: Row(
                            children: [
                              Icon(Icons.phone,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                rep.phone ?? '-',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // إجمالي الديون
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            numberFormat.format(rep.totalDebt),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ),

                      // إجمالي المدفوع
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            numberFormat.format(rep.totalPaid),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ),

                      // المتبقي/المستحق
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                numberFormat.format(rep.remainingDebt.abs()),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: hasDebt
                                      ? Colors.red.shade700
                                      : hasCredit
                                          ? Colors.blue.shade700
                                          : Colors.green.shade700,
                                ),
                              ),
                              Text(
                                hasDebt
                                    ? 'دين'
                                    : hasCredit
                                        ? 'مستحق له'
                                        : 'مسدد',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: hasDebt
                                      ? Colors.red.shade700
                                      : hasCredit
                                          ? Colors.blue.shade700
                                          : Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // الإجراءات
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 20),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RepresentativeDetailsScreen(
                                      representative: rep,
                                    ),
                                  ),
                                );
                                if (mounted) {
                                  Provider.of<RepresentativeProvider>(
                                    context,
                                    listen: false,
                                  ).loadRepresentatives();
                                }
                              },
                              tooltip: 'عرض التفاصيل',
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddRepresentativeScreen(
                                      representative: rep,
                                    ),
                                  ),
                                );
                                if (result == true && mounted) {
                                  Provider.of<RepresentativeProvider>(
                                    context,
                                    listen: false,
                                  ).loadRepresentatives();
                                }
                              },
                              tooltip: 'تعديل',
                              color: Colors.orange,
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
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
