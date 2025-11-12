// lib/providers/notes_provider.dart

import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/database_helper.dart';

class NotesProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Note> _notes = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;

  // Getters
  List<Note> get notes => _notes;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  // الملاحظات المثبتة
  List<Note> get pinnedNotes => _notes.where((n) => n.isPinned).toList();

  // الملاحظات غير المثبتة
  List<Note> get unpinnedNotes => _notes.where((n) => !n.isPinned).toList();

  // الملاحظات المفلترة
  List<Note> get filteredNotes {
    var result = _notes;

    // فلترة حسب الفئة
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      result = result.where((n) => n.category == _selectedCategory).toList();
    }

    // فلترة حسب البحث
    if (_searchQuery.isNotEmpty) {
      result = result.where((n) {
        return n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            n.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return result;
  }

  int get totalNotes => _notes.length;

  // تحميل جميع الملاحظات
  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _db.getNotes();
      _notes = data.map((map) => Note.fromMap(map)).toList();
      await _loadCategories();
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحميل التصنيفات
  Future<void> _loadCategories() async {
    try {
      _categories = await _db.getNoteCategories();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  // البحث في الملاحظات
  Future<void> searchNotes(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      await loadNotes();
    } else {
      try {
        final data = await _db.searchNotes(query);
        _notes = data.map((map) => Note.fromMap(map)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint('Error searching notes: $e');
      }
    }
  }

  // تصفية حسب الفئة
  void filterByCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // مسح الفلاتر
  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    loadNotes();
  }

  // إضافة ملاحظة جديدة
  Future<bool> addNote(Note note) async {
    try {
      final id = await _db.insertNote(note.toMap());
      if (id > 0) {
        await loadNotes();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding note: $e');
      return false;
    }
  }

  // تحديث ملاحظة
  Future<bool> updateNote(Note note) async {
    if (note.id == null) return false;

    try {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      final result = await _db.updateNote(note.id!, updatedNote.toMap());
      if (result > 0) {
        await loadNotes();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating note: $e');
      return false;
    }
  }

  // حذف ملاحظة
  Future<bool> deleteNote(int id) async {
    try {
      final result = await _db.deleteNote(id);
      if (result > 0) {
        await loadNotes();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting note: $e');
      return false;
    }
  }

  // تثبيت/إلغاء تثبيت ملاحظة
  Future<bool> togglePinNote(int id, bool isPinned) async {
    try {
      final result = await _db.togglePinNote(id, isPinned);
      if (result > 0) {
        final index = _notes.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notes[index] = _notes[index].copyWith(
            isPinned: isPinned,
            updatedAt: DateTime.now(),
          );
          // إعادة ترتيب القائمة
          _notes.sort((a, b) {
            if (a.isPinned == b.isPinned) {
              return b.updatedAt.compareTo(a.updatedAt);
            }
            return a.isPinned ? -1 : 1;
          });
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error toggling pin: $e');
      return false;
    }
  }

  // حذف جميع الملاحظات
  Future<void> deleteAllNotes() async {
    for (var note in _notes) {
      if (note.id != null) {
        await _db.deleteNote(note.id!);
      }
    }
    await loadNotes();
  }
}
