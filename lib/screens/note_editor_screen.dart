// lib/screens/note_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../utils/responsive.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _categoryController;

  Color _selectedColor = Colors.white;
  String? _selectedCategory;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.note != null;

    _titleController = TextEditingController(
      text: widget.note?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _categoryController = TextEditingController();

    _selectedColor = widget.note?.color ?? NoteColors.colors[0];
    _selectedCategory = widget.note?.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل الملاحظة' : 'ملاحظة جديدة',
          style: TextStyle(fontSize: Responsive.font(20)),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.check, size: Responsive.icon(24)),
            tooltip: 'حفظ',
            onPressed: _saveNote,
          ),
          Responsive.hBox(8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: Responsive.paddingAll(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(
                    fontSize: Responsive.font(24),
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'العنوان',
                    hintStyle: TextStyle(fontSize: Responsive.font(24)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال عنوان الملاحظة';
                    }
                    return null;
                  },
                  autofocus: !_isEditing,
                ),

                Divider(color: Colors.grey[300]),

                Responsive.vBox(16),

                // المحتوى
                TextFormField(
                  controller: _contentController,
                  style: TextStyle(fontSize: Responsive.font(16)),
                  maxLines: 15,
                  decoration: InputDecoration(
                    hintText: 'اكتب ملاحظتك هنا...',
                    hintStyle: TextStyle(
                      fontSize: Responsive.font(16),
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال محتوى الملاحظة';
                    }
                    return null;
                  },
                ),

                Responsive.vBox(32),

                // التصنيف
                Text(
                  'التصنيف',
                  style: TextStyle(
                    fontSize: Responsive.font(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Responsive.vBox(12),
                Consumer<NotesProvider>(
                  builder: (context, provider, _) {
                    final categories = [
                      ...NoteCategory.defaultCategories,
                      ...provider.categories.where(
                          (c) => !NoteCategory.defaultCategories.contains(c)),
                    ];

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...categories.map((cat) => _buildCategoryChip(cat)),
                        _buildAddCategoryChip(),
                      ],
                    );
                  },
                ),

                Responsive.vBox(32),

                // اللون
                Text(
                  'اللون',
                  style: TextStyle(
                    fontSize: Responsive.font(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Responsive.vBox(12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: NoteColors.colors.map((color) {
                    return _buildColorOption(color);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;

    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        fontSize: Responsive.font(14),
        color: isSelected ? Colors.blue : Colors.black87,
      ),
    );
  }

  Widget _buildAddCategoryChip() {
    return ActionChip(
      avatar: Icon(
        Icons.add,
        size: Responsive.icon(18),
        color: Colors.blue,
      ),
      label: Text(
        'إضافة تصنيف',
        style: TextStyle(
          fontSize: Responsive.font(14),
          color: Colors.blue,
        ),
      ),
      onPressed: _showAddCategoryDialog,
      backgroundColor: Colors.blue.withOpacity(0.1),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _selectedColor.value == color.value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: Responsive.width(50),
        height: Responsive.height(50),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
                size: Responsive.icon(24),
              )
            : null,
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة تصنيف جديد'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            hintText: 'اسم التصنيف',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) => _addNewCategory(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _categoryController.clear();
              Navigator.pop(context);
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _addNewCategory,
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _addNewCategory() {
    final category = _categoryController.text.trim();
    if (category.isNotEmpty) {
      setState(() {
        _selectedCategory = category;
      });
      _categoryController.clear();
      Navigator.pop(context);
    }
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<NotesProvider>(context, listen: false);

    final note = Note(
      id: widget.note?.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      category: _selectedCategory,
      color: _selectedColor,
      isPinned: widget.note?.isPinned ?? false,
      createdAt: widget.note?.createdAt,
    );

    bool success;
    if (_isEditing) {
      success = await provider.updateNote(note);
    } else {
      success = await provider.addNote(note);
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'تم تحديث الملاحظة' : 'تم إضافة الملاحظة',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في حفظ الملاحظة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
