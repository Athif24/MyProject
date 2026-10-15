import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notes/presentation/cubit/notes_state.dart';

/// Cubit layar Catatan.
///
/// Memuat catatan secara reaktif dari repository, lalu menyaring dan
/// mengurutkannya di sisi klien: filter kategori dan kata kunci pencarian
/// (judul atau isi) digabung, sedangkan urutan selalu "disematkan lebih dulu,
/// lalu yang terbaru".
class NotesCubit extends Cubit<NotesState> {
  final NoteRepository _noteRepository;

  /// Sumber waktu; bisa diganti pada pengujian.
  final DateTime Function() _now;

  StreamSubscription<List<Note>>? _notesSub;

  List<Note> _notes = const [];
  bool _failed = false;
  String? _errorMessage;

  NotesCubit({
    required NoteRepository noteRepository,
    DateTime Function()? now,
  })  : _noteRepository = noteRepository,
        _now = now ?? DateTime.now,
        super(NotesState(today: _dateOnly((now ?? DateTime.now)())));

  /// Berlangganan seluruh catatan (tanpa yang terhapus).
  void start() {
    unawaited(_notesSub?.cancel());
    _notesSub = _noteRepository.watchNotes().listen(
      (notes) {
        _failed = false;
        _notes = notes;
        _recompute();
      },
      onError: (Object error) {
        _failed = true;
        _errorMessage = '$error';
        _recompute();
      },
    );
  }

  /// Memuat ulang setelah error.
  void retry() {
    _failed = false;
    emit(state.copyWith(status: NotesStatus.loading, clearError: true));
    start();
  }

  void setQuery(String value) {
    emit(state.copyWith(query: value));
    _recompute();
  }

  /// Memilih kategori; `null` berarti "Semua".
  void setCategory(NoteCategory? category) {
    emit(state.copyWith(category: category, clearCategory: category == null));
    _recompute();
  }

  /// Berganti antara tampilan grid dan daftar.
  void toggleViewMode() {
    emit(state.copyWith(
      viewMode: state.viewMode == NotesViewMode.grid
          ? NotesViewMode.list
          : NotesViewMode.grid,
    ));
  }

  /// Memulihkan catatan yang baru dihapus (aksi "Urungkan").
  Future<void> restore(List<String> ids) => _noteRepository.restoreNotes(ids);

  void _recompute() {
    final query = state.query.trim().toLowerCase();
    final category = state.category;

    final visible = _notes.where((note) {
      if (category != null && note.category != category.name) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList()
      ..sort(_byPinnedThenLatest);

    emit(state.copyWith(
      status: _failed ? NotesStatus.error : NotesStatus.loaded,
      allNotes: _notes,
      visibleNotes: visible,
      today: _dateOnly(_now()),
      errorMessage: _failed ? _errorMessage : null,
      clearError: !_failed,
    ));
  }

  /// Disematkan lebih dulu, lalu yang paling baru diperbarui.
  static int _byPinnedThenLatest(Note a, Note b) {
    if (a.isPinned != b.isPinned) {
      return a.isPinned ? -1 : 1;
    }
    return b.updatedAt.compareTo(a.updatedAt);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  Future<void> close() async {
    await _notesSub?.cancel();
    return super.close();
  }
}
