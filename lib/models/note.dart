// lib/models/note.dart

import 'package:flutter/material.dart';

class Note {
  final int? id;
  final String title;
  final String content;
  final String? category;
  final Color color;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.category,
    required this.color,
    this.isPinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ⭐⭐⭐ تحويل من Map إلى Note (مع معالجة كل الحالات)
  factory Note.fromMap(Map<String, dynamic> map) {
    // ⭐ معالجة اللون من قاعدة البيانات
    Color noteColor;
    try {
      final colorValue = map['color'];

      if (colorValue is int) {
        // حالة 1: اللون محفوظ كـ int مباشرة
        noteColor = Color(colorValue);
      } else if (colorValue is String) {
        // حالة 2: اللون محفوظ كـ String
        final colorString = colorValue.trim();

        // محاولة parse كـ int
        final intValue = int.tryParse(colorString);
        if (intValue != null) {
          noteColor = Color(intValue);
        } else {
          // محاولة parse كـ double ثم تحويله لـ int
          final doubleValue = double.tryParse(colorString);
          if (doubleValue != null) {
            noteColor = Color(doubleValue.toInt());
          } else {
            // fallback للون الأبيض
            noteColor = Colors.white;
          }
        }
      } else {
        // fallback للون الأبيض
        noteColor = Colors.white;
      }
    } catch (e) {
      // في حالة أي خطأ، استخدم الأبيض
      noteColor = Colors.white;
      debugPrint('⚠️ Error parsing color: $e');
    }

    return Note(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String?,
      color: noteColor,
      isPinned: (map['isPinned'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // ⭐⭐⭐ تحويل من Note إلى Map (حفظ صحيح)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'category': category,
      'color': color.value.toString(), // ⭐ حفظ كـ String من int
      'isPinned': isPinned ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // نسخ مع تعديل بعض القيم
  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    Color? color,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, category: $category, isPinned: $isPinned)';
  }
}

// ألوان افتراضية للملاحظات
class NoteColors {
  static const List<Color> colors = [
    Color(0xFFFFFFFF), // أبيض
    Color(0xFFFFCDD2), // أحمر فاتح
    Color(0xFFF8BBD0), // وردي فاتح
    Color(0xFFE1BEE7), // بنفسجي فاتح
    Color(0xFFD1C4E9), // بنفسجي
    Color(0xFFC5CAE9), // نيلي فاتح
    Color(0xFFBBDEFB), // أزرق فاتح
    Color(0xFFB3E5FC), // سماوي فاتح
    Color(0xFFB2EBF2), // فيروزي فاتح
    Color(0xFFB2DFDB), // تركواز فاتح
    Color(0xFFC8E6C9), // أخضر فاتح
    Color(0xFFDCEDC8), // أخضر ليموني فاتح
    Color(0xFFF0F4C3), // أصفر فاتح
    Color(0xFFFFF9C4), // أصفر ليمون
    Color(0xFFFFECB3), // كهرماني فاتح
    Color(0xFFFFE0B2), // برتقالي فاتح
    Color(0xFFFFCCBC), // برتقالي محمر فاتح
    Color(0xFFD7CCC8), // بني فاتح
    Color(0xFFCFD8DC), // رمادي مزرق
    Color(0xFFF5F5F5), // رمادي فاتح جداً
  ];

  static Color getRandomColor() {
    return colors[(DateTime.now().millisecondsSinceEpoch % colors.length)];
  }
}

// تصنيفات افتراضية
class NoteCategory {
  static const String personal = 'شخصي';
  static const String work = 'عمل';
  static const String ideas = 'أفكار';
  static const String todo = 'مهام';
  static const String important = 'مهم';

  static const List<String> defaultCategories = [
    personal,
    work,
    ideas,
    todo,
    important,
  ];
}
