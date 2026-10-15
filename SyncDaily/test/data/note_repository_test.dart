import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/notes/data/repositories/note_repository_impl.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';

/// Tes repository catatan lewat database Drift asli (in-memory).
void main() {
  late AppDatabase db;
  late NoteRepository noteRepo;

  final ts = DateTime.utc(2026, 10, 14, 8, 30);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    noteRepo = NoteRepositoryImpl(db.notesDao);
  });

  tearDown(() => db.close());

  Note makeNote({
    required String id,
    String title = 'Catatan',
    String content = '',
    String? category,
    NoteColor? color,
    bool isPinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Note(
      id: id,
      title: title,
      content: content,
      category: category,
      color: color,
      isPinned: isPinned,
      createdAt: createdAt ?? ts,
      updatedAt: updatedAt ?? ts,
      deletedAt: deletedAt,
    );
  }

  Future<List<Note>> readAll() => noteRepo.watchNotes().first;

  test('upsertNote menyimpan dan getNote membacanya kembali', () async {
    await noteRepo.upsertNote(makeNote(
      id: 'n1',
      title: 'Beli buku',
      content: 'Di toko dekat kampus',
      category: 'study',
      color: NoteColor.green,
    ));

    final note = await noteRepo.getNote('n1');

    expect(note, isNotNull);
    expect(note!.title, 'Beli buku');
    expect(note.content, 'Di toko dekat kampus');
    expect(note.category, 'study');
    expect(note.color, NoteColor.green);
    expect(note.isPinned, isFalse);
    expect(note.createdAt.isAtSameMomentAs(ts), isTrue);
  });

  test('getNote mengembalikan null bila id tidak ada', () async {
    expect(await noteRepo.getNote('tidak-ada'), isNull);
  });

  test('upsertNote memperbarui catatan yang sudah ada', () async {
    await noteRepo.upsertNote(makeNote(id: 'n1', title: 'Lama'));
    await noteRepo.upsertNote(makeNote(
      id: 'n1',
      title: 'Baru',
      updatedAt: ts.add(const Duration(hours: 1)),
    ));

    final notes = await readAll();

    expect(notes, hasLength(1));
    expect(notes.single.title, 'Baru');
  });

  test('watchNotes mengurutkan yang disematkan lebih dulu, lalu terbaru',
      () async {
    await noteRepo.upsertNote(makeNote(id: 'n1', title: 'Lama'));
    await noteRepo.upsertNote(makeNote(
      id: 'n2',
      title: 'Baru',
      updatedAt: ts.add(const Duration(hours: 2)),
    ));
    await noteRepo.upsertNote(makeNote(
      id: 'n3',
      title: 'Disematkan',
      isPinned: true,
      updatedAt: ts,
    ));

    final notes = await readAll();

    expect(notes.map((n) => n.id), ['n3', 'n2', 'n1']);
  });

  test('softDeleteNote menyembunyikan catatan sampai dipulihkan', () async {
    await noteRepo.upsertNote(makeNote(id: 'n1'));

    await noteRepo.softDeleteNote('n1');
    expect(await readAll(), isEmpty);

    await noteRepo.restoreNotes(['n1']);
    final notes = await readAll();

    expect(notes, hasLength(1));
    expect(notes.single.id, 'n1');
    expect(notes.single.deletedAt, isNull);
  });

  test('restoreNotes mengabaikan daftar kosong', () async {
    await noteRepo.upsertNote(makeNote(id: 'n1'));

    await noteRepo.restoreNotes(const []);

    expect(await readAll(), hasLength(1));
  });
}
