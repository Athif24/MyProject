import 'package:sync_daily/features/notes/domain/entities/note.dart';

/// Kategori catatan bawaan (tetap, bukan buatan pengguna).
///
/// Disimpan di kolom `category` tabel `notes` sebagai teks ([name]), mis.
/// `personal`. Warnanya mengikuti kategori (lihat
/// `presentation/theme/note_color_theme.dart`).
enum NoteCategory { personal, work, idea, study, important }

/// Membaca nilai kolom `category`; `null` atau nilai tak dikenal menghasilkan
/// `null` (catatan tanpa kategori).
NoteCategory? noteCategoryFromStorage(String? value) {
  if (value == null) {
    return null;
  }
  for (final category in NoteCategory.values) {
    if (category.name == value) {
      return category;
    }
  }
  return null;
}

/// Warna bawaan tiap kategori, disimpan di kolom `color` agar konsisten saat
/// nanti disinkronkan. Catatan tanpa kategori tidak punya warna.
NoteColor? noteColorForCategory(NoteCategory? category) {
  switch (category) {
    case null:
      return null;
    case NoteCategory.personal:
      return NoteColor.violet;
    case NoteCategory.work:
      return NoteColor.blue;
    case NoteCategory.idea:
      return NoteColor.yellow;
    case NoteCategory.study:
      return NoteColor.green;
    case NoteCategory.important:
      return NoteColor.red;
  }
}
