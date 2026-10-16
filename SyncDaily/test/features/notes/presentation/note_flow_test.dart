import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/router/app_router.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/core/widgets/app_add_button.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_card.dart';
import 'package:sync_daily/main.dart';

import '../../../helpers/fake_note_repository.dart';
import '../../../helpers/test_dependencies.dart';
import '../../../helpers/test_repositories.dart';

/// Tes widget alur Catatan: buat -> cari -> ubah -> hapus (dengan Urungkan).
///
/// Memakai repository catatan tiruan (bukan Drift) mengikuti pola tes widget
/// lain di proyek ini: query stream Drift meninggalkan timer saat dibatalkan di
/// dalam `flutter_test`.
void main() {
  late AppDatabase db;
  late FakeNoteRepository noteRepository;

  setUpAll(() async {
    await IdDate.ensureInitialized();
  });

  setUp(() async {
    db = await setUpInMemoryDependencies();
    registerMockRepositories();
    noteRepository = FakeNoteRepository();
    getIt.unregister<NoteRepository>();
    getIt.registerSingleton<NoteRepository>(noteRepository);
  });

  tearDown(() async {
    await noteRepository.dispose();
    await getIt.reset();
    await db.close();
  });

  Future<void> pumpNotes(WidgetTester tester) async {
    AppRouter.router.go('/notes');

    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();
  }

  Finder cardWith(String title) => find.descendant(
        of: find.byType(NoteCard),
        matching: find.text(title),
      );

  Finder searchField() => find.byType(TextField);

  /// Node fokus kolom cari di layar Catatan.
  FocusNode searchFocusNode(WidgetTester tester) => tester
      .widget<EditableText>(
        find.descendant(
          of: searchField(),
          matching: find.byType(EditableText),
        ),
      )
      .focusNode;

  testWidgets('kolom cari lepas fokus dan keyboard setelah menyimpan catatan',
      (tester) async {
    await pumpNotes(tester);

    // Kolom cari difokuskan lebih dulu supaya keyboard terbuka.
    await tester.tap(searchField());
    await tester.pumpAndSettle();
    expect(searchFocusNode(tester).hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    // Buat catatan baru, lalu simpan.
    await tester.tap(find.byType(AppAddButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Beli buku');
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    // Kembali di layar Catatan: fokus tidak dipulihkan, keyboard tidak muncul.
    expect(cardWith('Beli buku'), findsOneWidget);
    expect(searchFocusNode(tester).hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('kolom cari lepas fokus dan keyboard setelah kembali dari detail',
      (tester) async {
    final ts = DateTime.utc(2026, 10, 1, 8);
    await noteRepository.upsertNote(Note(
      id: 'n1',
      title: 'Beli buku',
      content: 'Buku kuliah',
      createdAt: ts,
      updatedAt: ts,
    ));
    await pumpNotes(tester);

    // Kolom cari difokuskan lebih dulu supaya keyboard terbuka.
    await tester.tap(searchField());
    await tester.pumpAndSettle();
    expect(searchFocusNode(tester).hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    // Buka detail lewat kartu: keyboard ikut tertutup.
    await tester.tap(cardWith('Beli buku'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noteDetail), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);

    // Kembali ke daftar: fokus tidak dipulihkan, keyboard tidak muncul.
    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();

    expect(cardWith('Beli buku'), findsOneWidget);
    expect(searchFocusNode(tester).hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('buat, cari, ubah, lalu hapus dan urungkan', (tester) async {
    await pumpNotes(tester);
    expect(find.text(AppStrings.noNotes), findsOneWidget);

    // --- Buat catatan baru lewat tombol + ungu.
    await tester.tap(find.byType(AppAddButton));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noteNew), findsOneWidget);
    expect(find.text(AppStrings.save), findsOneWidget);
    expect(find.byIcon(AppIcons.back), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Beli buku');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Buku kuliah semester ini',
    );
    await tester.tap(find.text(AppStrings.noteCategoryStudy));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    // Kembali ke daftar dan kartu baru tampil.
    expect(find.text(AppStrings.screenNotes), findsOneWidget);
    expect(cardWith('Beli buku'), findsOneWidget);

    // --- Cari catatan.
    await tester.enterText(searchField(), 'beli');
    await tester.pumpAndSettle();
    expect(cardWith('Beli buku'), findsOneWidget);

    await tester.enterText(searchField(), 'tidak ada');
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noNotesMatch), findsOneWidget);

    await tester.enterText(searchField(), '');
    await tester.pumpAndSettle();
    expect(cardWith('Beli buku'), findsOneWidget);

    // --- Ubah lewat halaman detail.
    await tester.tap(cardWith('Beli buku'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noteDetail), findsOneWidget);
    expect(find.text('Buku kuliah semester ini'), findsOneWidget);
    expect(find.text(AppStrings.noteCategoryStudy), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.edit));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noteEdit), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Beli buku baru');
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    // Kembali ke detail dengan judul baru, lalu kembali ke daftar.
    expect(find.text(AppStrings.noteDetail), findsOneWidget);
    expect(find.text('Beli buku baru'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();
    expect(cardWith('Beli buku baru'), findsOneWidget);

    // --- Hapus dengan konfirmasi.
    await tester.tap(cardWith('Beli buku baru'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(AppIcons.delete));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.deleteNoteTitle), findsOneWidget);
    expect(find.text('"Beli buku baru" akan dihapus.'), findsOneWidget);

    await tester.tap(find.text(AppStrings.delete));
    await tester.pumpAndSettle();

    // Kembali ke daftar: keadaan kosong + snackbar Urungkan.
    expect(find.text(AppStrings.noNotes), findsOneWidget);
    expect(find.text(AppStrings.noteDeleted), findsOneWidget);

    // --- Urungkan mengembalikan catatan.
    await tester.tap(find.text(AppStrings.undo));
    await tester.pumpAndSettle();

    expect(cardWith('Beli buku baru'), findsOneWidget);
    expect(find.text(AppStrings.noNotes), findsNothing);
  });

  testWidgets('simpan tanpa judul menampilkan galat dan tidak menyimpan',
      (tester) async {
    await pumpNotes(tester);

    await tester.tap(find.byType(AppAddButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Hanya isi');
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noteTitleRequired), findsOneWidget);
    expect(find.text(AppStrings.noteNew), findsOneWidget);
  });

  testWidgets('detail catatan yang tidak ada menampilkan pesan tidak ditemukan',
      (tester) async {
    AppRouter.router.go('/notes/tidak-ada');

    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noteNotFound), findsOneWidget);
    expect(find.text(AppStrings.noteNotFoundDescription), findsOneWidget);
  });
}
