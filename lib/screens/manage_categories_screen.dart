// lib/screens/manage_categories_screen.dart

import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../widgets/password_dialog.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Controllers for adding new items
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _supplierPhoneController =
      TextEditingController();
  final TextEditingController _warehouseController = TextEditingController();

  // Lists to store items
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadCategories();
    await _loadSuppliers();
    await _loadWarehouses();
  }

  Future<void> _loadCategories() async {
    final db = await _dbHelper.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    if (mounted) {
      setState(() {
        _categories = result;
      });
    }
  }

  Future<void> _loadSuppliers() async {
    final db = await _dbHelper.database;
    final result = await db.query('suppliers', orderBy: 'name ASC');
    if (mounted) {
      setState(() {
        _suppliers = result;
      });
    }
  }

  Future<void> _loadWarehouses() async {
    final db = await _dbHelper.database;
    final result = await db.query('warehouses', orderBy: 'name ASC');
    if (mounted) {
      setState(() {
        _warehouses = result;
      });
    }
  }

  // ⭐⭐⭐ دوال التحقق الجديدة

  /// التحقق من وجود اسم مكرر
  Future<bool> _isNameDuplicate(String table, String name,
      {int? excludeId}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      table,
      where: excludeId != null ? 'name = ? AND id != ?' : 'name = ?',
      whereArgs: excludeId != null ? [name.trim(), excludeId] : [name.trim()],
    );
    return result.isNotEmpty;
  }

  /// التحقق من استخدام الصنف في المنتجات
  Future<int> _getCategoryUsageCount(String categoryName) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE category = ?',
      [categoryName],
    );
    // ⭐ التعديل: استخدام result.first['count'] بدلاً من firstIntValue
    return (result.first['count'] as int?) ?? 0;
  }

  /// التحقق من استخدام المورد في المنتجات
  Future<int> _getSupplierUsageCount(String supplierName) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE supplierName = ?',
      [supplierName],
    );
    // ⭐ التعديل
    return (result.first['count'] as int?) ?? 0;
  }

  /// التحقق من استخدام المخزن في المنتجات
  Future<int> _getWarehouseUsageCount(String warehouseName) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE warehouse = ?',
      [warehouseName],
    );
    // ⭐ التعديل
    return (result.first['count'] as int?) ?? 0;
  }

  // ⭐ إضافة صنف مع التحقق من التكرار
  Future<void> _addCategory() async {
    if (_categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال اسم الصنف'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // ⭐ التحقق من التكرار
      final isDuplicate = await _isNameDuplicate(
        'categories',
        _categoryController.text.trim(),
      );

      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ هذا الصنف موجود بالفعل'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final db = await _dbHelper.database;
      await db.insert('categories', {
        'name': _categoryController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      _categoryController.clear();
      await _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إضافة الصنف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في الإضافة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ⭐ إضافة مورد مع التحقق من التكرار
  Future<void> _addSupplier() async {
    if (_supplierNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال اسم المورد'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // ⭐ التحقق من التكرار
      final isDuplicate = await _isNameDuplicate(
        'suppliers',
        _supplierNameController.text.trim(),
      );

      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ هذا المورد موجود بالفعل'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final db = await _dbHelper.database;
      await db.insert('suppliers', {
        'name': _supplierNameController.text.trim(),
        'phone': _supplierPhoneController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      _supplierNameController.clear();
      _supplierPhoneController.clear();
      await _loadSuppliers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إضافة المورد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في الإضافة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ⭐ إضافة مخزن مع التحقق من التكرار
  Future<void> _addWarehouse() async {
    if (_warehouseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال اسم المخزن'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // ⭐ التحقق من التكرار
      final isDuplicate = await _isNameDuplicate(
        'warehouses',
        _warehouseController.text.trim(),
      );

      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ هذا المخزن موجود بالفعل'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final db = await _dbHelper.database;
      await db.insert('warehouses', {
        'name': _warehouseController.text.trim(),
        'location': '',
        'created_at': DateTime.now().toIso8601String(),
      });

      _warehouseController.clear();
      await _loadWarehouses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إضافة المخزن بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في الإضافة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ⭐⭐⭐ حذف عنصر مع التحقق من الاستخدام
  Future<void> _deleteItem(String table, int id, String itemName) async {
    try {
      // ⭐ التحقق من الاستخدام
      int usageCount = 0;
      String usageMessage = '';

      if (table == 'categories') {
        usageCount = await _getCategoryUsageCount(itemName);
        usageMessage = 'يستخدم في $usageCount منتج';
      } else if (table == 'suppliers') {
        usageCount = await _getSupplierUsageCount(itemName);
        usageMessage = 'يستخدم في $usageCount منتج';
      } else if (table == 'warehouses') {
        usageCount = await _getWarehouseUsageCount(itemName);
        usageMessage = 'يستخدم في $usageCount منتج';
      }

      // ⭐ منع الحذف إذا كان مستخدماً
      if (usageCount > 0) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Text('لا يمكن الحذف'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'لا يمكن حذف "$itemName"',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            usageMessage,
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'يجب حذف المنتجات المرتبطة أولاً',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // ⭐ طلب كلمة السر للحذف
      final bool? confirmed = await showDialog<bool>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => PasswordDialog(
          title: 'تأكيد الحذف',
          message: 'أدخل كلمة السر لحذف: $itemName',
        ),
      );

      if (confirmed != true) return;

      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        final result = await txn.delete(
          table,
          where: 'id = ?',
          whereArgs: [id],
        );

        if (result == 0) {
          throw Exception('لم يتم العثور على العنصر للحذف');
        }
      });

      // Reload data
      if (table == 'categories') {
        await _loadCategories();
      } else if (table == 'suppliers') {
        await _loadSuppliers();
      } else if (table == 'warehouses') {
        await _loadWarehouses();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم الحذف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في الحذف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ⭐⭐⭐ تعديل عنصر مع التحقق من الاستخدام والتكرار
  Future<void> _editItem(
    String table,
    int id,
    String currentName, {
    String? currentPhone,
  }) async {
    try {
      // ⭐ التحقق من الاستخدام
      int usageCount = 0;
      String usageMessage = '';

      if (table == 'categories') {
        usageCount = await _getCategoryUsageCount(currentName);
        usageMessage = 'يستخدم في $usageCount منتج';
      } else if (table == 'suppliers') {
        usageCount = await _getSupplierUsageCount(currentName);
        usageMessage = 'يستخدم في $usageCount منتج';
      } else if (table == 'warehouses') {
        usageCount = await _getWarehouseUsageCount(currentName);
        usageMessage = 'يستخدم في $usageCount منتج';
      }

      // ⭐ منع التعديل إذا كان مستخدماً
      if (usageCount > 0) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Text('لا يمكن التعديل'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'لا يمكن تعديل "$currentName"',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            usageMessage,
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لا يمكن تعديل الاسم لأنه مستخدم في منتجات',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (table == 'suppliers') ...[
                    const SizedBox(height: 8),
                    Text(
                      'يمكنك تعديل رقم الهاتف فقط',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (table == 'suppliers') ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _editPhoneOnly(id, currentName, currentPhone ?? '');
                    },
                    child: const Text('تعديل الهاتف فقط'),
                  ),
                ] else
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('حسناً'),
                  ),
              ],
            ),
          );
        }
        return;
      }

      // ⭐ طلب كلمة السر للتعديل
      final bool? confirmed = await showDialog<bool>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => const PasswordDialog(
          title: 'تأكيد التعديل',
          message: 'أدخل كلمة السر للتعديل',
        ),
      );

      if (confirmed != true) return;

      // Show edit dialog
      final TextEditingController nameController =
          TextEditingController(text: currentName);
      final TextEditingController phoneController =
          TextEditingController(text: currentPhone ?? '');

      final result = await showDialog<Map<String, String>>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تعديل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(),
                ),
              ),
              if (table == 'suppliers') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'phone': phoneController.text,
                });
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      );

      if (result == null || result['name']!.trim().isEmpty) return;

      // ⭐ التحقق من التكرار (إذا تم تغيير الاسم)
      if (result['name']!.trim() != currentName) {
        final isDuplicate = await _isNameDuplicate(
          table,
          result['name']!.trim(),
          excludeId: id,
        );

        if (isDuplicate) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ هذا الاسم موجود بالفعل'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        if (table == 'suppliers') {
          await txn.update(
            table,
            {
              'name': result['name']!.trim(),
              'phone': result['phone']!.trim(),
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        } else {
          await txn.update(
            table,
            {'name': result['name']!.trim()},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      });

      // Reload data
      if (table == 'categories') {
        await _loadCategories();
      } else if (table == 'suppliers') {
        await _loadSuppliers();
      } else if (table == 'warehouses') {
        await _loadWarehouses();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم التعديل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في التعديل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ⭐ دالة مساعدة لتعديل الهاتف فقط (للموردين)
  Future<void> _editPhoneOnly(int id, String name, String currentPhone) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const PasswordDialog(
        title: 'تأكيد التعديل',
        message: 'أدخل كلمة السر لتعديل رقم الهاتف',
      ),
    );

    if (confirmed != true) return;

    final TextEditingController phoneController =
        TextEditingController(text: currentPhone);

    final result = await showDialog<String>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل هاتف: $name'),
        content: TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'رقم الهاتف',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, phoneController.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      final db = await _dbHelper.database;
      await db.update(
        'suppliers',
        {'phone': result.trim()},
        where: 'id = ?',
        whereArgs: [id],
      );

      await _loadSuppliers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تعديل رقم الهاتف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _categoryController.dispose();
    _supplierNameController.dispose();
    _supplierPhoneController.dispose();
    _warehouseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة البيانات الأساسية'),
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الأصناف', icon: Icon(Icons.category)),
            Tab(text: 'الموردين', icon: Icon(Icons.store)),
            Tab(text: 'المخازن', icon: Icon(Icons.warehouse)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesTab(),
          _buildSuppliersTab(),
          _buildWarehousesTab(),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'اسم الصنف',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _addCategory(),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add),
                label: const Text('إضافة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
        ),
        Expanded(
          child: _categories.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد أصناف',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.category,
                            color: Colors.purple[700],
                          ),
                        ),
                        title: Text(
                          category['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _editItem(
                                'categories',
                                category['id'],
                                category['name'],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(
                                'categories',
                                category['id'],
                                category['name'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSuppliersTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _supplierNameController,
                      decoration: InputDecoration(
                        labelText: 'اسم المورد',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _supplierPhoneController,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _addSupplier,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
            ],
          ),
        ),
        Expanded(
          child: _suppliers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا يوجد موردين',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = _suppliers[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.store,
                            color: Colors.green[700],
                          ),
                        ),
                        title: Text(
                          supplier['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: supplier['phone'] != null &&
                                supplier['phone'].toString().isNotEmpty
                            ? Text(
                                'الهاتف: ${supplier['phone']}',
                                style: const TextStyle(fontSize: 14),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _editItem(
                                'suppliers',
                                supplier['id'],
                                supplier['name'],
                                currentPhone: supplier['phone']?.toString(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(
                                'suppliers',
                                supplier['id'],
                                supplier['name'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWarehousesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _warehouseController,
                  decoration: InputDecoration(
                    labelText: 'اسم المخزن',
                    prefixIcon: const Icon(Icons.warehouse),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _addWarehouse(),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _addWarehouse,
                icon: const Icon(Icons.add),
                label: const Text('إضافة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
        ),
        Expanded(
          child: _warehouses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warehouse, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد مخازن',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _warehouses.length,
                  itemBuilder: (context, index) {
                    final warehouse = _warehouses[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.warehouse,
                            color: Colors.blue[700],
                          ),
                        ),
                        title: Text(
                          warehouse['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _editItem(
                                'warehouses',
                                warehouse['id'],
                                warehouse['name'],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(
                                'warehouses',
                                warehouse['id'],
                                warehouse['name'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
