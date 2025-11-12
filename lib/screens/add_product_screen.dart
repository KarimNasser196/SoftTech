import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import '../utils/responsive.dart';
import '../widgets/password_dialog.dart';

class AddProductScreenUpdated extends StatefulWidget {
  final Product? product;

  const AddProductScreenUpdated({super.key, this.product});

  @override
  State<AddProductScreenUpdated> createState() =>
      _AddProductScreenUpdatedState();
}

class _AddProductScreenUpdatedState extends State<AddProductScreenUpdated> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isEditing = false;
  bool _showDateTimePicker = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _specificationsController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _retailPriceController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _bulkWholesalePriceController;
  late TextEditingController _quantityController;

  // Focus nodes for Enter navigation
  final _nameFocus = FocusNode();
  final _categoryFocus = FocusNode();
  final _warehouseFocus = FocusNode();
  final _supplierFocus = FocusNode();
  final _specificationsFocus = FocusNode();
  final _purchasePriceFocus = FocusNode();
  final _retailPriceFocus = FocusNode();
  final _wholesalePriceFocus = FocusNode();
  final _bulkWholesalePriceFocus = FocusNode();
  final _quantityFocus = FocusNode();

  // Dropdown data loaded from database
  List<String> _categories = [];
  List<String> _warehouses = [];
  List<String> _suppliers = [];

  String? _selectedCategory;
  String? _selectedWarehouse;
  String? _selectedSupplier;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;

    // Initialize controllers
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _specificationsController =
        TextEditingController(text: widget.product?.specifications ?? '');
    _purchasePriceController = TextEditingController(
        text: widget.product?.purchasePrice.toString() ?? '');
    _retailPriceController = TextEditingController(
        text: widget.product?.retailPrice.toString() ?? '');
    _wholesalePriceController = TextEditingController(
        text: widget.product?.wholesalePrice.toString() ?? '');
    _bulkWholesalePriceController = TextEditingController(
        text: widget.product?.bulkWholesalePrice.toString() ?? '');
    _quantityController =
        TextEditingController(text: widget.product?.quantity.toString() ?? '');

    _selectedCategory = widget.product?.category;
    _selectedWarehouse = widget.product?.warehouse;
    _selectedSupplier = widget.product?.supplierName;
    if (widget.product != null) {
      _selectedDate = widget.product!.dateAdded;
      _selectedTime = TimeOfDay(
        hour: widget.product!.dateAdded.hour,
        minute: widget.product!.dateAdded.minute,
      );
    }
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    final db = await _dbHelper.database;

    // Load categories
    final categoriesResult = await db.query('categories', orderBy: 'name ASC');

    // Load warehouses
    final warehousesResult = await db.query('warehouses', orderBy: 'name ASC');

    // Load suppliers
    final suppliersResult = await db.query('suppliers', orderBy: 'name ASC');

    setState(() {
      _categories =
          categoriesResult.map((cat) => cat['name'].toString()).toList();
      _warehouses = warehousesResult
          .map((warehouse) => warehouse['name'].toString())
          .toList();
      _suppliers = suppliersResult
          .map((supplier) => supplier['name'].toString())
          .toList();
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _specificationsController.dispose();
    _purchasePriceController.dispose();
    _retailPriceController.dispose();
    _wholesalePriceController.dispose();
    _bulkWholesalePriceController.dispose();
    _quantityController.dispose();

    // Dispose focus nodes
    _nameFocus.dispose();
    _categoryFocus.dispose();
    _warehouseFocus.dispose();
    _supplierFocus.dispose();
    _specificationsFocus.dispose();
    _purchasePriceFocus.dispose();
    _retailPriceFocus.dispose();
    _wholesalePriceFocus.dispose();
    _bulkWholesalePriceFocus.dispose();
    _quantityFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل منتج' : 'إضافة منتج جديد',
          style: TextStyle(fontSize: Responsive.font(20)),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxHeight > 650;

          return Form(
            key: _formKey,
            child: isLargeScreen
                ? _buildLargeScreenLayout()
                : _buildSmallScreenLayout(),
          );
        },
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Padding(
      padding: Responsive.paddingAll(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: Responsive.paddingSym(h: 12, v: 8),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, color: Colors.blue[700], size: 20),
                  Responsive.hBox(8),
                  Text(
                    _isEditing ? 'تعديل منتج' : 'منتج جديد',
                    style: TextStyle(
                      fontSize: Responsive.font(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Responsive.vBox(8),
          Expanded(
            child: _buildCompactLayout(),
          ),
          Responsive.vBox(8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('إلغاء', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              Responsive.hBox(12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saveProduct,
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(
                    _isEditing ? 'حفظ التعديلات' : 'إضافة المنتج',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallScreenLayout() {
    return SingleChildScrollView(
      padding: Responsive.paddingAll(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
            ),
            child: Padding(
              padding: Responsive.paddingAll(20),
              child: Row(
                children: [
                  Container(
                    padding: Responsive.paddingAll(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius:
                          BorderRadius.circular(Responsive.radius(10)),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.blue[700],
                      size: Responsive.icon(32),
                    ),
                  ),
                  Responsive.hBox(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'تعديل بيانات المنتج' : 'منتج جديد',
                          style: TextStyle(
                            fontSize: Responsive.font(20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Responsive.vBox(4),
                        Text(
                          'الرجاء ملء جميع الحقول المطلوبة',
                          style: TextStyle(
                            fontSize: Responsive.font(14),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Responsive.vBox(24),
          _buildNormalLayout(),
          Responsive.vBox(24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: Responsive.icon(18)),
                  label: Text('إلغاء',
                      style: TextStyle(fontSize: Responsive.font(14))),
                  style: OutlinedButton.styleFrom(
                    padding: Responsive.paddingSym(v: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Responsive.radius(12)),
                    ),
                  ),
                ),
              ),
              Responsive.hBox(16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saveProduct,
                  icon: Icon(Icons.check, size: Responsive.icon(18)),
                  label: Text(
                    _isEditing ? 'حفظ التعديلات' : 'إضافة المنتج',
                    style: TextStyle(fontSize: Responsive.font(14)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: Responsive.paddingSym(v: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Responsive.radius(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildCompactSectionCard(
                title: 'المعلومات الأساسية',
                icon: Icons.info_outline,
                color: Colors.blue,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    nextFocus: _categoryFocus,
                    label: 'اسم المنتج',
                    icon: Icons.inventory_2,
                    hint: 'أدخل اسم المنتج',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال اسم المنتج';
                      }
                      return null;
                    },
                    autofocus: true,
                  ),
                  Responsive.vBox(12),
                  _buildSearchableDropdown(
                    label: 'الصنف',
                    icon: Icons.category,
                    selectedItem: _selectedCategory,
                    items: _categories,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء اختيار الصنف';
                      }
                      return null;
                    },
                    hint: 'ابحث عن الصنف...',
                  ),
                  Responsive.vBox(12),
                  _buildSearchableDropdown(
                    label: 'المخزن',
                    icon: Icons.warehouse,
                    selectedItem: _selectedWarehouse,
                    items: _warehouses,
                    onChanged: (value) {
                      setState(() {
                        _selectedWarehouse = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء اختيار المخزن';
                      }
                      return null;
                    },
                    hint: 'ابحث عن المخزن...',
                  ),
                  Responsive.vBox(12),
                  _buildSearchableDropdown(
                    label: 'المورد',
                    icon: Icons.store,
                    selectedItem: _selectedSupplier,
                    items: _suppliers,
                    onChanged: (value) {
                      setState(() {
                        _selectedSupplier = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء اختيار المورد';
                      }
                      return null;
                    },
                    hint: 'ابحث عن المورد...',
                  ),
                ],
              ),
              Responsive.vBox(12),
              _buildCompactSectionCard(
                title: 'المخزون',
                icon: Icons.inventory,
                color: Colors.purple,
                children: [
                  _buildTextField(
                    controller: _quantityController,
                    focusNode: _quantityFocus,
                    label: 'الكمية المتاحة',
                    icon: Icons.numbers,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال الكمية';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null) {
                        return 'رقم غير صحيح';
                      }
                      if (quantity < 0) {
                        return 'الكمية لا يمكن أن تكون سالبة';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _saveProduct(),
                  ),
                ],
              ),
            ],
          ),
        ),
        Responsive.hBox(12),
        Expanded(
          child: Column(
            children: [
              _buildCompactSectionCard(
                title: 'الأسعار',
                icon: Icons.attach_money,
                color: Colors.green,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _purchasePriceController,
                          focusNode: _purchasePriceFocus,
                          nextFocus: _retailPriceFocus,
                          label: 'سعر الشراء',
                          icon: Icons.shopping_cart,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'مطلوب';
                            if (double.tryParse(value) == null) {
                              return 'غير صحيح';
                            }
                            return null;
                          },
                          suffix: Text('جنيه',
                              style: TextStyle(fontSize: Responsive.font(12))),
                        ),
                      ),
                      Responsive.hBox(8),
                      Expanded(
                        child: _buildTextField(
                          controller: _retailPriceController,
                          focusNode: _retailPriceFocus,
                          nextFocus: _wholesalePriceFocus,
                          label: 'سعر البيع (فردي)',
                          icon: Icons.sell,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'مطلوب';
                            if (double.tryParse(value) == null) {
                              return 'غير صحيح';
                            }
                            return null;
                          },
                          suffix: Text('جنيه',
                              style: TextStyle(fontSize: Responsive.font(12))),
                        ),
                      ),
                    ],
                  ),
                  Responsive.vBox(12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _wholesalePriceController,
                          focusNode: _wholesalePriceFocus,
                          nextFocus: _bulkWholesalePriceFocus,
                          label: 'سعر الجملة',
                          icon: Icons.shopping_basket,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'مطلوب';
                            if (double.tryParse(value) == null) {
                              return 'غير صحيح';
                            }
                            return null;
                          },
                          suffix: Text('جنيه',
                              style: TextStyle(fontSize: Responsive.font(12))),
                        ),
                      ),
                      Responsive.hBox(8),
                      Expanded(
                        child: _buildTextField(
                          controller: _bulkWholesalePriceController,
                          focusNode: _bulkWholesalePriceFocus,
                          nextFocus: _quantityFocus,
                          label: 'سعر جملة الجملة',
                          icon: Icons.store,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'مطلوب';
                            if (double.tryParse(value) == null) {
                              return 'غير صحيح';
                            }
                            return null;
                          },
                          suffix: Text('جنيه',
                              style: TextStyle(fontSize: Responsive.font(12))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Responsive.vBox(12),
              _buildCompactSectionCard(
                title: 'المواصفات',
                icon: Icons.description,
                color: Colors.orange,
                children: [
                  _buildTextField(
                    controller: _specificationsController,
                    focusNode: _specificationsFocus,
                    nextFocus: _purchasePriceFocus,
                    label: 'المواصفات',
                    icon: Icons.description,
                    hint: 'أدخل مواصفات المنتج',
                    maxLines: 2,
                  ),
                ],
              ),
              Responsive.vBox(18),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showDateTimePicker = !_showDateTimePicker;
                    });
                  },
                  icon: Icon(
                    _showDateTimePicker ? Icons.expand_less : Icons.access_time,
                    size: Responsive.icon(25),
                  ),
                  label: Text(
                    _showDateTimePicker ? 'إخفاء' : 'تخصيص التاريخ',
                    style: TextStyle(fontSize: Responsive.font(20)),
                  ),
                ),
              ),
              if (_showDateTimePicker) _buildDateTimeSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNormalLayout() {
    return Column(
      children: [
        _buildSectionCard(
          title: 'المعلومات الأساسية',
          icon: Icons.info_outline,
          color: Colors.blue,
          children: [
            _buildTextField(
              controller: _nameController,
              focusNode: _nameFocus,
              nextFocus: _categoryFocus,
              label: 'اسم المنتج',
              icon: Icons.inventory_2,
              hint: 'أدخل اسم المنتج',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال اسم المنتج';
                }
                return null;
              },
              autofocus: true,
            ),
            Responsive.vBox(16),
            _buildSearchableDropdown(
              label: 'الصنف',
              icon: Icons.category,
              selectedItem: _selectedCategory,
              items: _categories,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء اختيار الصنف';
                }
                return null;
              },
              hint: 'ابحث عن الصنف أو اختر من القائمة',
            ),
            Responsive.vBox(16),
            _buildSearchableDropdown(
              label: 'المخزن',
              icon: Icons.warehouse,
              selectedItem: _selectedWarehouse,
              items: _warehouses,
              onChanged: (value) {
                setState(() {
                  _selectedWarehouse = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء اختيار المخزن';
                }
                return null;
              },
              hint: 'ابحث عن المخزن أو اختر من القائمة',
            ),
            Responsive.vBox(16),
            _buildSearchableDropdown(
              label: 'المورد',
              icon: Icons.store,
              selectedItem: _selectedSupplier,
              items: _suppliers,
              onChanged: (value) {
                setState(() {
                  _selectedSupplier = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء اختيار المورد';
                }
                return null;
              },
              hint: 'ابحث عن المورد أو اختر من القائمة',
            ),
            Responsive.vBox(16),
            _buildTextField(
              controller: _specificationsController,
              focusNode: _specificationsFocus,
              nextFocus: _purchasePriceFocus,
              label: 'المواصفات',
              icon: Icons.description,
              hint: 'أدخل مواصفات المنتج',
              maxLines: 3,
            ),
          ],
        ),
        Responsive.vBox(24),
        _buildSectionCard(
          title: 'الأسعار',
          icon: Icons.attach_money,
          color: Colors.green,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _purchasePriceController,
                    focusNode: _purchasePriceFocus,
                    nextFocus: _retailPriceFocus,
                    label: 'سعر الشراء',
                    icon: Icons.shopping_cart,
                    hint: '0.00',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'مطلوب';
                      }
                      if (double.tryParse(value) == null) {
                        return 'رقم غير صحيح';
                      }
                      return null;
                    },
                    suffix: Text('جنيه',
                        style: TextStyle(fontSize: Responsive.font(14))),
                  ),
                ),
                Responsive.hBox(12),
                Expanded(
                  child: _buildTextField(
                    controller: _retailPriceController,
                    focusNode: _retailPriceFocus,
                    nextFocus: _wholesalePriceFocus,
                    label: 'سعر البيع (فردي)',
                    icon: Icons.sell,
                    hint: '0.00',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'مطلوب';
                      }
                      if (double.tryParse(value) == null) {
                        return 'رقم غير صحيح';
                      }
                      return null;
                    },
                    suffix: Text('جنيه',
                        style: TextStyle(fontSize: Responsive.font(14))),
                  ),
                ),
              ],
            ),
            Responsive.vBox(16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _wholesalePriceController,
                    focusNode: _wholesalePriceFocus,
                    nextFocus: _bulkWholesalePriceFocus,
                    label: 'سعر الجملة',
                    icon: Icons.shopping_basket,
                    hint: '0.00',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'مطلوب';
                      }
                      if (double.tryParse(value) == null) {
                        return 'رقم غير صحيح';
                      }
                      return null;
                    },
                    suffix: Text('جنيه',
                        style: TextStyle(fontSize: Responsive.font(14))),
                  ),
                ),
                Responsive.hBox(12),
                Expanded(
                  child: _buildTextField(
                    controller: _bulkWholesalePriceController,
                    focusNode: _bulkWholesalePriceFocus,
                    nextFocus: _quantityFocus,
                    label: 'سعر جملة الجملة',
                    icon: Icons.store,
                    hint: '0.00',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'مطلوب';
                      }
                      if (double.tryParse(value) == null) {
                        return 'رقم غير صحيح';
                      }
                      return null;
                    },
                    suffix: Text('جنيه',
                        style: TextStyle(fontSize: Responsive.font(14))),
                  ),
                ),
              ],
            ),
          ],
        ),
        Responsive.vBox(24),
        _buildSectionCard(
          title: 'المخزون',
          icon: Icons.inventory,
          color: Colors.purple,
          children: [
            _buildTextField(
              controller: _quantityController,
              focusNode: _quantityFocus,
              label: 'الكمية المتاحة',
              icon: Icons.numbers,
              hint: '0',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال الكمية';
                }
                if (int.tryParse(value) == null) {
                  return 'رقم غير صحيح';
                }
                return null;
              },
              onFieldSubmitted: (_) => _saveProduct(),
            ),
          ],
        ),
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _showDateTimePicker = !_showDateTimePicker;
              });
            },
            icon: Icon(
              _showDateTimePicker ? Icons.expand_less : Icons.access_time,
              size: Responsive.icon(30),
            ),
            label: Text(
              _showDateTimePicker
                  ? 'إخفاء خيارات التاريخ والوقت'
                  : 'تخصيص تاريخ ووقت التسجيل',
              style: TextStyle(fontSize: Responsive.font(14)),
            ),
          ),
        ),
        if (_showDateTimePicker) ...[
          Responsive.vBox(16),
          _buildDateTimeSection(),
        ],
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return _buildCompactSectionCard(
      title: 'تاريخ ووقت التسجيل',
      icon: Icons.access_time,
      color: Colors.indigo,
      children: [
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
                  padding: Responsive.paddingAll(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(Responsive.radius(10)),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: Colors.indigo, size: Responsive.icon(16)),
                      Responsive.hBox(8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('التاريخ',
                                style: TextStyle(
                                    fontSize: Responsive.font(10),
                                    color: Colors.grey[600])),
                            Responsive.vBox(2),
                            Text(
                              _selectedDate != null
                                  ? DateFormat('yyyy-MM-dd')
                                      .format(_selectedDate!)
                                  : 'اختر التاريخ',
                              style: TextStyle(
                                  fontSize: Responsive.font(13),
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Responsive.hBox(8),
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
                  padding: Responsive.paddingAll(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(Responsive.radius(10)),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: Colors.indigo, size: Responsive.icon(16)),
                      Responsive.hBox(8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('الوقت',
                                style: TextStyle(
                                    fontSize: Responsive.font(10),
                                    color: Colors.grey[600])),
                            Responsive.vBox(2),
                            Text(
                              _selectedTime != null
                                  ? _selectedTime!.format(context)
                                  : 'اختر الوقت',
                              style: TextStyle(
                                  fontSize: Responsive.font(13),
                                  fontWeight: FontWeight.bold),
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
        Responsive.vBox(8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedDate = null;
                _selectedTime = null;
              });
            },
            icon: Icon(Icons.refresh, size: Responsive.icon(14)),
            label: Text('مسح التخصيص',
                style: TextStyle(fontSize: Responsive.font(11))),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
      ),
      child: Padding(
        padding: Responsive.paddingAll(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: Responsive.icon(18)),
                Responsive.hBox(8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.font(14),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Responsive.vBox(12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
      ),
      child: Padding(
        padding: Responsive.paddingAll(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: Responsive.icon(24)),
                Responsive.hBox(12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.font(18),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Responsive.vBox(20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    Widget? suffix,
    bool autofocus = false,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: Responsive.font(14)),
        hintText: hint,
        hintStyle: TextStyle(fontSize: Responsive.font(14)),
        prefixIcon: Icon(icon, size: Responsive.icon(20)),
        suffix: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: Responsive.paddingSym(h: 16, v: 16),
      ),
      style: TextStyle(fontSize: Responsive.font(15)),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted ??
          (nextFocus != null ? (_) => nextFocus.requestFocus() : null),
    );
  }

  // ⭐ الدالة الجديدة للـ Dropdown Search
  Widget _buildSearchableDropdown({
    required String label,
    required IconData icon,
    String? selectedItem,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return DropdownSearch<String>(
      items: items,
      selectedItem: selectedItem,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: Responsive.font(14)),
          hintText: hint ?? 'اختر من القائمة',
          hintStyle: TextStyle(
            fontSize: Responsive.font(14),
            color: Colors.grey[400],
          ),
          prefixIcon: Icon(icon, size: Responsive.icon(20)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: Responsive.paddingSym(h: 16, v: 16),
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'ابحث...',
            hintStyle: TextStyle(fontSize: Responsive.font(14)),
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(10)),
            ),
            contentPadding: Responsive.paddingSym(h: 12, v: 12),
          ),
          style: TextStyle(fontSize: Responsive.font(15)),
        ),
        menuProps: MenuProps(
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          elevation: 8,
        ),
        itemBuilder: (context, item, isSelected) {
          return Container(
            padding: Responsive.paddingSym(h: 16, v: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : null,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                if (isSelected)
                  Icon(Icons.check_circle,
                      color: Colors.blue[700], size: Responsive.icon(20)),
                if (isSelected) Responsive.hBox(8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: Responsive.font(15),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue[700] : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        fit: FlexFit.loose,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        emptyBuilder: (context, searchEntry) => Center(
          child: Padding(
            padding: Responsive.paddingAll(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off,
                    size: Responsive.icon(48), color: Colors.grey[400]),
                Responsive.vBox(12),
                Text(
                  'لا توجد نتائج',
                  style: TextStyle(
                    fontSize: Responsive.font(16),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }

  void _saveProduct() async {
    if (_isEditing) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => const PasswordDialog(
          title: 'تأكيد التعديل',
          message: 'أدخل كلمة السر لتعديل المنتج',
        ),
      );

      if (confirmed != true) return;
    }

    if (_formKey.currentState!.validate()) {
      DateTime finalDateTime;
      if (_selectedDate != null || _selectedTime != null) {
        final now = DateTime.now();
        final date = _selectedDate ?? now;
        final time = _selectedTime ?? TimeOfDay.fromDateTime(now);
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

      final product = Product(
        id: _isEditing ? widget.product!.id : null,
        name: _nameController.text,
        category: _selectedCategory,
        warehouse: _selectedWarehouse,
        supplierName: _selectedSupplier!,
        specifications: _specificationsController.text.isNotEmpty
            ? _specificationsController.text
            : null,
        purchasePrice: double.parse(_purchasePriceController.text),
        retailPrice: double.parse(_retailPriceController.text),
        wholesalePrice: double.parse(_wholesalePriceController.text),
        bulkWholesalePrice: double.parse(_bulkWholesalePriceController.text),
        quantity: int.parse(_quantityController.text),
        dateAdded: finalDateTime,
      );
      if (!mounted) return;
      final provider = Provider.of<ProductProvider>(context, listen: false);

      try {
        if (_isEditing) {
          await provider.updateProduct(product);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'تم تحديث المنتج بنجاح',
                    style: TextStyle(fontSize: Responsive.font(14)),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          await provider.addProduct(product);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'تم إضافة المنتج بنجاح',
                    style: TextStyle(fontSize: Responsive.font(14)),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        final errorMessage = e.toString().replaceAll('Exception: ', '');

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange[700], size: 30),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'تنبيه',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                errorMessage,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      }
    }
  }
}
