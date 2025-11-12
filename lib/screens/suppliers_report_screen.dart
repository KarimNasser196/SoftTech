import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soundtry/services/database_helper.dart';

class SuppliersReportScreen extends StatefulWidget {
  const SuppliersReportScreen({super.key});
  @override
  State<SuppliersReportScreen> createState() => _SuppliersReportScreenState();
}

class _SuppliersReportScreenState extends State<SuppliersReportScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future<Map<String, SupplierStats>> calculateSupplierStats() async {
      final dbHelper = DatabaseHelper.instance;
      final productsData = await dbHelper.getProducts();

      final Map<String, SupplierStats> supplierMap = {};

      for (var productData in productsData) {
        final supplierName = productData['supplierName'] as String;
        final quantity = productData['quantity'] as int;
        final purchasePrice = (productData['purchasePrice'] as num).toDouble();
        final dateAdded = DateTime.parse(productData['dateAdded'] as String);
        final batchCode = productData['batchCode'] as String? ?? 'غير محدد';

        // ⭐ استخدام البيانات الحالية من المنتج مباشرة
        final productInfo = ProductInfo(
          productName: productData['name'] as String,
          quantity: quantity, // ⭐ الكمية الحالية
          purchasePrice: purchasePrice, // ⭐ السعر الحالي
          dateAdded: dateAdded,
          batchCode: batchCode,
        );

        if (!supplierMap.containsKey(supplierName)) {
          supplierMap[supplierName] = SupplierStats(products: []);
        }

        // ⭐ نضيف المنتج فقط إذا كانت الكمية أكبر من 0
        if (quantity > 0) {
          supplierMap[supplierName]!.products.add(productInfo);
        }
      }

      return supplierMap;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الموردين للمنتجات الحالية '),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, SupplierStats>>(
        future: calculateSupplierStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد شحنات مسجلة'),
                ],
              ),
            );
          }

          final supplierStats = snapshot.data!;

          // فلترة حسب البحث
          var filteredSuppliers = supplierStats.entries.toList();
          if (_searchQuery.isNotEmpty) {
            filteredSuppliers = filteredSuppliers.where((entry) {
              final supplierName = entry.key.toLowerCase();
              final hasMatchingProduct = entry.value.products.any(
                (p) => p.productName.toLowerCase().contains(_searchQuery),
              );
              return supplierName.contains(_searchQuery) || hasMatchingProduct;
            }).toList();
          }

          // ترتيب حسب القيمة الإجمالية
          filteredSuppliers
              .sort((a, b) => b.value.totalValue.compareTo(a.value.totalValue));

          return Column(
            children: [
              // شريط البحث
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مورد أو منتج...',
                    prefixIcon: const Icon(Icons.search, color: Colors.orange),
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
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),

              // الإحصائيات
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.orange[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'عدد الموردين',
                      '${supplierStats.length}',
                      Icons.store,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'إجمالي الشحنات',
                      '${supplierStats.values.fold<int>(0, (sum, s) => sum + s.products.length)}',
                      Icons.inventory_2,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'القيمة الكلية',
                      '${NumberFormat('#,##0.00', 'ar').format(supplierStats.values.fold<double>(0, (sum, s) => sum + s.totalValue))} ج',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ],
                ),
              ),

              // القائمة
              Expanded(
                child: filteredSuppliers.isEmpty
                    ? const Center(child: Text('لا توجد نتائج'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredSuppliers.length,
                        itemBuilder: (context, index) {
                          final entry = filteredSuppliers[index];
                          final supplierName = entry.key;
                          final stats = entry.value;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 3,
                            child: ExpansionTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.store,
                                  color: Colors.orange[700],
                                ),
                              ),
                              title: Text(
                                supplierName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('عدد الشحنات: ${stats.products.length}'),
                                  Text(
                                    'إجمالي الكمية: ${stats.totalQuantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'إجمالي القيمة',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    '${NumberFormat('#,##0.00', 'ar').format(stats.totalValue)} جنيه',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
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
                                        'الشحنات:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...stats.products.map((product) {
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.grey[300]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      product.productName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  // ⭐ عرض كود الشحنة
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.purple[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                          color: Colors
                                                              .purple[200]!),
                                                    ),
                                                    child: Text(
                                                      product.batchCode,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.purple[700],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      DateFormat('yyyy-MM-dd')
                                                          .format(product
                                                              .dateAdded),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.blue[700],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'الكمية: ${product.quantity}',
                                                        style: const TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                      Text(
                                                        'السعر: ${product.purchasePrice.toStringAsFixed(2)} جنيه',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.red[700],
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    'القيمة: ${NumberFormat('#,##0.00', 'ar').format(product.totalValue)} ج',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.green[700],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ⭐ Classes
class SupplierStats {
  final List<ProductInfo> products;

  SupplierStats({required this.products});

  int get totalQuantity => products.fold<int>(0, (sum, p) => sum + p.quantity);

  double get totalValue =>
      products.fold<double>(0, (sum, p) => sum + p.totalValue);
}

class ProductInfo {
  final String productName;
  final int quantity;
  final double purchasePrice;
  final DateTime dateAdded;
  final String batchCode;

  ProductInfo({
    required this.productName,
    required this.quantity,
    required this.purchasePrice,
    required this.dateAdded,
    required this.batchCode,
  });

  double get totalValue => quantity * purchasePrice;
}
