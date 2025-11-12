// lib/providers/representative_provider.dart

import 'package:flutter/foundation.dart';
import 'package:soundtry/models/representative.dart';
import 'package:soundtry/models/representative_transaction.dart';
import 'package:soundtry/services/database_helper.dart';

class RepresentativeProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Representative> _representatives = [];
  List<Representative> _filteredRepresentatives = [];
  String _filterType = 'الكل'; // 'الكل', 'مندوب', 'عميل'
  bool _showOnlyWithDebt = false;
  bool _showOnlyWithCredit = false; // ⭐ إضافة فلتر المستحقين

  List<Representative> get representatives => _filteredRepresentatives;
  String get filterType => _filterType;
  bool get showOnlyWithDebt => _showOnlyWithDebt;
  bool get showOnlyWithCredit => _showOnlyWithCredit; // ⭐ getter جديد

  // ⭐⭐⭐ إحصائيات محسنة ومفصلة

  // إحصائيات عامة
  int get totalRepresentatives => _representatives.length;

  // إحصائيات المندوبين
  int get totalMandoubs =>
      _representatives.where((r) => r.type == 'مندوب').length;

  int get mandoubsWithDebt => _representatives
      .where((r) => r.type == 'مندوب' && r.remainingDebt > 0)
      .length;

  int get mandoubsWithCredit => _representatives
      .where((r) => r.type == 'مندوب' && r.remainingDebt < 0)
      .length;

  // إحصائيات العملاء
  int get totalCustomers =>
      _representatives.where((r) => r.type == 'عميل').length;

  int get customersWithDebt => _representatives
      .where((r) => r.type == 'عميل' && r.remainingDebt > 0)
      .length;

  int get customersWithCredit => _representatives
      .where((r) => r.type == 'عميل' && r.remainingDebt < 0)
      .length;

  // ⭐ إحصائيات الديون (القيم الموجبة فقط)
  double get totalDebtsAmount => _representatives
      .where((r) => r.remainingDebt > 0)
      .fold(0.0, (sum, r) => sum + r.remainingDebt);

  int get totalDebtorsCount =>
      _representatives.where((r) => r.remainingDebt > 0).length;

  // ⭐ إحصائيات المستحقات (القيم السالبة فقط)
  double get totalCreditsAmount => _representatives
      .where((r) => r.remainingDebt < 0)
      .fold(0.0, (sum, r) => sum + r.remainingDebt.abs());

  int get totalCreditorsCount =>
      _representatives.where((r) => r.remainingDebt < 0).length;

  // ⭐ إحصائيات الحسابات المسددة
  int get totalSettledCount =>
      _representatives.where((r) => r.remainingDebt == 0).length;

  // إجمالي المدفوع
  double get totalPaid =>
      _representatives.fold(0.0, (sum, r) => sum + r.totalPaid);

  // الصافي (يمكن أن يكون موجب أو سالب)
  double get totalDebts =>
      _representatives.fold(0.0, (sum, r) => sum + r.remainingDebt);

  List<Representative> getAllByType(String type) {
    return _representatives.where((r) => r.type == type).toList();
  }

  RepresentativeProvider() {
    loadRepresentatives();
  }

  // تحميل جميع المندوبين/العملاء
  Future<void> loadRepresentatives() async {
    try {
      final data = await _dbHelper.getRepresentatives();
      _representatives =
          data.map((map) => Representative.fromMap(map)).toList();
      _applyFilters();
      notifyListeners();
      debugPrint('Loaded ${_representatives.length} representatives');
    } catch (e) {
      debugPrint('Error loading representatives: $e');
    }
  }

  // ⭐ تطبيق الفلاتر المحدثة
  void _applyFilters() {
    _filteredRepresentatives = _representatives.where((rep) {
      // فلتر النوع
      bool matchesType = _filterType == 'الكل' || rep.type == _filterType;

      // فلتر المديونين
      bool matchesDebt = !_showOnlyWithDebt || rep.remainingDebt > 0;

      // فلتر المستحقين
      bool matchesCredit = !_showOnlyWithCredit || rep.remainingDebt < 0;

      return matchesType && matchesDebt && matchesCredit;
    }).toList();

    // ترتيب حسب المديونية (الأعلى أولاً، ثم المستحقات)
    _filteredRepresentatives.sort((a, b) {
      // المديونين أولاً
      if (a.remainingDebt > 0 && b.remainingDebt <= 0) return -1;
      if (a.remainingDebt <= 0 && b.remainingDebt > 0) return 1;

      // ثم المستحقين
      if (a.remainingDebt < 0 && b.remainingDebt >= 0) return -1;
      if (a.remainingDebt >= 0 && b.remainingDebt < 0) return 1;

      // ثم الترتيب حسب القيمة المطلقة
      return b.remainingDebt.abs().compareTo(a.remainingDebt.abs());
    });
  }

  // تغيير الفلتر حسب النوع
  void setFilterType(String type) {
    _filterType = type;
    _applyFilters();
    notifyListeners();
  }

  // ⭐ تفعيل/إلغاء عرض المديونين فقط
  void toggleShowOnlyWithDebt() {
    _showOnlyWithDebt = !_showOnlyWithDebt;
    // إذا تم تفعيل فلتر المديونين، نلغي فلتر المستحقين
    if (_showOnlyWithDebt) {
      _showOnlyWithCredit = false;
    }
    _applyFilters();
    notifyListeners();
  }

  // ⭐ تفعيل/إلغاء عرض المستحقين فقط
  void toggleShowOnlyWithCredit() {
    _showOnlyWithCredit = !_showOnlyWithCredit;
    // إذا تم تفعيل فلتر المستحقين، نلغي فلتر المديونين
    if (_showOnlyWithCredit) {
      _showOnlyWithDebt = false;
    }
    _applyFilters();
    notifyListeners();
  }

  // إضافة مندوب/عميل جديد
  Future<bool> addRepresentative(Representative representative) async {
    try {
      final id = await _dbHelper.insertRepresentative(representative.toMap());
      if (id > 0) {
        await loadRepresentatives();
        debugPrint('Added representative with id: $id');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding representative: $e');
      return false;
    }
  }

  // تحديث مندوب/عميل
  Future<bool> updateRepresentative(Representative representative) async {
    try {
      if (representative.id == null) return false;

      final result = await _dbHelper.updateRepresentative(
        representative.id!,
        representative.toMap(),
      );

      if (result > 0) {
        await loadRepresentatives();
        debugPrint('Updated representative id: ${representative.id}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating representative: $e');
      return false;
    }
  }

  // حذف مندوب/عميل
  Future<bool> deleteRepresentative(int id) async {
    try {
      final result = await _dbHelper.deleteRepresentative(id);
      if (result > 0) {
        await loadRepresentatives();
        debugPrint('Deleted representative id: $id');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting representative: $e');
      return false;
    }
  }

  // الحصول على مندوب/عميل بالـ ID
  Representative? getRepresentativeById(int id) {
    try {
      return _representatives.firstWhere((rep) => rep.id == id);
    } catch (e) {
      return null;
    }
  }

  // إضافة دفعة لمندوب/عميل
  Future<bool> addPayment({
    required int representativeId,
    required double amount,
    String? notes,
    DateTime? paymentDateTime,
  }) async {
    try {
      final rep = getRepresentativeById(representativeId);
      if (rep == null) return false;

      // تحديث إجمالي المدفوع
      final updatedRep = rep.copyWith(
        totalPaid: rep.totalPaid + amount,
      );

      // حفظ معاملة الدفعة
      final transaction = RepresentativeTransaction(
        representativeId: representativeId,
        representativeName: rep.name,
        type: 'دفعة',
        amount: amount,
        paidAmount: amount,
        remainingDebt: updatedRep.remainingDebt,
        notes: notes,
        dateTime: paymentDateTime ?? DateTime.now(),
      );

      await _dbHelper.insertRepresentativeTransaction(transaction.toMap());
      await updateRepresentative(updatedRep);

      debugPrint('Added payment of $amount for representative ${rep.name}');
      return true;
    } catch (e) {
      debugPrint('Error adding payment: $e');
      return false;
    }
  }

  // سحب مستحقات من العميل/المندوب
  Future<bool> withdrawCredit({
    required int representativeId,
    required double amount,
    String? notes,
    DateTime? withdrawalDateTime,
  }) async {
    try {
      final rep = getRepresentativeById(representativeId);
      if (rep == null) return false;

      // التأكد من وجود مستحقات كافية
      if (rep.remainingDebt >= 0) {
        debugPrint('No credit available for withdrawal');
        return false;
      }

      final creditAmount = rep.remainingDebt.abs();
      if (amount > creditAmount) {
        debugPrint('Withdrawal amount exceeds available credit');
        return false;
      }

      // تحديث إجمالي المدفوع (تقليله بمقدار المبلغ المسحوب)
      final updatedRep = rep.copyWith(
        totalPaid: rep.totalPaid - amount,
      );

      // حفظ معاملة السحب
      final transaction = RepresentativeTransaction(
        representativeId: representativeId,
        representativeName: rep.name,
        type: 'سحب مستحقات',
        amount: amount,
        paidAmount: 0,
        remainingDebt: updatedRep.remainingDebt,
        notes: notes,
        dateTime: withdrawalDateTime ?? DateTime.now(),
      );

      await _dbHelper.insertRepresentativeTransaction(transaction.toMap());
      await updateRepresentative(updatedRep);

      debugPrint('Withdrew $amount from credit for representative ${rep.name}');
      return true;
    } catch (e) {
      debugPrint('Error withdrawing credit: $e');
      return false;
    }
  }

  // تسجيل عملية بيع آجلة
  Future<bool> recordDeferredSale({
    required int representativeId,
    required double totalAmount,
    required double paidAmount,
    required String productsSummary,
    String? invoiceNumber,
    List<int>? saleIds,
    String? notes,
    DateTime? saleDateTime,
  }) async {
    try {
      final rep = getRepresentativeById(representativeId);
      if (rep == null) return false;

      // تحديث إجمالي الديون والمدفوع
      final updatedRep = rep.copyWith(
        totalDebt: rep.totalDebt + totalAmount,
        totalPaid: rep.totalPaid + paidAmount,
      );

      // حفظ معاملة البيع
      final transaction = RepresentativeTransaction(
        representativeId: representativeId,
        representativeName: rep.name,
        type: 'بيع',
        amount: totalAmount,
        paidAmount: paidAmount,
        remainingDebt: updatedRep.remainingDebt,
        productsSummary: productsSummary,
        invoiceNumber: invoiceNumber,
        saleIds: saleIds?.join(','),
        notes: notes,
        dateTime: saleDateTime ?? DateTime.now(),
      );

      await _dbHelper.insertRepresentativeTransaction(transaction.toMap());
      await updateRepresentative(updatedRep);

      debugPrint('Recorded deferred sale for representative ${rep.name}');
      return true;
    } catch (e) {
      debugPrint('Error recording deferred sale: $e');
      return false;
    }
  }

  // تسجيل مرتجع
  Future<bool> recordReturn({
    required int representativeId,
    required double returnAmount,
    required String productsSummary,
    required String invoiceNumber,
    String? notes,
  }) async {
    try {
      final db = await _dbHelper.database;

      // الحصول على المندوب
      final repData = await db.query(
        'representatives',
        where: 'id = ?',
        whereArgs: [representativeId],
      );

      if (repData.isEmpty) {
        debugPrint('❌ المندوب غير موجود');
        return false;
      }

      final currentTotalDebt =
          (repData.first['totalDebt'] as num?)?.toDouble() ??
              (repData.first['total_debt'] as num?)?.toDouble() ??
              0.0;
      final currentTotalPaid =
          (repData.first['totalPaid'] as num?)?.toDouble() ??
              (repData.first['total_paid'] as num?)?.toDouble() ??
              0.0;

      debugPrint('📊 البيانات الحالية:');
      debugPrint('   - إجمالي الدين: $currentTotalDebt');
      debugPrint('   - إجمالي المدفوع: $currentTotalPaid');
      debugPrint('   - قيمة المرتجع: $returnAmount');

      // تحديث الحساب: تقليل الدين
      final newTotalDebt = currentTotalDebt - returnAmount;
      final newRemainingDebt = newTotalDebt - currentTotalPaid;

      debugPrint('📊 البيانات الجديدة:');
      debugPrint('   - إجمالي الدين الجديد: $newTotalDebt');
      debugPrint('   - المتبقي الجديد: $newRemainingDebt');

      final representative = getRepresentativeById(representativeId);
      if (representative == null) {
        debugPrint('❌ فشل في الحصول على بيانات المندوب');
        return false;
      }

      final updatedRep = representative.copyWith(
        totalDebt: newTotalDebt,
        totalPaid: currentTotalPaid,
      );

      final updateSuccess = await updateRepresentative(updatedRep);

      if (!updateSuccess) {
        debugPrint('❌ فشل تحديث بيانات المندوب');
        return false;
      }

      final transactionResult = await db.insert('representative_transactions', {
        'representativeId': representativeId,
        'representativeName': representative.name,
        'type': 'مرتجع',
        'amount': returnAmount,
        'paidAmount': 0,
        'remainingDebt': newRemainingDebt,
        'productsSummary': productsSummary,
        'invoiceNumber': invoiceNumber,
        'notes': notes,
        'dateTime': DateTime.now().toIso8601String(),
      });

      if (transactionResult == 0) {
        debugPrint('❌ فشل تسجيل معاملة المرتجع');
        return false;
      }

      debugPrint('✅ تم تسجيل المرتجع بنجاح - الدين الجديد: $newRemainingDebt');

      return true;
    } catch (e) {
      debugPrint('❌ Error recording return: $e');
      return false;
    }
  }

  Future<List<RepresentativeTransaction>> getTransactions(
      int representativeId) async {
    try {
      final data =
          await _dbHelper.getRepresentativeTransactions(representativeId);
      return data.map((map) => RepresentativeTransaction.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }

  // الحصول على جميع المعاملات
  Future<List<RepresentativeTransaction>> getAllTransactions() async {
    try {
      final data = await _dbHelper.getAllRepresentativeTransactions();
      return data.map((map) => RepresentativeTransaction.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting all transactions: $e');
      return [];
    }
  }

  // البحث عن مندوب/عميل
  List<Representative> searchRepresentatives(String query) {
    if (query.isEmpty) {
      return _filteredRepresentatives;
    }

    return _filteredRepresentatives.where((rep) {
      return rep.name.toLowerCase().contains(query.toLowerCase()) ||
          (rep.phone?.contains(query) ?? false);
    }).toList();
  }

  // الحصول على أعلى 5 مديونين
  List<Representative> getTopDebtors() {
    final debtors = _representatives.where((r) => r.remainingDebt > 0).toList();
    debtors.sort((a, b) => b.remainingDebt.compareTo(a.remainingDebt));
    return debtors.take(5).toList();
  }

  // ⭐ الحصول على أعلى 5 مستحقين
  List<Representative> getTopCreditors() {
    final creditors =
        _representatives.where((r) => r.remainingDebt < 0).toList();
    creditors.sort((a, b) => a.remainingDebt.compareTo(b.remainingDebt));
    return creditors.take(5).toList();
  }

  // ⭐ حذف معاملة مع إعادة حساب الأرصدة
  Future<bool> deleteTransaction(int transactionId) async {
    try {
      final db = DatabaseHelper.instance;

      // ⭐ 1. الحصول على بيانات المعاملة قبل الحذف
      final database = await db.database;
      final txList = await database.query(
        'representative_transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (txList.isEmpty) return false;

      final txData = txList.first;
      final representativeId = txData['representativeId'] as int;

      // ⭐ 2. حذف المعاملة
      await database.delete(
        'representative_transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      // ⭐ 3. إعادة حساب الأرصدة من الصفر
      await _recalculateRepresentativeBalance(representativeId);

      // ⭐ 4. تحديث القائمة
      await loadRepresentatives();
      notifyListeners();

      return true;
    } catch (e) {
      return false;
    }
  }

// ⭐ دالة مساعدة لإعادة حساب الرصيد من الصفر
  Future<void> _recalculateRepresentativeBalance(int representativeId) async {
    try {
      final db = DatabaseHelper.instance;
      final database = await db.database;

      // جلب جميع المعاملات المتبقية
      final transactions = await database.query(
        'representative_transactions',
        where: 'representativeId = ?',
        whereArgs: [representativeId],
        orderBy: 'dateTime ASC',
      );

      double totalDebt = 0;
      double totalPaid = 0;
      double runningBalance = 0;

      // إعادة حساب كل معاملة
      for (var tx in transactions) {
        final type = tx['type'] as String;
        final amount = tx['amount'] as double;
        final paidAmount = tx['paidAmount'] as double;

        if (type == 'بيع') {
          totalDebt += amount;
          totalPaid += paidAmount;
          runningBalance += (amount - paidAmount);
        } else if (type == 'دفعة') {
          totalPaid += amount;
          runningBalance -= amount;
        } else if (type == 'مرتجع') {
          totalDebt -= amount;
          runningBalance -= amount;
        } else if (type == 'سحب مستحقات') {
          totalDebt += amount;
          runningBalance += amount;
        } else if (type == 'دين مباشر') {
          totalDebt += amount;
          runningBalance += amount;
        } else if (type == 'إيداع رصيد') {
          // ⭐⭐⭐ إضافة رصيد يقلل الدين (مثل الدفعة)
          totalPaid += amount;
          runningBalance -= amount;
        }

        // تحديث remainingDebt لكل معاملة
        await database.update(
          'representative_transactions',
          {'remainingDebt': runningBalance},
          where: 'id = ?',
          whereArgs: [tx['id']],
        );
      }

      // تحديث جدول المندوبين
      await database.update(
        'representatives',
        {
          'totalDebt': totalDebt,
          'totalPaid': totalPaid,
        },
        where: 'id = ?',
        whereArgs: [representativeId],
      );
    } catch (e) {
      rethrow;
    }
  }

// ⭐ إضافة دين مباشر
  Future<bool> addDirectDebt({
    required int representativeId,
    required double amount,
    String? notes,
    DateTime? debtDateTime,
  }) async {
    try {
      final db = DatabaseHelper.instance;

      // الحصول على بيانات المندوب/العميل
      final rep = _representatives.firstWhere((r) => r.id == representativeId);

      // إضافة المعاملة (سنحسب الرصيد لاحقاً)
      await db.insertRepresentativeTransaction({
        'representativeId': representativeId,
        'representativeName': rep.name,
        'type': 'دين مباشر',
        'amount': amount,
        'paidAmount': 0,
        'remainingDebt': 0, // ⭐ سيتم حسابه في إعادة الحساب
        'dateTime': (debtDateTime ?? DateTime.now()).toIso8601String(),
        'notes': notes,
        'productsSummary': null,
        'invoiceNumber': null,
        'saleIds': null,
      });

      // ⭐ إعادة حساب الأرصدة
      await _recalculateRepresentativeBalance(representativeId);

      await loadRepresentatives();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

// ⭐⭐⭐ إضافة رصيد (فلوس) للحساب
  Future<bool> addCreditToAccount({
    required int representativeId,
    required double amount,
    String? notes,
    DateTime? creditDateTime,
  }) async {
    try {
      final db = DatabaseHelper.instance;

      // الحصول على بيانات المندوب/العميل
      final rep = _representatives.firstWhere((r) => r.id == representativeId);

      // إضافة المعاملة
      await db.insertRepresentativeTransaction({
        'representativeId': representativeId,
        'representativeName': rep.name,
        'type': 'إيداع رصيد', // ⭐ نوع جديد
        'amount': amount,
        'paidAmount': 0,
        'remainingDebt': 0, // سيتم حسابه
        'dateTime': (creditDateTime ?? DateTime.now()).toIso8601String(),
        'notes': notes,
        'productsSummary': null,
        'invoiceNumber': null,
        'saleIds': null,
      });

      // ⭐ إعادة حساب الأرصدة
      await _recalculateRepresentativeBalance(representativeId);

      await loadRepresentatives();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
