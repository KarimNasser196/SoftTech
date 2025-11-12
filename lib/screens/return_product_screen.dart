// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

class ReturnProductScreen extends StatefulWidget {
  const ReturnProductScreen({super.key});

  @override
  State<ReturnProductScreen> createState() => _ReturnProductScreenState();
}

class _ReturnProductScreenState extends State<ReturnProductScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // ⭐ متغيرات الفلترة بالتاريخ
  String _dateFilterType = 'الكل';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ⭐ دالة فلترة حسب التاريخ
  bool _isReturnInDateRange(dynamic transaction) {
    if (_dateFilterType == 'الكل') return true;

    final returnDate = transaction.dateTime;
    final now = DateTime.now();

    switch (_dateFilterType) {
      case 'اليوم':
        return returnDate.year == now.year &&
            returnDate.month == now.month &&
            returnDate.day == now.day;

      case 'الأسبوع':
        final weekAgo = now.subtract(const Duration(days: 7));
        return returnDate.isAfter(weekAgo) &&
            returnDate.isBefore(now.add(const Duration(days: 1)));

      case 'الشهر':
        return returnDate.year == now.year && returnDate.month == now.month;

      case 'فترة مخصصة':
        if (_customStartDate == null || _customEndDate == null) return true;

        final startOfDay = DateTime(
          _customStartDate!.year,
          _customStartDate!.month,
          _customStartDate!.day,
        );
        final endOfDay = DateTime(
          _customEndDate!.year,
          _customEndDate!.month,
          _customEndDate!.day,
          23,
          59,
          59,
        );

        return returnDate
                .isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            returnDate.isBefore(endOfDay.add(const Duration(seconds: 1)));

      default:
        return true;
    }
  }

  // ⭐ دالة اختيار التاريخ
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_customStartDate ?? DateTime.now())
          : (_customEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _customStartDate = picked;
          if (_customEndDate != null && picked.isAfter(_customEndDate!)) {
            _customEndDate = picked;
          }
        } else {
          if (_customStartDate != null && picked.isBefore(_customStartDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تاريخ النهاية يجب أن يكون بعد تاريخ البداية'),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            _customEndDate = picked;
          }
        }
      });
    }
  }

  // ⭐ Widget لأزرار الفلترة
  Widget _buildDateFilterChip(String label, IconData icon) {
    final isSelected = _dateFilterType == label;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _dateFilterType = label;
          if (label != 'فترة مخصصة') {
            _customStartDate = null;
            _customEndDate = null;
          }
        });
      },
      selectedColor: Colors.orange,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.orange[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? Colors.orange : Colors.orange[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Map<String, String> _extractSaleInfo(String? notes) {
    if (notes == null || notes.isEmpty) {
      return {'customerName': 'غير متاح', 'saleInfo': ''};
    }

    // استخراج اسم العميل - نمط أكثر مرونة
    String customerName = 'غير متاح';

    // ⭐ محاولة 1: استرجاع من [الاسم] (النمط الجديد)
    var customerMatch = RegExp(r'استرجاع من\s+([^|]+)').firstMatch(notes);
    if (customerMatch != null) {
      customerName = customerMatch.group(1)!.trim();
    } else {
      // محاولة 2: بيع لـ [الاسم]
      customerMatch = RegExp(r'بيع لـ\s*([^|]+)').firstMatch(notes);
      if (customerMatch != null) {
        customerName = customerMatch.group(1)!.trim();
      } else {
        // محاولة 3: العميل: [الاسم] أو المندوب: [الاسم]
        customerMatch = RegExp(r'(?:عميل|مندوب):\s*([^|]+)').firstMatch(notes);
        if (customerMatch != null) {
          customerName = customerMatch.group(1)!.trim();
        }
      }
    }

    // ⭐ استخراج السعر
    final priceMatch = RegExp(r'بسعر\s*([\d.]+)').firstMatch(notes);
    final price = priceMatch?.group(1);

    String saleInfo = '';
    if (price != null) {
      saleInfo = 'السعر: $price جنيه';
    }

    // ⭐⭐⭐ هنا الـ return المطلوب
    return {
      'customerName': customerName,
      'saleInfo': saleInfo,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          // جلب معاملات الاسترجاع
          var returnTransactions = provider.inventoryTransactions
              .where((tx) => tx.transactionType == 'استرجاع من بيع')
              .toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

          // ⭐ تطبيق فلتر البحث
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            returnTransactions = returnTransactions.where((tx) {
              final productName = tx.productName.toLowerCase();
              final saleInfo = _extractSaleInfo(tx.notes);
              final customerName = saleInfo['customerName']!.toLowerCase();
              final reason = (tx.notes ?? '').toLowerCase();

              return productName.contains(query) ||
                  customerName.contains(query) ||
                  reason.contains(query);
            }).toList();
          }

          // ⭐ تطبيق فلتر التاريخ
          returnTransactions = returnTransactions
              .where((tx) => _isReturnInDateRange(tx))
              .toList();

          // ⭐ حساب الإحصائيات
          final totalReturns = returnTransactions.length;
          final totalQuantityReturned = returnTransactions.fold<int>(
            0,
            (sum, tx) => sum + tx.quantityChange,
          );

          if (provider.inventoryTransactions
              .where((tx) => tx.transactionType == 'استرجاع من بيع')
              .isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.reply, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد منتجات مسترجعة',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يمكنك استرجاع المنتجات من صفحة المبيعات',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // ⭐⭐⭐ شريط البحث والفلترة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.reply,
                            size: 28,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المنتجات المسترجعة',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'عرض وإدارة المرتجعات',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 1️⃣ حقل البحث
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن منتج، عميل، أو سبب...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.orange),
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
                          borderSide: const BorderSide(color: Colors.orange),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.orange, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // 2️⃣ أزرار الفلترة
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDateFilterChip('الكل', Icons.all_inclusive),
                          const SizedBox(width: 8),
                          _buildDateFilterChip('اليوم', Icons.today),
                          const SizedBox(width: 8),
                          _buildDateFilterChip('الأسبوع', Icons.date_range),
                          const SizedBox(width: 8),
                          _buildDateFilterChip('الشهر', Icons.calendar_month),
                          const SizedBox(width: 8),
                          _buildDateFilterChip(
                              'فترة مخصصة', Icons.date_range_outlined),
                        ],
                      ),
                    ),

                    // 3️⃣ حقول الفترة المخصصة
                    if (_dateFilterType == 'فترة مخصصة') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'اختر الفترة الزمنية',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context, true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.orange[300]!),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _customStartDate == null
                                                ? 'من تاريخ'
                                                : DateFormat('yyyy-MM-dd')
                                                    .format(_customStartDate!),
                                            style: TextStyle(
                                              color: _customStartDate == null
                                                  ? Colors.grey[600]
                                                  : Colors.black,
                                            ),
                                          ),
                                          Icon(
                                            Icons.calendar_today,
                                            size: 18,
                                            color: Colors.orange[700],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.arrow_forward,
                                      color: Colors.orange),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context, false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.orange[300]!),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _customEndDate == null
                                                ? 'إلى تاريخ'
                                                : DateFormat('yyyy-MM-dd')
                                                    .format(_customEndDate!),
                                            style: TextStyle(
                                              color: _customEndDate == null
                                                  ? Colors.grey[600]
                                                  : Colors.black,
                                            ),
                                          ),
                                          Icon(
                                            Icons.calendar_today,
                                            size: 18,
                                            color: Colors.orange[700],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 4️⃣ شريط الإحصائيات
              if (_searchQuery.isNotEmpty || _dateFilterType != 'الكل')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.orange[200]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        icon: Icons.receipt,
                        label: 'عدد المرتجعات',
                        value: totalReturns.toString(),
                        color: Colors.orange,
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildStatCard(
                        icon: Icons.inventory,
                        label: 'إجمالي القطع',
                        value: totalQuantityReturned.toString(),
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),

              // 5️⃣ الجدول
              Expanded(
                child: returnTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد مرتجعات مطابقة',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'جرب تغيير البحث أو الفلترة',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : _buildReturnsTable(returnTransactions),
              ),
            ],
          );
        },
      ),
    );
  }

  // ⭐ Widget الإحصائيات
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ⭐⭐⭐ الجدول الجديد
  Widget _buildReturnsTable(List<dynamic> returns) {
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
                minWidth: MediaQuery.of(context).size.width - 100,
              ),
              child: DataTable(
                columnSpacing: 30,
                headingRowHeight: 56,
                dataRowHeight: 70,
                headingRowColor: WidgetStateProperty.all(Colors.orange[50]),
                columns: const [
                  DataColumn(
                    label: Text(
                      'المنتج',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'العميل',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'الكمية',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'السبب',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'التاريخ',
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
                rows: returns.map((tx) {
                  final saleInfo = _extractSaleInfo(tx.notes);
                  final customerName = saleInfo['customerName']!;
                  final reason = tx.notes?.split('|').last.trim() ?? 'غير محدد';

                  return DataRow(
                    cells: [
                      // المنتج
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 180),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tx.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'بعد الاسترجاع: ${tx.quantityAfter}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // العميل
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      customerName,
                                      style: const TextStyle(fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (saleInfo['saleInfo']!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  saleInfo['saleInfo']!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // الكمية
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${tx.quantityChange}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ),

                      // السبب
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(
                              minWidth: 180, maxWidth: 250),
                          child: Text(
                            reason,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // التاريخ
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 140),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 12, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('yyyy-MM-dd')
                                        .format(tx.dateTime),
                                    style: const TextStyle(fontSize: 13),
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
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // الإجراءات
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          onPressed: () => _showReturnDetails(tx, saleInfo),
                          tooltip: 'عرض التفاصيل',
                          color: Colors.orange,
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

  // ⭐ Dialog التفاصيل
  void _showReturnDetails(dynamic tx, Map<String, String> saleInfo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.reply,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'تفاصيل الاسترجاع',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // معلومات المنتج
                _buildInfoSection(
                  'معلومات المنتج',
                  Icons.inventory_2,
                  Colors.blue,
                  [
                    _buildInfoItem('اسم المنتج', tx.productName),
                    _buildInfoItem(
                      'الكمية المسترجعة',
                      '${tx.quantityChange}',
                      valueColor: Colors.orange,
                    ),
                    _buildInfoItem(
                      'الكمية بعد الاسترجاع',
                      '${tx.quantityAfter}',
                      valueColor: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // معلومات البيع
                _buildInfoSection(
                  'معلومات البيع الأصلي',
                  Icons.shopping_cart,
                  Colors.green,
                  [
                    _buildInfoItem('العميل', saleInfo['customerName']!),
                    if (saleInfo['saleInfo']!.isNotEmpty)
                      _buildInfoItem('السعر', saleInfo['saleInfo']!),
                  ],
                ),

                const SizedBox(height: 16),

                // معلومات الاسترجاع
                _buildInfoSection(
                  'معلومات الاسترجاع',
                  Icons.assignment_return,
                  Colors.orange,
                  [
                    _buildInfoItem(
                      'سبب الاسترجاع',
                      tx.notes?.split('|').last.trim() ?? 'غير محدد',
                    ),
                    _buildInfoItem(
                      'تاريخ الاسترجاع',
                      DateFormat('yyyy-MM-dd HH:mm').format(tx.dateTime),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // زر الإغلاق
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إغلاق'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
