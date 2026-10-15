import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_daily/core/strings/app_strings.dart';

/// Durasi tampil snackbar "Urungkan" sebelum hilang sendiri.
///
/// `persist: false` wajib: pada SnackBar dengan aksi, `persist` default-nya
/// `true` sehingga tanpa ini snackbar tidak pernah hilang sendiri.
const Duration _undoSnackBarDuration = Duration(seconds: 6);

/// Membuka layar detail catatan, lalu bila catatan dihapus di sana: kembali ke
/// layar asal dan tampilkan snackbar "Urungkan" yang memanggil [onUndo] dengan
/// id yang terhapus.
///
/// Sama seperti pola daftar tugas/Kalender, supaya perilaku hapus + Urungkan
/// konsisten; yang berbeda hanya cara memulihkan id tersebut.
Future<void> openNoteDetailWithUndo({
  required BuildContext context,
  required String noteId,
  required Future<void> Function(List<String> ids) onUndo,
}) async {
  final deletedIds = await context.push<List<String>>('/notes/$noteId');
  if (deletedIds == null || deletedIds.isEmpty || !context.mounted) {
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: const Text(AppStrings.noteDeleted),
      duration: _undoSnackBarDuration,
      persist: false,
      action: SnackBarAction(
        label: AppStrings.undo,
        onPressed: () => onUndo(deletedIds),
      ),
    ),
  );
}
