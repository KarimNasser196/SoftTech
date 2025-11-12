// lib/services/database_helper.dart (UPDATED WITH REPRESENTATIVES & CUSTOMERS)

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory_management.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, filePath);
    debugPrint('Database path: $path');

    try {
      if (Platform.isWindows) {
        sqfliteFfiInit();
        final databaseFactory = databaseFactoryFfi;
        return await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 16, // ⭐ تم تحديث النسخة
            onCreate: _createDB,
            onUpgrade: _upgradeDB,
          ),
        );
      } else {
        throw UnsupportedError('This app is only supported on Windows desktop');
      }
    } catch (e) {
      debugPrint('Error opening database: $e');
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    debugPrint('Creating database tables...');

    try {
      // جدول المنتجات
      await db.execute('''
CREATE TABLE products (
  id $idType,
  name $textType,
  category $textNullableType,
  warehouse $textNullableType,
  specifications $textNullableType,
  purchasePrice $realType,
  retailPrice $realType,
  wholesalePrice $realType,
  bulkWholesalePrice $realType,
  supplierName $textType,
  quantity $integerType,
  batchCode $textNullableType,
  dateAdded $textType,
  notes $textNullableType
)
''');
      await db
          .execute('CREATE INDEX idx_supplierName ON products(supplierName)');
      await db.execute(
          'CREATE INDEX idx_batchCode_products ON products(batchCode)');
      debugPrint('Created products table');
      await db.execute('''
CREATE TABLE product_suppliers (
  id $idType,
  productId $integerType,
  supplierName $textType,
  purchasePrice $realType,
  quantity $integerType,
  batchCode $textType,
  dateAdded $textType,
  notes $textNullableType,
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
)
''');
      await db.execute(
          'CREATE INDEX idx_productId_suppliers ON product_suppliers(productId)');
      await db.execute(
          'CREATE INDEX idx_supplierName_suppliers ON product_suppliers(supplierName)');
      await db.execute(
          'CREATE INDEX idx_batchCode ON product_suppliers(batchCode)');
      debugPrint('Created product_suppliers table');
      // جدول المبيعات
      await db.execute('''
CREATE TABLE sales (
  id $idType,
  productId $integerType,
  productName $textType,
  priceType $textType,
  unitPrice $realType,
  purchasePrice $realType,
  quantitySold $integerType,
  quantityRemainingInStock $integerType,
  totalAmount $realType,
  customerName $textType,
  supplierName $textType,
  saleDateTime $textType,
  notes $textNullableType,
  representativeId $textNullableType,
  paymentType $textNullableType,
  paidAmount $realType,
  remainingAmount $realType,
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
)
''');
      await db.execute('CREATE INDEX idx_productId_sales ON sales(productId)');
      await db.execute('CREATE INDEX idx_saleDateTime ON sales(saleDateTime)');
      await db.execute(
          'CREATE INDEX idx_representativeId ON sales(representativeId)');
      debugPrint('Created sales table');

      // جدول حركة المخزون
      await db.execute('''
CREATE TABLE inventory_transactions (
  id $idType,
  productId $integerType,
  productName $textType,
  transactionType $textType,
  quantityChange $integerType,
  quantityAfter $integerType,
  dateTime $textType,
  relatedSaleId $textNullableType,
  notes $textNullableType,
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
)
''');
      await db.execute(
          'CREATE INDEX idx_productId_inventory ON inventory_transactions(productId)');
      await db.execute(
          'CREATE INDEX idx_dateTime_inventory ON inventory_transactions(dateTime)');
      await db.execute(
          'CREATE INDEX idx_relatedSaleId ON inventory_transactions(relatedSaleId)');
      debugPrint('Created inventory_transactions table');

      // جدول أقسام الصيانة
      await db.execute('''
CREATE TABLE maintenance_departments (
  id $idType,
  name $textType,
  description $textNullableType,
  created_at $textType
)
''');
      debugPrint('Created maintenance_departments table');

      // جدول الصيانة
      await db.execute('''
CREATE TABLE maintenance_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  deviceType TEXT NOT NULL,
  customerName TEXT NOT NULL,
  customerPhone TEXT NOT NULL,
  problemDescription TEXT NOT NULL,
  status TEXT NOT NULL,
  cost REAL NOT NULL,
  paidAmount REAL NOT NULL,
  receivedDate TEXT NOT NULL,
  deliveryDate TEXT,
  repairCode TEXT NOT NULL,
  departmentId INTEGER,
  FOREIGN KEY (departmentId) REFERENCES maintenance_departments (id)
)
''');
      await db.execute(
          'CREATE INDEX idx_customerName ON maintenance_records(customerName)');
      await db.execute(
          'CREATE INDEX idx_customerPhone ON maintenance_records(customerPhone)');
      await db
          .execute('CREATE INDEX idx_status ON maintenance_records(status)');
      await db.execute(
          'CREATE INDEX idx_receivedDate ON maintenance_records(receivedDate)');
      await db.execute(
          'CREATE INDEX idx_repairCode ON maintenance_records(repairCode)');
      debugPrint('Created maintenance_records table with phone support');

      // جدول الأصناف
      await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  created_at $textType
)
''');
      debugPrint('Created categories table');

      // جدول الموردين
      await db.execute('''
CREATE TABLE suppliers (
  id $idType,
  name $textType,
  phone $textNullableType,
  created_at $textType
)
''');
      debugPrint('Created suppliers table');

      // جدول المخازن
      await db.execute('''
CREATE TABLE warehouses (
  id $idType,
  name $textType,
  location $textNullableType,
  created_at $textType
)
''');
      debugPrint('Created warehouses table');

      // جدول المندوبين/العملاء
      await db.execute('''
CREATE TABLE representatives (
  id $idType,
  name $textType,
  phone $textNullableType,
  address $textNullableType,
  type $textType,
  totalDebt $realType,
  totalPaid $realType,
  createdAt $textType,
  notes $textNullableType
)
''');
      await db.execute('CREATE INDEX idx_rep_name ON representatives(name)');
      await db.execute('CREATE INDEX idx_rep_type ON representatives(type)');
      debugPrint('Created representatives table');

      // جدول معاملات المندوبين (مبيعات/دفعات/مرتجعات)
      await db.execute('''
CREATE TABLE representative_transactions (
  id $idType,
  representativeId $integerType,
  representativeName $textType,
  type $textType,
  amount $realType,
  paidAmount $realType,
  remainingDebt $realType,
  productsSummary $textNullableType,
  dateTime $textType,
  notes $textNullableType,
  invoiceNumber $textNullableType,
  saleIds $textNullableType,
  FOREIGN KEY (representativeId) REFERENCES representatives (id) ON DELETE CASCADE
)
''');
      await db.execute(
          'CREATE INDEX idx_rep_trans_rep_id ON representative_transactions(representativeId)');
      await db.execute(
          'CREATE INDEX idx_rep_trans_date ON representative_transactions(dateTime)');
      await db.execute(
          'CREATE INDEX idx_rep_trans_type ON representative_transactions(type)');
      debugPrint('Created representative_transactions table');

      // جدول تفاصيل المرتجعات
      await db.execute('''
CREATE TABLE return_details (
  id $idType,
  saleId $integerType,
  productId $integerType,
  productName $textType,
  quantityReturned $integerType,
  unitPrice $realType,
  totalAmount $realType,
  returnDateTime $textType,
  reason $textNullableType,
  representativeId $textNullableType,
  FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE,
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
)
''');
      await db
          .execute('CREATE INDEX idx_return_sale_id ON return_details(saleId)');
      await db.execute(
          'CREATE INDEX idx_return_rep_id ON return_details(representativeId)');
      debugPrint('Created return_details table');
      await db.execute('''
CREATE TABLE notes (
  id $idType,
  title $textType,
  content $textType,
  category $textNullableType,
  color $textType,
  isPinned $integerType,
  createdAt $textType,
  updatedAt $textType
)
''');
      await db.execute('CREATE INDEX idx_notes_category ON notes(category)');
      await db.execute('CREATE INDEX idx_notes_pinned ON notes(isPinned)');
      await db.execute('CREATE INDEX idx_notes_updated ON notes(updatedAt)');
      debugPrint('Created notes table');
      // إدراج أقسام افتراضية للصيانة
      await db.insert('maintenance_departments', {
        'name': 'قسم اللاب توب',
        'description': 'صيانة أجهزة اللاب توب والكمبيوتر المحمول',
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('maintenance_departments', {
        'name': 'قسم الشاشات',
        'description': 'صيانة الشاشات والمونيتورات',
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('maintenance_departments', {
        'name': 'قسم الموبايل',
        'description': 'صيانة الهواتف الذكية والتابلت',
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('maintenance_departments', {
        'name': 'أخرى',
        'description': 'صيانة أجهزة أخرى',
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Added default maintenance departments');
    } catch (e) {
      debugPrint('Error creating tables: $e');
      rethrow;
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    // إنشاء نسخة احتياطية
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, 'inventory_management.db');
      final backupPath = join(
        documentsDirectory.path,
        'inventory_management_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      await File(dbPath).copy(backupPath);
      debugPrint('Backed up database to $backupPath');
    } catch (e) {
      debugPrint('Error backing up database: $e');
    }

    // النسخة 10: إضافة نظام المندوبين والعملاء
    if (oldVersion < 10) {
      try {
        // إضافة جدول المندوبين/العملاء
        await db.execute('''
CREATE TABLE IF NOT EXISTS representatives (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  type TEXT NOT NULL,
  totalDebt REAL NOT NULL DEFAULT 0,
  totalPaid REAL NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL,
  notes TEXT
)
''');
        await db.execute('CREATE INDEX idx_rep_name ON representatives(name)');
        await db.execute('CREATE INDEX idx_rep_type ON representatives(type)');
        debugPrint('✅ Created representatives table');

        // إضافة جدول معاملات المندوبين
        await db.execute('''
CREATE TABLE IF NOT EXISTS representative_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  representativeId INTEGER NOT NULL,
  representativeName TEXT NOT NULL,
  type TEXT NOT NULL,
  amount REAL NOT NULL,
  paidAmount REAL NOT NULL DEFAULT 0,
  remainingDebt REAL NOT NULL DEFAULT 0,
  productsSummary TEXT,
  dateTime TEXT NOT NULL,
  notes TEXT,
  invoiceNumber TEXT,
  saleIds TEXT,
  FOREIGN KEY (representativeId) REFERENCES representatives (id) ON DELETE CASCADE
)
''');
        await db.execute(
            'CREATE INDEX idx_rep_trans_rep_id ON representative_transactions(representativeId)');
        await db.execute(
            'CREATE INDEX idx_rep_trans_date ON representative_transactions(dateTime)');
        await db.execute(
            'CREATE INDEX idx_rep_trans_type ON representative_transactions(type)');
        debugPrint('✅ Created representative_transactions table');

        // إضافة جدول تفاصيل المرتجعات
        await db.execute('''
CREATE TABLE IF NOT EXISTS return_details (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  saleId INTEGER NOT NULL,
  productId INTEGER NOT NULL,
  productName TEXT NOT NULL,
  quantityReturned INTEGER NOT NULL,
  unitPrice REAL NOT NULL,
  totalAmount REAL NOT NULL,
  returnDateTime TEXT NOT NULL,
  reason TEXT,
  representativeId TEXT,
  FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE,
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
)
''');
        await db.execute(
            'CREATE INDEX idx_return_sale_id ON return_details(saleId)');
        await db.execute(
            'CREATE INDEX idx_return_rep_id ON return_details(representativeId)');
        debugPrint('✅ Created return_details table');

        // تحديث جدول المبيعات لإضافة الأعمدة الجديدة
        final salesColumns = await db.rawQuery('PRAGMA table_info(sales)');
        final columnNames =
            salesColumns.map((col) => col['name'] as String).toSet();

        if (!columnNames.contains('representativeId')) {
          await db
              .execute('ALTER TABLE sales ADD COLUMN representativeId TEXT');
          debugPrint('✅ Added representativeId to sales');
        }

        if (!columnNames.contains('paymentType')) {
          await db.execute(
              'ALTER TABLE sales ADD COLUMN paymentType TEXT DEFAULT "نقد"');
          debugPrint('✅ Added paymentType to sales');
        }

        if (!columnNames.contains('paidAmount')) {
          await db.execute(
              'ALTER TABLE sales ADD COLUMN paidAmount REAL DEFAULT 0');
          debugPrint('✅ Added paidAmount to sales');
        }

        if (!columnNames.contains('remainingAmount')) {
          await db.execute(
              'ALTER TABLE sales ADD COLUMN remainingAmount REAL DEFAULT 0');
          debugPrint('✅ Added remainingAmount to sales');
        }

        debugPrint(
            '✅ Successfully upgraded to version 10 with Representatives & Customers system');
      } catch (e) {
        debugPrint('❌ Error in version 10 upgrade: $e');
      }
    }

    // النسخة 11: إضافة عمود customerPhone
    if (oldVersion < 11) {
      try {
        final maintenanceColumns =
            await db.rawQuery('PRAGMA table_info(maintenance_records)');
        final columnNames =
            maintenanceColumns.map((col) => col['name'] as String).toSet();

        if (!columnNames.contains('customerPhone')) {
          await db.execute(
              'ALTER TABLE maintenance_records ADD COLUMN customerPhone TEXT DEFAULT ""');
          debugPrint('✅ Added customerPhone to maintenance_records');
        }

        debugPrint('✅ Successfully upgraded to version 11 with phone support');
      } catch (e) {
        debugPrint('❌ Error in version 11 upgrade: $e');
      }
    }

    // النسخة 12: إضافة جدول الأقسام
    if (oldVersion < 12) {
      try {
        // إنشاء جدول الأقسام
        await db.execute('''
CREATE TABLE IF NOT EXISTS maintenance_departments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  created_at TEXT NOT NULL
)
''');
        debugPrint('✅ Created maintenance_departments table');

        // التحقق من عمود departmentId في جدول الصيانة
        final maintenanceColumns =
            await db.rawQuery('PRAGMA table_info(maintenance_records)');
        final columnNames =
            maintenanceColumns.map((col) => col['name'] as String).toSet();

        if (!columnNames.contains('departmentId')) {
          await db.execute(
              'ALTER TABLE maintenance_records ADD COLUMN departmentId INTEGER');
          debugPrint('✅ Added departmentId to maintenance_records');
        }

        // إضافة بعض الأقسام الافتراضية
        await db.insert('maintenance_departments', {
          'name': 'قسم اللاب توب',
          'description': 'صيانة أجهزة اللاب توب والكمبيوتر المحمول',
          'created_at': DateTime.now().toIso8601String(),
        });
        await db.insert('maintenance_departments', {
          'name': 'قسم الشاشات',
          'description': 'صيانة الشاشات والمونيتورات',
          'created_at': DateTime.now().toIso8601String(),
        });
        await db.insert('maintenance_departments', {
          'name': 'قسم الموبايل',
          'description': 'صيانة الهواتف الذكية والتابلت',
          'created_at': DateTime.now().toIso8601String(),
        });
        await db.insert('maintenance_departments', {
          'name': 'أخرى',
          'description': 'صيانة أجهزة أخرى',
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ Added default departments');

        debugPrint(
            '✅ Successfully upgraded to version 12 with departments system');
      } catch (e) {
        debugPrint('❌ Error in version 12 upgrade: $e');
      }
    }
// النسخة 14: إضافة جدول الموردين المتعددين
    if (oldVersion < 14) {
      try {
        const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
        const textType = 'TEXT NOT NULL';
        const textNullableType = 'TEXT';
        const realType = 'REAL NOT NULL';
        const integerType = 'INTEGER NOT NULL';

        await db.execute('''
CREATE TABLE IF NOT EXISTS product_suppliers (
  id $idType,
  productId $integerType,
  supplierName $textType,
  purchasePrice $realType,
  quantity $integerType,
  dateAdded $textType,
  notes $textNullableType,
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
)
''');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_productId_suppliers ON product_suppliers(productId)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_supplierName_suppliers ON product_suppliers(supplierName)');

        debugPrint(
            '✅ Successfully upgraded to version 14 with product_suppliers table');
      } catch (e) {
        debugPrint('❌ Error in version 14 upgrade: $e');
      }
    }
    // النسخة 15: إضافة عمود batchCode
    // النسخة 15: إضافة عمود batchCode للجدولين
    if (oldVersion < 15) {
      try {
        // ⭐ 1. إضافة batchCode لجدول products
        final productsColumns =
            await db.rawQuery('PRAGMA table_info(products)');
        final productsColumnNames =
            productsColumns.map((col) => col['name'] as String).toSet();

        if (!productsColumnNames.contains('batchCode')) {
          await db.execute('ALTER TABLE products ADD COLUMN batchCode TEXT');
          debugPrint('✅ Added batchCode to products');

          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_batchCode_products ON products(batchCode)');
          debugPrint('✅ Created index on products.batchCode');
        }

        // ⭐ 2. إضافة batchCode لجدول product_suppliers
        final suppliersColumns =
            await db.rawQuery('PRAGMA table_info(product_suppliers)');
        final suppliersColumnNames =
            suppliersColumns.map((col) => col['name'] as String).toSet();

        if (!suppliersColumnNames.contains('batchCode')) {
          await db.execute(
              'ALTER TABLE product_suppliers ADD COLUMN batchCode TEXT DEFAULT ""');
          debugPrint('✅ Added batchCode to product_suppliers');

          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_batchCode ON product_suppliers(batchCode)');
          debugPrint('✅ Created index on product_suppliers.batchCode');
        }

        // ⭐ 3. تحديث السجلات القديمة
        final oldProducts = await db.query('products');
        for (var product in oldProducts) {
          if (product['batchCode'] == null ||
              (product['batchCode'] as String).isEmpty) {
            final id = product['id'] as int;
            final dateAdded = DateTime.parse(product['dateAdded'] as String);
            final code = await generateBatchCode(
              product['category'] as String?,
              dateAdded,
            );
            await db.update(
              'products',
              {'batchCode': code},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }

        final oldShipments = await db.query('product_suppliers');
        for (var shipment in oldShipments) {
          if (shipment['batchCode'] == null ||
              (shipment['batchCode'] as String).isEmpty) {
            final id = shipment['id'] as int;
            final dateAdded = DateTime.parse(shipment['dateAdded'] as String);
            final code =
                'OLD-${dateAdded.year}-${dateAdded.month.toString().padLeft(2, '0')}-S${id.toString().padLeft(3, '0')}';

            await db.update(
              'product_suppliers',
              {'batchCode': code},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }

        debugPrint('✅ Successfully upgraded to version 15 with batchCode');
      } catch (e) {
        debugPrint('❌ Error in version 15 upgrade: $e');
      }
    }

    if (oldVersion < 16) {
      try {
        const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
        const textType = 'TEXT NOT NULL';
        const textNullableType = 'TEXT';
        const integerType = 'INTEGER NOT NULL';

        await db.execute('''
CREATE TABLE IF NOT EXISTS notes (
  id $idType,
  title $textType,
  content $textType,
  category $textNullableType,
  color $textType,
  isPinned $integerType DEFAULT 0,
  createdAt $textType,
  updatedAt $textType
)
''');

        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_notes_category ON notes(category)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_notes_pinned ON notes(isPinned)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_notes_updated ON notes(updatedAt)');

        debugPrint('✅ Successfully upgraded to version 16 with Notes system');
      } catch (e) {
        debugPrint('❌ Error in version 16 upgrade: $e');
      }
    }

    if (oldVersion < 13) {
      debugPrint('✅ Database is now at version 13');
    }
  }

  // ========== دوال المندوبين/العملاء ==========
  Future<List<Map<String, dynamic>>> getRepresentatives({String? type}) async {
    final db = await database;
    try {
      if (type != null) {
        return await db.query(
          'representatives',
          where: 'type = ?',
          whereArgs: [type],
          orderBy: 'name ASC',
        );
      }
      return await db.query('representatives', orderBy: 'name ASC');
    } catch (e) {
      debugPrint('Error fetching representatives: $e');
      return [];
    }
  }

  Future<int> insertRepresentative(Map<String, dynamic> representative) async {
    final db = await database;
    try {
      final id = await db.insert('representatives', representative);
      debugPrint('Inserted representative with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting representative: $e');
      return -1;
    }
  }

  Future<int> updateRepresentative(
      int id, Map<String, dynamic> representative) async {
    final db = await database;
    try {
      return await db.update(
        'representatives',
        representative,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error updating representative: $e');
      return 0;
    }
  }

  Future<int> deleteRepresentative(int id) async {
    final db = await database;
    try {
      return await db
          .delete('representatives', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('Error deleting representative: $e');
      return 0;
    }
  }

  // ========== دوال معاملات المندوبين ==========
  Future<int> insertRepresentativeTransaction(
      Map<String, dynamic> transaction) async {
    final db = await database;
    try {
      final id = await db.insert('representative_transactions', transaction);
      debugPrint('Inserted representative transaction with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting representative transaction: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getRepresentativeTransactions(
      int representativeId) async {
    final db = await database;
    try {
      return await db.query(
        'representative_transactions',
        where: 'representativeId = ?',
        whereArgs: [representativeId],
        orderBy: 'dateTime DESC',
      );
    } catch (e) {
      debugPrint('Error fetching representative transactions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllRepresentativeTransactions() async {
    final db = await database;
    try {
      return await db.query('representative_transactions',
          orderBy: 'dateTime DESC');
    } catch (e) {
      debugPrint('Error fetching all representative transactions: $e');
      return [];
    }
  }

  // ========== دوال المرتجعات ==========
  Future<int> insertReturnDetail(Map<String, dynamic> returnDetail) async {
    final db = await database;
    try {
      final id = await db.insert('return_details', returnDetail);
      debugPrint('Inserted return detail with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting return detail: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getReturnsBySaleId(int saleId) async {
    final db = await database;
    try {
      return await db.query(
        'return_details',
        where: 'saleId = ?',
        whereArgs: [saleId],
        orderBy: 'returnDateTime DESC',
      );
    } catch (e) {
      debugPrint('Error fetching returns by sale id: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllReturns() async {
    final db = await database;
    try {
      return await db.query('return_details', orderBy: 'returnDateTime DESC');
    } catch (e) {
      debugPrint('Error fetching all returns: $e');
      return [];
    }
  }

  // ========== دوال المنتجات ==========
  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    try {
      final products = await db.query('products');
      debugPrint('Fetched ${products.length} products');
      return products;
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    try {
      final id = await db.insert(
        'products',
        product,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Inserted product with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting product: $e');
      return -1;
    }
  }

  Future<int> updateProduct(int id, Map<String, dynamic> product) async {
    final db = await database;
    try {
      final result = await db.update(
        'products',
        product,
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Updated product id $id: $result row(s) affected');
      return result;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return 0;
    }
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    try {
      final result =
          await db.delete('products', where: 'id = ?', whereArgs: [id]);
      debugPrint('Deleted product id $id');
      return result;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return 0;
    }
  }

  Future<int> updateProductQuantity(int productId, int newQuantity) async {
    final db = await database;
    try {
      final result = await db.update(
        'products',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [productId],
      );
      debugPrint('Updated quantity for product id $productId to $newQuantity');
      return result;
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      return 0;
    }
  }

  // ========== دوال المبيعات ==========
  Future<int> insertSale(Map<String, dynamic> sale) async {
    final db = await database;
    try {
      final id = await db.insert(
        'sales',
        sale,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Inserted sale with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting sale: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getSales() async {
    final db = await database;
    try {
      final sales = await db.query('sales', orderBy: 'saleDateTime DESC');
      debugPrint('Fetched ${sales.length} sales');
      return sales;
    } catch (e) {
      debugPrint('Error fetching sales: $e');
      return [];
    }
  }

// ⭐ بعد دالة getSales()
  Future<List<Map<String, dynamic>>> getSalesWithReturns(int productId) async {
    final db = await database;
    try {
      // جلب كل المبيعات للمنتج
      final sales = await db.query(
        'sales',
        where: 'productId = ?',
        whereArgs: [productId],
        orderBy: 'saleDateTime DESC',
      );

      List<Map<String, dynamic>> result = [];

      for (var sale in sales) {
        final saleId = sale['id'] as int;

        // جلب المرتجعات لهذا البيع
        final returns = await db.query(
          'return_details',
          where: 'saleId = ?',
          whereArgs: [saleId],
        );

        // تقسيم الكمية المباعة لقطع منفصلة
        final quantitySold = sale['quantitySold'] as int;
        final quantityReturned = returns.fold<int>(
          0,
          (sum, r) => sum + (r['quantityReturned'] as int),
        );

        final actualSold = quantitySold - quantityReturned;

        // إنشاء سطر لكل قطعة مباعة
        for (int i = 0; i < actualSold; i++) {
          result.add({
            'saleId': saleId,
            'productId': sale['productId'],
            'productName': sale['productName'],
            'unitPrice': sale['unitPrice'],
            'purchasePrice': sale['purchasePrice'], // ⭐ السعر الصحيح
            'profit':
                (sale['unitPrice'] as num) - (sale['purchasePrice'] as num),
            'customerName': sale['customerName'],
            'supplierName': sale['supplierName'],
            'saleDateTime': sale['saleDateTime'],
            'invoiceNumber': _extractInvoiceNumber(sale['notes']),
            'isReturned': false,
          });
        }

        // إضافة القطع المرتجعة
        for (var returnDetail in returns) {
          final qtyReturned = returnDetail['quantityReturned'] as int;
          for (int i = 0; i < qtyReturned; i++) {
            result.add({
              'saleId': saleId,
              'productId': sale['productId'],
              'productName': sale['productName'],
              'unitPrice': sale['unitPrice'],
              'purchasePrice': sale['purchasePrice'],
              'profit': 0, // مرتجع
              'customerName': sale['customerName'],
              'supplierName': sale['supplierName'],
              'saleDateTime': returnDetail['returnDateTime'],
              'invoiceNumber': _extractInvoiceNumber(sale['notes']),
              'isReturned': true,
              'returnReason': returnDetail['reason'],
            });
          }
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error in getSalesWithReturns: $e');
      return [];
    }
  }

// ⭐ دالة مساعدة
  String _extractInvoiceNumber(dynamic notes) {
    if (notes == null) return 'غير محدد';
    final match =
        RegExp(r'فاتورة:\s*(.+?)(?:\||$)').firstMatch(notes.toString());
    return match?.group(1)?.trim() ?? 'غير محدد';
  }

  Future<int> updateSale(int saleId, Map<String, dynamic> saleData) async {
    final db = await database;
    try {
      final result = await db
          .update('sales', saleData, where: 'id = ?', whereArgs: [saleId]);
      debugPrint('Updated sale id $saleId');
      return result;
    } catch (e) {
      debugPrint('Error updating sale: $e');
      return 0;
    }
  }

  Future<int> deleteSale(int saleId) async {
    final db = await database;
    try {
      final result =
          await db.delete('sales', where: 'id = ?', whereArgs: [saleId]);
      debugPrint('Deleted sale id $saleId');
      return result;
    } catch (e) {
      debugPrint('Error deleting sale: $e');
      return 0;
    }
  }

  // ========== دوال حركة المخزون ==========
  Future<int> insertInventoryTransaction(
      Map<String, dynamic> transaction) async {
    final db = await database;
    try {
      final id = await db.insert('inventory_transactions', transaction,
          conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint('Inserted inventory transaction with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting inventory transaction: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllInventoryTransactions() async {
    final db = await database;
    try {
      final transactions =
          await db.query('inventory_transactions', orderBy: 'dateTime DESC');
      debugPrint('Fetched ${transactions.length} inventory transactions');
      return transactions;
    } catch (e) {
      debugPrint('Error fetching inventory transactions: $e');
      return [];
    }
  }

  // ========== دوال الصيانة ==========
  Future<List<Map<String, dynamic>>> getMaintenanceRecords() async {
    final db = await database;
    try {
      final records =
          await db.query('maintenance_records', orderBy: 'receivedDate DESC');
      debugPrint('Fetched ${records.length} maintenance records');
      return records;
    } catch (e) {
      debugPrint('Error fetching maintenance records: $e');
      return [];
    }
  }

  Future<int> insertMaintenanceRecord(Map<String, dynamic> record) async {
    final db = await database;
    try {
      final id = await db.insert('maintenance_records', record,
          conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint('Inserted maintenance record with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting maintenance record: $e');
      return -1;
    }
  }

  Future<int> updateMaintenanceRecord(
      int id, Map<String, dynamic> record) async {
    final db = await database;
    try {
      final result = await db.update('maintenance_records', record,
          where: 'id = ?', whereArgs: [id]);
      debugPrint('Updated maintenance record id $id: $result row(s) affected');
      return result;
    } catch (e) {
      debugPrint('Error updating maintenance record: $e');
      return 0;
    }
  }

  Future<int> deleteMaintenanceRecord(int id) async {
    final db = await database;
    try {
      final result = await db
          .delete('maintenance_records', where: 'id = ?', whereArgs: [id]);
      debugPrint('Deleted maintenance record id $id: $result row(s) affected');
      return result;
    } catch (e) {
      debugPrint('Error deleting maintenance record: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getMaintenanceRecordsByStatus(
      String status) async {
    final db = await database;
    try {
      final records = await db.query('maintenance_records',
          where: 'status = ?',
          whereArgs: [status],
          orderBy: 'receivedDate DESC');
      return records;
    } catch (e) {
      debugPrint('Error fetching maintenance records by status: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMaintenanceRecordByCode(
      String repairCode) async {
    final db = await database;
    try {
      final records = await db.query('maintenance_records',
          where: 'repairCode = ?', whereArgs: [repairCode], limit: 1);
      if (records.isNotEmpty) {
        return records.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching maintenance record by code: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getMaintenanceStatistics() async {
    final db = await database;
    try {
      final records = await db.query('maintenance_records');

      int total = records.length;
      int pending = records.where((r) => r['status'] == 'قيد الإصلاح').length;
      int ready = records.where((r) => r['status'] == 'جاهز للاستلام').length;
      int completed = records.where((r) => r['status'] == 'تم التسليم').length;

      double totalRevenue = records
          .where((r) => r['status'] == 'تم التسليم')
          .fold<double>(0, (sum, r) => sum + (r['cost'] as num).toDouble());

      double totalPaid = records.fold<double>(
        0,
        (sum, r) => sum + (r['paidAmount'] as num).toDouble(),
      );

      return {
        'total': total,
        'pending': pending,
        'ready': ready,
        'completed': completed,
        'totalRevenue': totalRevenue,
        'totalPaid': totalPaid,
      };
    } catch (e) {
      debugPrint('Error getting maintenance statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'ready': 0,
        'completed': 0,
        'totalRevenue': 0.0,
        'totalPaid': 0.0,
      };
    }
  }

  // ========== دوال أقسام الصيانة ==========
  Future<List<Map<String, dynamic>>> getMaintenanceDepartments() async {
    final db = await database;
    try {
      return await db.query('maintenance_departments', orderBy: 'name ASC');
    } catch (e) {
      debugPrint('Error fetching departments: $e');
      return [];
    }
  }

  Future<int> insertMaintenanceDepartment(Map<String, dynamic> dept) async {
    final db = await database;
    try {
      return await db.insert('maintenance_departments', dept);
    } catch (e) {
      debugPrint('Error inserting department: $e');
      return -1;
    }
  }

  Future<int> updateMaintenanceDepartment(
      int id, Map<String, dynamic> dept) async {
    final db = await database;
    try {
      return await db.update(
        'maintenance_departments',
        dept,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error updating department: $e');
      return 0;
    }
  }

  Future<int> deleteMaintenanceDepartment(int id) async {
    final db = await database;
    try {
      return await db.delete(
        'maintenance_departments',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting department: $e');
      return 0;
    }
  }

  // ========== دوال الأصناف ==========
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    try {
      return await db.query('categories', orderBy: 'name ASC');
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    try {
      return await db.insert('categories', category);
    } catch (e) {
      debugPrint('Error inserting category: $e');
      return -1;
    }
  }

  // ========== دوال الموردين ==========
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final db = await database;
    try {
      return await db.query('suppliers', orderBy: 'name ASC');
    } catch (e) {
      debugPrint('Error fetching suppliers: $e');
      return [];
    }
  }

  Future<int> insertSupplier(Map<String, dynamic> supplier) async {
    final db = await database;
    try {
      return await db.insert('suppliers', supplier);
    } catch (e) {
      debugPrint('Error inserting supplier: $e');
      return -1;
    }
  }

  // ========== دوال المخازن ==========
  Future<List<Map<String, dynamic>>> getWarehouses() async {
    final db = await database;
    try {
      return await db.query('warehouses', orderBy: 'name ASC');
    } catch (e) {
      debugPrint('Error fetching warehouses: $e');
      return [];
    }
  }

  Future<int> insertWarehouse(Map<String, dynamic> warehouse) async {
    final db = await database;
    try {
      return await db.insert('warehouses', warehouse);
    } catch (e) {
      debugPrint('Error inserting warehouse: $e');
      return -1;
    }
  }

  Future<void> deleteAllData() async {
    final db = await database;

    await db.transaction((txn) async {
      // ⭐ 1. حذف المبيعات
      await txn.delete('sales');

      // ⭐ 2. حذف حركات المخزون
      await txn.delete('inventory_transactions');

      // ⭐ 3. حذف المنتجات
      await txn.delete('products');

      // ⭐⭐⭐ 4. حذف جدول الموردين المتعددين - أضف هذا السطر ✅
      await txn.delete('product_suppliers');

      // ⭐ 5. حذف سجلات الصيانة
      await txn.delete('maintenance_records');

      // ⭐ 6. حذف المندوبين والعملاء
      await txn.delete('representatives');

      // ⭐ 7. حذف معاملات المندوبين
      await txn.delete('representative_transactions');

      // ⭐ 8. حذف تفاصيل المرتجعات
      await txn.delete('return_details');

      // ⭐ 9. حذف الأصناف
      await txn.delete('categories');

      // ⭐ 10. حذف الموردين (من الجدول الأساسي)
      await txn.delete('suppliers');

      // ⭐ 11. حذف المخازن
      await txn.delete('warehouses');
      await txn.delete('notes');

      debugPrint('✅ تم حذف جميع البيانات بنجاح من جميع الجداول');
    });
  }

  Future<void> resetDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'inventory_management.db');

      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      final dbFile = File(path);
      if (await dbFile.exists()) {
        await dbFile.delete();
        debugPrint('Database file deleted: $path');
      }

      _database = await _initDB('inventory_management.db');
      debugPrint('Database reset successfully');
    } catch (e) {
      debugPrint('Error resetting database: $e');
      rethrow;
    }
  }
// ========== دوال الموردين المتعددين ==========

  /// إضافة شحنة جديدة من مورد
  Future<int> insertProductSupplier(Map<String, dynamic> shipment) async {
    final db = await database;
    try {
      final id = await db.insert('product_suppliers', shipment);
      debugPrint('Inserted product supplier shipment with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting product supplier: $e');
      return -1;
    }
  }

  /// الحصول على جميع شحنات منتج معين
  Future<List<Map<String, dynamic>>> getProductSuppliers(int productId) async {
    final db = await database;
    try {
      return await db.query(
        'product_suppliers',
        where: 'productId = ?',
        whereArgs: [productId],
        orderBy: 'dateAdded DESC',
      );
    } catch (e) {
      debugPrint('Error fetching product suppliers: $e');
      return [];
    }
  }

  /// الحصول على جميع الشحنات
  Future<List<Map<String, dynamic>>> getAllProductSuppliers() async {
    final db = await database;
    try {
      return await db.query('product_suppliers', orderBy: 'dateAdded DESC');
    } catch (e) {
      debugPrint('Error fetching all product suppliers: $e');
      return [];
    }
  }

  /// الحصول على شحنات مورد معين
  Future<List<Map<String, dynamic>>> getSupplierShipments(
      String supplierName) async {
    final db = await database;
    try {
      return await db.query(
        'product_suppliers',
        where: 'supplierName = ?',
        whereArgs: [supplierName],
        orderBy: 'dateAdded DESC',
      );
    } catch (e) {
      debugPrint('Error fetching supplier shipments: $e');
      return [];
    }
  }

  /// حذف شحنة
  Future<int> deleteProductSupplier(int id) async {
    final db = await database;
    try {
      return await db
          .delete('product_suppliers', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('Error deleting product supplier: $e');
      return 0;
    }
  }

  /// توليد كود شحنة فريد بناءً على تاريخ المنتج
  Future<String> generateBatchCode(String? category, DateTime dateAdded) async {
    final db = await database;

    // استخراج أول 3 أحرف من الصنف
    String categoryCode = 'GEN'; // افتراضي
    if (category != null && category.isNotEmpty) {
      categoryCode = category
          .replaceAll(' ', '')
          .toUpperCase()
          .substring(0, category.length >= 3 ? 3 : category.length)
          .padRight(3, 'X');
    }

    // ⭐ استخدام التاريخ المُمرر بدلاً من DateTime.now()
    final yearMonth =
        '${dateAdded.year}-${dateAdded.month.toString().padLeft(2, '0')}';

    // ⭐⭐⭐ البحث في جدول products (ليس product_suppliers)
    final existing = await db.query(
      'products',
      where: 'batchCode LIKE ?',
      whereArgs: ['$categoryCode-$yearMonth-%'],
      orderBy: 'batchCode DESC',
      limit: 1,
    );

    int sequence = 1;
    if (existing.isNotEmpty) {
      final lastCode = existing.first['batchCode'] as String?;
      if (lastCode != null && lastCode.isNotEmpty) {
        final parts = lastCode.split('-');
        if (parts.length == 4) {
          sequence = (int.tryParse(parts[3]) ?? 0) + 1;
        }
      }
    }

    return '$categoryCode-$yearMonth-${sequence.toString().padLeft(3, '0')}';
  }

  Future<List<Map<String, dynamic>>> getNotes({String? category}) async {
    final db = await database;
    try {
      if (category != null && category.isNotEmpty) {
        return await db.query(
          'notes',
          where: 'category = ?',
          whereArgs: [category],
          orderBy: 'isPinned DESC, updatedAt DESC',
        );
      }
      return await db.query('notes', orderBy: 'isPinned DESC, updatedAt DESC');
    } catch (e) {
      debugPrint('Error fetching notes: $e');
      return [];
    }
  }

  /// البحث في الملاحظات
  Future<List<Map<String, dynamic>>> searchNotes(String query) async {
    final db = await database;
    try {
      return await db.query(
        'notes',
        where: 'title LIKE ? OR content LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'isPinned DESC, updatedAt DESC',
      );
    } catch (e) {
      debugPrint('Error searching notes: $e');
      return [];
    }
  }

  /// إضافة ملاحظة جديدة
  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    try {
      final id = await db.insert('notes', note);
      debugPrint('Inserted note with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting note: $e');
      return -1;
    }
  }

  /// تحديث ملاحظة
  Future<int> updateNote(int id, Map<String, dynamic> note) async {
    final db = await database;
    try {
      final result = await db.update(
        'notes',
        note,
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Updated note id $id');
      return result;
    } catch (e) {
      debugPrint('Error updating note: $e');
      return 0;
    }
  }

  /// حذف ملاحظة
  Future<int> deleteNote(int id) async {
    final db = await database;
    try {
      final result = await db.delete('notes', where: 'id = ?', whereArgs: [id]);
      debugPrint('Deleted note id $id');
      return result;
    } catch (e) {
      debugPrint('Error deleting note: $e');
      return 0;
    }
  }

  /// تثبيت/إلغاء تثبيت ملاحظة
  Future<int> togglePinNote(int id, bool isPinned) async {
    final db = await database;
    try {
      return await db.update(
        'notes',
        {'isPinned': isPinned ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error toggling pin note: $e');
      return 0;
    }
  }

  /// الحصول على التصنيفات المستخدمة
  Future<List<String>> getNoteCategories() async {
    final db = await database;
    try {
      final result = await db.rawQuery(
        'SELECT DISTINCT category FROM notes WHERE category IS NOT NULL AND category != "" ORDER BY category',
      );
      return result.map((r) => r['category'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching note categories: $e');
      return [];
    }
  }

  Future close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint('Database closed');
  }
}
