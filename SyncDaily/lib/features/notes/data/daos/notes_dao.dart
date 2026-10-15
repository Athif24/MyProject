import 'package:drift/drift.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/notes/data/database/notes_table.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  Stream<List<NoteRow>> watchNotes() {
    return (select(notes)
          ..where((n) => n.deletedAt.isNull())
          ..orderBy([
            (n) => OrderingTerm.desc(n.isPinned),
            (n) => OrderingTerm.desc(n.updatedAt),
          ]))
        .watch();
  }

  Future<NoteRow?> getById(String id) {
    return (select(notes)..where((n) => n.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertNote(NotesCompanion companion) {
    return into(notes).insertOnConflictUpdate(companion);
  }

  Future<void> softDeleteNote(String id, DateTime now) {
    return (update(notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Memulihkan catatan yang sebelumnya di-soft-delete (mengosongkan
  /// `deletedAt`), dipakai aksi "Urungkan".
  Future<void> restoreNotes(List<String> ids, DateTime now) async {
    if (ids.isEmpty) {
      return;
    }
    await (update(notes)..where((n) => n.id.isIn(ids))).write(
      NotesCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }
}
