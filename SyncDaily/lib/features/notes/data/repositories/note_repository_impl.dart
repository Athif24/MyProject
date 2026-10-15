import 'package:sync_daily/features/notes/data/daos/notes_dao.dart';
import 'package:sync_daily/features/notes/data/mappers/note_mapper.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NotesDao _dao;

  NoteRepositoryImpl(this._dao);

  @override
  Stream<List<Note>> watchNotes() {
    return _dao.watchNotes().map(
          (rows) => rows.map((row) => row.toEntity()).toList(),
        );
  }

  @override
  Future<Note?> getNote(String id) async {
    final row = await _dao.getById(id);
    return row?.toEntity();
  }

  @override
  Future<void> upsertNote(Note note) => _dao.upsertNote(note.toCompanion());

  @override
  Future<void> softDeleteNote(String id) =>
      _dao.softDeleteNote(id, DateTime.now().toUtc());

  @override
  Future<void> restoreNotes(List<String> ids) =>
      _dao.restoreNotes(ids, DateTime.now().toUtc());
}
