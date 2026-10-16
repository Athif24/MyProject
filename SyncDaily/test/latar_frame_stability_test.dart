import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/router/app_router.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/core/widgets/app_bottom_nav.dart';
import 'package:sync_daily/core/widgets/app_chip.dart';
import 'package:sync_daily/core/widgets/app_search_field.dart';
import 'package:sync_daily/core/widgets/latar_layar.dart';
import 'package:sync_daily/features/calendar/presentation/pages/calendar_page.dart';
import 'package:sync_daily/features/calendar/presentation/widgets/calendar_item_tile.dart';
import 'package:sync_daily/features/calendar/presentation/widgets/calendar_month_grid.dart';
import 'package:sync_daily/features/home/presentation/pages/home_page.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notes/presentation/pages/notes_page.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_card.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_summary.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/main.dart';

import 'helpers/fake_note_repository.dart';
import 'helpers/test_dependencies.dart';
import 'helpers/test_repositories.dart';

/// Tes regresi kilatan latar dan lompatan tata letak.
///
/// Latar halaman ([LayarLatar]) harus selalu setinggi layar, dan tata letak
/// Catatan/Kalender tidak boleh berubah antara frame pertama setelah data
/// termuat dan frame stabil: teks keadaan kosong, kolom cari, chip, dan kartu
/// pertama harus tetap pada posisi yang sama.
///
/// Pengukuran diambil pada **setiap** `pump()` (bukan `pumpAndSettle`) supaya
/// frame peralihan tata letak ikut tertangkap. Dipakai repository tiruan
/// (`FakeNoteRepository` + `MockTaskRepository`) seperti tes widget lain di
/// proyek ini.
void main() {
  late AppDatabase db;
  late FakeNoteRepository noteRepository;

  final ts = DateTime.utc(2026, 10, 1, 8);

  setUpAll(() async {
    await IdDate.ensureInitialized();
    registerFallbackValue(<String>[]);
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

  /// Mengisi agenda Kalender dengan dua item pada tanggal hari ini.
  void registerTodayAgenda() {
    final now = DateTime.now();
    final tasks = <Task>[
      Task(
        id: 'a',
        title: 'Agenda Hari Ini',
        type: TaskType.task,
        dueAt: DateTime(now.year, now.month, now.day, 9),
        createdAt: ts,
        updatedAt: ts,
      ),
      Task(
        id: 'b',
        title: 'Agenda Kedua',
        type: TaskType.task,
        dueAt: DateTime(now.year, now.month, now.day, 13),
        createdAt: ts,
        updatedAt: ts,
      ),
    ];

    final taskRepository = MockTaskRepository();
    when(
      () => taskRepository.watchSummary(
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'),
        today: any(named: 'today'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        const TaskSummary(
          today: 0,
          schedule: 0,
          allTasks: 0,
          projectsOwned: 0,
          projectsReceived: 0,
        ),
      ),
    );
    when(() => taskRepository.watchAllTasks())
        .thenAnswer((_) => Stream.value(tasks));
    when(() => taskRepository.watchRecurrences())
        .thenAnswer((_) => Stream<List<TaskRecurrence>>.value(const []));
    when(() => taskRepository.restoreTasks(any())).thenAnswer((_) async {});
    when(() => taskRepository.getReminders(any())).thenAnswer((_) async => []);
    when(() => taskRepository.getRecurrence(any())).thenAnswer((_) async => null);

    getIt.unregister<TaskRepository>();
    getIt.registerSingleton<TaskRepository>(taskRepository);
  }

  double screenHeight(WidgetTester tester) =>
      tester.view.physicalSize.height / tester.view.devicePixelRatio;

  Finder pageLatar(Type page) => find.descendant(
        of: find.byType(page),
        matching: find.byType(LayarLatar),
      );

  Finder navItem(IconData icon) => find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.byIcon(icon),
      );

  double? topOf(WidgetTester tester, Finder? finder) {
    if (finder == null || finder.evaluate().isEmpty) {
      return null;
    }
    return tester.getTopLeft(finder).dy;
  }

  /// Membuka aplikasi dari Beranda pada ukuran [size] (dp).
  Future<void> pumpApp(WidgetTester tester, Size size) async {
    AppRouter.router.go('/home');
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();
  }

  /// Mengetuk tab [tabIcon] lalu mengukur tata letak pada tiap `pump()`.
  ///
  /// Pengukuran hanya diambil pada frame ketika [loadedMarker] (penanda isi
  /// yang sudah termuat) tampil; frame loading dilewati. Setiap pump juga
  /// diperiksa agar luapan (overflow) tidak lolos.
  Future<List<_FrameSample>> framesAfterTabSwitch(
    WidgetTester tester, {
    required IconData tabIcon,
    required Type page,
    required Finder loadedMarker,
    Finder? emptyText,
    Finder? search,
    Finder? chip,
    Finder? firstItem,
    Finder? grid,
  }) async {
    await tester.tap(navItem(tabIcon));

    final frames = <_FrameSample>[];
    for (var i = 0; i < 10; i++) {
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'tata letak meluap pada pump ke-${i + 1}',
      );
      if (loadedMarker.evaluate().isEmpty) {
        continue;
      }
      frames.add(
        _FrameSample(
          latarHeight: tester.getSize(pageLatar(page)).height,
          emptyTop: topOf(tester, emptyText),
          searchTop: topOf(tester, search),
          chipTop: topOf(tester, chip),
          firstItemTop: topOf(tester, firstItem),
          gridTop: topOf(tester, grid),
        ),
      );
    }
    return frames;
  }

  void expectSameTop(
    double? actual,
    double? expected,
    String what,
    int frame,
    String label,
  ) {
    if (expected == null) {
      expect(
        actual,
        isNull,
        reason: '$what muncul tak terduga pada frame $frame ($label)',
      );
      return;
    }
    expect(actual, isNotNull, reason: '$what hilang pada frame $frame ($label)');
    expect(
      actual,
      moreOrLessEquals(expected, epsilon: 0.5),
      reason: '$what berpindah pada frame $frame ($label)',
    );
  }

  /// Tinggi latar penuh dan tidak ada yang berpindah antar frame.
  void expectFullHeightAndStable(
    WidgetTester tester,
    List<_FrameSample> frames, {
    required String label,
  }) {
    expect(
      frames.length,
      greaterThanOrEqualTo(2),
      reason: 'perlu frame pertama dan frame stabil untuk $label',
    );

    final height = screenHeight(tester);
    final first = frames.first;
    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final number = i + 1;
      expect(
        frame.latarHeight,
        moreOrLessEquals(height, epsilon: 0.5),
        reason: 'tinggi LayarLatar tidak penuh pada frame $number ($label)',
      );
      expectSameTop(
        frame.emptyTop,
        first.emptyTop,
        'teks keadaan kosong',
        number,
        label,
      );
      expectSameTop(frame.searchTop, first.searchTop, 'kolom cari', number, label);
      expectSameTop(frame.chipTop, first.chipTop, 'chip kategori', number, label);
      expectSameTop(
        frame.firstItemTop,
        first.firstItemTop,
        'kartu pertama',
        number,
        label,
      );
      expectSameTop(frame.gridTop, first.gridTop, 'grid bulan', number, label);
    }
  }

  for (final size in const [Size(400, 800), Size(320, 640)]) {
    final label = '${size.width.round()} x ${size.height.round()}';

    group('Catatan $label', () {
      testWidgets('daftar kosong: latar penuh dan tata letak tetap sejak '
          'frame pertama', (tester) async {
        await pumpApp(tester, size);

        final emptyText = find.text(AppStrings.noNotes);
        final frames = await framesAfterTabSwitch(
          tester,
          tabIcon: AppIcons.notes,
          page: NotesPage,
          loadedMarker: emptyText,
          emptyText: emptyText,
          search: find.byType(AppSearchField),
          chip: find.byType(AppChip).first,
        );

        expectFullHeightAndStable(
          tester,
          frames,
          label: 'Catatan kosong $label',
        );
      });

      testWidgets('daftar terisi: latar penuh dan kartu tidak berpindah',
          (tester) async {
        await noteRepository.upsertNote(makeNote('n1', title: 'Ide aplikasi'));
        await noteRepository.upsertNote(makeNote(
          'n2',
          title: 'Rapat tim',
          category: NoteCategory.work,
        ));
        await pumpApp(tester, size);

        final cards = find.byType(NoteCard);
        final frames = await framesAfterTabSwitch(
          tester,
          tabIcon: AppIcons.notes,
          page: NotesPage,
          loadedMarker: cards,
          search: find.byType(AppSearchField),
          chip: find.byType(AppChip).first,
          firstItem: cards.first,
        );

        expectFullHeightAndStable(
          tester,
          frames,
          label: 'Catatan terisi $label',
        );
      });
    });

    group('Kalender $label', () {
      testWidgets('agenda kosong: latar penuh dan tata letak tetap sejak '
          'frame pertama', (tester) async {
        await pumpApp(tester, size);

        final emptyText = find.text(AppStrings.noItemsOnDay);
        final frames = await framesAfterTabSwitch(
          tester,
          tabIcon: AppIcons.calendar,
          page: CalendarPage,
          loadedMarker: emptyText,
          emptyText: emptyText,
          grid: find.byType(CalendarMonthGrid),
        );

        expectFullHeightAndStable(
          tester,
          frames,
          label: 'Kalender kosong $label',
        );
      });

      testWidgets('agenda terisi: latar penuh dan agenda tidak berpindah',
          (tester) async {
        registerTodayAgenda();
        await pumpApp(tester, size);

        final tiles = find.byType(CalendarItemTile);
        final frames = await framesAfterTabSwitch(
          tester,
          tabIcon: AppIcons.calendar,
          page: CalendarPage,
          loadedMarker: tiles,
          grid: find.byType(CalendarMonthGrid),
          firstItem: tiles.first,
        );

        expectFullHeightAndStable(
          tester,
          frames,
          label: 'Kalender terisi $label',
        );
      });
    });

    testWidgets('Beranda $label: latar penuh sejak frame pertama',
        (tester) async {
      AppRouter.router.go('/home');
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SyncDailyApp());
      final height = screenHeight(tester);
      for (var i = 0; i < 6; i++) {
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'tata letak meluap pada pump ke-${i + 1} (Beranda $label)',
        );
        expect(
          tester.getSize(pageLatar(HomePage)).height,
          moreOrLessEquals(height, epsilon: 0.5),
          reason: 'tinggi LayarLatar tidak penuh pada pump ke-${i + 1} '
              '(Beranda $label)',
        );
      }
    });
  }
}

/// Pengukuran tata letak satu frame pada satu layar.
class _FrameSample {
  const _FrameSample({
    required this.latarHeight,
    this.emptyTop,
    this.searchTop,
    this.chipTop,
    this.firstItemTop,
    this.gridTop,
  });

  /// Tinggi kotak latar ([LayarLatar]).
  final double latarHeight;

  /// Posisi Y teks keadaan kosong (null bila keadaan kosong tidak tampil).
  final double? emptyTop;

  /// Posisi Y kolom cari (null di layar yang tidak punya).
  final double? searchTop;

  /// Posisi Y chip filter pertama (null di layar yang tidak punya).
  final double? chipTop;

  /// Posisi Y kartu/item pertama (null bila daftar kosong).
  final double? firstItemTop;

  /// Posisi Y grid bulan Kalender (null di layar lain).
  final double? gridTop;
}
