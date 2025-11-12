// lib/screens/add_maintenance_screen.dart (محدث مع Responsive + إخفاء التاريخ + التنقل بالـ Enter)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/models/maintenance_department.dart';
import 'package:soundtry/services/database_helper.dart';
import 'package:soundtry/utils/responsive.dart';
import '../models/maintenance_record.dart';
import '../providers/maintenance_provider.dart';

class AddMaintenanceScreen extends StatefulWidget {
  final MaintenanceRecord? record;

  const AddMaintenanceScreen({super.key, this.record});

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _deviceTypeController;
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _problemController;
  late TextEditingController _costController;
  late TextEditingController _paidAmountController;

  // FocusNodes للتنقل بالـ Enter
  final FocusNode _customerNameFocus = FocusNode();
  final FocusNode _customerPhoneFocus = FocusNode();
  final FocusNode _deviceTypeFocus = FocusNode();
  final FocusNode _problemFocus = FocusNode();
  final FocusNode _costFocus = FocusNode();
  final FocusNode _paidAmountFocus = FocusNode();

  DateTime? _selectedReceivedDate;
  TimeOfDay? _selectedReceivedTime;
  bool _showDateTimeFields = false; // ⭐ للتحكم في إظهار الحقول

  String _selectedStatus = 'قيد الإصلاح';
  final bool _isSaving = false;
  bool get _isEditing => widget.record != null;

  final List<String> _statusOptions = [
    'قيد الإصلاح',
    'جاهز للاستلام',
    'تم التسليم',
    'ملغي',
    'مرفوض',
  ];

  int? _selectedDepartmentId;
  List<MaintenanceDepartment> _departments = [];
  bool _departmentsLoaded = false;

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    _deviceTypeController = TextEditingController(
      text: record?.deviceType ?? '',
    );
    _customerNameController = TextEditingController(
      text: record?.customerName ?? '',
    );
    _customerPhoneController = TextEditingController(
      text: record?.customerPhone ?? '',
    );
    _problemController = TextEditingController(
      text: record?.problemDescription ?? '',
    );
    _costController = TextEditingController(
      text: record?.cost.toString() ?? '0',
    );
    _paidAmountController = TextEditingController(
      text: record?.paidAmount.toString() ?? '0',
    );

    if (widget.record != null) {
      _selectedStatus = widget.record!.status;
      _selectedReceivedDate = widget.record!.receivedDate;
      _selectedReceivedTime = TimeOfDay(
        hour: widget.record!.receivedDate.hour,
        minute: widget.record!.receivedDate.minute,
      );
      _showDateTimeFields = true; // إظهار الحقول في حالة التعديل
    }

    _loadDepartments();
  }

  @override
  void dispose() {
    _customerNameFocus.dispose();
    _customerPhoneFocus.dispose();
    _deviceTypeFocus.dispose();
    _problemFocus.dispose();
    _costFocus.dispose();
    _paidAmountFocus.dispose();
    super.dispose();
  }

  String? _validatePaidAmount(String? value) {
    if (value == null || value.isEmpty) return null;

    final paidAmount = double.tryParse(value);
    final cost = double.tryParse(_costController.text) ?? 0;

    if (paidAmount == null) return 'رقم غير صحيح';
    if (paidAmount < 0) return 'لا يمكن أن يكون سالب';
    if (paidAmount > cost) {
      return 'المدفوع لا يمكن أن يكون أكبر من التكلفة';
    }

    return null;
  }

  Future<void> _loadDepartments() async {
    try {
      final db = DatabaseHelper.instance;
      final data = await db.getMaintenanceDepartments();

      if (mounted) {
        setState(() {
          _departments =
              data.map((d) => MaintenanceDepartment.fromMap(d)).toList();
          _departmentsLoaded = true;

          if (widget.record != null && widget.record!.departmentId != null) {
            final deptExists =
                _departments.any((d) => d.id == widget.record!.departmentId);
            if (deptExists) {
              _selectedDepartmentId = widget.record!.departmentId;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading departments: $e');
      if (mounted) {
        setState(() {
          _departmentsLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    if (!_departmentsLoaded) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('جاري التحميل...'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.record == null ? 'استلام جهاز جديد' : 'تفاصيل الصيانة'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: Responsive.isDesktop(context) ? 1700 : double.infinity,
            maxHeight: Responsive.isDesktop(context) ? 1000 : double.infinity,
          ),
          padding: Responsive.paddingAll(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صف واحد يحتوي على كل الحقول الأساسية
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // العمود الأول - معلومات العميل والجهاز
                      Expanded(
                        child: _buildSection(
                          'معلومات العميل والجهاز',
                          Icons.info,
                          Colors.blue,
                          [
                            _buildTextField(
                              _customerNameController,
                              'اسم العميل *',
                              Icons.person,
                              focusNode: _customerNameFocus,
                              nextFocus: _customerPhoneFocus,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'مطلوب'
                                      : null,
                            ),
                            SizedBox(height: Responsive.height(12)),
                            _buildTextField(
                              _customerPhoneController,
                              'رقم الهاتف *',
                              Icons.phone,
                              keyboardType: TextInputType.phone,
                              focusNode: _customerPhoneFocus,
                              nextFocus: _deviceTypeFocus,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'مطلوب'
                                      : null,
                            ),
                            SizedBox(height: Responsive.height(12)),
                            _buildTextField(
                              _deviceTypeController,
                              'نوع الجهاز *',
                              Icons.devices,
                              focusNode: _deviceTypeFocus,
                              nextFocus: _problemFocus,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'مطلوب'
                                      : null,
                            ),
                            SizedBox(height: Responsive.height(12)),
                            _buildDepartmentDropdown(),
                          ],
                        ),
                      ),

                      SizedBox(width: Responsive.width(16)),

                      // العمود الثاني - وصف العطل والحالة
                      Expanded(
                        child: _buildSection(
                          'وصف العطل والحالة',
                          Icons.report_problem,
                          Colors.orange,
                          [
                            _buildTextField(
                              _problemController,
                              'وصف العطل *',
                              Icons.description,
                              maxLines: 4,
                              focusNode: _problemFocus,
                              nextFocus: _costFocus,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'مطلوب'
                                      : null,
                            ),
                            SizedBox(height: Responsive.height(12)),
                            _buildStatusDropdown(),
                          ],
                        ),
                      ),

                      SizedBox(width: Responsive.width(16)),

                      // العمود الثالث - التكاليف
                      Expanded(
                        child: _buildSection(
                          'التكاليف والدفع',
                          Icons.attach_money,
                          Colors.teal,
                          [
                            _buildTextField(
                              _costController,
                              'التكلفة',
                              Icons.paid,
                              keyboardType: TextInputType.number,
                              focusNode: _costFocus,
                              nextFocus: _paidAmountFocus,
                              validator: (value) {
                                if (value == null || value.isEmpty) return null;
                                final cost = double.tryParse(value);
                                if (cost == null || cost < 0) return 'رقم صحيح';
                                return null;
                              },
                            ),
                            SizedBox(height: Responsive.height(12)),
                            _buildTextField(
                              _paidAmountController,
                              'المبلغ المدفوع',
                              Icons.payment,
                              keyboardType: TextInputType.number,
                              focusNode: _paidAmountFocus,
                              validator: _validatePaidAmount,
                            ),
                            SizedBox(height: Responsive.height(16)),
                            _buildRemainingAmount(),
                            if (_isEditing) ...[
                              SizedBox(height: Responsive.height(12)),
                              ElevatedButton.icon(
                                onPressed: _showPaymentDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة دفعة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size(double.infinity, 45),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: Responsive.height(24)),

                  // ⭐ زر إظهار/إخفاء التاريخ والوقت
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showDateTimeFields = !_showDateTimeFields;
                        });
                      },
                      icon: Icon(_showDateTimeFields
                          ? Icons.keyboard_arrow_up
                          : Icons.access_time),
                      label: Text(_showDateTimeFields
                          ? 'إخفاء تعديل التاريخ والوقت'
                          : 'تعديل تاريخ ووقت الاستلام'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),

                  // ⭐ حقول التاريخ والوقت (تظهر عند الضغط)
                  if (_showDateTimeFields) ...[
                    SizedBox(height: Responsive.height(16)),
                    _buildSection(
                      'تاريخ ووقت الاستلام',
                      Icons.calendar_today,
                      Colors.indigo,
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePicker(),
                            ),
                            SizedBox(width: Responsive.width(16)),
                            Expanded(
                              child: _buildTimePicker(),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.height(12)),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedReceivedDate = null;
                              _selectedReceivedTime = null;
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('استخدام الوقت الحالي'),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: Responsive.height(32)),

                  // أزرار الحفظ والإلغاء
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _confirmSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('حفظ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.width(48),
                            vertical: Responsive.height(16),
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.width(16)),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.cancel),
                        label: const Text('إلغاء'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.width(48),
                            vertical: Responsive.height(16),
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
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
      ),
      child: Padding(
        padding: Responsive.paddingAll(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: Responsive.paddingAll(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Responsive.radius(8)),
                  ),
                  child: Icon(icon, color: color, size: Responsive.icon(24)),
                ),
                SizedBox(width: Responsive.width(12)),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.font(16),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.height(16)),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    FocusNode? nextFocus,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(Responsive.radius(8)),
        ),
        contentPadding: Responsive.paddingSym(h: 12, v: 12),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      textInputAction:
          nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<int?>(
      initialValue: _selectedDepartmentId,
      decoration: InputDecoration(
        labelText: 'القسم *',
        prefixIcon: const Icon(Icons.folder),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(8)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: Responsive.paddingSym(h: 12, v: 12),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('اختر القسم'),
        ),
        ..._departments.map((dept) {
          return DropdownMenuItem<int?>(
            value: dept.id,
            child: Row(
              children: [
                Icon(Icons.folder, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(dept.name),
              ],
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedDepartmentId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'الرجاء اختيار القسم';
        }
        return null;
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'الحالة',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(8)),
        ),
        prefixIcon: const Icon(Icons.flag),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: Responsive.paddingSym(h: 12, v: 12),
      ),
      items: _statusOptions.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(status),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedStatus = value!;
        });
      },
    );
  }

  Widget _buildRemainingAmount() {
    return Container(
      padding: Responsive.paddingAll(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(Responsive.radius(8)),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'المتبقي:',
            style: TextStyle(
              fontSize: Responsive.font(14),
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(
            _calculateRemaining(),
            style: TextStyle(
              fontSize: Responsive.font(20),
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedReceivedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() {
            _selectedReceivedDate = date;
          });
        }
      },
      child: Container(
        padding: Responsive.paddingAll(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(Responsive.radius(8)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.indigo),
            SizedBox(width: Responsive.width(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'التاريخ',
                    style: TextStyle(
                      fontSize: Responsive.font(12),
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedReceivedDate != null
                        ? DateFormat('yyyy-MM-dd')
                            .format(_selectedReceivedDate!)
                        : 'الوقت الحالي',
                    style: TextStyle(
                      fontSize: Responsive.font(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedReceivedTime ?? TimeOfDay.now(),
        );
        if (time != null) {
          setState(() {
            _selectedReceivedTime = time;
          });
        }
      },
      child: Container(
        padding: Responsive.paddingAll(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(Responsive.radius(8)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.indigo),
            SizedBox(width: Responsive.width(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الوقت',
                    style: TextStyle(
                      fontSize: Responsive.font(12),
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedReceivedTime != null
                        ? _selectedReceivedTime!.format(context)
                        : 'الوقت الحالي',
                    style: TextStyle(
                      fontSize: Responsive.font(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateRemaining() {
    final cost = double.tryParse(_costController.text) ?? 0;
    final paidAmount = double.tryParse(_paidAmountController.text) ?? 0;
    final remaining = cost - paidAmount;
    return '${remaining.toStringAsFixed(2)} جنيه';
  }

  void _showPaymentDialog() {
    final paymentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دفعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'المبلغ المتبقي: ${_calculateRemaining()}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paymentController,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
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
              final amount = double.tryParse(paymentController.text);
              if (amount != null && amount > 0) {
                setState(() {
                  final currentPaid =
                      double.tryParse(_paidAmountController.text) ?? 0;
                  _paidAmountController.text =
                      (currentPaid + amount).toString();
                });
                Navigator.pop(context);

                if (_isEditing) {
                  _addPayment(amount);
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPayment(double amount) async {
    try {
      final provider = Provider.of<MaintenanceProvider>(context, listen: false);
      await provider.addPayment(widget.record!.id!, amount);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة الدفعة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmSave() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_isEditing ? 'تأكيد التعديل' : 'تأكيد الحفظ'),
          content: Text(
            _isEditing ? 'هل تريد حفظ التعديلات؟' : 'هل تريد حفظ سجل الصيانة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveRecord();
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      String? departmentName;
      if (_selectedDepartmentId != null) {
        final dept =
            _departments.firstWhere((d) => d.id == _selectedDepartmentId);
        departmentName = dept.name;
      }

      DateTime receivedDateTime;
      if (_selectedReceivedDate != null) {
        final date = _selectedReceivedDate!;
        final time = _selectedReceivedTime ?? TimeOfDay.now();
        receivedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      } else {
        receivedDateTime = widget.record?.receivedDate ?? DateTime.now();
      }

      final record = MaintenanceRecord(
        id: widget.record?.id,
        deviceType: _deviceTypeController.text,
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        problemDescription: _problemController.text,
        status: _selectedStatus,
        cost: double.tryParse(_costController.text) ?? 0,
        paidAmount: double.tryParse(_paidAmountController.text) ?? 0,
        receivedDate: receivedDateTime,
        deliveryDate: _selectedStatus == 'تم التسليم' ? DateTime.now() : null,
        repairCode: widget.record?.repairCode,
        departmentId: _selectedDepartmentId,
        departmentName: departmentName,
      );

      final provider = Provider.of<MaintenanceProvider>(context, listen: false);

      if (widget.record == null) {
        await provider.addMaintenanceRecord(record);
      } else {
        await provider.updateMaintenanceRecord(record);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.record == null
                  ? 'تم استلام الجهاز بنجاح'
                  : 'تم تحديث السجل بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {}
    }
  }
}
