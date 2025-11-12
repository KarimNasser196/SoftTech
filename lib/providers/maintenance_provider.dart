// lib/providers/maintenance_provider.dart (محدث مع إحصائيات يومية وإصلاح السجلات)

import 'package:flutter/foundation.dart';
import '../models/maintenance_record.dart';
import '../services/database_helper.dart';

class MaintenanceProvider with ChangeNotifier {
  List<MaintenanceRecord> _maintenanceRecords = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MaintenanceRecord> get maintenanceRecords => _maintenanceRecords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // إحصائيات عامة
  int get totalRecords => _maintenanceRecords.length;

  int get pendingRecords =>
      _maintenanceRecords.where((r) => r.status == 'قيد الإصلاح').length;

  int get readyForPickup =>
      _maintenanceRecords.where((r) => r.status == 'جاهز للاستلام').length;

  int get completedRecords =>
      _maintenanceRecords.where((r) => r.status == 'تم التسليم').length;

  int get rejectedRecords =>
      _maintenanceRecords.where((r) => r.status == 'مرفوض').length;

  double get totalRevenue => _maintenanceRecords
      .where((r) => r.status == 'تم التسليم')
      .fold<double>(0, (sum, r) => sum + r.cost);

  double get totalPaid =>
      _maintenanceRecords.fold<double>(0, (sum, r) => sum + r.paidAmount);

  double get totalRemaining => _maintenanceRecords
      .where((r) =>
          r.status != 'تم التسليم' && r.status != 'ملغي' && r.status != 'مرفوض')
      .fold<double>(0, (sum, r) => sum + r.remainingAmount);

  int get cancelledRecords {
    return _maintenanceRecords.where((r) => r.status == 'ملغي').length;
  }

  Map<String, double> getFinancialStatisticsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    double revenue = 0;
    double remainingInProgress = 0;
    double remainingAfterDelivery = 0; // ⭐ جديد

    for (var record in _maintenanceRecords) {
      final recordDate = record.receivedDate;

      final isInRange =
          recordDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
              recordDate.isBefore(end.add(const Duration(seconds: 1)));

      if (!isInRange) continue;

      // حساب الإيرادات
      double actualPaid = record.paidAmount;
      if (actualPaid == 0 && record.status == 'تم التسليم' && record.cost > 0) {
        actualPaid = record.cost;
      }
      revenue += actualPaid;

      // ⭐ تقسيم المتبقي
      if (record.status == 'قيد الإصلاح' || record.status == 'جاهز للاستلام') {
        remainingInProgress += record.remainingAmount;
      } else if (record.status == 'تم التسليم') {
        remainingAfterDelivery += record.remainingAmount;
      }
    }

    return {
      'revenue': revenue,
      'remaining': remainingInProgress,
      'remainingAfterDelivery': remainingAfterDelivery, // ⭐ جديد
    };
  }

  Map<String, double> _calculateAllTimeFinancials() {
    double revenue = 0;
    double remainingInProgress =
        0; // المتبقي في "قيد الإصلاح" و "جاهز للاستلام"
    double remainingAfterDelivery = 0; // ⭐ المتبقي بعد التسليم

    for (var record in _maintenanceRecords) {
      // حساب الإيرادات (المدفوع فعلياً)
      double actualPaid = record.paidAmount;
      if (actualPaid == 0 && record.status == 'تم التسليم' && record.cost > 0) {
        actualPaid = record.cost;
      }
      revenue += actualPaid;

      // ⭐ تقسيم المتبقي حسب الحالة
      if (record.status == 'قيد الإصلاح' || record.status == 'جاهز للاستلام') {
        remainingInProgress += record.remainingAmount;
      } else if (record.status == 'تم التسليم') {
        // ⭐ الديون بعد التسليم
        remainingAfterDelivery += record.remainingAmount;
      }
    }

    return {
      'revenue': revenue,
      'remaining': remainingInProgress, // المتبقي العادي
      'remainingAfterDelivery': remainingAfterDelivery, // ⭐ المتبقي بعد التسليم
    };
  }

  Map<String, int> getTodayStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return {
      'received': _maintenanceRecords.where((r) {
        final date = DateTime(
            r.receivedDate.year, r.receivedDate.month, r.receivedDate.day);
        return date == today;
      }).length,
      'inProgress': _maintenanceRecords.where((r) {
        final date = DateTime(
            r.receivedDate.year, r.receivedDate.month, r.receivedDate.day);
        return date == today && r.status == 'قيد الإصلاح';
      }).length,
      'ready': _maintenanceRecords.where((r) {
        final date = DateTime(
            r.receivedDate.year, r.receivedDate.month, r.receivedDate.day);
        return date == today && r.status == 'جاهز للاستلام';
      }).length,
      'delivered': _maintenanceRecords.where((r) {
        final date = DateTime(
            r.receivedDate.year, r.receivedDate.month, r.receivedDate.day);
        return date == today && r.status == 'تم التسليم';
      }).length,
      'cancelled': _maintenanceRecords.where((r) {
        final date = DateTime(
            r.receivedDate.year, r.receivedDate.month, r.receivedDate.day);
        return date == today && r.status == 'ملغي';
      }).length,
      'rejected': _maintenanceRecords.where((r) {
        final date = DateTime(
            r.receivedDate.year, r.receivedDate.month, r.receivedDate.day);
        return date == today && r.status == 'مرفوض';
      }).length,
    };
  }

  Map<String, double> getFinancialStatistics(String period) {
    final now = DateTime.now();
    DateTime? start;

    switch (period) {
      case 'اليوم':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'هذا الأسبوع':
        int daysToSubtract = (now.weekday + 1) % 7;
        start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: daysToSubtract));
        break;
      case 'هذا الشهر':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'الكل':
        return _calculateAllTimeFinancials();
      default:
        return _calculateAllTimeFinancials();
    }

    return getFinancialStatisticsByDateRange(start, now);
  }

  Map<String, int> getStatisticsByDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);

    final dateRecords = _maintenanceRecords.where((r) {
      final recordDate = DateTime(
        r.receivedDate.year,
        r.receivedDate.month,
        r.receivedDate.day,
      );
      return recordDate == targetDate;
    }).toList();

    return {
      'received': dateRecords.length,
      'inProgress': dateRecords.where((r) => r.status == 'قيد الإصلاح').length,
      'ready': dateRecords.where((r) => r.status == 'جاهز للاستلام').length,
      'delivered': dateRecords.where((r) => r.status == 'تم التسليم').length,
      'rejected': dateRecords.where((r) => r.status == 'مرفوض').length,
      'cancelled': dateRecords.where((r) => r.status == 'ملغي').length,
    };
  }

  Map<String, int> getStatisticsByPeriod(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final periodRecords = _maintenanceRecords.where((r) {
      return r.receivedDate.isAfter(start) && r.receivedDate.isBefore(end);
    }).toList();

    return {
      'received': periodRecords.length,
      'inProgress':
          periodRecords.where((r) => r.status == 'قيد الإصلاح').length,
      'ready': periodRecords.where((r) => r.status == 'جاهز للاستلام').length,
      'delivered': periodRecords.where((r) => r.status == 'تم التسليم').length,
      'rejected': periodRecords.where((r) => r.status == 'مرفوض').length,
      'cancelled': periodRecords.where((r) => r.status == 'ملغي').length,
    };
  }

  MaintenanceProvider() {
    _initializeData();
  }

  void _initializeData() {
    Future.delayed(Duration.zero, () async {
      try {
        _isLoading = true;
        notifyListeners();

        await fetchMaintenanceRecords();

        // ⭐ إصلاح السجلات القديمة (مرة واحدة فقط)
        await fixOldMaintenanceRecords();

        _isLoading = false;
        notifyListeners();
      } catch (e) {
        debugPrint('Error initializing maintenance data: $e');
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  // ⭐ دالة إصلاح السجلات القديمة
  Future<void> fixOldMaintenanceRecords() async {
    try {
      int fixedCount = 0;

      for (var record in _maintenanceRecords) {
        // إذا كان paidAmount = 0 والحالة "تم التسليم"
        if (record.paidAmount == 0 &&
            record.status == 'تم التسليم' &&
            record.cost > 0) {
          final updatedRecord = record.copyWith(
            paidAmount: record.cost, // افترض أنه دفع بالكامل
          );

          await updateMaintenanceRecord(updatedRecord);
          fixedCount++;
        }
      }

      if (fixedCount > 0) {
        debugPrint('✅ Fixed $fixedCount old maintenance records');
        await fetchMaintenanceRecords(); // إعادة جلب البيانات
      }
    } catch (e) {
      debugPrint('❌ Error fixing old records: $e');
    }
  }

  Future<void> fetchMaintenanceRecords() async {
    try {
      final dbHelper = DatabaseHelper.instance;

      final recordsData = await dbHelper.getMaintenanceRecords();

      final departmentsData = await dbHelper.getMaintenanceDepartments();
      final departments = {
        for (var d in departmentsData) d['id'] as int: d['name'] as String
      };

      _maintenanceRecords = recordsData.map((data) {
        final record = MaintenanceRecord.fromMap(data);
        if (record.departmentId != null &&
            departments.containsKey(record.departmentId)) {
          return record.copyWith(
            departmentName: departments[record.departmentId],
          );
        }
        return record;
      }).toList();

      _maintenanceRecords
          .sort((a, b) => b.receivedDate.compareTo(a.receivedDate));

      debugPrint('Fetched ${_maintenanceRecords.length} maintenance records');
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching maintenance records: $e');
      _maintenanceRecords = [];
      _errorMessage = 'فشل في جلب سجلات الصيانة: $e';
      notifyListeners();
    }
  }

  // باقي الدوال كما هي...
  Future<void> addMaintenanceRecord(MaintenanceRecord record) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final id = await dbHelper.insertMaintenanceRecord(record.toMap());

      if (id == -1) throw Exception('فشل في إضافة سجل الصيانة');

      final newRecord = record.copyWith(id: id);
      _maintenanceRecords.insert(0, newRecord);

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding maintenance record: $e');
      _errorMessage = 'فشل في إضافة سجل الصيانة: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMaintenanceRecord(MaintenanceRecord record) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final result = await dbHelper.updateMaintenanceRecord(
        record.id!,
        record.toMap(),
      );

      if (result == 0) throw Exception('فشل في تحديث سجل الصيانة');

      final index = _maintenanceRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _maintenanceRecords[index] = record;
      }

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating maintenance record: $e');
      _errorMessage = 'فشل في تحديث سجل الصيانة: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMaintenanceRecord(int id) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final result = await dbHelper.deleteMaintenanceRecord(id);

      if (result == 0) throw Exception('فشل في حذف سجل الصيانة');

      _maintenanceRecords.removeWhere((r) => r.id == id);

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting maintenance record: $e');
      _errorMessage = 'فشل في حذف سجل الصيانة: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateStatus(int id, String newStatus) async {
    try {
      final record = _maintenanceRecords.firstWhere((r) => r.id == id);

      final updatedRecord = record.copyWith(
        status: newStatus,
        deliveryDate:
            newStatus == 'تم التسليم' ? DateTime.now() : record.deliveryDate,
      );

      await updateMaintenanceRecord(updatedRecord);
    } catch (e) {
      debugPrint('Error updating status: $e');
      rethrow;
    }
  }

  Future<void> addPayment(int id, double amount) async {
    try {
      final record = _maintenanceRecords.firstWhere((r) => r.id == id);
      final newPaidAmount = record.paidAmount + amount;

      if (newPaidAmount > record.cost) {
        throw Exception('المبلغ المدفوع أكبر من التكلفة');
      }

      final updatedRecord = record.copyWith(paidAmount: newPaidAmount);
      await updateMaintenanceRecord(updatedRecord);
    } catch (e) {
      debugPrint('Error adding payment: $e');
      rethrow;
    }
  }

  List<MaintenanceRecord> getRecordsByStatus(String status) {
    return _maintenanceRecords.where((r) => r.status == status).toList();
  }

  List<MaintenanceRecord> searchRecords(String query) {
    if (query.isEmpty) return _maintenanceRecords;

    final lowerQuery = query.toLowerCase();
    return _maintenanceRecords.where((r) {
      return r.customerName.toLowerCase().contains(lowerQuery) ||
          r.customerPhone.contains(query) ||
          r.deviceType.toLowerCase().contains(lowerQuery) ||
          r.problemDescription.toLowerCase().contains(lowerQuery) ||
          r.repairCode.contains(query);
    }).toList();
  }

  Future<MaintenanceRecord?> getRecordByCode(String repairCode) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final recordData = await dbHelper.getMaintenanceRecordByCode(repairCode);

      if (recordData != null) {
        return MaintenanceRecord.fromMap(recordData);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting record by code: $e');
      return null;
    }
  }

  Future<MaintenanceRecord?> getRecordByPhone(String phone) async {
    try {
      final records =
          _maintenanceRecords.where((r) => r.customerPhone == phone).toList();
      if (records.isNotEmpty) {
        return records.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting record by phone: $e');
      return null;
    }
  }

  Map<String, int> getStatusStatistics() {
    final stats = <String, int>{};
    for (var record in _maintenanceRecords) {
      stats[record.status] = (stats[record.status] ?? 0) + 1;
    }
    return stats;
  }
}
