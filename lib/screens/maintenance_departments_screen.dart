// lib/screens/maintenance_departments_screen.dart

import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/maintenance_department.dart';

class MaintenanceDepartmentsScreen extends StatefulWidget {
  const MaintenanceDepartmentsScreen({super.key});

  @override
  State<MaintenanceDepartmentsScreen> createState() =>
      _MaintenanceDepartmentsScreenState();
}

class _MaintenanceDepartmentsScreenState
    extends State<MaintenanceDepartmentsScreen> {
  List<MaintenanceDepartment> _departments = [];
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final db = DatabaseHelper.instance;
    final data = await db.getMaintenanceDepartments();
    setState(() {
      _departments = data.map((d) => MaintenanceDepartment.fromMap(d)).toList();
    });
  }

  Future<void> _addDepartment() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم القسم')),
      );
      return;
    }

    final dept = MaintenanceDepartment(
      name: _nameController.text,
      description: _descController.text.isEmpty ? null : _descController.text,
    );

    final db = DatabaseHelper.instance;
    await db.insertMaintenanceDepartment(dept.toMap());

    _nameController.clear();
    _descController.clear();
    _loadDepartments();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة القسم بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة أقسام الصيانة'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم القسم',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'الوصف (اختياري)',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _addDepartment,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة قسم'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
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
            child: _departments.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد أقسام',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2,
                    ),
                    itemCount: _departments.length,
                    itemBuilder: (context, index) {
                      final dept = _departments[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _editDepartment(dept),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.folder,
                                        color: Colors.blue[700],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        dept.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red, size: 20),
                                      onPressed: () =>
                                          _deleteDepartment(dept.id!),
                                    ),
                                  ],
                                ),
                                if (dept.description != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    dept.description!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _editDepartment(MaintenanceDepartment dept) {
    _nameController.text = dept.name;
    _descController.text = dept.description ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل القسم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم القسم',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'الوصف',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              _descController.clear();
              Navigator.pop(context);
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = MaintenanceDepartment(
                id: dept.id,
                name: _nameController.text,
                description:
                    _descController.text.isEmpty ? null : _descController.text,
                createdAt: dept.createdAt,
              );

              final db = DatabaseHelper.instance;
              await db.updateMaintenanceDepartment(dept.id!, updated.toMap());

              _nameController.clear();
              _descController.clear();
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadDepartments();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم التعديل بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteDepartment(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا القسم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = DatabaseHelper.instance;
              await db.deleteMaintenanceDepartment(id);
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadDepartments();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم الحذف بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
