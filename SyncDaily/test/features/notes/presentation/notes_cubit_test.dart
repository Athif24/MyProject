import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/notes/data/repositories/note_repository_impl.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notes/presentation/cubit/notes_cubit.dart';
import 'package:sync_daily/features/notes/presentation/cubit/notes_state.dart';

/// Tes cubit layar Catatan lewat repository Drift asli: penyaringan kategori,
/// pencarian judul/isi, urutan sematan, mode tampilan, dan keadaan kosong.
void main() {
  late AppDatabase db;
  late NoteRepository noteRepo;

  final fixedNow = DateTime(2026, 10, 14, 8, 30);
  final today = DateTime(2026, 10, 14);
  final ts = DateTime.utc(2026, 10, 1);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    noteRepo = NoteRepositoryImpl(db.notesDao);
  });

  tearDown(() async {
    await db.close();
  });

  Note note(
    String id, {
    String title = 'Catatan',
    String content = '',
    String? category,
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
      color: noteColorForCategory(noteCategoryFromStorage(category)),
      isPinned: isPinned,
      createdAt: createdAt ?? ts,
      updatedAt: updatedAt ?? ts,
      deletedAt: deletedAt,
    );
  }

  Future<void> seed(Note value) => noteRepo.upsertNote(value);

  Future<NotesCubit> startCubit() async {
    final cubit = NotesCubit(
      noteRepository: noteRepo,
      now: () => fixedNow,
    )..start();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return cubit;
  }

  /// Data campuran: dua kategori, satu disematkan, satu terbaru.
  Future<void> seedMixed() async {
    await seed(note(
      'n1',
      title: 'Ide aplikasi',
      content: 'Menulis rencana fitur',
      category: NoteCategory.idea.name,
      updatedAt: ts,
    ));
    await seed(note(
      'n2',
      title: 'Beli buku',
      content: 'Buku kuliah semester ini',
      category: NoteCategory.study.name,
      updatedAt: ts.add(const Duration(hours: 5)),
    ));
    await seed(note(
      'n3',
      title: 'Rapat tim',
      content: 'Agenda mingguan',
      category: NoteCategory.work.name,
      isPinned: true,
      updatedAt: ts.add(const Duration(hours: 1)),
    ));
  }

  test('memuat catatan dan mengurutkan sematan lebih dulu lalu terbaru',
      () async {
    await seedMixed();

    final cubit = await startCubit();

    expect(cubit.state.status, NotesStatus.loaded);
    expect(cubit.state.visibleNotes.map((n) => n.id), ['n3', 'n2', 'n1']);
    await cubit.close();
  });

  test('tanggal hari ini diambil dari jam yang diinjeksi', () async {
    final cubit = await startCubit();

    expect(cubit.state.today, today);
    await cubit.close();
  });

  test('filter kategori menyaring catatan', () async {
    await seedMixed();

    final cubit = await startCubit();
    cubit.setCategory(NoteCategory.study);

    expect(cubit.state.visibleNotes.map((n) => n.id), ['n2']);
    await cubit.close();
  });

  test('pencarian mencocokkan judul atau isi tanpa peka huruf besar/kecil',
      () async {
    await seedMixed();

    final cubit = await startCubit();

    cubit.setQuery('beli');
    expect(cubit.state.visibleNotes.map((n) => n.id), ['n2']);

    // Kueri cocok dengan isi catatan n1.
    cubit.setQuery('RENCANA');
    expect(cubit.state.visibleNotes.map((n) => n.id), ['n1']);

    await cubit.close();
  });

  test('kueri di-trim sehingga spasi di ujung diabaikan', () async {
    await seedMixed();

    final cubit = await startCubit();
    cubit.setQuery('  buku  ');

    expect(cubit.state.visibleNotes.map((n) => n.id), ['n2']);
    await cubit.close();
  });

  test('filter kategori dan pencarian digabung (AND)', () async {
    await seedMixed();

    final cubit = await startCubit();
    cubit.setCategory(NoteCategory.study);
    cubit.setQuery('tidur');

    expect(cubit.state.isEmpty, isTrue);
    expect(cubit.state.hasFilter, isTrue);

    cubit.setQuery('buku');
    expect(cubit.state.visibleNotes.map((n) => n.id), ['n2']);
    await cubit.close();
  });

  test('mengganti kategori ke Semua menampilkan seluruh catatan', () async {
    await seedMixed();

    final cubit = await startCubit();
    cubit.setCategory(NoteCategory.work);
    expect(cubit.state.visibleNotes, hasLength(1));

    cubit.setCategory(null);
    expect(cubit.state.visibleNotes, hasLength(3));
    expect(cubit.state.category, isNull);
    await cubit.close();
  });

  test('ganti mode tampilan bolak-balik antara grid dan daftar', () async {
    final cubit = await startCubit();

    expect(cubit.state.viewMode, NotesViewMode.grid);

    cubit.toggleViewMode();
    expect(cubit.state.viewMode, NotesViewMode.list);

    cubit.toggleViewMode();
    expect(cubit.state.viewMode, NotesViewMode.grid);
    await cubit.close();
  });

  test('keadaan kosong tanpa filter berarti belum ada catatan', () async {
    final cubit = await startCubit();

    expect(cubit.state.isEmpty, isTrue);
    expect(cubit.state.hasFilter, isFalse);
    await cubit.close();
  });

  test('menyematkan catatan dari luar cubit mengubah urutan', () async {
    await seed(note('n1', updatedAt: ts));
    await seed(note('n2', updatedAt: ts.add(const Duration(hours: 1))));

    final cubit = await startCubit();
    expect(cubit.state.visibleNotes.map((n) => n.id), ['n2', 'n1']);

    await noteRepo.upsertNote(note('n1', isPinned: true, updatedAt: ts));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(cubit.state.visibleNotes.map((n) => n.id), ['n1', 'n2']);
    await cubit.close();
  });

  test('catatan yang dihapus hilang dari daftar dan bisa dipulihkan', () async {
    await seedMixed();

    final cubit = await startCubit();
    await noteRepo.softDeleteNote('n2');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(cubit.state.visibleNotes.map((n) => n.id), ['n3', 'n1']);

    await cubit.restore(['n2']);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(cubit.state.visibleNotes.map((n) => n.id), ['n3', 'n2', 'n1']);
    await cubit.close();
  });

  test('close membatalkan langganan tanpa galat', () async {
    final cubit = await startCubit();
    await cubit.close();

    // Perubahan setelah close tidak boleh lagi mengubah state (cubit tertutup).
    await seed(note('n9'));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(cubit.isClosed, isTrue);
  });
}
