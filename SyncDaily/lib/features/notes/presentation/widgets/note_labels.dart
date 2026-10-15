import 'package:flutter/material.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';

/// Label Indonesia untuk kategori catatan bawaan.
String noteCategoryLabel(NoteCategory category) {
  switch (category) {
    case NoteCategory.personal:
      return AppStrings.noteCategoryPersonal;
    case NoteCategory.work:
      return AppStrings.noteCategoryWork;
    case NoteCategory.idea:
      return AppStrings.noteCategoryIdea;
    case NoteCategory.study:
      return AppStrings.noteCategoryStudy;
    case NoteCategory.important:
      return AppStrings.noteCategoryImportant;
  }
}

/// Label kategori dari nilai kolom `category` (teks); catatan tanpa kategori
/// memakai "Tanpa kategori".
String noteCategoryLabelFromStorage(String? value) {
  final category = noteCategoryFromStorage(value);
  return category == null
      ? AppStrings.noteCategoryNone
      : noteCategoryLabel(category);
}

/// Label tanggal kartu catatan: `Hari ini`, `Kemarin`, atau tanggal `id_ID`
/// (mis. `14 Okt`, dan dengan tahun bila bukan tahun berjalan).
///
/// [today] adalah tanggal hari ini (tanpa jam) dari jam yang diinjeksi cubit.
String noteDateLabel(DateTime updatedAt, DateTime today) {
  final day = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);
  final yesterday = today.subtract(const Duration(days: 1));
  if (day == today) {
    return AppStrings.noteUpdatedToday;
  }
  if (day == yesterday) {
    return AppStrings.noteUpdatedYesterday;
  }
  return updatedAt.year == today.year
      ? IdDate.dayMonth(updatedAt)
      : IdDate.full(updatedAt);
}

/// Label semantik tombol ganti tampilan (aksi yang dijalankan saat diketuk).
String noteViewModeLabel(bool isGrid) =>
    isGrid ? AppStrings.noteViewList : AppStrings.noteViewGrid;

/// Ikon tombol ganti tampilan (ikon mode yang akan dibuka).
IconData noteViewModeIcon(bool isGrid) =>
    isGrid ? AppIcons.listView : AppIcons.gridView;
