import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_theme.dart';
import 'package:sync_daily/core/theme/category_theme.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';

/// Pasangan latar/ikon kartu catatan.
///
/// Selalu diambil dari token kategori theme (`AppCategoryColors`) supaya tidak
/// ada nilai warna yang ditulis langsung di widget.
@immutable
class NotePalette {
  final Color background;
  final Color icon;

  const NotePalette({required this.background, required this.icon});
}

/// Kategori theme untuk tiap warna catatan bawaan.
TaskCategory taskCategoryForNoteColor(NoteColor color) {
  switch (color) {
    case NoteColor.violet:
      return TaskCategory.task;
    case NoteColor.orange:
      return TaskCategory.reminder;
    case NoteColor.blue:
      return TaskCategory.event;
    case NoteColor.green:
      return TaskCategory.milestone;
    case NoteColor.pink:
      return TaskCategory.note;
    case NoteColor.yellow:
      return TaskCategory.project;
    case NoteColor.red:
      return TaskCategory.deadline;
  }
}

extension NotePaletteExt on BuildContext {
  /// Warna kartu catatan.
  ///
  /// Warna mengikuti kategori (satu-satunya penentu menurut desain). Catatan
  /// tanpa kategori memakai kolom `color` bila ada (mis. data dari server),
  /// dan bila keduanya kosong memakai warna catatan bawaan (pink).
  NotePalette notePaletteFor(NoteCategory? category, NoteColor? color) {
    final resolved = noteColorForCategory(category) ?? color;
    final taskCategory = resolved == null
        ? TaskCategory.note
        : taskCategoryForNoteColor(resolved);
    final colors = categoryColors;
    return NotePalette(
      background: colors.backgroundFor(taskCategory),
      icon: colors.iconFor(taskCategory),
    );
  }
}
