// lib/providers/product_provider.dart (COMPLETE - مع جميع الدوال المطلوبة)

import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/sale_transaction.dart';
import '../models/inventory_transaction.dart';
import '../services/database_helper.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<SaleTransaction> _sales = [];
  List<InventoryTransaction> _inventoryTransactions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _errorMessage;
  bool _isInitialized = false;

  List<Product> get products => _searchQuery.isEmpty
      ? _products
      : _products.where((product) {
          final query = _searchQuery.toLowerCase();
          return product.name.toLowerCase().contains(query) ||
              (product.specifications?.toLowerCase().contains(query) ??
                  false) ||
              product.supplierName.toLowerCase().contains(query);
        }).toList();

  List<SaleTransaction> get sales => _sales;
  List<InventoryTransaction> get inventoryTransactions =>
      _inventoryTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  int get totalProducts => _products.length;
  int get totalQuantityInStock =>
      _products.fold<int>(0, (sum, p) => sum + p.quantity);
  double get totalInventoryValue => _products.fold<double>(
        0,
        (sum, p) => sum + (p.purchasePrice * p.quantity),
      );

  ProductProvider() {
    _initializeData();
  }

  /// FIX: Defer all initialization to avoid build phase issues
  void _initializeData() {
    Future.delayed(Duration.zero, () async {
      try {
        _isLoading = true;
        notifyListeners();

        await fetchProducts();
        await fetchSales();
        await fetchInventoryTransactions();

        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        debugPrint('Error initializing data: $e');
        _isLoading = false;
        _isInitialized = false;
        notifyListeners();
      }
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final productsData = await dbHelper.getProducts();
      _products = productsData.map((data) => Product.fromMap(data)).toList();
      debugPrint('Fetched ${productsData.length} products');
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      _products = [];
      _errorMessage = 'فشل في جلب المنتجات: $e';
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      if (product.name.isEmpty) throw Exception('اسم المنتج مطلوب');
      if (product.supplierName.isEmpty) throw Exception('اسم المورد مطلوب');
      if (product.quantity < 0) {
        throw Exception('الكمية يجب أن تكون رقم إيجابي');
      }

      if (product.purchasePrice <= 0 ||
          product.retailPrice <= 0 ||
          product.wholesalePrice <= 0 ||
          product.bulkWholesalePrice <= 0) {
        throw Exception('الأسعار يجب أن تكون أرقام موجبة');
      }

      final dbHelper = DatabaseHelper.instance;

      // ⭐ 1. توليد كود الشحنة
      final batchCode =
          await dbHelper.generateBatchCode(product.category, product.dateAdded);
      // ⭐⭐⭐ 2. إضافة منتج جديد دائماً (لا نبحث عن منتج مشابه)
      final productMap = product.toMap();
      productMap['dateAdded'] = product.dateAdded.toIso8601String();
      productMap['batchCode'] = batchCode; // ⭐ حفظ الكود في المنتج نفسه

      final productId = await dbHelper.insertProduct(productMap);
      if (productId == -1) throw Exception('فشل في إدراج المنتج');

      debugPrint('✅ منتج جديد: ${product.name}');

      // ⭐ 4. إضافة المنتج للقائمة المحلية
      final newProduct = product.copyWith(id: productId, batchCode: batchCode);
      _products.add(newProduct);

      // ⭐ 5. تسجيل حركة المخزون
      final inventoryTx = InventoryTransaction(
        productId: productId,
        productName: product.name,
        transactionType: 'إضافة شحنة',
        quantityChange: product.quantity,
        quantityAfter: product.quantity,
        notes:
            'شحنة: $batchCode | من ${product.supplierName} | سعر: ${product.purchasePrice.toStringAsFixed(2)} ج',
        dateTime: product.dateAdded,
      );

      final txId =
          await dbHelper.insertInventoryTransaction(inventoryTx.toMap());
      if (txId != -1) {
        _inventoryTransactions.add(inventoryTx.copyWith(id: txId));
      }

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'فشل في إضافة المنتج: $e';
      notifyListeners();
      rethrow;
    }
  }

// ⭐ دالة تحديث المنتج مع الحماية - FIXED
  Future<void> updateProduct(Product product) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      // جلب المنتج القديم
      final oldProduct = _products.firstWhere(
        (p) => p.id == product.id,
        orElse: () => throw Exception('المنتج غير موجود في القائمة'),
      );

      // ⭐ الحفاظ على batchCode الأصلي
      final productToUpdate = product.copyWith(
        batchCode: oldProduct.batchCode, // ⭐ نستخدم الكود القديم دائماً
      );

      // ⭐⭐⭐ منع الكمية السالبة
      if (productToUpdate.quantity < 0) {
        throw Exception(
          '❌ لا يمكن تعديل الكمية لرقم سالب\n\n'
          '💡 الحل:\n'
          '• أدخل كمية موجبة (0 أو أكثر)\n'
          '• إذا كنت تريد تقليل الكمية، أدخل الرقم الصحيح',
        );
      }

      // ⭐ التحقق من وجود مبيعات أو حركات مخزون
      final sales = await dbHelper.getSales();
      final hasSales = sales.any((s) => s['productId'] == product.id);

      final transactions = await dbHelper.getAllInventoryTransactions();
      final hasTransactions = transactions
          .where((t) => t['productId'] == product.id)
          .any((t) =>
              t['transactionType'] == 'بيع' ||
              t['transactionType'] == 'استرجاع من بيع');

      // ⭐ إذا كان له مبيعات أو حركات، امنع تعديل البيانات الحساسة
      if (hasSales || hasTransactions) {
        // التحقق من تعديل الاسم
        if (oldProduct.name != productToUpdate.name) {
          throw Exception(
            '❌ لا يمكن تعديل اسم المنتج\n\n'
            'السبب: المنتج له ${hasSales ? "مبيعات" : "حركات"} مسجلة\n\n'
            '💡 الحل:\n'
            '• إذا كان خطأ إملائي بسيط، يمكنك تعديل المواصفات\n'
            '• أو إضافة منتج جديد بالاسم الصحيح',
          );
        }

        // التحقق من تعديل سعر الشراء
        if (oldProduct.purchasePrice != productToUpdate.purchasePrice) {
          throw Exception(
            '❌ لا يمكن تعديل سعر الشراء\n\n'
            'السبب: المنتج له ${hasSales ? "مبيعات" : "حركات"} مسجلة\n'
            'سيؤدي التعديل إلى:\n'
            '• حسابات خاطئة للأرباح\n'
            '• قيمة مخزون غير دقيقة\n\n'
            '💡 الحل:\n'
            '• إذا تغير السعر، أضف المنتج بسعر الشراء الجديد\n'
            '• أو استمر باستخدام المنتج الحالي',
          );
        }

        // التحقق من تعديل الصنف
        if (oldProduct.category != productToUpdate.category) {
          throw Exception(
            '❌ لا يمكن تعديل الصنف\n\n'
            'السبب: المنتج له ${hasSales ? "مبيعات" : "حركات"} مسجلة\n\n'
            '💡 الحل:\n'
            '• إضافة منتج جديد بالصنف الصحيح',
          );
        }

        // التحقق من تعديل المورد
        if (oldProduct.supplierName != productToUpdate.supplierName) {
          throw Exception(
            '❌ لا يمكن تعديل المورد\n\n'
            'السبب: المنتج له ${hasSales ? "مبيعات" : "حركات"} مسجلة\n\n'
            '💡 الحل:\n'
            '• إضافة منتج جديد من المورد الجديد',
          );
        }

        // التحقق من تعديل المخزن
        if (oldProduct.warehouse != productToUpdate.warehouse) {
          throw Exception(
            '❌ لا يمكن تعديل المخزن\n\n'
            'السبب: المنتج له ${hasSales ? "مبيعات" : "حركات"} مسجلة\n\n'
            '💡 الحل:\n'
            '• نقل الكمية إلى مخزن آخر بعملية مخزون منفصلة',
          );
        }

        // ⚠️ تحذير عند تعديل أسعار البيع
        if (oldProduct.retailPrice != productToUpdate.retailPrice ||
            oldProduct.wholesalePrice != productToUpdate.wholesalePrice ||
            oldProduct.bulkWholesalePrice !=
                productToUpdate.bulkWholesalePrice) {
          debugPrint(
            '⚠️ تحذير: تم تعديل أسعار البيع\n'
            'ملاحظة: التعديل لن يؤثر على المبيعات السابقة',
          );
        }
      }

      // تسجيل تغيير الكمية في حركة المخزون
      if (oldProduct.quantity != productToUpdate.quantity) {
        final quantityChange = productToUpdate.quantity - oldProduct.quantity;
        final transactionType = quantityChange > 0 ? 'زيادة' : 'نقصان';

        final inventoryTx = InventoryTransaction(
          productId: productToUpdate.id!,
          productName: productToUpdate.name,
          transactionType: transactionType,
          quantityChange: quantityChange,
          quantityAfter: productToUpdate.quantity,
          notes: 'تعديل كمية المنتج',
          dateTime: DateTime.now(),
        );

        final txId = await dbHelper.insertInventoryTransaction(
          inventoryTx.toMap(),
        );
        if (txId == -1) throw Exception('فشل في إدراج معاملة المخزون');
        _inventoryTransactions.add(inventoryTx.copyWith(id: txId));
      }

      // ⭐⭐⭐ تحديث في قاعدة البيانات باستخدام المنتج المحدث
      await dbHelper.updateProduct(
          productToUpdate.id!, productToUpdate.toMap());

      // ⭐⭐⭐ تحديث في الذاكرة باستخدام المنتج المحدث (مع الـ batchCode)
      final index = _products.indexWhere((p) => p.id == productToUpdate.id);
      if (index != -1) {
        _products[index] = productToUpdate; // ⭐ هنا كان الخطأ
      }

      _errorMessage = null;
      notifyListeners();

      debugPrint('✅ تم تحديث المنتج بنجاح: ${productToUpdate.name}');
      debugPrint('   - Batch Code: ${productToUpdate.batchCode}');
      debugPrint('   - الكمية الجديدة: ${productToUpdate.quantity}');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث المنتج: $e');
      _errorMessage = 'فشل في تحديث المنتج: $e';
      notifyListeners();
      rethrow;
    }
  }

// ⭐ في ملف product_provider.dart
// استبدل الجزء ده من دالة deleteProduct:

  Future<void> deleteProduct(int id) async {
    try {
      final dbHelper = DatabaseHelper.instance;

      // جلب اسم المنتج للرسائل
      final product = _products.firstWhere(
        (p) => p.id == id,
        orElse: () => throw Exception('المنتج غير موجود'),
      );

      // ⭐ التحقق من المبيعات
      final sales = await dbHelper.getSales();
      final productSales = sales.where((s) => s['productId'] == id).toList();

      if (productSales.isNotEmpty) {
        throw Exception(
          '❌ لا يمكن حذف المنتج "${product.name}"\n\n'
          '📊 المنتج له مبيعات مسجلة:\n'
          '1️⃣ تصفير الكمية المتاحة (الموصى به)\n'
          '2️⃣ إضافة ملاحظة في المواصفات\n'
          '3️⃣ الاحتفاظ بالمنتج في النظام',
        );
      }

      // ⭐⭐⭐ التحقق الصحيح من معاملات المندوبين
      // نتأكد إن المنتج نفسه موجود في المعاملات (مش بس التشابه في الاسم)
      final repTransactions = await dbHelper.getAllRepresentativeTransactions();
      bool hasActualRepTransactions = false;

      for (var transaction in repTransactions) {
        final saleIds = transaction['saleIds'] as String?;
        if (saleIds != null && saleIds.isNotEmpty) {
          final saleIdsList = saleIds
              .split(',')
              .map((e) => int.tryParse(e.trim()))
              .whereType<int>()
              .toList();
          // التحقق من إن المبيعات المرتبطة بالمعاملة تخص هذا المنتج
          final relatedSales =
              productSales.where((s) => saleIdsList.contains(s['id']));
          if (relatedSales.isNotEmpty) {
            hasActualRepTransactions = true;
            break;
          }
        }
      }

      if (hasActualRepTransactions) {
        throw Exception(
          '❌ لا يمكن حذف المنتج "${product.name}"\n\n'
          '👥 المنتج مرتبط بمعاملات مندوبين/عملاء\n\n'
          '💡 الحل:\n'
          '• الاحتفاظ بالمنتج في النظام',
        );
      }

      // ⭐⭐⭐ 1. تسجيل حركة الحذف في المخزون
      final inventoryTx = InventoryTransaction(
        productId: product.id!,
        productName: product.name,
        transactionType: 'حذف منتج',
        quantityChange: -product.quantity,
        quantityAfter: 0,
        notes:
            'تم حذف المنتج نهائياً من النظام | الكمية المحذوفة: ${product.quantity} | المورد: ${product.supplierName}',
        dateTime: DateTime.now(),
      );

      final txId =
          await dbHelper.insertInventoryTransaction(inventoryTx.toMap());
      if (txId != -1) {
        _inventoryTransactions.add(inventoryTx.copyWith(id: txId));
        debugPrint('✅ تم تسجيل حركة حذف المنتج');
      }

      // ⭐⭐⭐ 2. حذف المنتج من قاعدة البيانات
      final result = await dbHelper.deleteProduct(id);

      if (result == 0) {
        throw Exception('فشل في حذف المنتج: لم يتم العثور على المنتج');
      }

      _products.removeWhere((p) => p.id == id);
      _errorMessage = null;
      notifyListeners();

      debugPrint('✅ تم حذف المنتج بنجاح: ${product.name}');
    } catch (e) {
      debugPrint('❌ خطأ في حذف المنتج: $e');
      _errorMessage = 'فشل في حذف المنتج: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sellProductWithCustomPrice(
    Product product,
    int quantity,
    String customerName,
    double customPrice,
    String notes, {
    DateTime? saleDateTime,
  }) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      final actualPurchasePrice = product.purchasePrice;

      final sale = SaleTransaction(
        productId: product.id!,
        productName: product.name,
        priceType: 'مخصص',
        unitPrice: customPrice,
        purchasePrice: actualPurchasePrice,
        quantitySold: quantity,
        quantityRemainingInStock: 0, // هنحدثها بعدين
        customerName: customerName,
        supplierName: product.supplierName,
        saleDateTime: saleDateTime ?? DateTime.now(),
        notes: notes,
        paymentType: 'نقد',
      );

      await db.transaction((txn) async {
        // ⭐⭐⭐ 1. جلب الكمية الحالية من قاعدة البيانات (مش من الـ object)
        final currentProduct = await txn.query(
          'products',
          columns: ['quantity'],
          where: 'id = ?',
          whereArgs: [product.id],
          limit: 1,
        );

        if (currentProduct.isEmpty) {
          throw Exception('المنتج غير موجود');
        }

        final currentQuantity = currentProduct.first['quantity'] as int;

        // ⭐⭐⭐ 2. التحقق من الكمية المتاحة
        if (quantity > currentQuantity) {
          throw Exception(
            'الكمية المطلوبة ($quantity) أكبر من المتاح ($currentQuantity) لـ ${product.name}',
          );
        }

        // ⭐⭐⭐ 3. حساب الكمية الجديدة
        final newQuantity = currentQuantity - quantity;

        // 4. تسجيل البيع
        final saleId = await txn.insert('sales', sale.toMap());
        if (saleId == -1) {
          throw Exception('فشل في تسجيل البيع');
        }

        // 5. تحديث الكمية
        await txn.update(
          'products',
          {'quantity': newQuantity},
          where: 'id = ?',
          whereArgs: [product.id],
        );

        // 6. تسجيل حركة المخزون
        final inventoryTx = InventoryTransaction(
          productId: product.id!,
          productName: product.name,
          transactionType: 'بيع',
          quantityChange: -quantity,
          quantityAfter: newQuantity,
          relatedSaleId: saleId.toString(),
          notes: 'بيع لـ $customerName | ${notes.split('|').first.trim()}',
          dateTime: saleDateTime ?? DateTime.now(),
        );

        await txn.insert('inventory_transactions', inventoryTx.toMap());
        _inventoryTransactions.add(inventoryTx);
      });

      // تحديث القوائم المحلية
      _sales.add(sale);
      final productIndex = _products.indexWhere((p) => p.id == product.id);
      if (productIndex != -1) {
        // ⭐⭐⭐ جلب الكمية المحدثة من قاعدة البيانات
        final updatedProducts = await dbHelper.getProducts();
        final updatedProduct = updatedProducts.firstWhere(
          (p) => p['id'] == product.id,
          orElse: () => throw Exception('المنتج غير موجود بعد التحديث'),
        );
        _products[productIndex] = Product.fromMap(updatedProduct);
      }

      notifyListeners();
      debugPrint('✅ تم البيع بنجاح');
      debugPrint('   - المنتج: ${product.name}');
      debugPrint('   - الكمية: $quantity');
      debugPrint('   - سعر البيع: ${customPrice.toStringAsFixed(2)}');
    } catch (e) {
      debugPrint('❌ خطأ في البيع: $e');
      rethrow;
    }
  }

  Future<void> returnProduct(
    Product product,
    int quantityReturned,
    String reason,
  ) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final productData = await dbHelper.getProducts();
      final exists = productData.any((p) => p['id'] == product.id);
      if (!exists) {
        throw Exception(
          'المنتج غير موجود في قاعدة البيانات (ID: ${product.id})',
        );
      }
      if (quantityReturned <= 0) {
        throw Exception('الكمية يجب أن تكون أكبر من 0');
      }

      final newQuantity = product.quantity + quantityReturned;
      debugPrint(
        'Updating product ID ${product.id} with new quantity: $newQuantity',
      );

      final updateResult = await dbHelper.updateProductQuantity(
        product.id!,
        newQuantity,
      );
      if (updateResult == 0) {
        throw Exception(
          'فشل في تحديث كمية المنتج: لم يتم العثور على المنتج (ID: ${product.id})',
        );
      }

      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product.copyWith(quantity: newQuantity);
      } else {
        await fetchProducts();
      }

      final inventoryTx = InventoryTransaction(
        productId: product.id!,
        productName: product.name,
        transactionType: 'استرجاع',
        quantityChange: quantityReturned,
        quantityAfter: newQuantity,
        notes: reason,
        dateTime: DateTime.now(),
      );

      final txId = await dbHelper.insertInventoryTransaction(
        inventoryTx.toMap(),
      );
      if (txId == -1) throw Exception('فشل في إدراج معاملة المخزون');

      _inventoryTransactions.add(inventoryTx.copyWith(id: txId));
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error returning product: $e');
      _errorMessage = 'فشل في تسجيل الاسترجاع: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> returnSale(
    int saleId,
    int quantityReturned,
    String reason,
  ) async {
    try {
      final dbHelper = DatabaseHelper.instance;

      final saleIndex = _sales.indexWhere((s) => s.id == saleId);
      if (saleIndex == -1) {
        throw Exception('البيع غير موجود');
      }

      final sale = _sales[saleIndex];
      final product = _products.firstWhere(
        (p) => p.id == sale.productId,
        orElse: () => throw Exception('المنتج غير موجود'),
      );

      if (quantityReturned > sale.quantitySold) {
        throw Exception(
          'كمية الاسترجاع لا يمكن أن تكون أكثر من الكمية المباعة (${sale.quantitySold})',
        );
      }

      if (quantityReturned <= 0) {
        throw Exception('كمية الاسترجاع يجب أن تكون أكبر من 0');
      }

      final newQuantity = product.quantity + quantityReturned;
      final updateResult = await dbHelper.updateProductQuantity(
        sale.productId,
        newQuantity,
      );
      if (updateResult == 0) {
        throw Exception('فشل في تحديث كمية المنتج');
      }

      final productIndex = _products.indexWhere((p) => p.id == sale.productId);
      if (productIndex != -1) {
        _products[productIndex] = product.copyWith(quantity: newQuantity);
      }

      // حذف أو تحديث البيع
      if (quantityReturned == sale.quantitySold) {
        final returnDetail = {
          'saleId': saleId,
          'productId': sale.productId,
          'productName': sale.productName,
          'quantityReturned': quantityReturned,
          'unitPrice': sale.unitPrice,
          'totalAmount': sale.unitPrice * quantityReturned,
          'returnDateTime': DateTime.now().toIso8601String(),
          'reason': reason,
          'representativeId': sale.representativeId,
        };

        await dbHelper.insertReturnDetail(returnDetail);
        debugPrint('✅ تم تسجيل المرتجع في return_details');
        await dbHelper.deleteSale(saleId);
        _sales.removeAt(saleIndex);
        debugPrint('تم حذف البيع رقم $saleId نهائياً');
      } else {
        final remainingQuantity = sale.quantitySold - quantityReturned;
        final updatedSale = sale.copyWith(
          quantitySold: remainingQuantity,
          quantityRemainingInStock:
              sale.quantityRemainingInStock + quantityReturned,
        );
        await dbHelper.updateSale(saleId, updatedSale.toMap());
        _sales[saleIndex] = updatedSale;
        debugPrint(
            'تم تحديث البيع رقم $saleId - الكمية المتبقية: $remainingQuantity');
      }

      // ⭐⭐⭐ استخراج معلومات الفاتورة
      final invoiceNumber = _extractInvoiceNumber(sale.notes);

      // ⭐⭐⭐ تسجيل الاسترجاع في حركة المخزون مع حفظ اسم العميل
      final inventoryTx = InventoryTransaction(
        productId: sale.productId,
        productName: sale.productName,
        transactionType: 'استرجاع من بيع',
        quantityChange: quantityReturned,
        quantityAfter: newQuantity,
        relatedSaleId: saleId.toString(),
        notes:
            'استرجاع من ${sale.customerName} | فاتورة: $invoiceNumber | السبب: $reason', // ⭐ استخدام sale.customerName مباشرة
        dateTime: DateTime.now(),
      );

      final txId = await dbHelper.insertInventoryTransaction(
        inventoryTx.toMap(),
      );
      if (txId == -1) throw Exception('فشل في تسجيل معاملة المخزون');

      _inventoryTransactions.add(inventoryTx.copyWith(id: txId));
      _errorMessage = null;
      notifyListeners();

      debugPrint(
          '✅ تم الاسترجاع بنجاح: $quantityReturned من ${sale.productName}');
    } catch (e) {
      debugPrint('Error returning sale: $e');
      _errorMessage = 'فشل في الاسترجاع: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ⭐ دالة حذف عملية بيع وإرجاع الكمية (NEW)
  // ═══════════════════════════════════════════════════════════════

  Future<void> deleteSale(int saleId) async {
    try {
      final dbHelper = DatabaseHelper.instance;

      // الحصول على بيانات البيع
      final sale = _sales.firstWhere(
        (s) => s.id == saleId,
        orElse: () => throw Exception('البيع غير موجود'),
      );

      // الحصول على المنتج وإرجاع الكمية
      final product = _products.firstWhere(
        (p) => p.id == sale.productId,
        orElse: () => throw Exception('المنتج غير موجود'),
      );

      final updatedQuantity = product.quantity + sale.quantitySold;

      // تحديث المنتج في قاعدة البيانات
      final updateResult = await dbHelper.updateProductQuantity(
        product.id!,
        updatedQuantity,
      );
      if (updateResult == 0) {
        throw Exception('فشل في تحديث كمية المنتج');
      }

      // تسجيل عملية الإرجاع في سجل المخزون
      final inventoryTx = InventoryTransaction(
        productId: product.id!,
        productName: product.name,
        transactionType: 'إلغاء بيع',
        quantityChange: sale.quantitySold,
        quantityAfter: updatedQuantity,
        notes: 'إلغاء فاتورة رقم: ${_extractInvoiceNumber(sale.notes)}',
        relatedSaleId: saleId.toString(),
        dateTime: DateTime.now(),
      );

      final txId = await dbHelper.insertInventoryTransaction(
        inventoryTx.toMap(),
      );
      if (txId == -1) throw Exception('فشل في تسجيل معاملة المخزون');

      // حذف البيع من قاعدة البيانات
      await dbHelper.deleteSale(saleId);

      // تحديث القوائم المحلية
      _sales.removeWhere((s) => s.id == saleId);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product.copyWith(quantity: updatedQuantity);
      }

      _inventoryTransactions.add(inventoryTx.copyWith(id: txId));
      _errorMessage = null;
      notifyListeners();

      debugPrint('✅ تم حذف البيع وإرجاع الكمية بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في حذف البيع: $e');
      _errorMessage = 'فشل في حذف البيع: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // دالة مساعدة: استخراج رقم الفاتورة
  // ═══════════════════════════════════════════════════════════════

  String _extractInvoiceNumber(String? notes) {
    if (notes == null || notes.isEmpty) return 'غير محدد';
    final match = RegExp(r'فاتورة:\s*(.+?)(?:\||$)').firstMatch(notes);
    return match?.group(1)?.trim() ?? 'غير محدد';
  }

  Future<void> fetchSales() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final salesData = await dbHelper.getSales();
      _sales = salesData.map((data) => SaleTransaction.fromMap(data)).toList();
      debugPrint('Fetched ${_sales.length} sales');
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching sales: $e');
      _sales = [];
      _errorMessage = 'فشل في جلب المبيعات: $e';
      notifyListeners();
    }
  }

  Future<void> fetchInventoryTransactions() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final txData = await dbHelper.getAllInventoryTransactions();
      _inventoryTransactions =
          txData.map((data) => InventoryTransaction.fromMap(data)).toList();
      debugPrint(
        'Fetched ${_inventoryTransactions.length} inventory transactions',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching inventory transactions: $e');
      _inventoryTransactions = [];
      _errorMessage = 'فشل في جلب معاملات المخزون: $e';
      notifyListeners();
    }
  }

  List<SaleTransaction> getRecentSales({int limit = 5}) {
    final sorted = List<SaleTransaction>.from(_sales)
      ..sort((a, b) => b.saleDateTime.compareTo(a.saleDateTime));
    return sorted.take(limit).toList();
  }

  double calculateTotalProfit() {
    final totalProfit = _sales.fold<double>(
      0,
      (sum, sale) =>
          sum + (sale.unitPrice - sale.purchasePrice) * sale.quantitySold,
    );
    debugPrint('Calculated total profit: $totalProfit');
    return totalProfit;
  }

  Future<void> refreshProducts() async {
    await fetchProducts();
  }

  // ═══════════════════════════════════════════════════════════════
  // دالة تحديث سجل المخزون (Helper)
  // ═══════════════════════════════════════════════════════════════

  Future<void> refreshInventoryTransactions() async {
    try {
      await fetchInventoryTransactions();
    } catch (e) {
      debugPrint('❌ خطأ في تحديث سجل المخزون: $e');
    }
  }

  // ⭐ دالة لتحديث الملاحظات القديمة في حركات المخزون
  Future<void> fixOldReturnTransactions() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      // جلب جميع المرتجعات
      final returns = await db.query(
        'inventory_transactions',
        where: 'transactionType = ?',
        whereArgs: ['استرجاع من بيع'],
      );

      for (var returnTx in returns) {
        final relatedSaleId = returnTx['relatedSaleId'] as String?;
        if (relatedSaleId == null) continue;

        // محاولة جلب البيع الأصلي
        final sales = await db.query(
          'sales',
          where: 'id = ?',
          whereArgs: [int.tryParse(relatedSaleId)],
          limit: 1,
        );

        if (sales.isNotEmpty) {
          final customerName = sales.first['customerName'] as String;
          final oldNotes = returnTx['notes'] as String?;

          // تحديث الملاحظات
          if (oldNotes != null &&
              !oldNotes.contains('استرجاع من $customerName')) {
            final newNotes = 'استرجاع من $customerName | $oldNotes';
            await db.update(
              'inventory_transactions',
              {'notes': newNotes},
              where: 'id = ?',
              whereArgs: [returnTx['id']],
            );
          }
        }
      }

      debugPrint('✅ تم تحديث الملاحظات القديمة');
      await fetchInventoryTransactions();
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الملاحظات: $e');
    }
  }

  // ⭐ بعد fetchSales()
  Future<List<Map<String, dynamic>>> getProductSalesDetails(
      int productId) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      return await dbHelper.getSalesWithReturns(productId);
    } catch (e) {
      debugPrint('Error getting product sales details: $e');
      return [];
    }
  }
}
