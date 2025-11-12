import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/screens/add_product_screen.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

enum ViewMode { cards, table }

class ProductsListScreenUpdated extends StatefulWidget {
  const ProductsListScreenUpdated({super.key});

  @override
  State<ProductsListScreenUpdated> createState() =>
      _ProductsListScreenUpdatedState();
}

class _ProductsListScreenUpdatedState extends State<ProductsListScreenUpdated> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late TextEditingController _searchController;
  String? _selectedCategoryFilter;
  String? _selectedWarehouseFilter;
  String? _selectedSupplierFilter;
  DateTimeRange? _selectedDateRange;

  List<Map<String, dynamic>> _availableCategories = [];
  List<Map<String, dynamic>> _availableWarehouses = [];
  List<Map<String, dynamic>> _availableSuppliers = [];

  ViewMode _viewMode = ViewMode.cards;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _loadFilterOptions();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadFilterOptions() async {
    try {
      final db = await _dbHelper.database;

      final categories = await db.query('categories', orderBy: 'name ASC');
      final warehouses = await db.query('warehouses', orderBy: 'name ASC');
      final suppliers = await db.query('suppliers', orderBy: 'name ASC');

      if (mounted) {
        setState(() {
          _availableCategories = categories;
          _availableWarehouses = warehouses;
          _availableSuppliers = suppliers;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading filter options: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    var filtered = products;

    // Filter by category
    if (_selectedCategoryFilter != null) {
      filtered =
          filtered.where((p) => p.category == _selectedCategoryFilter).toList();
    }

    // Filter by warehouse
    if (_selectedWarehouseFilter != null) {
      filtered = filtered
          .where((p) => p.warehouse == _selectedWarehouseFilter)
          .toList();
    }

    // Filter by supplier
    if (_selectedSupplierFilter != null) {
      filtered = filtered
          .where((p) => p.supplierName == _selectedSupplierFilter)
          .toList();
    }

    // Filter by date range
    if (_selectedDateRange != null) {
      filtered = filtered.where((p) {
        try {
          final productDate = DateTime.parse(p.dateAdded.toString());
          final startDate = DateTime(
            _selectedDateRange!.start.year,
            _selectedDateRange!.start.month,
            _selectedDateRange!.start.day,
          );
          final endDate = DateTime(
            _selectedDateRange!.end.year,
            _selectedDateRange!.end.month,
            _selectedDateRange!.end.day,
            23,
            59,
            59,
          );
          return productDate
                  .isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              productDate.isBefore(endDate.add(const Duration(seconds: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
    }

    return filtered;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
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
      helpText: 'اختر نطاق التاريخ',
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
        _selectedDateRange = picked;
      });
    }
  }

  String _getDateRangeText() {
    if (_selectedDateRange == null) return 'الكل';
    final formatter = DateFormat('yyyy/MM/dd');
    return '${formatter.format(_selectedDateRange!.start)} - ${formatter.format(_selectedDateRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar, filters and Add button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن منتج...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    Provider.of<ProductProvider>(
                                      context,
                                      listen: false,
                                    ).setSearchQuery('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (query) {
                          Provider.of<ProductProvider>(
                            context,
                            listen: false,
                          ).setSearchQuery(query);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // View mode toggle
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.grid_view,
                              color: _viewMode == ViewMode.cards
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              if (mounted) {
                                setState(() {
                                  _viewMode = ViewMode.cards;
                                });
                              }
                            },
                            tooltip: 'عرض البطاقات',
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.grey[300],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.table_rows,
                              color: _viewMode == ViewMode.table
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              if (mounted) {
                                setState(() {
                                  _viewMode = ViewMode.table;
                                });
                              }
                            },
                            tooltip: 'عرض الجدول',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddProduct(context),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة منتج'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filters row
                // Filters row - استبدل Row بـ Wrap
                Wrap(
                  spacing: 12, // المسافة الأفقية
                  runSpacing: 12, // المسافة الرأسية
                  children: [
                    // Category Filter
                    SizedBox(
                      width: 250, // ⭐ عرض ثابت
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedCategoryFilter,
                        decoration: InputDecoration(
                          labelText: 'تصفية حسب الصنف',
                          prefixIcon: const Icon(Icons.category, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('الكل'),
                          ),
                          ..._availableCategories.map(
                            (cat) => DropdownMenuItem(
                              value: cat['name'].toString(),
                              child: Text(cat['name'].toString()),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (mounted) {
                            setState(() {
                              _selectedCategoryFilter = value;
                            });
                          }
                        },
                      ),
                    ),

                    // Warehouse Filter
                    SizedBox(
                      width: 250,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedWarehouseFilter,
                        decoration: InputDecoration(
                          labelText: 'تصفية حسب المخزن',
                          prefixIcon: const Icon(Icons.warehouse, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('الكل'),
                          ),
                          ..._availableWarehouses.map(
                            (warehouse) => DropdownMenuItem(
                              value: warehouse['name'].toString(),
                              child: Text(warehouse['name'].toString()),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (mounted) {
                            setState(() {
                              _selectedWarehouseFilter = value;
                            });
                          }
                        },
                      ),
                    ),

                    // Supplier Filter
                    SizedBox(
                      width: 250,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedSupplierFilter,
                        decoration: InputDecoration(
                          labelText: 'تصفية حسب المورد',
                          prefixIcon: const Icon(Icons.store, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('الكل'),
                          ),
                          ..._availableSuppliers.map(
                            (supplier) => DropdownMenuItem(
                              value: supplier['name'].toString(),
                              child: Text(supplier['name'].toString()),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (mounted) {
                            setState(() {
                              _selectedSupplierFilter = value;
                            });
                          }
                        },
                      ),
                    ),

                    // Date Range Filter
                    SizedBox(
                      width: 250,
                      child: InkWell(
                        onTap: _selectDateRange,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'تصفية حسب التاريخ',
                            prefixIcon: const Icon(Icons.date_range, size: 20),
                            suffixIcon: _selectedDateRange != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      if (mounted) {
                                        setState(() {
                                          _selectedDateRange = null;
                                        });
                                      }
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: _selectedDateRange != null
                                ? Colors.blue[50]
                                : Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            _getDateRangeText(),
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedDateRange != null
                                  ? Colors.blue[700]
                                  : Colors.grey[600],
                              fontWeight: _selectedDateRange != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Products grid or table
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredProducts = _getFilteredProducts(
                  provider.products,
                );

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد منتجات',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToAddProduct(context),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة منتج جديد'),
                        ),
                      ],
                    ),
                  );
                }

                return _viewMode == ViewMode.cards
                    ? _buildProductsTable(context, filteredProducts)
                    : _buildProductsGrid(context, filteredProducts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(
    BuildContext context,
    List<Product> products,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: products.map((product) {
          return SizedBox(
            width: 380,
            child: _buildProductCard(context, product),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductsTable(
    BuildContext context,
    List<Product> products,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16), // ⭐ قللنا الـ padding
      child: Card(
        elevation: 4,
        child: SizedBox(
          width: double.infinity, // ⭐ ياخد العرض كله
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minWidth: MediaQuery.of(context).size.width),
              child: DataTable(
                columnSpacing: 30, // ⭐ زودنا المسافة بين الأعمدة
                headingRowHeight: 56, // ⭐ ارتفاع الهيدر

                headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                columns: const [
                  DataColumn(
                    label: Expanded(
                      child: Text(
                        'الاسم',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  // ⭐⭐⭐ عمود جديد
                  DataColumn(
                    label: Text(
                      'كود الشحنة',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'الصنف',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'المخزن',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'المورد',
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
                      'إجراءات',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
                rows: products.map((product) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 200),
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      // ⭐⭐⭐ عرض كود الشحنة
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 150),
                          child: product.batchCode != null &&
                                  product.batchCode!.isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[50],
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        Border.all(color: Colors.purple[200]!),
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
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const Text('-', style: TextStyle(fontSize: 14)),
                        ),
                      ),

                      DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 120),
                          child: Text(
                            product.category ?? '-',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 120),
                          child: Text(
                            product.warehouse ?? '-',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 150),
                          child: Text(
                            product.supplierName,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            '${product.quantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: product.quantity > 0
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 200),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // زر عرض
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 18),
                                onPressed: () =>
                                    _showProductDetails(context, product),
                                tooltip: 'عرض',
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),

                              // زر تعديل
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () =>
                                    _navigateToEditProduct(context, product),
                                tooltip: 'تعديل',
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),

                              // زر حذف
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () =>
                                    _confirmDelete(context, product),
                                tooltip: 'حذف',
                                color: Colors.red,
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(context, product),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.blue[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // ⭐⭐⭐ عرض كود الشحنة
                        if (product.batchCode != null &&
                            product.batchCode!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.purple[200]!),
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        if (product.category != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.category!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (product.warehouse != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.warehouse,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'المخزن:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            product.warehouse!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Icon(Icons.store, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'المورد:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Expanded(
                          child: Text(
                            product.supplierName,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      product.quantity > 0 ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      product.quantity > 0 ? Icons.check_circle : Icons.warning,
                      color: product.quantity > 0
                          ? Colors.green[700]
                          : Colors.red[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الكمية المتاحة: ${product.quantity}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: product.quantity > 0
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showProductDetails(context, product),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('عرض'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToEditProduct(context, product),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('تعديل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _confirmDelete(context, product),
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, Product product) async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        color: Colors.blue[700],
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
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
                _buildDetailSection(
                  'معلومات أساسية',
                  Icons.info_outline,
                  Colors.blue,
                  [
                    // ⭐⭐⭐ عرض كود الشحنة
                    if (product.batchCode != null &&
                        product.batchCode!.isNotEmpty)
                      _buildDetailItem('كود الشحنة', product.batchCode!,
                          valueColor: Colors.purple[700],
                          valueWeight: FontWeight.bold),
                    if (product.category != null)
                      _buildDetailItem('الصنف', product.category!),
                    if (product.warehouse != null)
                      _buildDetailItem('المخزن', product.warehouse!),
                    _buildDetailItem('المورد الحالي', product.supplierName),
                    if (product.specifications != null &&
                        product.specifications!.isNotEmpty)
                      _buildDetailItem('المواصفات', product.specifications!),
                    _buildDetailItem(
                        'تاريخ التسجيل',
                        DateFormat('yyyy-MM-dd HH:mm').format(
                          DateTime.parse(product.dateAdded.toString()),
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailSection(
                  'الأسعار',
                  Icons.attach_money,
                  Colors.green,
                  [
                    _buildDetailItem(
                      'سعر الشراء الحالي',
                      '${product.purchasePrice.toStringAsFixed(2)} جنيه',
                      valueColor: Colors.red[700],
                    ),
                    _buildDetailItem(
                      'سعر البيع (فردي)',
                      '${product.retailPrice.toStringAsFixed(2)} جنيه',
                      valueColor: Colors.blue[700],
                    ),
                    _buildDetailItem(
                      'سعر الجملة',
                      '${product.wholesalePrice.toStringAsFixed(2)} جنيه',
                      valueColor: Colors.green[700],
                    ),
                    _buildDetailItem(
                      'سعر جملة الجملة',
                      '${product.bulkWholesalePrice.toStringAsFixed(2)} جنيه',
                      valueColor: Colors.orange[700],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailSection(
                  'معلومات المخزون',
                  Icons.inventory,
                  Colors.purple,
                  [
                    _buildDetailItem(
                      'الكمية المتاحة',
                      '${product.quantity}',
                      valueColor: product.quantity > 0
                          ? Colors.green[700]
                          : Colors.red[700],
                      valueWeight: FontWeight.bold,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('إغلاق'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToEditProduct(context, product);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('تعديل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
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

  Widget _buildDetailItem(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
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
                fontWeight: valueWeight ?? FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddProduct(
    BuildContext context,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreenUpdated()),
    );

    if (mounted) {
      await _loadFilterOptions();
      if (mounted) {
        Provider.of<ProductProvider>(context, listen: false).products;
      }
    }
  }

  void _navigateToEditProduct(BuildContext context, Product product) async {
    final productProvider = context.read<ProductProvider>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreenUpdated(product: product),
      ),
    );

    if (!mounted) return;

    await _loadFilterOptions();

    if (!mounted) return;

    productProvider.products;
  }

  void _confirmDelete(BuildContext context, Product product) async {
    try {
      // ⭐ محاولة الحذف مباشرة - سيرمي استثناء إذا كان غير مسموح
      await Provider.of<ProductProvider>(
        context,
        listen: false,
      ).deleteProduct(product.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('تم حذف المنتج "${product.name}" بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        await _loadFilterOptions();
      }
    } catch (e) {
      if (!mounted) return;

      // ⭐ عرض رسالة الخطأ التفصيلية
      final errorMessage = e.toString().replaceAll('Exception: ', '');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.red[700], size: 30),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'لا يمكن الحذف',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'حسناً',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }
  }
}
