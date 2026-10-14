import 'package:sync_daily/features/notes/domain/entities/note.dart';

abstract class NoteRepository {
  Stream<List<Note>> watchNotes();

  Future<Note?> getNote(String id);

  Future<void> upsertNote(Note note);

  Future<void> softDeleteNote(String id);
}
