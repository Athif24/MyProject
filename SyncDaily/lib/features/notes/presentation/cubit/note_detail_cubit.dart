import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notes/presentation/cubit/note_detail_state.dart';

/// Cubit layar detail catatan.
///
/// Data catatan dimuat reaktif dari `watchNotes()` sehingga hasil form ubah
/// langsung terlihat.
class NoteDetailCubit extends Cubit<NoteDetailState> {
  final String noteId;
  final NoteRepository _noteRepository;

  StreamSubscription<List<Note>>? _notesSub;

  NoteDetailCubit({
    required this.noteId,
    required NoteRepository noteRepository,
  })  : _noteRepository = noteRepository,
        super(const NoteDetailState());

  void start() {
    unawaited(_notesSub?.cancel());
    _notesSub = _noteRepository.watchNotes().listen(
          _onNotes,
          onError: _onError,
        );
  }

  void _onNotes(List<Note> notes) {
    // Selama proses hapus, abaikan emisi aliran data: baris yang baru hilang
    // tidak boleh mengubah keadaan sebelum halaman ditutup.
    if (state.status == NoteDetailStatus.deleting) {
      return;
    }
    Note? note;
    for (final item in notes) {
      if (item.id == noteId) {
        note = item;
        break;
      }
    }
    if (note == null) {
      emit(state.copyWith(
        status: NoteDetailStatus.notFound,
        clearNote: true,
      ));
      return;
    }
    emit(state.copyWith(status: NoteDetailStatus.loaded, note: note));
  }

  /// Memuat ulang catatan (dipanggil setelah kembali dari form ubah).
  Future<void> refresh() async {
    // Tidak ada gunanya memuat ulang saat halaman sedang ditutup.
    if (state.status == NoteDetailStatus.deleting) {
      return;
    }
    try {
      final note = await _noteRepository.getNote(noteId);
      if (note == null) {
        emit(state.copyWith(
          status: NoteDetailStatus.notFound,
          clearNote: true,
        ));
        return;
      }
      emit(state.copyWith(status: NoteDetailStatus.loaded, note: note));
    } catch (error, stackTrace) {
      _onError(error, stackTrace);
    }
  }

  /// Menyematkan atau melepas sematan catatan (toggle di halaman detail).
  ///
  /// Hanya kolom `isPinned` yang berubah; `updatedAt` dan isi catatan tidak
  /// ikut berubah karena sematan hanyalah pengatur tampilan.
  Future<void> togglePin() async {
    final note = state.note;
    if (note == null || state.status == NoteDetailStatus.deleting) {
      return;
    }
    try {
      await _noteRepository.upsertNote(
        Note(
          id: note.id,
          title: note.title,
          content: note.content,
          category: note.category,
          color: note.color,
          isPinned: !note.isPinned,
          remoteId: note.remoteId,
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          deletedAt: note.deletedAt,
        ),
      );
    } catch (error, stackTrace) {
      _onError(error, stackTrace);
    }
  }

  /// Menghapus catatan. Mengembalikan id yang terhapus untuk aksi "Urungkan".
  ///
  /// Status pindah ke [NoteDetailStatus.deleting] lebih dulu supaya layar
  /// menampilkan keadaan netral: tanpa itu, catatan yang hilang dari
  /// `watchNotes()` sempat memunculkan "Catatan tidak ditemukan" sebelum
  /// halaman kembali ke layar sebelumnya.
  Future<List<String>> delete() async {
    emit(state.copyWith(status: NoteDetailStatus.deleting, clearError: true));
    try {
      await _noteRepository.softDeleteNote(noteId);
      return [noteId];
    } catch (error, stackTrace) {
      _onError(error, stackTrace);
      rethrow;
    }
  }

  void _onError(Object error, StackTrace stackTrace) {
    emit(state.copyWith(
      status: NoteDetailStatus.error,
      errorMessage: '$error',
    ));
  }

  @override
  Future<void> close() async {
    await _notesSub?.cancel();
    return super.close();
  }
}
