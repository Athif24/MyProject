import 'package:drift/drift.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';

extension NoteRowMapper on NoteRow {
  Note toEntity() => Note(
        id: id,
        title: title,
        content: content,
        category: category,
        color: color,
        isPinned: isPinned,
        remoteId: remoteId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}

extension NoteEntityMapper on Note {
  NotesCompanion toCompanion() => NotesCompanion(
        id: Value(id),
        title: Value(title),
        content: Value(content),
        category: Value(category),
        color: Value(color),
        isPinned: Value(isPinned),
        remoteId: Value(remoteId),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      );
}
