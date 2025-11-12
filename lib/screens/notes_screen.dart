// lib/screens/notes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../utils/responsive.dart';
import 'note_editor_screen.dart';
import 'package:intl/intl.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();

  // ⭐ متغيرات الفلترة حسب التاريخ
  String _dateFilterType = 'الكل'; // الكل، اليوم، الأسبوع، الشهر، فترة مخصصة
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesProvider>(context, listen: false).loadNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // شريط البحث والفلاتر
          _buildTopBar(),

          // عرض الملاحظات
          Expanded(
            child: Consumer<NotesProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notes = provider.filteredNotes;

                // ⭐⭐⭐ تطبيق فلترة التاريخ
                final filteredByDate = _filterNotesByDate(notes);

                if (filteredByDate.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildNotesList(filteredByDate, provider);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('ملاحظة جديدة'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: Responsive.paddingAll(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // عنوان الصفحة
              Text(
                'الملاحظات',
                style: TextStyle(
                  fontSize: Responsive.font(24),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Responsive.hBox(16),
              Consumer<NotesProvider>(
                builder: (context, provider, _) {
                  return Text(
                    '(${provider.totalNotes})',
                    style: TextStyle(
                      fontSize: Responsive.font(18),
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
              const Spacer(),

              // أزرار الفلترة
              Consumer<NotesProvider>(
                builder: (context, provider, _) {
                  return Row(
                    children: [
                      // فلتر التصنيف
                      if (provider.categories.isNotEmpty)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.filter_list,
                            size: Responsive.icon(24),
                          ),
                          tooltip: 'تصفية حسب الفئة',
                          onSelected: (category) {
                            provider.filterByCategory(
                              category == 'all' ? null : category,
                            );
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'all',
                              child: Row(
                                children: [
                                  Icon(
                                    provider.selectedCategory == null
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: Responsive.icon(20),
                                  ),
                                  Responsive.hBox(8),
                                  const Text('الكل'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            ...provider.categories.map((cat) {
                              return PopupMenuItem(
                                value: cat,
                                child: Row(
                                  children: [
                                    Icon(
                                      provider.selectedCategory == cat
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      size: Responsive.icon(20),
                                    ),
                                    Responsive.hBox(8),
                                    Text(cat),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),

                      Responsive.hBox(8),

                      // زر مسح الفلاتر
                      if (provider.selectedCategory != null ||
                          provider.searchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.clear_all,
                            size: Responsive.icon(24),
                          ),
                          tooltip: 'مسح الفلاتر',
                          onPressed: () {
                            provider.clearFilters();
                            _searchController.clear();
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),

          Responsive.vBox(16),

          // شريط البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث في الملاحظات...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        Provider.of<NotesProvider>(context, listen: false)
                            .searchNotes('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              Provider.of<NotesProvider>(context, listen: false)
                  .searchNotes(value);
            },
          ),

          Responsive.vBox(12),

          // ⭐⭐⭐ أزرار الفلترة حسب التاريخ
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateFilterChip('الكل', Icons.all_inclusive),
                Responsive.hBox(8),
                _buildDateFilterChip('اليوم', Icons.today),
                Responsive.hBox(8),
                _buildDateFilterChip('الأسبوع', Icons.date_range),
                Responsive.hBox(8),
                _buildDateFilterChip('الشهر', Icons.calendar_month),
                Responsive.hBox(8),
                _buildDateFilterChip('فترة مخصصة', Icons.date_range_outlined),
              ],
            ),
          ),

          // ⭐⭐⭐ حقول اختيار الفترة المخصصة
          if (_dateFilterType == 'فترة مخصصة') ...[
            Responsive.vBox(12),
            Container(
              padding: Responsive.paddingAll(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: Colors.blue, size: Responsive.icon(20)),
                      Responsive.hBox(8),
                      const Text(
                        'اختر الفترة الزمنية',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Responsive.vBox(12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: Responsive.paddingSym(h: 12, v: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(Responsive.radius(8)),
                              border: Border.all(color: Colors.blue[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _customStartDate == null
                                      ? 'من تاريخ'
                                      : DateFormat('yyyy-MM-dd')
                                          .format(_customStartDate!),
                                  style: TextStyle(
                                    fontSize: Responsive.font(12),
                                    color: _customStartDate == null
                                        ? Colors.grey[600]
                                        : Colors.black,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: Responsive.icon(18),
                                  color: Colors.blue[700],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: Responsive.paddingSym(h: 8),
                        child:
                            const Icon(Icons.arrow_forward, color: Colors.blue),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: Responsive.paddingSym(h: 12, v: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(Responsive.radius(8)),
                              border: Border.all(color: Colors.blue[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _customEndDate == null
                                      ? 'إلى تاريخ'
                                      : DateFormat('yyyy-MM-dd')
                                          .format(_customEndDate!),
                                  style: TextStyle(
                                    fontSize: Responsive.font(12),
                                    color: _customEndDate == null
                                        ? Colors.grey[600]
                                        : Colors.black,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: Responsive.icon(18),
                                  color: Colors.blue[700],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ⭐⭐⭐ دالة الفلترة حسب التاريخ
  List<Note> _filterNotesByDate(List<Note> notes) {
    if (_dateFilterType == 'الكل') return notes;

    final now = DateTime.now();

    return notes.where((note) {
      final noteDate = note.updatedAt;

      switch (_dateFilterType) {
        case 'اليوم':
          return noteDate.year == now.year &&
              noteDate.month == now.month &&
              noteDate.day == now.day;

        case 'الأسبوع':
          final now = DateTime.now();

          final int daysFromSaturday = (now.weekday % 7);
          final weekStart = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: daysFromSaturday));

          final weekEnd = now.add(const Duration(days: 1));

          return noteDate.isAfter(weekStart) && noteDate.isBefore(weekEnd);

        case 'الشهر':
          return noteDate.year == now.year && noteDate.month == now.month;

        case 'فترة مخصصة':
          if (_customStartDate == null || _customEndDate == null) return true;

          final startOfDay = DateTime(_customStartDate!.year,
              _customStartDate!.month, _customStartDate!.day);
          final endOfDay = DateTime(_customEndDate!.year, _customEndDate!.month,
              _customEndDate!.day, 23, 59, 59);

          return noteDate
                  .isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              noteDate.isBefore(endOfDay.add(const Duration(seconds: 1)));

        default:
          return true;
      }
    }).toList();
  }

  // ⭐⭐⭐ دالة اختيار التاريخ
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_customStartDate ?? DateTime.now())
          : (_customEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _customStartDate = picked;
          if (_customEndDate != null && picked.isAfter(_customEndDate!)) {
            _customEndDate = picked;
          }
        } else {
          if (_customStartDate != null && picked.isBefore(_customStartDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تاريخ النهاية يجب أن يكون بعد تاريخ البداية'),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            _customEndDate = picked;
          }
        }
      });
    }
  }

  // ⭐⭐⭐ Widget لأزرار الفلترة
  Widget _buildDateFilterChip(String label, IconData icon) {
    final isSelected = _dateFilterType == label;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: Responsive.icon(18),
              color: isSelected ? Colors.white : Colors.blue[700]),
          SizedBox(width: Responsive.width(4)),
          Text(label, style: TextStyle(fontSize: Responsive.font(12))),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _dateFilterType = label;
          if (label != 'فترة مخصصة') {
            _customStartDate = null;
            _customEndDate = null;
          }
        });
      },
      selectedColor: Colors.blue,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: Responsive.font(12),
        color: isSelected ? Colors.white : Colors.blue[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.blue[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes, NotesProvider provider) {
    // تقسيم الملاحظات إلى مثبتة وغير مثبتة
    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final unpinnedNotes = notes.where((n) => !n.isPinned).toList();

    return ListView(
      padding: Responsive.paddingAll(16),
      children: [
        // الملاحظات المثبتة
        if (pinnedNotes.isNotEmpty) ...[
          Padding(
            padding: Responsive.paddingSym(v: 8, h: 4),
            child: Text(
              'مثبت',
              style: TextStyle(
                fontSize: Responsive.font(16),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Responsive.vBox(8),
          ...pinnedNotes.map((note) => Padding(
                padding: Responsive.paddingSym(v: 6),
                child: _buildNoteRow(note, provider),
              )),
          Responsive.vBox(16),
        ],

        // الملاحظات الأخرى
        if (unpinnedNotes.isNotEmpty) ...[
          if (pinnedNotes.isNotEmpty)
            Padding(
              padding: Responsive.paddingSym(v: 8, h: 4),
              child: Text(
                'أخرى',
                style: TextStyle(
                  fontSize: Responsive.font(16),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          if (pinnedNotes.isNotEmpty) Responsive.vBox(8),
          ...unpinnedNotes.map((note) => Padding(
                padding: Responsive.paddingSym(v: 6),
                child: _buildNoteRow(note, provider),
              )),
        ],
      ],
    );
  }

  Widget _buildNoteRow(Note note, NotesProvider provider) {
    return Card(
      elevation: 1,
      color: note.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
      ),
      child: InkWell(
        onTap: () => _openNoteEditor(context, note: note),
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
        child: Padding(
          padding: Responsive.paddingAll(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أيقونة التثبيت
              if (note.isPinned)
                Padding(
                  padding: Responsive.paddingOnly(left: 12),
                  child: Icon(
                    Icons.push_pin,
                    size: Responsive.icon(20),
                    color: Colors.grey[700],
                  ),
                ),

              // محتوى الملاحظة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان
                    Text(
                      note.title,
                      style: TextStyle(
                        fontSize: Responsive.font(18),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Responsive.vBox(8),

                    // المحتوى
                    Text(
                      note.content,
                      style: TextStyle(
                        fontSize: Responsive.font(14),
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Responsive.vBox(12),

                    // التصنيف والتاريخ
                    Row(
                      children: [
                        if (note.category != null) ...[
                          Container(
                            padding: Responsive.paddingSym(h: 12, v: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(Responsive.radius(8)),
                            ),
                            child: Text(
                              note.category!,
                              style: TextStyle(
                                fontSize: Responsive.font(12),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Responsive.hBox(12),
                        ],

                        // ⭐⭐⭐ عرض التاريخ والوقت معاً
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: Responsive.icon(14),
                                color: Colors.grey[600],
                              ),
                              Responsive.hBox(4),
                              Text(
                                DateFormat('yyyy-MM-dd').format(note.updatedAt),
                                style: TextStyle(
                                  fontSize: Responsive.font(11),
                                  color: Colors.grey[600],
                                ),
                              ),
                              Responsive.hBox(8),
                              Icon(
                                Icons.access_time,
                                size: Responsive.icon(14),
                                color: Colors.grey[600],
                              ),
                              Responsive.hBox(4),
                              Text(
                                DateFormat('HH:mm').format(note.updatedAt),
                                style: TextStyle(
                                  fontSize: Responsive.font(11),
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // قائمة الخيارات
              PopupMenuButton(
                icon: Icon(
                  Icons.more_vert,
                  size: Responsive.icon(20),
                  color: Colors.grey[700],
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(
                          note.isPinned
                              ? Icons.push_pin_outlined
                              : Icons.push_pin,
                          size: Responsive.icon(20),
                        ),
                        Responsive.hBox(8),
                        Text(note.isPinned ? 'إلغاء التثبيت' : 'تثبيت'),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(Duration.zero, () {
                        provider.togglePinNote(note.id!, !note.isPinned);
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: Responsive.icon(20),
                          color: Colors.red,
                        ),
                        Responsive.hBox(8),
                        const Text(
                          'حذف',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(Duration.zero, () {
                        _confirmDelete(context, note, provider);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add,
            size: Responsive.icon(100),
            color: Colors.grey[300],
          ),
          Responsive.vBox(16),
          Text(
            'لا توجد ملاحظات',
            style: TextStyle(
              fontSize: Responsive.font(20),
              color: Colors.grey[600],
            ),
          ),
          Responsive.vBox(8),
          Text(
            'اضغط على الزر أدناه لإضافة ملاحظة جديدة',
            style: TextStyle(
              fontSize: Responsive.font(14),
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _openNoteEditor(BuildContext context, {Note? note}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: note),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Note note, NotesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الملاحظة'),
        content: Text('هل أنت متأكد من حذف "${note.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteNote(note.id!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'تم حذف الملاحظة' : 'فشل حذف الملاحظة',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
