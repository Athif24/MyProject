import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/router/app_router.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/core/widgets/app_chip.dart';
import 'package:sync_daily/core/widgets/app_icon_button.dart';
import 'package:sync_daily/core/widgets/app_search_field.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_card.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_labels.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_tile.dart';
import 'package:sync_daily/main.dart';

import '../../../helpers/fake_note_repository.dart';
import '../../../helpers/test_dependencies.dart';
import '../../../helpers/test_repositories.dart';

/// Tes widget layar Catatan: susunan bagian tetap (judul, kolom cari, chip
/// kategori), grid dua kolom, tampilan daftar, keadaan kosong, sematan, dan
/// ketahanan tata letak di layar pendek.
///
/// Memakai repository catatan tiruan (lihat `FakeNoteRepository`) supaya tidak
/// membuka query stream Drift di dalam `flutter_test`.
void main() {
  late AppDatabase db;
  late FakeNoteRepository noteRepository;

  final ts = DateTime.utc(2026, 10, 1, 8);

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

  Note makeNote(
    String id, {
    String title = 'Catatan',
    String content = 'Isi catatan',
    NoteCategory? category,
    bool isPinned = false,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title,
      content: content,
      category: category?.name,
      color: noteColorForCategory(category),
      isPinned: isPinned,
      createdAt: ts,
      updatedAt: updatedAt ?? ts,
    );
  }

  Future<void> pumpNotes(
    WidgetTester tester, {
    Size physicalSize = const Size(1200, 2400),
  }) async {
    AppRouter.router.go('/notes');

    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();
  }

  /// Teks di dalam kartu/daftar catatan (bukan chip kategori).
  Finder inList(String text) => find.descendant(
        of: find.byWidgetPredicate(
          (widget) => widget is NoteCard || widget is NoteTile,
        ),
        matching: find.text(text),
      );

  /// Ketuk tombol ganti tampilan (satu-satunya [AppIconButton] di layar ini).
  ///
  /// Diketuk di tengah tombol, seperti pengguna: FAB galeri komponen sudah
  /// dipindah ke kiri bawah (lihat `AppShell`) sehingga tidak menutupi ikon di
  /// header. Kalau FAB menutupinya lagi, ketukan ini tidak mengubah tampilan
  /// dan tes gagal.
  Future<void> tapViewToggle(WidgetTester tester) async {
    await tester.tap(find.byType(AppIconButton));
    await tester.pumpAndSettle();
  }

  group('susunan layar', () {
    testWidgets('menampilkan judul, kolom cari, dan chip kategori',
        (tester) async {
      await pumpNotes(tester);

      expect(find.text(AppStrings.screenNotes), findsOneWidget);
      expect(find.byType(AppSearchField), findsOneWidget);
      for (final label in [
        AppStrings.noteCategoryAll,
        AppStrings.noteCategoryPersonal,
        AppStrings.noteCategoryWork,
        AppStrings.noteCategoryIdea,
        AppStrings.noteCategoryStudy,
        AppStrings.noteCategoryImportant,
      ]) {
        expect(
          find.descendant(
            of: find.byType(AppChip),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('kolom cari tidak menerima fokus saat layar dibuka',
        (tester) async {
      await pumpNotes(tester);

      for (final editable in tester.widgetList<EditableText>(
        find.byType(EditableText),
      )) {
        expect(editable.focusNode.hasFocus, isFalse);
      }
    });

    testWidgets('kartu grid tersusun dua kolom dengan label dan tanggal',
        (tester) async {
      await noteRepository.upsertNote(makeNote(
        'n1',
        title: 'Ide aplikasi',
        content: 'Rencana fitur baru',
        category: NoteCategory.idea,
        updatedAt: DateTime.now(),
      ));
      await noteRepository.upsertNote(makeNote(
        'n2',
        title: 'Rapat tim',
        category: NoteCategory.work,
        updatedAt: DateTime(2025, 10, 1, 8),
      ));

      await pumpNotes(tester);

      final cards = find.byType(NoteCard);
      expect(cards, findsNWidgets(2));
      // Dua kolom: baris pertama punya sumbu Y sama, sumbu X berbeda.
      final first = tester.getTopLeft(cards.at(0));
      final second = tester.getTopLeft(cards.at(1));
      expect(first.dy, second.dy);
      expect(first.dx, isNot(second.dx));

      expect(inList('Ide aplikasi'), findsOneWidget);
      expect(inList('Rencana fitur baru'), findsOneWidget);
      expect(inList(noteCategoryLabel(NoteCategory.idea)), findsOneWidget);
      // Catatan yang diperbarui hari ini memakai label "Hari ini", sedangkan
      // catatan tahun lain memakai tanggal id_ID lengkap.
      expect(inList(AppStrings.noteUpdatedToday), findsOneWidget);
      expect(inList(IdDate.full(DateTime(2025, 10, 1, 8))), findsOneWidget);
      expect(inList(IdDate.dayMonth(DateTime(2025, 10, 1, 8))), findsNothing);
    });

    testWidgets('catatan tanpa isi menampilkan penanda tanpa isi',
        (tester) async {
      await noteRepository.upsertNote(makeNote('n1', content: ''));

      await pumpNotes(tester);

      expect(inList(AppStrings.noNoteContent), findsOneWidget);
    });

    testWidgets('tombol ganti tampilan mengubah grid menjadi daftar',
        (tester) async {
      await noteRepository.upsertNote(makeNote('n1', title: 'Ide aplikasi'));

      await pumpNotes(tester);
      expect(find.byType(NoteCard), findsOneWidget);
      expect(find.byType(NoteTile), findsNothing);
      expect(find.byIcon(AppIcons.listView), findsOneWidget);

      await tapViewToggle(tester);

      expect(find.byType(NoteCard), findsNothing);
      expect(find.byType(NoteTile), findsOneWidget);
      expect(find.text('Ide aplikasi'), findsOneWidget);
      // Ikon berubah menjadi mode yang akan dibuka.
      expect(find.byIcon(AppIcons.gridView), findsOneWidget);

      await tapViewToggle(tester);
      expect(find.byType(NoteCard), findsOneWidget);
      expect(find.byType(NoteTile), findsNothing);
    });

    testWidgets('ikon sematan hanya tampil pada catatan yang disematkan',
        (tester) async {
      await noteRepository.upsertNote(makeNote(
        'n1',
        title: 'Disematkan',
        isPinned: true,
      ));
      await noteRepository.upsertNote(makeNote('n2', title: 'Biasa'));

      await pumpNotes(tester);

      expect(find.byIcon(AppIcons.pin), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Disematkan'),
            matching: find.byType(NoteCard),
          ),
          matching: find.byIcon(AppIcons.pin),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tidak punya tombol tambah di layar Catatan', (tester) async {
      await pumpNotes(tester);

      // Penambahan catatan lewat satu pintu: panel "Buat Baru" pada tombol +
      // navigasi bawah. Baris judul hanya berisi judul dan tombol ganti
      // tampilan (tanpa tombol + ungu).
      final titleRow = find.ancestor(
        of: find.text(AppStrings.screenNotes),
        matching: find.byType(Row),
      );
      expect(titleRow, findsOneWidget);
      expect(tester.widget<Row>(titleRow).children, hasLength(2));
      expect(find.byType(AppIconButton), findsOneWidget);
    });
  });

  group('tombol galeri debug', () {
    // 400 x 800 dan 320 x 640 dp (dengan devicePixelRatio 3 dari [pumpNotes]).
    for (final size in const [Size(400, 800), Size(320, 640)]) {
      testWidgets(
          'ikon ganti tampilan dapat diketuk pada '
          '${size.width.round()} x ${size.height.round()}', (tester) async {
        await noteRepository.upsertNote(makeNote('n1', title: 'Ide aplikasi'));

        await pumpNotes(tester, physicalSize: size * 3);

        // FAB galeri debug pindah ke kiri bawah: tidak lagi menutupi ikon
        // ganti tampilan di header.
        final fab = tester.getRect(find.byType(FloatingActionButton));
        expect(
          fab.overlaps(tester.getRect(find.byType(AppIconButton))),
          isFalse,
        );

        // Ketukan di tengah ikon mengubah tampilan -> tidak tertutup FAB.
        await tapViewToggle(tester);

        expect(find.byType(NoteTile), findsOneWidget);
        expect(find.byType(NoteCard), findsNothing);
      });
    }
  });

  group('penyaringan', () {
    setUp(() async {
      await noteRepository.upsertNote(makeNote(
        'n1',
        title: 'Beli buku',
        content: 'Buku kuliah',
        category: NoteCategory.study,
      ));
      await noteRepository.upsertNote(makeNote(
        'n2',
        title: 'Rapat tim',
        category: NoteCategory.work,
      ));
    });

    testWidgets('chip kategori menyaring kartu', (tester) async {
      await pumpNotes(tester);
      expect(find.byType(NoteCard), findsNWidgets(2));

      await tester.tap(
        find.descendant(
          of: find.byType(AppChip),
          matching: find.text(AppStrings.noteCategoryWork),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NoteCard), findsOneWidget);
      expect(inList('Rapat tim'), findsOneWidget);
      expect(inList('Beli buku'), findsNothing);
    });

    testWidgets('pencarian menyaring judul dan isi', (tester) async {
      await pumpNotes(tester);

      await tester.enterText(find.byType(TextField), 'beli');
      await tester.pumpAndSettle();
      expect(find.byType(NoteCard), findsOneWidget);
      expect(inList('Beli buku'), findsOneWidget);

      // Kueri juga cocok dengan isi catatan.
      await tester.enterText(find.byType(TextField), 'KULIAH');
      await tester.pumpAndSettle();
      expect(inList('Beli buku'), findsOneWidget);
    });

    testWidgets('tanpa hasil: keadaan kosong berbeda dari belum ada catatan',
        (tester) async {
      await pumpNotes(tester);
      expect(find.text(AppStrings.noNotes), findsNothing);

      await tester.enterText(find.byType(TextField), 'tidak ada');
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noNotesMatch), findsOneWidget);
      expect(
        find.text(AppStrings.noNotesMatchDescription),
        findsOneWidget,
      );
    });

    testWidgets('filter kategori dan pencarian digabung', (tester) async {
      await pumpNotes(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(AppChip),
          matching: find.text(AppStrings.noteCategoryStudy),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'rapat');
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noNotesMatch), findsOneWidget);
      expect(find.byType(NoteCard), findsNothing);
    });

    testWidgets('belum ada catatan menampilkan keadaan kosong',
        (tester) async {
      await noteRepository.softDeleteNote('n1');
      await noteRepository.softDeleteNote('n2');

      await pumpNotes(tester);

      expect(find.text(AppStrings.noNotes), findsOneWidget);
      expect(find.text(AppStrings.noNotesDescription), findsOneWidget);
    });
  });

  group('tata letak', () {
    testWidgets('kolom cari dan chip tetap di atas saat daftar bergulir',
        (tester) async {
      for (var i = 0; i < 12; i++) {
        await noteRepository.upsertNote(makeNote(
          'n$i',
          title: 'Catatan $i',
          updatedAt: ts.add(Duration(hours: i)),
        ));
      }

      await pumpNotes(tester);

      final searchBefore = tester.getTopLeft(find.byType(AppSearchField));
      final chipsBefore = tester.getTopLeft(find.byType(AppChip).first);
      // Kartu terakhir (paling lama) masih di bawah area pandang.
      final lastBefore = tester.getTopLeft(find.text('Catatan 0'));
      final viewportBottom =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(lastBefore.dy, greaterThan(viewportBottom));

      // Grid lebih tinggi dari layar, jadi gulir dimulai dari titik di dalam
      // area daftar yang terlihat (bukan dari titik tengah GridView).
      await tester.dragFrom(const Offset(200, 600), const Offset(0, -320));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('Catatan 0')).dy,
        lessThan(lastBefore.dy),
      );
      expect(tester.getTopLeft(find.byType(AppSearchField)), searchBefore);
      expect(tester.getTopLeft(find.byType(AppChip).first), chipsBefore);
    });

    testWidgets('layar pendek 320 x 640 tidak meluap', (tester) async {
      for (var i = 0; i < 12; i++) {
        await noteRepository.upsertNote(makeNote(
          'n$i',
          title: 'Catatan $i',
          content: 'Isi catatan yang cukup panjang untuk beberapa baris',
          category: NoteCategory.values[i % NoteCategory.values.length],
          updatedAt: ts.add(Duration(hours: i)),
        ));
      }

      await pumpNotes(tester, physicalSize: const Size(960, 1920));

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.screenNotes), findsOneWidget);
      expect(find.byType(AppSearchField), findsOneWidget);
      expect(find.byType(NoteCard), findsWidgets);
    });

    testWidgets('layar pendek 320 x 640 dengan daftar kosong tidak meluap',
        (tester) async {
      await pumpNotes(tester, physicalSize: const Size(960, 1920));

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.noNotes), findsOneWidget);
      expect(find.byType(AppSearchField), findsOneWidget);
    });

    testWidgets('kartu catatan muat di dalam tinggi token kartu',
        (tester) async {
      for (var i = 0; i < 6; i++) {
        await noteRepository.upsertNote(makeNote(
          'n$i',
          title: 'Judul catatan yang panjang $i',
          content: 'Isi yang panjang ' * 12,
          category: NoteCategory.important,
        ));
      }

      await pumpNotes(tester);

      expect(tester.takeException(), isNull);
      final cards = find.byType(NoteCard);
      for (var i = 0; i < cards.evaluate().length; i++) {
        expect(
          tester.getSize(cards.at(i)).height,
          AppSizes.noteCardHeight,
        );
      }
    });
  });

  group('label tanggal catatan', () {
    final today = DateTime(2026, 10, 20);

    test('hari ini', () {
      expect(
        noteDateLabel(DateTime(2026, 10, 20, 9, 30), today),
        AppStrings.noteUpdatedToday,
      );
    });

    test('kemarin', () {
      expect(
        noteDateLabel(DateTime(2026, 10, 19, 22), today),
        AppStrings.noteUpdatedYesterday,
      );
    });

    test('tanggal id_ID untuk tahun berjalan', () {
      expect(noteDateLabel(DateTime(2026, 10, 14, 7), today), '14 Okt');
    });

    test('tanggal id_ID dengan tahun bila tahun berbeda', () {
      expect(noteDateLabel(DateTime(2025, 12, 31, 7), today), '31 Des 2025');
    });
  });
}
