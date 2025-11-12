import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/models/product.dart';
import '../providers/product_provider.dart';
import '../utils/responsive.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.purple,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              labelStyle: TextStyle(fontSize: Responsive.font(14)),
              tabs: [
                Tab(
                  icon: Icon(Icons.account_balance_wallet,
                      size: Responsive.icon(24)),
                  text: 'الإحصائيات المالية',
                ),
                Tab(
                  icon: Icon(Icons.inventory, size: Responsive.icon(24)),
                  text: 'تقرير المنتجات',
                ),
                Tab(
                  icon: Icon(Icons.receipt_long, size: Responsive.icon(24)),
                  text: 'حركة المخزون',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                FinancialStatisticsTab(),
                ProductsReportTab(),
                InventoryMovementTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== الإحصائيات المالية - مع null safety ====================
class FinancialStatisticsTab extends StatelessWidget {
  const FinancialStatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        // ⭐ إضافة null safety checks
        final totalInventoryValue = provider.products.fold<double>(
          0,
          (sum, p) => sum + ((p.purchasePrice ?? 0) * (p.quantity ?? 0)),
        );

        final totalSalesAmount = provider.sales.fold<double>(
          0,
          (sum, sale) => sum + (sale.totalAmount ?? 0),
        );

        final totalProfit = provider.sales.fold<double>(
          0,
          (sum, sale) {
            final unitPrice = sale.unitPrice ?? 0;
            final purchasePrice = sale.purchasePrice ?? 0;
            final quantitySold = sale.quantitySold ?? 0;
            return sum + ((unitPrice - purchasePrice) * quantitySold);
          },
        );

        final profitMargin =
            totalSalesAmount > 0 ? (totalProfit / totalSalesAmount * 100) : 0.0;

        return SingleChildScrollView(
          padding: Responsive.paddingAll(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإحصائيات المالية',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(isMobile ? 24 : 32),
                    ),
              ),
              Responsive.vBox(24),

              // البطاقات الإحصائية
              isMobile
                  ? Column(
                      children: [
                        _buildStatCard(
                          context,
                          'إجمالي قيمة المخزون',
                          '${_safeFormat(totalInventoryValue)} جنيه',
                          Icons.inventory_2,
                          Colors.blue,
                          'بسعر الشراء',
                        ),
                        Responsive.vBox(12),
                        _buildStatCard(
                          context,
                          'إجمالي المبيعات',
                          '${_safeFormat(totalSalesAmount)} جنيه',
                          Icons.shopping_cart,
                          Colors.green,
                          '${provider.sales.length} عملية بيع',
                        ),
                        Responsive.vBox(12),
                        _buildStatCard(
                          context,
                          'إجمالي الربح',
                          '${_safeFormat(totalProfit)} جنيه',
                          Icons.trending_up,
                          Colors.orange,
                          'نسبة الربح: ${_safeFormat(profitMargin)}%',
                        ),
                      ],
                    )
                  : GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isTablet ? 2 : 3,
                      crossAxisSpacing: Responsive.width(24),
                      mainAxisSpacing: Responsive.height(24),
                      childAspectRatio: isTablet ? 1.3 : 1.5,
                      children: [
                        _buildStatCard(
                          context,
                          'إجمالي قيمة المخزون',
                          '${_safeFormat(totalInventoryValue)} جنيه',
                          Icons.inventory_2,
                          Colors.blue,
                          'بسعر الشراء',
                        ),
                        _buildStatCard(
                          context,
                          'إجمالي المبيعات',
                          '${_safeFormat(totalSalesAmount)} جنيه',
                          Icons.shopping_cart,
                          Colors.green,
                          '${provider.sales.length} عملية',
                        ),
                        _buildStatCard(
                          context,
                          'إجمالي الربح',
                          '${_safeFormat(totalProfit)} جنيه',
                          Icons.trending_up,
                          Colors.orange,
                          'هامش ${_safeFormat(profitMargin)}%',
                        ),
                      ],
                    ),

              Responsive.vBox(32),

              // جدول تفصيلي
              Text(
                'تفاصيل الأرباح حسب المنتج',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(20),
                    ),
              ),
              Responsive.vBox(16),

              Card(
                elevation: 4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(14),
                      color: Colors.black87,
                    ),
                    dataTextStyle: TextStyle(fontSize: Responsive.font(13)),
                    columns: const [
                      DataColumn(label: Text('المنتج')),
                      DataColumn(label: Text('الكمية المباعة')),
                      DataColumn(label: Text('إجمالي المبيعات')),
                      DataColumn(label: Text('تكلفة الشراء')),
                      DataColumn(label: Text('الربح الصافي')),
                      DataColumn(label: Text('هامش الربح %')),
                    ],
                    rows: _buildProfitRows(provider),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ⭐ دالة مساعدة للتنسيق الآمن
  String _safeFormat(double? value) {
    if (value == null || value.isNaN || value.isInfinite) {
      return '0.00';
    }
    return value.toStringAsFixed(2);
  }

  List<DataRow> _buildProfitRows(ProductProvider provider) {
    final productStats = <int, Map<String, dynamic>>{};

    // تجميع البيانات مع null safety
    for (var sale in provider.sales) {
      final productId = sale.productId;
      if (productId == null) continue;

      if (!productStats.containsKey(productId)) {
        productStats[productId] = {
          'name': sale.productName ?? 'غير معروف',
          'quantitySold': 0,
          'totalSales': 0.0,
          'totalCost': 0.0,
        };
      }

      final stats = productStats[productId]!;
      stats['quantitySold'] =
          (stats['quantitySold'] as int) + (sale.quantitySold ?? 0);
      stats['totalSales'] =
          (stats['totalSales'] as double) + (sale.totalAmount ?? 0);
      stats['totalCost'] = (stats['totalCost'] as double) +
          ((sale.purchasePrice ?? 0) * (sale.quantitySold ?? 0));
    }

    // إنشاء صفوف الجدول
    final rows = productStats.entries.map((entry) {
      final data = entry.value;
      final totalSales = (data['totalSales'] as double?) ?? 0.0;
      final totalCost = (data['totalCost'] as double?) ?? 0.0;
      final profit = totalSales - totalCost;
      final profitMargin = totalSales > 0 ? (profit / totalSales * 100) : 0.0;

      return DataRow(
        cells: [
          DataCell(Text(data['name'] ?? 'غير معروف')),
          DataCell(Text('${data['quantitySold'] ?? 0}')),
          DataCell(Text('${_safeFormat(totalSales)} جنيه')),
          DataCell(Text('${_safeFormat(totalCost)} جنيه')),
          DataCell(
            Text(
              '${_safeFormat(profit)} جنيه',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: profit > 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
          DataCell(
            Text(
              '${_safeFormat(profitMargin)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: profitMargin > 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      );
    }).toList();

    // ترتيب حسب الربح
    rows.sort((a, b) {
      try {
        final cellA = a.cells[4].child;
        final cellB = b.cells[4].child;

        if (cellA is! Text || cellB is! Text) return 0;

        final profitA = double.tryParse(
                cellA.data?.split(' ')[0].replaceAll(RegExp(r'[^0-9.-]'), '') ??
                    '0') ??
            0.0;

        final profitB = double.tryParse(
                cellB.data?.split(' ')[0].replaceAll(RegExp(r'[^0-9.-]'), '') ??
                    '0') ??
            0.0;

        return profitB.compareTo(profitA);
      } catch (e) {
        return 0;
      }
    });

    return rows;
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
      ),
      child: Padding(
        padding: Responsive.paddingAll(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: Responsive.icon(40), color: color),
            Responsive.vBox(12),
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.font(14),
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            Responsive.vBox(8),
            Text(
              value,
              style: TextStyle(
                fontSize: Responsive.font(20),
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Responsive.vBox(4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: Responsive.font(12),
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== تقرير المنتجات مع إجمالي القيمة ====================
class ProductsReportTab extends StatefulWidget {
  const ProductsReportTab({super.key});

  @override
  State<ProductsReportTab> createState() => _ProductsReportTabState();
}

class _ProductsReportTabState extends State<ProductsReportTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryFilter; // ⭐ فلتر الصنف
  List<String> _availableCategories = []; // ⭐ قائمة الأصناف

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCategoriesFromReports(ProductProvider provider) {
    final reports = _calculateProductReports(provider);
    final categories = reports
        .where((r) => r['category'] != null)
        .map((r) => r['category'] as String)
        .toSet()
        .toList();
    categories.sort();

    if (mounted) {
      setState(() {
        _availableCategories = categories;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final isMobile = Responsive.isMobile(context);

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        // ⭐⭐⭐ إعادة تحميل الأصناف عند تغيير البيانات
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_availableCategories.isEmpty && provider.sales.isNotEmpty) {
            _loadCategoriesFromReports(provider);
          }
        });

        if (provider.products.isEmpty && provider.sales.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory,
                  size: Responsive.icon(64),
                  color: Colors.grey,
                ),
                Responsive.vBox(16),
                Text(
                  'لا توجد منتجات أو مبيعات',
                  style: TextStyle(fontSize: Responsive.font(16)),
                ),
              ],
            ),
          );
        }

        // ⭐⭐⭐ حساب إحصائيات المنتجات في كل مرة يتغير فيها Provider
        final productReports = _calculateProductReports(provider);

        var filteredReports = productReports;

// ⭐ تطبيق فلتر الصنف أولاً
        if (_selectedCategoryFilter != null) {
          filteredReports = filteredReports.where((report) {
            return report['category'] == _selectedCategoryFilter;
          }).toList();
        }

// ⭐ ثم تطبيق البحث
        if (_searchQuery.isNotEmpty) {
          filteredReports = filteredReports.where((report) {
            final query = _searchQuery.toLowerCase();
            return report['name'].toLowerCase().contains(query) ||
                (report['category']?.toLowerCase().contains(query) ?? false) ||
                (report['warehouse']?.toLowerCase().contains(query) ?? false) ||
                report['supplier'].toLowerCase().contains(query);
          }).toList();
        }

        // ⭐ حساب إجمالي القيمة الكلية للمنتجات المفلترة
        final totalInventoryValue = filteredReports.fold<double>(
          0,
          (sum, report) => sum + report['inventoryValue'],
        );

        return SingleChildScrollView(
          padding: Responsive.paddingAll(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تقرير المنتجات',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(isMobile ? 24 : 32),
                    ),
              ),
              Responsive.vBox(8),

              // ⭐ عرض الإحصائيات مع إجمالي القيمة
              Row(
                children: [
                  Text(
                    'عدد المنتجات: ${filteredReports.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: Responsive.font(16),
                        ),
                  ),
                  Responsive.hBox(16),
                  Container(
                    padding: Responsive.paddingSym(h: 12, v: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(Responsive.radius(8)),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: Responsive.icon(20),
                          color: Colors.green[700],
                        ),
                        Responsive.hBox(6),
                        Text(
                          'إجمالي قيمة المخزون: ${NumberFormat('#,##0.00', 'ar').format(totalInventoryValue)} جنيه',
                          style: TextStyle(
                            fontSize: Responsive.font(16),
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Responsive.vBox(16),

              // حقل البحث
              Container(
                constraints: BoxConstraints(
                  maxWidth: Responsive.width(900),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج، صنف، مخزن، أو مورد...',
                    hintStyle: TextStyle(fontSize: Responsive.font(14)),
                    prefixIcon: Icon(
                      Icons.search,
                      size: Responsive.icon(24),
                      color: Colors.purple,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: Responsive.icon(20),
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(Responsive.radius(12)),
                      borderSide: const BorderSide(color: Colors.purple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(Responsive.radius(12)),
                      borderSide:
                          const BorderSide(color: Colors.purple, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: Responsive.paddingSym(h: 16, v: 12),
                  ),
                  style: TextStyle(fontSize: Responsive.font(14)),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Responsive.vBox(16),

// ⭐ فلتر الصنف
              Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth:
                            isMobile ? double.infinity : Responsive.width(300),
                      ),
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedCategoryFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'تصفية حسب الصنف',
                          prefixIcon: Icon(
                            Icons.category,
                            size: Responsive.icon(20),
                            color: Colors.purple,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(Responsive.radius(12)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: Responsive.paddingSym(h: 12, v: 12),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('الكل'),
                          ),
                          ..._availableCategories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryFilter = value;
                          });
                        },
                      ),
                    ),
                  ),

                  // ⭐ زر إعادة تعيين الفلاتر
                  if (_selectedCategoryFilter != null ||
                      _searchQuery.isNotEmpty) ...[
                    Responsive.hBox(12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedCategoryFilter = null;
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      icon: Icon(Icons.clear_all, size: Responsive.icon(18)),
                      label: Text(
                        'إعادة تعيين',
                        style: TextStyle(fontSize: Responsive.font(14)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: Responsive.paddingSym(h: 16, v: 12),
                      ),
                    ),
                  ],
                ],
              ),

              // عرض عدد النتائج
              if (_searchQuery.isNotEmpty || _selectedCategoryFilter != null)
                Padding(
                  padding: Responsive.paddingOnly(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        'النتائج: ${filteredReports.length} من ${productReports.length}',
                        style: TextStyle(
                          fontSize: Responsive.font(14),
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selectedCategoryFilter != null) ...[
                        Responsive.hBox(8),
                        Container(
                          padding: Responsive.paddingSym(h: 8, v: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius:
                                BorderRadius.circular(Responsive.radius(6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'الصنف: $_selectedCategoryFilter',
                                style: TextStyle(
                                  fontSize: Responsive.font(12),
                                  color: Colors.purple[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Responsive.hBox(4),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryFilter = null;
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  size: Responsive.icon(16),
                                  color: Colors.purple[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Responsive.vBox(16),
              // الجدول
              Card(
                elevation: 4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columnSpacing: Responsive.width(24),
                      headingRowHeight: 56,
                      headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                      headingTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.font(14),
                        color: Colors.black87,
                      ),
                      dataTextStyle: TextStyle(fontSize: Responsive.font(13)),
                      columns: const [
                        DataColumn(label: Text('اسم المنتج')),
                        DataColumn(label: Text('كود الشحنة')), // ⭐ جديد
                        DataColumn(label: Text('الصنف')),
                        DataColumn(label: Text('المخزن')),
                        DataColumn(label: Text('المورد')),
                        DataColumn(
                            label: Text('الكمية المتاحة'), numeric: true),
                        DataColumn(
                            label: Text('قيمة المخزون'),
                            numeric: true), // ⭐ عمود جديد
                        DataColumn(
                            label: Text('الكمية المباعة'), numeric: true),
                        DataColumn(label: Text('إجمالي المبيعات')),
                        DataColumn(label: Text('تكلفة الشراء')),
                        DataColumn(label: Text('الربح الصافي')),
                        DataColumn(label: Text('نسبة الربح %')),
                        DataColumn(label: Text('تفاصيل البيع')),
                      ],
                      rows: filteredReports.map((report) {
                        // ⭐ جلب batchCode من المنتج
                        final product = provider.products.firstWhere(
                          (p) => p.id == report['productId'],
                          orElse: () => Product(
                            name: '',
                            purchasePrice: 0,
                            retailPrice: 0,
                            wholesalePrice: 0,
                            bulkWholesalePrice: 0,
                            supplierName: '',
                            quantity: 0,
                          ),
                        );
                        return DataRow(
                          cells: [
                            DataCell(Text(
                              report['name'],
                            )),
                            // ⭐⭐⭐ خلية كود الشحنة الجديدة
                            DataCell(
                              product.batchCode != null &&
                                      product.batchCode!.isNotEmpty
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple[50],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.purple[200]!),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.qr_code,
                                            size: 14,
                                            color: Colors.purple[700],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            product.batchCode!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const Text('-',
                                      style: TextStyle(fontSize: 14)),
                            ),
                            DataCell(Text(report['category'] ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                            DataCell(Text(report['warehouse'] ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                            DataCell(Text(report['supplier'] ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10))),
                            DataCell(
                              Text(
                                '${report['availableQty']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: report['availableQty'] > 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${NumberFormat('#,##0.00', 'ar').format(report['inventoryValue'] ?? 0)} جنيه',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),

                            DataCell(
                              Text(
                                '${report['soldQty']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${report['totalSales'].toStringAsFixed(2)} جنيه',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${report['totalCost'].toStringAsFixed(2)} جنيه',
                              ),
                            ),
                            DataCell(
                              Text(
                                '${report['profit'].toStringAsFixed(2)} جنيه',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: report['profit'] > 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${report['profitMargin'].toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: report['profitMargin'] > 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.list_alt,
                                    color: Colors.blue),
                                tooltip: 'عرض تفاصيل البيع',
                                onPressed: () => _showSalesDetailsDialog(
                                  context,
                                  report['productId'],
                                  report['name'],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== Fix for _calculateProductReports ====================
  List<Map<String, dynamic>> _calculateProductReports(
      ProductProvider provider) {
    final Map<int, Map<String, dynamic>> productStats = {};

    // الخطوة 1: جمع المبيعات مع null safety
    for (var sale in provider.sales) {
      final productId = sale.productId;
      if (productId == null) continue;

      if (!productStats.containsKey(productId)) {
        productStats[productId] = {
          'productId': productId,
          'name': sale.productName ?? 'غير معروف',
          'category': null,
          'warehouse': null,
          'supplier': sale.supplierName ?? 'غير معروف',
          'availableQty': 0,
          'inventoryValue': 0.0,
          'soldQty': 0,
          'totalSales': 0.0,
          'totalCost': 0.0,
          'profit': 0.0,
          'profitMargin': 0.0,
        };
      }

      final stats = productStats[productId]!;
      final quantitySold = sale.quantitySold ?? 0;
      final totalAmount = sale.totalAmount ?? 0.0;
      final purchasePrice = sale.purchasePrice ?? 0.0;

      stats['soldQty'] = (stats['soldQty'] as int) + quantitySold;
      stats['totalSales'] = (stats['totalSales'] as double) + totalAmount;
      stats['totalCost'] =
          (stats['totalCost'] as double) + (purchasePrice * quantitySold);
    }

    // الخطوة 2: إضافة البيانات الحالية
    for (var product in provider.products) {
      final productId = product.id;
      if (productId == null) continue;

      if (productStats.containsKey(productId)) {
        productStats[productId]!['name'] = product.name ?? 'غير معروف';
        productStats[productId]!['category'] = product.category;
        productStats[productId]!['warehouse'] = product.warehouse;
        productStats[productId]!['supplier'] =
            product.supplierName ?? 'غير معروف';
        productStats[productId]!['availableQty'] = product.quantity ?? 0;
      } else {
        productStats[productId] = {
          'productId': productId,
          'name': product.name ?? 'غير معروف',
          'category': product.category,
          'warehouse': product.warehouse,
          'supplier': product.supplierName ?? 'غير معروف',
          'availableQty': product.quantity ?? 0,
          'inventoryValue': 0.0,
          'soldQty': 0,
          'totalSales': 0.0,
          'totalCost': 0.0,
          'profit': 0.0,
          'profitMargin': 0.0,
        };
      }

      // حساب قيمة المخزون
      final quantity = product.quantity ?? 0;
      final purchasePrice = product.purchasePrice ?? 0;
      productStats[productId]!['inventoryValue'] = quantity * purchasePrice;
    }

    // الخطوة 3: حساب الأرباح
    for (var stats in productStats.values) {
      final totalSales = (stats['totalSales'] as double?) ?? 0.0;
      final totalCost = (stats['totalCost'] as double?) ?? 0.0;

      stats['profit'] = totalSales - totalCost;
      stats['profitMargin'] = totalSales > 0
          ? ((stats['profit'] as double) / totalSales * 100)
          : 0.0;
    }

    return productStats.values.toList();
  }

  void _showSalesDetailsDialog(
    BuildContext context,
    int productId,
    String productName,
  ) async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final details = await provider.getProductSalesDetails(productId);

    if (!context.mounted) return;

    // ⭐ فلترة المبيعات: عرض المبيعات النشطة فقط (إخفاء المرتجعات)
    final allActiveSales =
        details.where((d) => !(d['isReturned'] as bool? ?? false)).toList();

    // ⭐⭐⭐ نقل المتغيرات هنا خارج showDialog
    String selectedDateFilter = 'الكل';
    DateTime? customStartDate;
    DateTime? customEndDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // ⭐ دالة فلترة المبيعات حسب التاريخ
          List<Map<String, dynamic>> filterSalesByDate(
              List<Map<String, dynamic>> sales) {
            if (selectedDateFilter == 'الكل') {
              return sales;
            }

            final now = DateTime.now();
            DateTime? startDate;
            DateTime? endDate = now;

            switch (selectedDateFilter) {
              case 'اليوم':
                startDate = DateTime(now.year, now.month, now.day);
                break;
              case 'الأسبوع':
                final now = DateTime.now();
                int daysFromSaturday = (now.weekday - DateTime.saturday);
                if (daysFromSaturday < 0) {
                  daysFromSaturday += 7;
                }

                startDate = now.subtract(Duration(days: daysFromSaturday));

                startDate =
                    DateTime(startDate.year, startDate.month, startDate.day);

                break;
              case 'الشهر':
                startDate = DateTime(now.year, now.month, 1);
                break;
              case 'فترة محددة':
                startDate = customStartDate;
                endDate = customEndDate ?? now;
                break;
            }

            if (startDate == null) return sales;

            return sales.where((sale) {
              final saleDate = DateTime.parse(sale['saleDateTime']);
              return saleDate
                      .isAfter(startDate!.subtract(const Duration(days: 1))) &&
                  saleDate.isBefore(endDate!.add(const Duration(days: 1)));
            }).toList();
          }

          // تطبيق الفلترة
          final activeSales = filterSalesByDate(allActiveSales);
          // ⭐⭐⭐ دمج المبيعات المتكررة في نفس الفاتورة والسعر
          Map<String, Map<String, dynamic>> groupedSales = {};

          for (var sale in activeSales) {
            // إنشاء مفتاح فريد: رقم الفاتورة + سعر الشراء + سعر البيع + التاريخ
            final key =
                '${sale['invoiceNumber']}_${sale['purchasePrice']}_${sale['unitPrice']}_${sale['saleDateTime']}';

            if (groupedSales.containsKey(key)) {
              // زيادة العدد والربح
              groupedSales[key]!['count'] =
                  (groupedSales[key]!['count'] as int) + 1;
              groupedSales[key]!['totalProfit'] =
                  (groupedSales[key]!['totalProfit'] as double) +
                      (sale['profit'] as num).toDouble();
            } else {
              // إضافة عنصر جديد
              groupedSales[key] = {
                ...sale,
                'count': 1,
                'totalProfit': (sale['profit'] as num).toDouble(),
              };
            }
          }

          final displaySales = groupedSales.values.toList();

          // ⭐ إعادة حساب الإحصائيات
          final totalQuantity = activeSales.length;
          final totalProfit = displaySales.fold<double>(
            0,
            (sum, d) {
              final profit = d['totalProfit'];
              return sum + (profit is num ? profit.toDouble() : 0.0);
            },
          );
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 750),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========== الهيدر ==========
                  Row(
                    children: [
                      Icon(Icons.list_alt, color: Colors.blue[700], size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تفاصيل المبيعات بالقطعة',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              productName,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // ========== شريط الفلاتر ==========
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.filter_list,
                                size: 20, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'تصفية حسب التاريخ:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // الأزرار السريعة
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterButton(
                              'الكل',
                              Icons.all_inclusive,
                              selectedDateFilter == 'الكل',
                              () {
                                setDialogState(() {
                                  selectedDateFilter = 'الكل';
                                });
                              },
                            ),
                            _buildFilterButton(
                              'اليوم',
                              Icons.today,
                              selectedDateFilter == 'اليوم',
                              () {
                                setDialogState(() {
                                  selectedDateFilter = 'اليوم';
                                });
                              },
                            ),
                            _buildFilterButton(
                              'الأسبوع',
                              Icons.calendar_view_week,
                              selectedDateFilter == 'الأسبوع',
                              () {
                                setDialogState(() {
                                  selectedDateFilter = 'الأسبوع';
                                });
                              },
                            ),
                            _buildFilterButton(
                              'الشهر',
                              Icons.calendar_month,
                              selectedDateFilter == 'الشهر',
                              () {
                                setDialogState(() {
                                  selectedDateFilter = 'الشهر';
                                });
                              },
                            ),
                            _buildFilterButton(
                              'فترة محددة',
                              Icons.date_range,
                              selectedDateFilter == 'فترة محددة',
                              () {
                                setDialogState(() {
                                  selectedDateFilter = 'فترة محددة';
                                });
                              },
                            ),
                          ],
                        ),

                        // حقول التاريخ المخصصة
                        if (selectedDateFilter == 'فترة محددة') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          customStartDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        customStartDate = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 18, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Text(
                                          customStartDate == null
                                              ? 'من تاريخ'
                                              : DateFormat('yyyy-MM-dd')
                                                  .format(customStartDate!),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: customStartDate == null
                                                ? Colors.grey[600]
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          customEndDate ?? DateTime.now(),
                                      firstDate:
                                          customStartDate ?? DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        customEndDate = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event,
                                            size: 18, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Text(
                                          customEndDate == null
                                              ? 'إلى تاريخ'
                                              : DateFormat('yyyy-MM-dd')
                                                  .format(customEndDate!),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: customEndDate == null
                                                ? Colors.grey[600]
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ========== مؤشر النتائج ==========
                  if (selectedDateFilter != 'الكل')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'عرض $totalQuantity من أصل ${allActiveSales.length} عملية بيع',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                selectedDateFilter = 'الكل';
                                customStartDate = null;
                                customEndDate = null;
                              });
                            },
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('إزالة الفلتر',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // ========== الإحصائيات ==========
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'إجمالي القطع المباعة',
                          '$totalQuantity',
                          Colors.blue,
                        ),
                        _buildStatItem(
                          'الربح الإجمالي',
                          '${totalProfit.toStringAsFixed(2)} جنيه',
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ========== الجدول ==========
                  activeSales.isEmpty
                      ? const Center(child: Text('لا توجد بيانات'))
                      : SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 50,
                              headingRowColor:
                                  WidgetStateProperty.all(Colors.blue[50]),
                              columns: const [
                                DataColumn(
                                  label: Text('الفاتورة',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                DataColumn(
                                  label: Text('كود الشحنة',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                DataColumn(
                                  label: Text('العدد', // ⭐ عمود جديد
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                DataColumn(
                                  label: Text('العميل',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                DataColumn(
                                  label: Text('سعر الشراء',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                DataColumn(
                                  label: Text('سعر البيع',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                DataColumn(
                                  label: Text('إجمالي الربح', // ⭐ تعديل
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                DataColumn(
                                  label: Text('التاريخ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                              rows: displaySales.map((detail) {
                                final saleId = detail['saleId'] as int;
                                final sale = provider.sales.firstWhere(
                                  (s) => s.id == saleId,
                                  orElse: () =>
                                      throw Exception('البيع غير موجود'),
                                );
                                final product = provider.products.firstWhere(
                                  (p) => p.id == sale.productId,
                                  orElse: () => Product(
                                    name: '',
                                    purchasePrice: 0,
                                    retailPrice: 0,
                                    wholesalePrice: 0,
                                    bulkWholesalePrice: 0,
                                    supplierName: '',
                                    quantity: 0,
                                  ),
                                );

                                final count = detail['count'] as int;
                                final totalProfit =
                                    detail['totalProfit'] as double;

                                return DataRow(
                                  cells: [
                                    // رقم الفاتورة
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          detail['invoiceNumber'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // كود الشحنة
                                    DataCell(
                                      product.batchCode != null &&
                                              product.batchCode!.isNotEmpty
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.purple[50],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                    color: Colors.purple[200]!),
                                              ),
                                              child: Text(
                                                product.batchCode!,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.purple[700],
                                                ),
                                              ),
                                            )
                                          : const Text('-',
                                              style: TextStyle(fontSize: 12)),
                                    ),

                                    // ⭐⭐⭐ عدد القطع المتكررة
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: count > 1
                                              ? Colors.orange[50]
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: count > 1
                                              ? Border.all(
                                                  color: Colors.orange[300]!)
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (count > 1)
                                              const SizedBox(width: 4),
                                            Text(
                                              count > 1 ? '×$count' : '$count',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: count > 1
                                                    ? Colors.orange[700]
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // اسم العميل
                                    DataCell(Text(detail['customerName'])),

                                    // سعر الشراء
                                    DataCell(
                                      Text(
                                        '${(detail['purchasePrice'] as num).toStringAsFixed(2)} ج',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                    // سعر البيع
                                    DataCell(
                                      Text(
                                        '${(detail['unitPrice'] as num).toStringAsFixed(2)} ج',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                    // ⭐⭐⭐ إجمالي الربح (مع عرض الربح لكل قطعة)
                                    DataCell(
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${totalProfit.toStringAsFixed(2)} ج',
                                            style: TextStyle(
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (count > 1)
                                            Text(
                                              '(${(totalProfit / count).toStringAsFixed(2)} ج/قطعة)',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // التاريخ
                                    DataCell(
                                      Text(
                                        DateFormat('yyyy-MM-dd HH:mm').format(
                                          DateTime.parse(
                                              detail['saleDateTime']),
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// ========== Widgets مساعدة ==========

  Widget _buildFilterButton(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Icon(
          label.contains('قطع') ? Icons.inventory_2 : Icons.attach_money,
          color: color,
          size: 28,
        ),
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
}

// ==================== حركة المخزون ====================
// lib/widgets/inventory_movement_tab.dart - مع فلتر التاريخ

class InventoryMovementTab extends StatefulWidget {
  const InventoryMovementTab({super.key});

  @override
  State<InventoryMovementTab> createState() => _InventoryMovementTabState();
}

class _InventoryMovementTabState extends State<InventoryMovementTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterType =
      'الكل'; // 'الكل', 'بيع', 'إضافة', 'استرجاع', 'زيادة', 'نقصان'

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        // تطبيق الفلتر
        var filteredTransactions = provider.inventoryTransactions;

        // فلتر حسب التاريخ
        if (_startDate != null) {
          filteredTransactions = filteredTransactions.where((tx) {
            return tx.dateTime
                .isAfter(_startDate!.subtract(const Duration(days: 1)));
          }).toList();
        }

        if (_endDate != null) {
          filteredTransactions = filteredTransactions.where((tx) {
            return tx.dateTime.isBefore(_endDate!.add(const Duration(days: 1)));
          }).toList();
        }

        // فلتر حسب نوع العملية
        if (_filterType != 'الكل') {
          filteredTransactions = filteredTransactions.where((tx) {
            return tx.transactionType == _filterType;
          }).toList();
        }

        if (provider.inventoryTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: Responsive.icon(64),
                  color: Colors.grey,
                ),
                Responsive.vBox(16),
                Text(
                  'لا توجد حركات مخزون بعد',
                  style: TextStyle(fontSize: Responsive.font(16)),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // شريط الفلاتر
            _buildFiltersSection(provider),

            // الجدول
            Expanded(
              child: SingleChildScrollView(
                padding: Responsive.paddingAll(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'حركة المخزون',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.font(32),
                              ),
                            ),
                            Responsive.vBox(4),
                            Text(
                              _getFilterDescription(
                                filteredTransactions.length,
                                provider.inventoryTransactions.length,
                              ),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: Responsive.font(16),
                              ),
                            ),
                          ],
                        ),
                        if (_startDate != null ||
                            _endDate != null ||
                            _filterType != 'الكل')
                          OutlinedButton.icon(
                            onPressed: _clearFilters,
                            icon: Icon(Icons.clear, size: Responsive.icon(18)),
                            label: Text(
                              'إزالة الفلاتر',
                              style: TextStyle(fontSize: Responsive.font(14)),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                    Responsive.vBox(24),
                    Card(
                      elevation: 4,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(Colors.blue[50]),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.font(14),
                            color: Colors.black87,
                          ),
                          dataTextStyle:
                              TextStyle(fontSize: Responsive.font(13)),
                          columns: const [
                            DataColumn(label: Text('المنتج')),
                            DataColumn(label: Text('نوع العملية')),
                            DataColumn(label: Text('التغيير'), numeric: true),
                            DataColumn(label: Text('المتبقي'), numeric: true),
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('الملاحظات')),
                          ],
                          rows: filteredTransactions.map((transaction) {
                            final isPositive = transaction.quantityChange > 0;
                            return DataRow(
                              cells: [
                                DataCell(Text(transaction.productName)),
                                DataCell(
                                  Container(
                                    padding: Responsive.paddingSym(h: 8, v: 4),
                                    decoration: BoxDecoration(
                                      color: _getTransactionTypeColor(
                                              transaction.transactionType)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                          Responsive.radius(4)),
                                    ),
                                    child: Text(
                                      transaction.transactionType,
                                      style: TextStyle(
                                        color: _getTransactionTypeColor(
                                            transaction.transactionType),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${isPositive ? '+' : ''}${transaction.quantityChange}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPositive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${transaction.quantityAfter}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    DateFormat('yyyy-MM-dd HH:mm')
                                        .format(transaction.dateTime),
                                  ),
                                ),
                                DataCell(Text(transaction.notes ?? '-')),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFiltersSection(ProductProvider provider) {
    return Container(
      padding: Responsive.paddingAll(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: Responsive.icon(20)),
              Responsive.hBox(8),
              Text(
                'تصفية حسب:',
                style: TextStyle(
                  fontSize: Responsive.font(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Responsive.vBox(12),

          // صف الفلاتر
          Wrap(
            spacing: Responsive.width(12),
            runSpacing: Responsive.height(12),
            children: [
              // فلتر نوع العملية
              _buildFilterChip(
                label: 'نوع العملية',
                value: _filterType,
                icon: Icons.category,
                onTap: () => _showTransactionTypeFilter(),
              ),

              // فلتر تاريخ البداية
              _buildFilterChip(
                label: _startDate == null
                    ? 'من تاريخ'
                    : 'من: ${DateFormat('yyyy-MM-dd').format(_startDate!)}',
                value: null,
                icon: Icons.calendar_today,
                onTap: () => _selectStartDate(),
              ),

              // فلتر تاريخ النهاية
              _buildFilterChip(
                label: _endDate == null
                    ? 'إلى تاريخ'
                    : 'إلى: ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
                value: null,
                icon: Icons.event,
                onTap: () => _selectEndDate(),
              ),

              // أزرار سريعة
              _buildQuickFilterChip('اليوم', () => _setTodayFilter()),
              _buildQuickFilterChip('آخر 7 أيام', () => _setLast7DaysFilter()),
              _buildQuickFilterChip('هذا الشهر', () => _setThisMonthFilter()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value != 'الكل';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: Responsive.paddingSym(h: 12, v: 8),
        decoration: BoxDecoration(
          color: hasValue ? Colors.blue[100] : Colors.white,
          borderRadius: BorderRadius.circular(Responsive.radius(8)),
          border: Border.all(
            color: hasValue ? Colors.blue : Colors.grey[300]!,
            width: hasValue ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: Responsive.icon(18),
              color: hasValue ? Colors.blue[700] : Colors.grey[600],
            ),
            Responsive.hBox(6),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.font(13),
                fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                color: hasValue ? Colors.blue[700] : Colors.grey[800],
              ),
            ),
            if (hasValue) ...[
              Responsive.hBox(4),
              Icon(
                Icons.check_circle,
                size: Responsive.icon(16),
                color: Colors.blue[700],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: Responsive.paddingSym(h: 12, v: 8),
        side: BorderSide(color: Colors.green[300]!),
        foregroundColor: Colors.green[700],
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: Responsive.font(12)),
      ),
    );
  }

  void _showTransactionTypeFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'اختر نوع العملية',
          style: TextStyle(fontSize: Responsive.font(18)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypeOption('الكل'),
            _buildTypeOption('بيع'), // ⭐
            _buildTypeOption('إضافة شحنة'), // ⭐
            _buildTypeOption('استرجاع من بيع'), // ⭐ فقط هذا
            _buildTypeOption('زيادة'),
            _buildTypeOption('نقصان'),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String type) {
    final isSelected = _filterType == type;

    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? Colors.blue : Colors.grey,
        size: Responsive.icon(24),
      ),
      title: Text(
        type,
        style: TextStyle(
          fontSize: Responsive.font(14),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black,
        ),
      ),
      tileColor: isSelected ? Colors.blue[50] : null,
      onTap: () {
        setState(() {
          _filterType = type;
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _endDate != null && _endDate!.isAfter(_startDate ?? DateTime(2020))
              ? _endDate!
              : (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
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
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _setTodayFilter() {
    setState(() {
      _startDate = DateTime.now();
      _endDate = DateTime.now();
    });
  }

  void _setLast7DaysFilter() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 7));
      _endDate = DateTime.now();
    });
  }

  void _setThisMonthFilter() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
    });
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _filterType = 'الكل';
    });
  }

  String _getFilterDescription(int filtered, int total) {
    if (filtered == total) {
      return 'عدد الحركات: $total';
    }
    return 'عرض $filtered من أصل $total حركة';
  }

  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case 'بيع':
        return Colors.red;
      case 'إضافة':
      case 'إضافة شحنة':
        return Colors.green;
      case 'استرجاع من بيع':
        return Colors.orange;
      case 'زيادة':
        return Colors.blue;
      case 'نقصان':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
