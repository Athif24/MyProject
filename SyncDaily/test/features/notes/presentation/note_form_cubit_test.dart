import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/features/notes/data/repositories/note_repository_impl.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notes/presentation/cubit/note_form_cubit.dart';
import 'package:sync_daily/features/notes/presentation/cubit/note_form_state.dart';

/// Tes cubit form catatan lewat repository Drift asli: buat, ubah, validasi
/// judul, dan warna yang mengikuti kategori.
void main() {
  late AppDatabase db;
  late NoteRepository noteRepo;

  final fixedNow = DateTime(2026, 10, 14, 8, 30);
  final created = DateTime.utc(2026, 10, 1, 9);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    noteRepo = NoteRepositoryImpl(db.notesDao);
  });

  tearDown(() async {
    await db.close();
  });

  NoteFormCubit makeCubit() => NoteFormCubit(
        noteRepository: noteRepo,
        now: () => fixedNow,
        newId: () => 'n-baru',
      );

  test('membuat catatan baru dengan judul, isi, kategori, dan sematan',
      () async {
    final cubit = makeCubit();
    cubit.setTitle('Beli buku');
    cubit.setContent('Di toko dekat kampus');
    cubit.setCategory(NoteCategory.study);
    cubit.setIsPinned(true);

    await cubit.save();

    expect(cubit.state.status, NoteFormStatus.saved);
    final saved = await noteRepo.getNote('n-baru');
    expect(saved, isNotNull);
    expect(saved!.title, 'Beli buku');
    expect(saved.content, 'Di toko dekat kampus');
    expect(saved.category, 'study');
    expect(saved.color, NoteColor.green);
    expect(saved.isPinned, isTrue);
    expect(saved.createdAt.isAtSameMomentAs(fixedNow.toUtc()), isTrue);
    expect(saved.updatedAt.isAtSameMomentAs(fixedNow.toUtc()), isTrue);
    await cubit.close();
  });

  test('judul dan isi di-trim saat disimpan', () async {
    final cubit = makeCubit();
    cubit.setTitle('  Beli buku  ');
    cubit.setContent('  Catatan  ');

    await cubit.save();

    final saved = await noteRepo.getNote('n-baru');
    expect(saved!.title, 'Beli buku');
    expect(saved.content, 'Catatan');
    await cubit.close();
  });

  test('tanpa kategori: kolom kategori dan warna dibiarkan kosong', () async {
    final cubit = makeCubit();
    cubit.setTitle('Tanpa kategori');

    await cubit.save();

    final saved = await noteRepo.getNote('n-baru');
    expect(saved!.category, isNull);
    expect(saved.color, isNull);
    await cubit.close();
  });

  test('warna mengikuti kategori: Penting menjadi merah', () async {
    final cubit = makeCubit();
    cubit.setTitle('Penting');
    cubit.setCategory(NoteCategory.important);

    await cubit.save();

    final saved = await noteRepo.getNote('n-baru');
    expect(saved!.color, NoteColor.red);
    await cubit.close();
  });

  test('judul kosong ditolak dan tidak menyimpan apa pun', () async {
    final cubit = makeCubit();
    cubit.setContent('Hanya isi');

    await cubit.save();

    expect(cubit.state.errorMessage, AppStrings.noteTitleRequired);
    expect(cubit.state.status, NoteFormStatus.idle);
    expect(await noteRepo.getNote('n-baru'), isNull);
    await cubit.close();
  });

  test('mengubah catatan memuat isian lama lalu menyimpan perubahan',
      () async {
    await noteRepo.upsertNote(Note(
      id: 'n1',
      title: 'Judul lama',
      content: 'Isi lama',
      category: 'work',
      color: NoteColor.blue,
      createdAt: created,
      updatedAt: created,
    ));

    final cubit = makeCubit();
    await cubit.init(noteId: 'n1');

    expect(cubit.state.isEditing, isTrue);
    expect(cubit.state.title, 'Judul lama');
    expect(cubit.state.content, 'Isi lama');
    expect(cubit.state.category, NoteCategory.work);

    cubit.setTitle('Judul baru');
    cubit.setCategory(NoteCategory.personal);
    await cubit.save(editingNoteId: 'n1');

    final saved = await noteRepo.getNote('n1');
    expect(saved!.title, 'Judul baru');
    expect(saved.category, 'personal');
    expect(saved.color, NoteColor.violet);
    // Tanggal dibuat tidak ikut berubah, tanggal perbarui ikut jam injeksi.
    expect(saved.createdAt.isAtSameMomentAs(created), isTrue);
    expect(saved.updatedAt.isAtSameMomentAs(fixedNow.toUtc()), isTrue);
    await cubit.close();
  });

  test('init dengan id tidak dikenal menghasilkan galat', () async {
    final cubit = makeCubit();

    await cubit.init(noteId: 'tidak-ada');

    expect(cubit.state.status, NoteFormStatus.error);
    expect(cubit.state.errorMessage, isNotNull);
    await cubit.close();
  });

  test('init tanpa id tetap mode buat baru', () async {
    final cubit = makeCubit();

    await cubit.init();

    expect(cubit.state.isEditing, isFalse);
    expect(cubit.state.title, isEmpty);
    await cubit.close();
  });
}
