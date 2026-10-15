import 'dart:async';

import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';

/// Repository catatan tiruan untuk tes widget.
///
/// Menyimpan catatan di memori dan memancarkan perubahannya lewat stream, jadi
/// alur buat -> cari -> ubah -> hapus bisa diuji tanpa query stream Drift (yang
/// meninggalkan timer saat dibatalkan di dalam `flutter_test`; lihat catatan di
/// `test/helpers/test_repositories.dart`). Perilakunya meniru
/// `NoteRepositoryImpl` + `NotesDao`: yang ter-soft-delete tidak dipancarkan,
/// sementara [getNote] tetap mengembalikannya seperti `NotesDao.getById`.
class FakeNoteRepository implements NoteRepository {
  final Map<String, Note> _notes = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  bool _closed = false;

  /// Catatan tersimpan apa adanya (termasuk yang ter-soft-delete).
  Note? stored(String id) => _notes[id];

  @override
  Stream<List<Note>> watchNotes() async* {
    yield _visible();
    await for (final _ in _changes.stream) {
      yield _visible();
    }
  }

  @override
  Future<Note?> getNote(String id) async => _notes[id];

  @override
  Future<void> upsertNote(Note note) async {
    _notes[note.id] = note;
    _notify();
  }

  @override
  Future<void> softDeleteNote(String id) async {
    final note = _notes[id];
    if (note == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    _notes[id] = _copy(note, deletedAt: now, updatedAt: now);
    _notify();
  }

  @override
  Future<void> restoreNotes(List<String> ids) async {
    for (final id in ids) {
      final note = _notes[id];
      if (note == null) {
        continue;
      }
      _notes[id] = _copy(note, clearDeletedAt: true);
    }
    _notify();
  }

  /// Menutup stream; panggil di `tearDown`.
  Future<void> dispose() async {
    _closed = true;
    await _changes.close();
  }

  /// Urutan seperti `NotesDao.watchNotes()`: disematkan dulu, lalu terbaru.
  List<Note> _visible() {
    return _notes.values.where((note) => !note.isDeleted).toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  void _notify() {
    if (!_closed) {
      _changes.add(null);
    }
  }

  Note _copy(
    Note note, {
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Note(
      id: note.id,
      title: note.title,
      content: note.content,
      category: note.category,
      color: note.color,
      isPinned: note.isPinned,
      remoteId: note.remoteId,
      createdAt: note.createdAt,
      updatedAt: updatedAt ?? note.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? note.deletedAt),
    );
  }
}
