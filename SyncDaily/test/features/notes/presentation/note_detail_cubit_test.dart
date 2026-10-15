import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/notes/data/repositories/note_repository_impl.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notes/presentation/cubit/note_detail_cubit.dart';
import 'package:sync_daily/features/notes/presentation/cubit/note_detail_state.dart';

/// Tes cubit detail catatan lewat repository Drift asli: memuat, menghapus
/// (tanpa kilatan "tidak ditemukan"), menyematkan, dan memulihkan.
void main() {
  late AppDatabase db;
  late NoteRepository noteRepo;

  final ts = DateTime.utc(2026, 10, 14, 8, 30);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    noteRepo = NoteRepositoryImpl(db.notesDao);
  });

  tearDown(() async {
    await db.close();
  });

  Note note({
    String id = 'n1',
    String title = 'Beli buku',
    String content = 'Isi catatan',
    String? category = 'study',
    NoteColor? color = NoteColor.green,
    bool isPinned = false,
    DateTime? deletedAt,
  }) {
    return Note(
      id: id,
      title: title,
      content: content,
      category: category,
      color: color,
      isPinned: isPinned,
      createdAt: ts,
      updatedAt: ts,
      deletedAt: deletedAt,
    );
  }

  Future<NoteDetailCubit> startCubit([String id = 'n1']) async {
    final cubit = NoteDetailCubit(noteId: id, noteRepository: noteRepo)..start();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return cubit;
  }

  test('memuat catatan dari aliran data', () async {
    await noteRepo.upsertNote(note());

    final cubit = await startCubit();

    expect(cubit.state.status, NoteDetailStatus.loaded);
    expect(cubit.state.note?.title, 'Beli buku');
    await cubit.close();
  });

  test('id tidak dikenal menghasilkan keadaan tidak ditemukan', () async {
    final cubit = await startCubit('tidak-ada');

    expect(cubit.state.status, NoteDetailStatus.notFound);
    expect(cubit.state.note, isNull);
    await cubit.close();
  });

  test('menghapus: mengembalikan id, catatan hilang, status tetap deleting',
      () async {
    await noteRepo.upsertNote(note());
    final cubit = await startCubit();
    expect(cubit.state.status, NoteDetailStatus.loaded);

    final ids = await cubit.delete();
    // Beri kesempatan emisi aliran data tanpa catatan itu masuk.
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(ids, ['n1']);
    expect(cubit.state.status, NoteDetailStatus.deleting);
    await cubit.close();
  });

  test('menyematkan lalu melepas sematan tidak mengubah tanggal perbarui',
      () async {
    await noteRepo.upsertNote(note());
    final cubit = await startCubit();

    await cubit.togglePin();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state.note?.isPinned, isTrue);
    expect(cubit.state.note?.updatedAt.isAtSameMomentAs(ts), isTrue);

    await cubit.togglePin();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state.note?.isPinned, isFalse);
    await cubit.close();
  });

  test('catatan yang dipulihkan muncul kembali di layar detail', () async {
    await noteRepo.upsertNote(note());
    final cubit = await startCubit();

    await cubit.delete();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state.status, NoteDetailStatus.deleting);

    // Karena status "deleting" menahan pembaruan, layar baru kembali normal
    // setelah cubit dimuat ulang oleh halaman baru.
    final restored = await startCubit();
    expect(restored.state.status, NoteDetailStatus.notFound);

    await noteRepo.restoreNotes(['n1']);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(restored.state.status, NoteDetailStatus.loaded);
    await cubit.close();
    await restored.close();
  });

  test('refresh memuat ulang isi catatan', () async {
    await noteRepo.upsertNote(note());
    final cubit = await startCubit();

    await noteRepo.upsertNote(note(title: 'Judul baru'));
    await cubit.refresh();

    expect(cubit.state.note?.title, 'Judul baru');
    await cubit.close();
  });
}
