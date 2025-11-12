// ignore_for_file: deprecated_member_use
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:soundtry/models/invoice.dart';
import 'package:soundtry/screens/invoice_screen.dart';
import '../providers/product_provider.dart';
import '../providers/representative_provider.dart';
import '../models/product.dart';
import '../models/representative.dart';

class CartItem {
  final Product product;
  int quantity;
  double customPrice;
  double discount;

  CartItem({
    required this.product,
    this.quantity = 1,
    required this.customPrice,
    this.discount = 0,
  });

  double get subtotal => customPrice * quantity;
  double get priceAfterDiscount => customPrice - (discount / quantity);
  double get total => (customPrice * quantity) - discount;
}

class SellProductScreen extends StatefulWidget {
  const SellProductScreen({super.key});
  @override
  State<SellProductScreen> createState() => _SellProductScreenState();
}

class _SellProductScreenState extends State<SellProductScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  late TabController _tabController;
  String? _selectedCategoryFilter;
  List<String> _availableCategories = [];
  final _paidAmountController = TextEditingController();
  // ⭐⭐⭐ إضافة متغيرات التاريخ والوقت
  DateTime? _selectedSaleDate;
  TimeOfDay? _selectedSaleTime;
  final List<CartItem> _cart = [];
  bool _isSelling = false;
  final _invoiceSearchController = TextEditingController();
  String _invoiceSearchQuery = '';
  String _clientTypeFilter = 'الكل'; // الكل، عميل، مندوب

  String? _selectedClientName;
  String _clientType = 'عميل';
  Representative? _selectedRepresentative;
  String _paymentType = 'نقد';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Provider.of<ProductProvider>(context, listen: false).refreshProducts();
    Provider.of<RepresentativeProvider>(context, listen: false)
        .loadRepresentatives();
    _loadCategories();
  }

  void _loadCategories() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final categories = provider.products
        .where((p) => p.category != null && p.category!.isNotEmpty)
        .map((p) => p.category!)
        .toSet()
        .toList();
    setState(() {
      _availableCategories = categories;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _notesController.dispose();
    _invoiceSearchController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    var filtered = products;
    if (_selectedCategoryFilter != null) {
      filtered =
          filtered.where((p) => p.category == _selectedCategoryFilter).toList();
    }
    return filtered;
  }

  double get _cartSubtotal =>
      _cart.fold(0.0, (sum, item) => sum + item.subtotal);
  double get _totalDiscounts =>
      _cart.fold(0.0, (sum, item) => sum + item.discount);
  double get _cartTotal => _cart.fold(0.0, (sum, item) => sum + item.total);

  void _addToCart(Product product, double price, int quantity) {
    if (quantity > product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكمية المطلوبة أكثر من المتاح')),
      );
      return;
    }

    setState(() {
      // ⭐⭐⭐ البحث عن منتج بنفس السعر
      final existingIndex = _cart.indexWhere(
        (item) => item.product.id == product.id && item.customPrice == price,
      );

      if (existingIndex != -1) {
        // ⭐ وُجد منتج بنفس السعر - نزيد الكمية فقط
        _cart[existingIndex].quantity += quantity;
      } else {
        // ⭐ لا يوجد منتج بهذا السعر - نضيف عنصر جديد
        _cart.add(CartItem(
          product: product,
          quantity: quantity,
          customPrice: price,
        ));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _selectedClientName = null;
      _clientType = 'عميل';
      _selectedRepresentative = null;
      _paymentType = 'نقد';
      _notesController.clear();
      _paidAmountController.clear();
      _selectedSaleDate = null; // ⭐
      _selectedSaleTime = null; // ⭐
    });
  }

  // ⭐⭐⭐ متغيرات الفلترة حسب التاريخ (أضف هذه السطور)
  String _dateFilterType = 'الكل'; // الكل، اليوم، الأسبوع، الشهر، فترة مخصصة
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isInvoiceInDateRange(List<dynamic> sales) {
    if (_dateFilterType == 'الكل') return true;

    final invoiceDate = sales.first.saleDateTime;
    final now = DateTime.now();

    switch (_dateFilterType) {
      case 'اليوم':
        return invoiceDate.year == now.year &&
            invoiceDate.month == now.month &&
            invoiceDate.day == now.day;

      case 'الأسبوع':
        final weekAgo = now.subtract(const Duration(days: 7));
        return invoiceDate.isAfter(weekAgo) &&
            invoiceDate.isBefore(now.add(const Duration(days: 1)));

      case 'الشهر':
        return invoiceDate.year == now.year && invoiceDate.month == now.month;

      case 'فترة مخصصة':
        if (_customStartDate == null || _customEndDate == null) return true;

        final startOfDay = DateTime(_customStartDate!.year,
            _customStartDate!.month, _customStartDate!.day);
        final endOfDay = DateTime(_customEndDate!.year, _customEndDate!.month,
            _customEndDate!.day, 23, 59, 59);

        return invoiceDate
                .isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            invoiceDate.isBefore(endOfDay.add(const Duration(seconds: 1)));

      default:
        return true;
    }
  }

  bool _isInvoiceMatchingClientType(List<dynamic> sales) {
    if (_clientTypeFilter == 'الكل') return true;

    final firstSale = sales.first;
    final clientMatch =
        RegExp(r'(عميل|مندوب):\s*([^|]+)').firstMatch(firstSale.notes ?? '');
    final clientType = clientMatch?.group(1)?.trim();

    return clientType == _clientTypeFilter;
  }

  Widget _buildClientTypeFilterChip(String label, IconData icon) {
    final isSelected = _clientTypeFilter == label;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 18, color: isSelected ? Colors.white : Colors.blue[700]),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _clientTypeFilter = label;
        });
      },
      selectedColor: Colors.blue,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.blue[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.blue[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }

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
              primary: Colors.green,
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

  Widget _buildDateFilterChip(String label, IconData icon) {
    final isSelected = _dateFilterType == label;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 18, color: isSelected ? Colors.white : Colors.green[700]),
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
      selectedColor: Colors.green,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.green[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Colors.green : Colors.green[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }

// ⭐ Widget لبطاقات الإحصائيات
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.green,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(icon: Icon(Icons.add_shopping_cart), text: 'بيع جديد'),
                Tab(icon: Icon(Icons.receipt_long), text: 'الفواتير'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSellTab(),
                _buildInvoicesListTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellTab() {
    return Consumer2<ProductProvider, RepresentativeProvider>(
      builder: (context, productProvider, repProvider, _) {
        if (productProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredProducts = _getFilteredProducts(productProvider.products);

        return Row(
          children: [
            // === Left Panel: Products List ===
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[50],
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // حقل البحث
                        SizedBox(
                          width: 400, // عرض ثابت
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'بحث عن منتج',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              productProvider.setSearchQuery(value);
                            },
                          ),
                        ),

                        // فلتر الصنف
                        SizedBox(
                          width: 250, // عرض ثابت
                          child: DropdownButtonFormField<String?>(
                            value: _selectedCategoryFilter,
                            decoration: const InputDecoration(
                              labelText: 'الصنف',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.filter_list, size: 20),
                              contentPadding: EdgeInsets.symmetric(
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
                                  value: cat,
                                  child: Text(cat),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryFilter = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 4,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width - 450,
                            ),
                            child: DataTable(
                              columnSpacing: 20,
                              horizontalMargin: 12,
                              headingRowColor:
                                  WidgetStateProperty.all(Colors.blue[50]),
                              columns: const [
                                DataColumn(label: Text('المنتج')),
                                DataColumn(label: Text('كود الشحنة')), // ⭐ جديد
                                DataColumn(label: Text('الصنف')),
                                DataColumn(label: Text('المتاح')),
                                DataColumn(label: Text('الأسعار')),
                                DataColumn(label: Text('إضافة')),
                              ],
                              rows: filteredProducts.map((product) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Container(
                                        constraints:
                                            const BoxConstraints(maxWidth: 200),
                                        child: Text(
                                          product.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    // ⭐⭐⭐ خلية كود الشحنة الجديدة
                                    DataCell(
                                      product.batchCode != null &&
                                              product.batchCode!.isNotEmpty
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.purple[50],
                                                borderRadius:
                                                    BorderRadius.circular(6),
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
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.purple[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const Text('-',
                                              style: TextStyle(fontSize: 14)),
                                    ),
                                    DataCell(Text(product.category ?? '-')),
                                    DataCell(
                                      Text(
                                        '${product.quantity}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: product.quantity > 0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        tooltip: 'عرض الأسعار',
                                        onPressed: () =>
                                            _showPricesDialogInTable(product),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_shopping_cart,
                                            color: Colors.green),
                                        onPressed: product.quantity > 0
                                            ? () =>
                                                _showAddToCartDialog(product)
                                            : null,
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
                  ),
                ],
              ),
            ),
            // === Right Panel: Cart ===
            Container(
              width: 400,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(left: BorderSide(color: Colors.grey[300]!)),
              ),
              child: _buildCartSection(repProvider),
            ),
          ],
        );
      },
    );
  }

  void _showPricesDialogInTable(Product product) {
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

  Widget _buildCartSection(RepresentativeProvider repProvider) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green,
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white),
              const SizedBox(width: 8),
              Text('قايمة البيع  (${_cart.length})',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_cart.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('تفريغ العربة'),
                        content: const Text('هل تريد حذف جميع المنتجات؟'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('إلغاء')),
                          ElevatedButton(
                            onPressed: () {
                              _clearCart();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('حذف'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: _cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('العربة فارغة',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    final item = _cart[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(item.product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  onPressed: () => _removeFromCart(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('الكمية: ${item.quantity}'),
                                Text(
                                    'السعر: ${item.customPrice.toStringAsFixed(2)}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    'المجموع: ${item.subtotal.toStringAsFixed(2)}'),
                                if (item.discount > 0)
                                  Text(
                                      'خصم: ${item.discount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 12)),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('بعد الخصم:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('${item.total.toStringAsFixed(2)} جنيه',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () => _showItemDiscountDialog(item),
                              icon: const Icon(Icons.discount, size: 16),
                              label: Text(item.discount > 0
                                  ? 'تعديل الخصم'
                                  : 'إضافة خصم'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 5),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المجموع الفرعي:'),
                          Text('${_cartSubtotal.toStringAsFixed(2)} جنيه',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (_totalDiscounts > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('إجمالي الخصومات:'),
                            Text('${_totalDiscounts.toStringAsFixed(2)} جنيه',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                          ],
                        ),
                      ],
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${_cartTotal.toStringAsFixed(2)} جنيه',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSelling
                        ? null
                        : () => _showCheckoutBottomSheet(repProvider),
                    icon: _isSelling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle),
                    label: const Text('إتمام البيع',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showItemDiscountDialog(CartItem item) {
    final discountController =
        TextEditingController(text: item.discount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('خصم على ${item.product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المجموع الفرعي: ${item.subtotal.toStringAsFixed(2)} جنيه'),
            const SizedBox(height: 16),
            TextField(
              controller: discountController,
              decoration: const InputDecoration(
                labelText: 'قيمة الخصم',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.discount),
                suffixText: 'جنيه',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final discount = double.tryParse(discountController.text) ?? 0;
              if (discount >= 0 && discount <= item.subtotal) {
                setState(() {
                  item.discount = discount;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('الخصم يجب أن يكون أقل من المجموع')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutBottomSheet(RepresentativeProvider repProvider) {
    // ⭐ متغير خارج StatefulBuilder للتحكم في إظهار التاريخ والوقت
    bool showDateTimePicker = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true, // ⭐ تغيير إلى true للسماح بالإغلاق
      enableDrag: true, // ⭐ تغيير إلى true للسماح بالسحب
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) {
          final paidAmount = double.tryParse(_paidAmountController.text) ?? 0;
          final remainingAmount = _cartTotal - paidAmount;

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.95,
            child: Column(
              children: [
                // المحتوى القابل للسكرول
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      left: 16,
                      right: 16,
                      top: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ... باقي المحتوى كما هو ...

                        // نوع العميل
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'نوع العميل',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('عميل'),
                                      value: 'عميل',
                                      groupValue: _clientType,
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      onChanged: (value) {
                                        setBottomSheetState(() {
                                          _clientType = value!;
                                          _selectedClientName = null;
                                          _selectedRepresentative = null;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('مندوب'),
                                      value: 'مندوب',
                                      groupValue: _clientType,
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      onChanged: (value) {
                                        setBottomSheetState(() {
                                          _clientType = value!;
                                          _selectedClientName = null;
                                          _selectedRepresentative = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // اختيار العميل/المندوب
                        DropdownSearch<Representative>(
                          items: repProvider.getAllByType(_clientType),
                          selectedItem: _selectedRepresentative,
                          itemAsString: (rep) => rep.name,
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: _clientType == 'عميل'
                                  ? 'اختر العميل *'
                                  : 'اختر المندوب *',
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(
                                _clientType == 'عميل'
                                    ? Icons.person
                                    : Icons.badge,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: const TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'ابحث...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            emptyBuilder: (context, searchEntry) =>
                                const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('لا توجد نتائج'),
                              ),
                            ),
                          ),
                          onChanged: (rep) {
                            setBottomSheetState(() {
                              _selectedRepresentative = rep;
                              _selectedClientName = rep?.name;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // نوع الدفع
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.payment,
                                      color: Colors.blue, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'نوع الدفع',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('نقد'),
                                      value: 'نقد',
                                      groupValue: _paymentType,
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      onChanged: (value) {
                                        setBottomSheetState(() {
                                          _paymentType = value!;
                                          _paidAmountController.clear();
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('آجل'),
                                      value: 'آجل',
                                      groupValue: _paymentType,
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      onChanged: (value) {
                                        setBottomSheetState(() {
                                          _paymentType = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ⭐⭐⭐ زر صغير لإظهار/إخفاء التاريخ والوقت
                        InkWell(
                          onTap: () {
                            setBottomSheetState(() {
                              showDateTimePicker = !showDateTimePicker;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_selectedSaleDate != null ||
                                      _selectedSaleTime != null)
                                  ? Colors.indigo[50]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (_selectedSaleDate != null ||
                                        _selectedSaleTime != null)
                                    ? Colors.indigo
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: (_selectedSaleDate != null ||
                                          _selectedSaleTime != null)
                                      ? Colors.indigo
                                      : Colors.grey[600],
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (_selectedSaleDate != null ||
                                          _selectedSaleTime != null)
                                      ? 'تاريخ مخصص'
                                      : 'تحديد تاريخ ووقت البيع',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: (_selectedSaleDate != null ||
                                            _selectedSaleTime != null)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: (_selectedSaleDate != null ||
                                            _selectedSaleTime != null)
                                        ? Colors.indigo
                                        : Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  showDateTimePicker
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ⭐⭐⭐ قسم التاريخ والوقت (يظهر عند الضغط على الأيقونة)
                        if (showDateTimePicker) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.indigo),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.indigo[50],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // اختيار التاريخ
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: _selectedSaleDate ??
                                                DateTime.now(),
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now(),
                                          );
                                          if (date != null) {
                                            setBottomSheetState(() {
                                              _selectedSaleDate = date;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.indigo.shade200),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: Colors.white,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                color: Colors.indigo,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'التاريخ',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _selectedSaleDate != null
                                                          ? DateFormat(
                                                                  'yyyy-MM-dd')
                                                              .format(
                                                                  _selectedSaleDate!)
                                                          : 'الآن',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
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

                                    // اختيار الوقت
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final time = await showTimePicker(
                                            context: context,
                                            initialTime: _selectedSaleTime ??
                                                TimeOfDay.now(),
                                          );
                                          if (time != null) {
                                            setBottomSheetState(() {
                                              _selectedSaleTime = time;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.indigo.shade200),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: Colors.white,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                color: Colors.indigo,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'الوقت',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _selectedSaleTime != null
                                                          ? _selectedSaleTime!
                                                              .format(context)
                                                          : 'الآن',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
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

                                // زر إعادة تعيين
                                if (_selectedSaleDate != null ||
                                    _selectedSaleTime != null) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setBottomSheetState(() {
                                          _selectedSaleDate = null;
                                          _selectedSaleTime = null;
                                        });
                                      },
                                      icon: const Icon(Icons.refresh, size: 14),
                                      label: const Text(
                                        'استخدام الوقت الحالي',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        foregroundColor: Colors.indigo,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // باقي الحقول...
                        // حقل المبلغ المدفوع (يظهر فقط للآجل)
                        if (_paymentType == 'آجل') ...[
                          TextField(
                            controller: _paidAmountController,
                            decoration: InputDecoration(
                              labelText: 'المبلغ المدفوع',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.payments,
                                  color: Colors.green),
                              suffixText: 'جنيه',
                              helperText: remainingAmount > 0
                                  ? 'المتبقي: ${remainingAmount.toStringAsFixed(2)} جنيه'
                                  : null,
                              helperStyle: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setBottomSheetState(() {});
                            },
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ملاحظات
                        TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // ملخص الفاتورة
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('المجموع الفرعي:'),
                                  Text(
                                      '${_cartSubtotal.toStringAsFixed(2)} جنيه',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              if (_totalDiscounts > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('إجمالي الخصومات:'),
                                    Text(
                                        '${_totalDiscounts.toStringAsFixed(2)} جنيه',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red)),
                                  ],
                                ),
                              ],
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('الإجمالي:',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  Text('${_cartTotal.toStringAsFixed(2)} جنيه',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green)),
                                ],
                              ),
                              if (_paymentType == 'آجل' && paidAmount > 0) ...[
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('المدفوع:',
                                        style: TextStyle(color: Colors.green)),
                                    Text(
                                        '${paidAmount.toStringAsFixed(2)} جنيه',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green)),
                                  ],
                                ),
                                if (remainingAmount > 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('المتبقي:',
                                          style:
                                              TextStyle(color: Colors.orange)),
                                      Text(
                                          '${remainingAmount.toStringAsFixed(2)} جنيه',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange)),
                                    ],
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // زر التأكيد في الأسفل (ثابت)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSelling
                          ? null
                          : () {
                              // التحقق من اختيار العميل/المندوب قبل الإغلاق
                              if (_selectedClientName == null ||
                                  _selectedClientName!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('الرجاء اختيار $_clientType'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              // التحقق من المبلغ المدفوع
                              if (_paymentType == 'آجل' &&
                                  paidAmount > _cartTotal) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('المبلغ المدفوع أكبر من الإجمالي'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              // كل شيء صحيح، أغلق وأكمل البيع
                              Navigator.pop(context);
                              _confirmSell();
                            },
                      icon: _isSelling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle),
                      label: const Text('تأكيد وإتمام البيع',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddToCartDialog(Product product) {
    final quantityController = TextEditingController(text: '1');
    final priceController =
        TextEditingController(text: product.retailPrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المتاح: ${product.quantity}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                  labelText: 'الكمية', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                  labelText: 'السعر',
                  border: OutlineInputBorder(),
                  suffixText: 'جنيه'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                    onPressed: () {
                      priceController.text =
                          product.retailPrice.toStringAsFixed(2);
                    },
                    child: const Text('فردي')),
                TextButton(
                    onPressed: () {
                      priceController.text =
                          product.wholesalePrice.toStringAsFixed(2);
                    },
                    child: const Text('جملة')),
                TextButton(
                    onPressed: () {
                      priceController.text =
                          product.bulkWholesalePrice.toStringAsFixed(2);
                    },
                    child: const Text('ج.ج')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text) ?? 1;
              final price =
                  double.tryParse(priceController.text) ?? product.retailPrice;
              if (quantity > 0 && price > 0) {
                _addToCart(product, price, quantity);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _confirmSell() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('العربة فارغة')));
      return;
    }
    if (_selectedClientName == null || _selectedClientName!.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('الرجاء اختيار $_clientType')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد البيع'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedRepresentative != null) ...[
                const SizedBox(height: 4),
                Text(_selectedRepresentative!.name,
                    style: TextStyle(fontSize: 14, color: Colors.blue[700])),
              ],
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _paymentType == 'نقد'
                      ? Colors.green[100]
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'الدفع: $_paymentType',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _paymentType == 'نقد'
                        ? Colors.green[900]
                        : Colors.orange[900],
                  ),
                ),
              ),
              const Divider(),
              const Text('المنتجات:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ..._cart.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ${item.product.name} × ${item.quantity}',
                            style: const TextStyle(fontSize: 14)),
                        Text(
                            '  ${item.customPrice.toStringAsFixed(2)} جنيه/الوحدة = ${item.subtotal.toStringAsFixed(2)} جنيه',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        if (item.discount > 0)
                          Text(
                              '  خصم: ${item.discount.toStringAsFixed(2)} جنيه',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        Text(
                            '  الإجمالي: ${item.total.toStringAsFixed(2)} جنيه',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.green)),
                      ],
                    ),
                  )),
              const Divider(thickness: 2),
              Text('المجموع الفرعي: ${_cartSubtotal.toStringAsFixed(2)} جنيه'),
              if (_totalDiscounts > 0)
                Text(
                    'إجمالي الخصومات: ${_totalDiscounts.toStringAsFixed(2)} جنيه',
                    style: const TextStyle(color: Colors.red)),
              Text('الإجمالي: ${_cartTotal.toStringAsFixed(2)} جنيه',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeSale();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSale() async {
    setState(() => _isSelling = true);

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final repProvider =
          Provider.of<RepresentativeProvider>(context, listen: false);
      final invoiceNumber = Invoice.generateInvoiceNumber();

      // ⭐⭐⭐ حساب التاريخ والوقت النهائي
      DateTime finalSaleDateTime;
      if (_selectedSaleDate != null) {
        final date = _selectedSaleDate!;
        final time = _selectedSaleTime ?? TimeOfDay.now();
        finalSaleDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      } else {
        finalSaleDateTime = DateTime.now();
      }

      // ⭐ حساب المدفوع والمتبقي
      final paidAmount = double.tryParse(_paidAmountController.text) ??
          (_paymentType == 'نقد' ? _cartTotal : 0);
      final remainingAmount = _cartTotal - paidAmount;

      // التحقق من المبلغ المدفوع
      if (paidAmount > _cartTotal) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('المبلغ المدفوع أكبر من الإجمالي')));
        setState(() => _isSelling = false);
        return;
      }

      // ⭐⭐⭐ التحقق من الكميات قبل البدء في البيع
      final Map<int, int> productTotalQuantities = {};
      for (var item in _cart) {
        final productId = item.product.id!;
        productTotalQuantities[productId] =
            (productTotalQuantities[productId] ?? 0) + item.quantity;
      }

      // ⭐⭐⭐ التحقق من توفر الكميات
      for (var entry in productTotalQuantities.entries) {
        final productId = entry.key;
        final requiredQuantity = entry.value;

        final product = productProvider.products.firstWhere(
          (p) => p.id == productId,
          orElse: () => throw Exception('المنتج غير موجود'),
        );

        if (requiredQuantity > product.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ الكمية المطلوبة من "${product.name}" ($requiredQuantity) أكبر من المتاح (${product.quantity})',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          setState(() => _isSelling = false);
          return;
        }
      }

      // ⭐⭐⭐ بناء الملاحظات بشكل صحيح
      String notesBase = 'فاتورة: $invoiceNumber'; // ⭐ رقم الفاتورة أولاً

      // إضافة ملاحظات المستخدم
      if (_notesController.text.isNotEmpty) {
        notesBase += ' | ${_notesController.text}';
      }

      // إضافة معلومات المندوب/العميل
      if (_selectedRepresentative != null) {
        notesBase += ' | $_clientType: $_selectedClientName';
      }

      // إضافة نوع الدفع
      notesBase += ' | دفع: $_paymentType';

      // إضافة معلومات الدفع الجزئي
      if (paidAmount > 0 && paidAmount < _cartTotal) {
        notesBase += ' | مدفوع: ${paidAmount.toStringAsFixed(2)}';
        notesBase += ' | متبقي: ${remainingAmount.toStringAsFixed(2)}';
      }

      // ⭐⭐⭐ الآن نبدأ البيع (بعد التحقق من كل الكميات)
      for (var item in _cart) {
        final finalPricePerUnit = item.priceAfterDiscount;
        await productProvider.sellProductWithCustomPrice(
          item.product,
          item.quantity,
          _selectedClientName!,
          finalPricePerUnit,
          notesBase,
          saleDateTime: finalSaleDateTime,
        );
      }

      // ⭐⭐⭐ الجزء الأهم: تسجيل المعاملة مع المندوب ⭐⭐⭐
      if (_selectedRepresentative != null) {
        final productsSummary = _cart
            .map((item) => '${item.product.name} (${item.quantity})')
            .join(', ');
        final success = await repProvider.recordDeferredSale(
          representativeId: _selectedRepresentative!.id!,
          totalAmount: _cartTotal,
          paidAmount: paidAmount,
          productsSummary: productsSummary,
          invoiceNumber: invoiceNumber,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          saleDateTime: finalSaleDateTime,
        );
        if (success) {
          debugPrint(
              '✅ تم تسجيل المعاملة مع المندوب ${_selectedRepresentative!.name}');
          debugPrint('   - رقم الفاتورة: $invoiceNumber');
          debugPrint('   - الإجمالي: ${_cartTotal.toStringAsFixed(2)}');
          debugPrint('   - المدفوع: ${paidAmount.toStringAsFixed(2)}');
          debugPrint('   - المتبقي: ${remainingAmount.toStringAsFixed(2)}');
        } else {
          debugPrint('❌ فشل تسجيل المعاملة مع المندوب');
        }
      }

      // إنشاء الفاتورة
      final invoiceItems = _cart
          .map((item) => InvoiceItem(
                productName: item.product.name,
                quantity: item.quantity,
                unitPrice: item.customPrice,
                discount: item.discount,
                purchasePrice: item.product.purchasePrice,
              ))
          .toList();
      await productProvider.fetchSales();
      final invoice = Invoice(
        invoiceNumber: invoiceNumber,
        invoiceDate: DateTime.now(),
        customerName: _selectedClientName!,
        items: invoiceItems,
        tax: 0,
        discount: _totalDiscounts,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم تسجيل البيع بنجاح ✅'),
        backgroundColor: Colors.green,
      ));

      // عرض نافذة النجاح
      final shouldPrintInvoice = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('تم البيع بنجاح'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⭐⭐⭐ عرض رقم الفاتورة
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'رقم الفاتورة: $invoiceNumber',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('هل تريد عرض وطباعة الفاتورة؟'),
              const SizedBox(height: 12),

              // معلومات المندوب
              if (_selectedRepresentative != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.badge, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedRepresentative!.name,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),

              // نوع الدفع
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _paymentType == 'نقد'
                      ? Colors.green[50]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.payment,
                      color:
                          _paymentType == 'نقد' ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text('الدفع: $_paymentType'),
                  ],
                ),
              ),

              // المتبقي
              if (remainingAmount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('المتبقي:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        '${remainingAmount.toStringAsFixed(2)} جنيه',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لا'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.receipt),
              label: const Text('عرض الفاتورة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      );

      if (shouldPrintInvoice == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => InvoiceScreen(invoice: invoice)),
        );
      }

      _clearCart();
      _loadCategories();
    } catch (e) {
      debugPrint('❌ Error in _completeSale: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSelling = false);
    }
  }

  // ⭐⭐⭐ استبدل دالة _buildInvoicesListTab بالكامل بهذا الكود الصحيح:

  Widget _buildInvoicesListTab() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.sales.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد فواتير'),
              ],
            ),
          );
        }

        final Map<String, List<dynamic>> groupedSales = {};
        for (var sale in provider.sales) {
          final invoiceNumber = _extractInvoiceNumber(sale.notes);
          if (!groupedSales.containsKey(invoiceNumber)) {
            groupedSales[invoiceNumber] = [];
          }
          groupedSales[invoiceNumber]!.add(sale);
        }

        // فلترة البحث النصي
        var filteredInvoices = groupedSales.entries.where((entry) {
          if (_invoiceSearchQuery.isEmpty) return true;

          final query = _invoiceSearchQuery.toLowerCase();
          final invoiceNumber = entry.key.toLowerCase();
          final sales = entry.value;
          final customerName = sales.first.customerName.toLowerCase();

          if (invoiceNumber.contains(query)) return true;
          if (customerName.contains(query)) return true;

          for (var sale in sales) {
            if (sale.productName.toLowerCase().contains(query)) {
              return true;
            }
          }

          return false;
        }).toList();

        // ⭐⭐⭐ تطبيق فلترة التاريخ
        filteredInvoices = filteredInvoices.where((entry) {
          return _isInvoiceInDateRange(entry.value);
        }).toList();
// ⭐⭐⭐ تطبيق فلترة نوع العميل
        filteredInvoices = filteredInvoices.where((entry) {
          return _isInvoiceMatchingClientType(entry.value);
        }).toList();
        // ⭐ حساب الإحصائيات
        final totalInvoices = filteredInvoices.length;
        final totalAmount = filteredInvoices.fold<double>(
          0.0,
          (sum, entry) =>
              sum +
              entry.value.fold<double>(0.0, (s, sale) => s + sale.totalAmount),
        );

        return Column(
          children: [
            // ⭐⭐⭐ Container الفلترة - تم إصلاحه
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                // ⭐⭐⭐ Column وليس Row
                children: [
                  // 1️⃣ حقل البحث
                  TextField(
                    controller: _invoiceSearchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث برقم الفاتورة، اسم العميل، أو المنتج...',
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                      suffixIcon: _invoiceSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _invoiceSearchController.clear();
                                  _invoiceSearchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.green),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.green, width: 2),
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
                        _invoiceSearchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

// ⭐ فلترة حسب نوع العميل
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildClientTypeFilterChip('الكل', Icons.all_inclusive),
                        const SizedBox(width: 8),
                        _buildClientTypeFilterChip('عميل', Icons.person),
                        const SizedBox(width: 8),
                        _buildClientTypeFilterChip('مندوب', Icons.badge),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2️⃣ أزرار الفلترة السريعة
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

                  // 3️⃣ حقول اختيار الفترة المخصصة
                  if (_dateFilterType == 'فترة مخصصة') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'اختر الفترة الزمنية',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
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
                                      border:
                                          Border.all(color: Colors.blue[300]!),
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
                                          color: Colors.blue[700],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward,
                                    color: Colors.blue),
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
                                      border:
                                          Border.all(color: Colors.blue[300]!),
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
                                          color: Colors.blue[700],
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
            if (_invoiceSearchQuery.isNotEmpty || _dateFilterType != 'الكل')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.green[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      icon: Icons.receipt,
                      label: 'عدد الفواتير',
                      value: totalInvoices.toString(),
                      color: Colors.blue,
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStatCard(
                      icon: Icons.attach_money,
                      label: 'الإجمالي',
                      value: '${totalAmount.toStringAsFixed(0)} جنيه',
                      color: Colors.green,
                    ),
                  ],
                ),
              ),

            // 5️⃣ قائمة الفواتير
            Expanded(
              child: filteredInvoices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد فواتير في هذه الفترة',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'جرب تغيير الفلترة',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الفواتير (${filteredInvoices.length})',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...filteredInvoices.map((entry) {
                            final invoiceNumber = entry.key;
                            final sales = entry.value;
                            final firstSale = sales.first;
                            final totalAmount = sales.fold<double>(
                                0, (sum, s) => sum + s.totalAmount);
                            final totalQuantity = sales.fold<int>(
                                0, (sum, s) => sum + (s.quantitySold as int));

                            // استخراج معلومات المندوب ونوع الدفع
                            final repMatch = RegExp(r'مندوب:\s*([^|]+)')
                                .firstMatch(firstSale.notes ?? '');
                            final paymentMatch = RegExp(r'دفع:\s*([^|]+)')
                                .firstMatch(firstSale.notes ?? '');
                            final repName = repMatch?.group(1)?.trim();
                            final paymentType =
                                paymentMatch?.group(1)?.trim() ?? 'نقد';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 3,
                              child: ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.receipt,
                                      color: Colors.green[700]),
                                ),
                                title: Text(
                                  'فاتورة $invoiceNumber',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('العميل: ${firstSale.customerName}',
                                        style: const TextStyle(fontSize: 14)),
                                    Text(
                                      'التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(firstSale.saleDateTime)}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                    if (repName != null) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.badge,
                                              size: 14,
                                              color: Colors.blue[700]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'المندوب: $repName',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.payment,
                                            size: 14,
                                            color: paymentType == 'نقد'
                                                ? Colors.green[700]
                                                : Colors.orange[700]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'الدفع: $paymentType',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: paymentType == 'نقد'
                                                ? Colors.green[700]
                                                : Colors.orange[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${totalAmount.toStringAsFixed(2)} جنيه',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.green),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'تفاصيل الفاتورة:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        const SizedBox(height: 12),
                                        ...sales.map((sale) {
                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        sale.productName,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'الكمية: ${sale.quantitySold} × ${sale.unitPrice.toStringAsFixed(2)} جنيه',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey[700]),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '${sale.totalAmount.toStringAsFixed(2)} جنيه',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: Colors.green),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        const Divider(thickness: 2),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('المجموع:',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16)),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${totalAmount.toStringAsFixed(2)} جنيه',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                      color: Colors.green),
                                                ),
                                                Text(
                                                  'إجمالي القطع: $totalQuantity',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600]),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _showReturnDialogNew(
                                                      sales, provider),
                                              icon: const Icon(
                                                  Icons.assignment_return,
                                                  color: Colors.orange),
                                              label: const Text('استرجاع'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.orange,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _showAddProductToInvoiceDialog(
                                                      invoiceNumber,
                                                      sales,
                                                      provider),
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.blue),
                                              label: const Text('إضافة منتج'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _showInvoiceForGroup(sales),
                                              icon: const Icon(Icons.receipt),
                                              label: const Text('عرض الفاتورة'),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.green),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showReturnDialogNew(List<dynamic> sales, ProductProvider provider) {
    final Map<int, TextEditingController> quantityControllers = {};
    final Map<int, TextEditingController> reasonControllers = {};

    // ⭐ استخدام index بدل id
    for (int i = 0; i < sales.length; i++) {
      quantityControllers[i] = TextEditingController(text: '0');
      reasonControllers[i] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('استرجاع من الفاتورة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: const Text(
                    'اختر المنتجات والكمية المراد استرجاعها',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                // ⭐ استخدام indexed loop
                ...List.generate(sales.length, (index) {
                  final sale = sales[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sale.productName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('الكمية المباعة: ${sale.quantitySold}',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 13)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: quantityControllers[index], // ⭐
                            decoration: InputDecoration(
                              labelText: 'كمية الاسترجاع *',
                              hintText: 'الحد الأقصى: ${sale.quantitySold}',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final qty = int.tryParse(value) ?? 0;
                              if (qty > sale.quantitySold) {
                                quantityControllers[index]!.text =
                                    sale.quantitySold.toString();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'الحد الأقصى: ${sale.quantitySold}'),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: reasonControllers[index], // ⭐
                            decoration: const InputDecoration(
                              labelText: 'سبب الاسترجاع *',
                              hintText: 'اكتب السبب هنا...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                bool hasReturns = false;
                bool hasErrors = false;
                double totalReturnAmount = 0;
                String returnedProducts = '';

                final firstSale = sales.first;
                final invoiceNumber = _extractInvoiceNumber(firstSale.notes);

                final clientMatch = RegExp(r'(عميل|مندوب):\s*([^|]+)')
                    .firstMatch(firstSale.notes ?? '');
                final clientType = clientMatch?.group(1)?.trim();
                final clientName = clientMatch?.group(2)?.trim();

                // ⭐ استخدام indexed loop
                for (int i = 0; i < sales.length; i++) {
                  final sale = sales[i];
                  final quantity =
                      int.tryParse(quantityControllers[i]!.text) ?? 0; // ⭐
                  final reason = reasonControllers[i]!.text.trim(); // ⭐

                  if (quantity > 0) {
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'يرجى كتابة سبب الاسترجاع لـ ${sale.productName}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      hasErrors = true;
                      continue;
                    }

                    if (quantity > sale.quantitySold) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'كمية ${sale.productName} أكبر من المباعة (${sale.quantitySold})'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      hasErrors = true;
                      continue;
                    }

                    hasReturns = true;

                    final returnValue = sale.unitPrice * quantity;
                    totalReturnAmount += returnValue;

                    if (returnedProducts.isNotEmpty) returnedProducts += ', ';
                    returnedProducts += '${sale.productName} ($quantity)';

                    try {
                      // ⭐ التحقق من وجود id
                      if (sale.id == null) {
                        throw Exception('معرف البيع غير موجود');
                      }
                      await provider.returnSale(sale.id!, quantity, reason);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('خطأ في استرجاع ${sale.productName}: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      hasErrors = true;
                    }
                  }
                }

                if (hasReturns &&
                    !hasErrors &&
                    clientName != null &&
                    totalReturnAmount > 0) {
                  final repProvider = Provider.of<RepresentativeProvider>(
                      context,
                      listen: false);

                  final representative = repProvider.representatives.firstWhere(
                    (r) => r.name == clientName && r.type == clientType,
                    orElse: () => Representative(
                      name: '',
                      type: 'عميل',
                      totalDebt: 0,
                      totalPaid: 0,
                    ),
                  );

                  if (representative.id != null) {
                    final success = await repProvider.recordReturn(
                      representativeId: representative.id!,
                      returnAmount: totalReturnAmount,
                      productsSummary: returnedProducts,
                      invoiceNumber: invoiceNumber,
                      notes: 'استرجاع من فاتورة $invoiceNumber',
                    );

                    if (success) {
                      debugPrint('✅ تم تسجيل المرتجع في حساب $clientName');
                    }
                  }
                }

                if (!hasErrors) {
                  Navigator.pop(context);
                }

                if (hasReturns && !hasErrors) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('تم استرجاع المنتجات بنجاح وتحديث الحساب ✅'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  final repProvider = Provider.of<RepresentativeProvider>(
                      context,
                      listen: false);
                  await repProvider.loadRepresentatives();
                  await provider.fetchSales();
                  await provider.refreshInventoryTransactions();

                  setState(() {});
                } else if (!hasReturns && !hasErrors) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لم يتم تحديد أي منتجات للاسترجاع'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('تأكيد الاسترجاع'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductToInvoiceDialog(
      String invoiceNumber, List<dynamic> sales, ProductProvider provider) {
    Product? selectedProduct;
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    String selectedPaymentType = 'نقد'; // متغير نوع الدفع للمنتج الجديد

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة منتج للفاتورة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownSearch<Product>(
                  items:
                      provider.products.where((p) => p.quantity > 0).toList(),
                  selectedItem: selectedProduct,
                  itemAsString: (product) =>
                      '${product.name} (متاح: ${product.quantity})',
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'ابحث عن المنتج *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search, color: Colors.blue),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: const TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'اكتب اسم المنتج...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    emptyBuilder: (context, searchEntry) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('لا توجد منتجات متاحة'),
                      ),
                    ),
                    itemBuilder: (context, product, isSelected) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              const Icon(Icons.inventory_2, color: Colors.blue),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('الصنف: ${product.category ?? "-"}'),
                            Text(
                              'المتاح: ${product.quantity}',
                              style: TextStyle(
                                color: product.quantity > 10
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${product.retailPrice.toStringAsFixed(2)} جنيه',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProduct = value;
                      priceController.text =
                          value?.retailPrice.toStringAsFixed(2) ?? '';
                    });
                  },
                ),
                if (selectedProduct != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المتاح:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '${selectedProduct!.quantity}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: selectedProduct!.quantity > 10
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الصنف:',
                                style: TextStyle(fontSize: 12)),
                            Text(selectedProduct!.category ?? '-',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_cart),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'السعر',
                      border: OutlineInputBorder(),
                      suffixText: 'جنيه',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPriceButton(
                        'فردي',
                        selectedProduct!.retailPrice,
                        priceController,
                        setDialogState,
                        Colors.blue,
                      ),
                      _buildPriceButton(
                        'جملة',
                        selectedProduct!.wholesalePrice,
                        priceController,
                        setDialogState,
                        Colors.orange,
                      ),
                      _buildPriceButton(
                        'ج.ج',
                        selectedProduct!.bulkWholesalePrice,
                        priceController,
                        setDialogState,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.payment, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'نوع الدفع لهذا المنتج',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('نقد'),
                                value: 'نقد',
                                groupValue: selectedPaymentType,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedPaymentType = value!;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('آجل'),
                                value: 'آجل',
                                groupValue: selectedPaymentType,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedPaymentType = value!;
                                  });
                                },
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: selectedProduct == null
                  ? null
                  : () async {
                      final quantity =
                          int.tryParse(quantityController.text) ?? 1;
                      final price = double.tryParse(priceController.text) ??
                          selectedProduct!.retailPrice;

                      if (quantity > selectedProduct!.quantity) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('الكمية المطلوبة أكثر من المتاح')),
                        );
                        return;
                      }

                      try {
                        final firstSale = sales.first;

                        // ⭐⭐⭐ استخراج جميع المعلومات من الفاتورة الأصلية
                        final clientMatch = RegExp(r'(عميل|مندوب):\s*([^|]+)')
                            .firstMatch(firstSale.notes ?? '');
                        final clientType = clientMatch?.group(1)?.trim();
                        final clientName = clientMatch?.group(2)?.trim();
// ⭐ استخدام نوع الدفع المختار للمنتج الجديد
                        final paymentType = selectedPaymentType;

                        // ⭐ بناء الملاحظات بنفس تنسيق الفاتورة الأصلية
                        final notes =
                            'فاتورة: $invoiceNumber | $clientType: $clientName | دفع: $paymentType';

                        // ⭐⭐⭐ بيع المنتج مع تاريخ الفاتورة الأصلية
                        await provider.sellProductWithCustomPrice(
                          selectedProduct!,
                          quantity,
                          firstSale.customerName,
                          price,
                          notes,
                          saleDateTime:
                              DateTime.now(), // ⭐ استخدام تاريخ الفاتورة
                        );

                        // ⭐⭐⭐ تحديث حساب المندوب/العميل
                        if (clientName != null && clientType != null) {
                          final repProvider =
                              Provider.of<RepresentativeProvider>(context,
                                  listen: false);

                          final representative =
                              repProvider.representatives.firstWhere(
                            (r) => r.name == clientName && r.type == clientType,
                            orElse: () => Representative(
                                name: '',
                                type: 'عميل',
                                totalDebt: 0,
                                totalPaid: 0),
                          );

                          if (representative.id != null &&
                              representative.name.isNotEmpty) {
                            final addedAmount = price * quantity;

                            // ⭐ تحديد المبلغ المدفوع حسب نوع الدفع من الفاتورة الأصلية
                            final paidAmount =
                                paymentType == 'نقد' ? addedAmount : 0.0;

                            final success =
                                await repProvider.recordDeferredSale(
                              representativeId: representative.id!,
                              totalAmount: addedAmount,
                              paidAmount: paidAmount, // ⭐ حسب نوع الدفع
                              productsSummary:
                                  '${selectedProduct!.name} ($quantity)',
                              invoiceNumber: invoiceNumber,
                              notes: 'إضافة منتج للفاتورة',
                              saleDateTime: DateTime.now(),
                            );

                            if (success) {
                              debugPrint('✅ تم تحديث حساب $clientName');
                              debugPrint(
                                  '   - المبلغ المضاف: ${addedAmount.toStringAsFixed(2)}');
                              debugPrint('   - نوع الدفع: $paymentType');
                              debugPrint(
                                  '   - المدفوع: ${paidAmount.toStringAsFixed(2)}');
                              debugPrint(
                                  '   - المتبقي: ${(addedAmount - paidAmount).toStringAsFixed(2)}');
                            } else {
                              debugPrint('❌ فشل تسجيل المعاملة مع $clientName');
                            }
                          } else {
                            debugPrint(
                                '⚠️ المندوب/العميل غير موجود: $clientName');
                          }
                        }

                        if (!mounted) return;

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'تمت إضافة المنتج للفاتورة وتحديث الحساب بنجاح ✅'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // تحديث البيانات
                        final repProvider = Provider.of<RepresentativeProvider>(
                            context,
                            listen: false);
                        await repProvider.loadRepresentatives();
                        await provider.fetchSales();

                        setState(() {});
                      } catch (e) {
                        debugPrint('❌ خطأ في إضافة المنتج: $e');
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('خطأ: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

// ⭐ دالة مساعدة لأزرار الأسعار
  Widget _buildPriceButton(
    String label,
    double price,
    TextEditingController controller,
    StateSetter setState,
    Color color,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              controller.text = price.toStringAsFixed(2);
            });
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 11)),
              Text(
                '${price.toStringAsFixed(0)}',
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractInvoiceNumber(String? notes) {
    if (notes == null || notes.isEmpty) return 'غير محدد';
    final match = RegExp(r'فاتورة:\s*(.+?)(?:\||$)').firstMatch(notes);
    return match?.group(1)?.trim() ?? 'غير محدد';
  }

  void _showInvoiceForGroup(List<dynamic> sales) {
    final invoiceItems = sales
        .map((sale) => InvoiceItem(
              productName: sale.productName,
              quantity: sale.quantitySold,
              unitPrice: sale.unitPrice,
              discount: 0,
              purchasePrice: sale.purchasePrice,
            ))
        .toList();

    final invoice = Invoice(
      invoiceNumber: _extractInvoiceNumber(sales.first.notes),
      invoiceDate: sales.first.saleDateTime,
      customerName: sales.first.customerName,
      items: invoiceItems,
      tax: 0,
      discount: 0,
      notes: sales.first.notes?.split('|').first.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InvoiceScreen(invoice: invoice)),
    );
  }
}
