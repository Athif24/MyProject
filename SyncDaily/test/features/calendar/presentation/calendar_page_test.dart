import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/router/app_router.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/category_theme.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/core/widgets/app_bottom_nav.dart';
import 'package:sync_daily/core/widgets/list_item_tile.dart';
import 'package:sync_daily/core/widgets/section_header.dart';
import 'package:sync_daily/features/calendar/presentation/widgets/calendar_add_button.dart';
import 'package:sync_daily/features/calendar/presentation/widgets/calendar_item_tile.dart';
import 'package:sync_daily/features/calendar/presentation/widgets/calendar_month_grid.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_summary.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/main.dart';

import '../../../helpers/test_dependencies.dart';
import '../../../helpers/test_repositories.dart';

/// Tes widget layar Kalender (F5).
///
/// Memakai repository tiruan seperti tes widget lain di proyek ini (lihat
/// catatan di `test/helpers/test_repositories.dart`). Tanggal acuan dihitung
/// dari `DateTime.now()` supaya tes tidak bergantung pada tanggal berjalan.
void main() {
  late AppDatabase db;
  late MockTaskRepository taskRepository;
  late DateTime today;
  late DateTime day1;
  late DateTime day2;
  late List<Task> tasks;

  final ts = DateTime.utc(2026, 1, 1);

  setUpAll(() async {
    await IdDate.ensureInitialized();
    registerFallbackValue(<String>[]);
  });

  setUp(() async {
    db = await setUpInMemoryDependencies();
    registerMockRepositories();

    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    day1 = DateTime(now.year, now.month, 1);
    day2 = DateTime(now.year, now.month, 2);

    tasks = [
      Task(
        id: 'a',
        title: 'Item Satu',
        type: TaskType.task,
        dueAt: DateTime(day1.year, day1.month, day1.day, 9),
        createdAt: ts,
        updatedAt: ts,
      ),
      Task(
        id: 'b',
        title: 'Item Dua',
        type: TaskType.task,
        dueAt: DateTime(day2.year, day2.month, day2.day, 9),
        createdAt: ts,
        updatedAt: ts,
      ),
      Task(
        id: 'c',
        title: 'Selesai Satu',
        type: TaskType.task,
        status: TaskStatus.done,
        dueAt: DateTime(day1.year, day1.month, day1.day, 13),
        createdAt: ts,
        updatedAt: ts,
      ),
      // Sub-tugas induk 'c' pada hari yang sama (urutan data: Zebra lalu Apel).
      Task(
        id: 'd',
        title: 'Sub Zebra',
        type: TaskType.task,
        parentTaskId: 'c',
        dueAt: DateTime(day1.year, day1.month, day1.day, 13),
        createdAt: ts,
        updatedAt: ts,
      ),
      Task(
        id: 'e',
        title: 'Sub Apel',
        type: TaskType.task,
        status: TaskStatus.done,
        parentTaskId: 'c',
        dueAt: DateTime(day1.year, day1.month, day1.day, 13),
        createdAt: ts,
        updatedAt: ts,
      ),
      // Sub-tugas yang induknya tidak ada pada hari itu (cadangan).
      Task(
        id: 'f',
        title: 'Sub Tanpa Induk',
        type: TaskType.task,
        parentTaskId: 'ghost',
        dueAt: DateTime(day1.year, day1.month, day1.day, 9),
        createdAt: ts,
        updatedAt: ts,
      ),
    ];

    taskRepository = MockTaskRepository();
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
    when(() => taskRepository.getReminders(any())).thenAnswer((_) async => []);
    when(() => taskRepository.getRecurrence(any())).thenAnswer((_) async => null);
    when(() => taskRepository.restoreTasks(any())).thenAnswer((_) async {});

    getIt.unregister<TaskRepository>();
    getIt.registerSingleton<TaskRepository>(taskRepository);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  Future<void> pumpCalendar(
    WidgetTester tester, {
    Size physicalSize = const Size(1200, 2400),
  }) async {
    AppRouter.router.go('/calendar');

    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();
  }

  Finder dayCell(DateTime date) => find.byWidgetPredicate(
        (widget) => widget is CalendarDayCell && widget.day.date == date,
      );

  /// Kartu agenda yang memuat judul [title].
  Finder cardOf(String title) => find.ancestor(
        of: find.text(title),
        matching: find.byType(CalendarItemTile),
      );

  /// Baris panah di dasar kartu [title] (hanya ada pada kartu bersub-tugas).
  Finder arrowOf(String title) => find.descendant(
        of: cardOf(title),
        matching: find.byIcon(AppIcons.expand),
      );

  Icon arrowIcon(WidgetTester tester, String title) =>
      tester.widget<Icon>(arrowOf(title));

  testWidgets('grid menampilkan bulan berjalan dengan hari ini terpilih',
      (tester) async {
    await pumpCalendar(tester);

    expect(find.text(AppStrings.screenCalendar), findsOneWidget);
    expect(find.text(IdDate.monthYear(today)), findsOneWidget);
    expect(find.text(AppStrings.calendarTodaySection), findsOneWidget);
    expect(tester.widget<CalendarDayCell>(dayCell(today)).isSelected, isTrue);
  });

  testWidgets('tombol bulan sebelumnya dan berikutnya menggeser judul bulan',
      (tester) async {
    await pumpCalendar(tester);

    await tester.tap(find.byIcon(AppIcons.chevronLeft));
    await tester.pumpAndSettle();
    expect(
      find.text(IdDate.monthYear(DateTime(today.year, today.month - 1, 1))),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(AppIcons.chevronRight));
    await tester.pumpAndSettle();
    expect(find.text(IdDate.monthYear(today)), findsOneWidget);
  });

  testWidgets('hari yang punya item diberi titik warna', (tester) async {
    await pumpCalendar(tester);

    expect(tester.widget<CalendarDayCell>(dayCell(day1)).categories, isNotEmpty);
    expect(tester.widget<CalendarDayCell>(dayCell(day2)).categories, isNotEmpty);
    expect(
      tester
          .widget<CalendarDayCell>(dayCell(DateTime(today.year, today.month, 10)))
          .categories,
      isEmpty,
    );
  });

  testWidgets('ketuk tanggal lain mengubah judul seksi dan daftar agenda',
      (tester) async {
    await pumpCalendar(tester);

    await tester.tap(dayCell(day2));
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.calendarDateSection(IdDate.dayMonth(day2))),
      findsOneWidget,
    );
    expect(find.text(AppStrings.calendarTodaySection), findsNothing);
    expect(find.text('Item Dua'), findsOneWidget);
    expect(find.text('Item Satu'), findsNothing);
  });

  testWidgets('ketuk tanggal hari ini kembali ke judul "Tugas Hari Ini"',
      (tester) async {
    await pumpCalendar(tester);

    await tester.tap(dayCell(day2));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.calendarTodaySection), findsNothing);

    await tester.tap(dayCell(today));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.calendarTodaySection), findsOneWidget);
  });

  testWidgets('item selesai tetap tampil bercoret dan bisa dibuka',
      (tester) async {
    await pumpCalendar(tester);

    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    expect(find.text('Selesai Satu'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Selesai Satu')).style?.decoration,
      TextDecoration.lineThrough,
    );
    expect(
      tester.widget<Text>(find.text('Item Satu')).style?.decoration,
      isNot(TextDecoration.lineThrough),
    );

    // Masih bisa dibuka menuju layar detail.
    await tester.tap(find.text('Selesai Satu'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.detailTask), findsOneWidget);

    AppRouter.router.pop();
    await tester.pumpAndSettle();
  });

  testWidgets('ketuk item membuka layar detail', (tester) async {
    await pumpCalendar(tester);

    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Item Satu'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.detailTask), findsOneWidget);

    AppRouter.router.pop();
    await tester.pumpAndSettle();
  });

  testWidgets('tombol tambah membuka form dengan tanggal terpilih terisi',
      (tester) async {
    await pumpCalendar(tester);

    await tester.tap(dayCell(day2));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CalendarAddButton));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.newItem), findsOneWidget);
    expect(find.textContaining(IdDate.full(day2)), findsOneWidget);
    // Tanpa autofocus: keyboard tidak langsung terbuka dari pintu masuk
    // Kalender.
    expect(tester.testTextInput.isVisible, isFalse);

    AppRouter.router.pop();
    await tester.pumpAndSettle();
  });

  testWidgets('tata letak tidak meluap pada layar sempit (320 dp)',
      (tester) async {
    // 960 px / 3 = 320 dp, sekalipun sel grid lebih sempit dari 44 dp.
    await pumpCalendar(tester, physicalSize: const Size(960, 1920));

    expect(find.byType(CalendarMonthGrid), findsOneWidget);
    expect(tester.widget<CalendarDayCell>(dayCell(day1)).categories, isNotEmpty);
    expect(find.text(AppStrings.calendarTodaySection), findsOneWidget);
  });

  testWidgets('daftar sub-tugas menyatu di kartu induk dan hanya tampil saat '
      'panah ditekan', (tester) async {
    // Viewport lebih tinggi: baris panah kartu terbawah tidak tertutup bilah
    // navigasi bawah saat diketuk.
    await pumpCalendar(tester, physicalSize: const Size(1200, 3000));
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    // Hanya tiga kartu: induk, sub-tugas cadangan, dan item selesai.
    expect(find.byType(CalendarItemTile), findsNWidgets(3));

    // Bawaan: tertutup. Hanya kartu bersub-tugas yang punya baris panah.
    expect(find.text('Sub Zebra'), findsNothing);
    expect(find.byIcon(AppIcons.expand), findsOneWidget);
    expect(
      arrowIcon(tester, 'Selesai Satu').semanticLabel,
      AppStrings.showSubtasks,
    );

    await tester.tap(arrowOf('Selesai Satu'));
    await tester.pumpAndSettle();

    expect(
      arrowIcon(tester, 'Selesai Satu').semanticLabel,
      AppStrings.hideSubtasks,
    );
    for (final title in ['Sub Zebra', 'Sub Apel']) {
      // Tetap di dalam kartu induk, bukan kartu terpisah.
      expect(
        find.ancestor(of: find.text(title), matching: cardOf('Selesai Satu')),
        findsOneWidget,
      );
    }
    expect(find.byType(CalendarItemTile), findsNWidgets(3));

    await tester.tap(arrowOf('Selesai Satu'));
    await tester.pumpAndSettle();

    expect(find.text('Sub Zebra'), findsNothing);
    expect(
      arrowIcon(tester, 'Selesai Satu').semanticLabel,
      AppStrings.showSubtasks,
    );
  });

  testWidgets('ketuk baris panah hanya membuka daftar, bukan detail induk',
      (tester) async {
    await pumpCalendar(tester, physicalSize: const Size(1200, 3000));
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    await tester.tap(arrowOf('Selesai Satu'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.detailTask), findsNothing);
    expect(find.text('Sub Zebra'), findsOneWidget);
  });

  testWidgets('ketuk kartu bersub-tugas membuka detail induk', (tester) async {
    await pumpCalendar(tester, physicalSize: const Size(1200, 3000));
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Selesai Satu'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.detailTask), findsOneWidget);
    // Dua baris sub-tugas di layar detail = detail induknya.
    expect(find.byType(CheckboxListTile), findsNWidgets(2));

    AppRouter.router.pop();
    await tester.pumpAndSettle();

    // Kembali ke Kalender: daftar sub-tugas tetap tertutup.
    expect(find.text('Sub Zebra'), findsNothing);
  });

  testWidgets('sub-tugas tanpa induk di hari itu tetap jadi kartu sendiri',
      (tester) async {
    await pumpCalendar(tester);
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    final tile = tester.widget<ListItemTile>(
      find.ancestor(
        of: find.text('Sub Tanpa Induk'),
        matching: find.byType(ListItemTile),
      ),
    );
    expect(tile.title, 'Sub Tanpa Induk');
    // Tanpa daftar sub-tugas, tanpa baris panah, dan subjudulnya tipe saja.
    expect(tile.footer, isNull);
    expect(tile.bottomBar, isNull);
    expect(tile.subtitle, AppStrings.formTitleTask);
  });

  testWidgets('kartu tanpa sub-tugas tidak punya baris panah', (tester) async {
    await pumpCalendar(tester);
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    for (final title in ['Item Satu', 'Sub Tanpa Induk']) {
      expect(arrowOf(title), findsNothing);
    }
    expect(find.byIcon(AppIcons.expand), findsOneWidget);
  });

  testWidgets('tinggi kartu bersub-tugas = kartu biasa + baris panah',
      (tester) async {
    // Viewport lebih tinggi: baris panah kartu terbawah tidak tertutup bilah
    // navigasi bawah saat diketuk.
    await pumpCalendar(tester, physicalSize: const Size(1200, 3000));
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    final plain = tester.getSize(cardOf('Item Satu')).height;
    final otherPlain = tester.getSize(cardOf('Sub Tanpa Induk')).height;
    final withSubtasks = tester.getSize(cardOf('Selesai Satu')).height;

    // Kartu tanpa sub-tugas tingginya tidak berubah (tanpa baris panah).
    expect(otherPlain, moreOrLessEquals(plain, epsilon: 0.5));
    // Kartu bersub-tugas yang tertutup menambah tepat satu baris panah.
    expect(
      withSubtasks,
      moreOrLessEquals(plain + AppSizes.minTouchTarget, epsilon: 0.5),
    );

    await tester.tap(arrowOf('Selesai Satu'));
    await tester.pumpAndSettle();

    // Saat terbuka, daftar sub-tugas menambah tinggi kartunya.
    expect(
      tester.getSize(cardOf('Selesai Satu')).height,
      greaterThan(withSubtasks),
    );
  });

  testWidgets('subjudul kartu meringkas sub-tugas yang sudah selesai',
      (tester) async {
    await pumpCalendar(tester);
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.cardSubtasksSummary(AppStrings.formTitleTask, 1, 2)),
      findsOneWidget,
    );
    expect(find.text('Tugas · 1/2 subtugas'), findsOneWidget);
  });

  testWidgets('status buka kartu bertahan saat ganti tanggal lalu kembali',
      (tester) async {
    await pumpCalendar(tester, physicalSize: const Size(1200, 3000));
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    await tester.tap(arrowOf('Selesai Satu'));
    await tester.pumpAndSettle();
    expect(find.text('Sub Zebra'), findsOneWidget);

    await tester.tap(dayCell(day2));
    await tester.pumpAndSettle();
    expect(find.text('Item Dua'), findsOneWidget);
    expect(find.text('Sub Zebra'), findsNothing);

    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    expect(find.text('Sub Zebra'), findsOneWidget);
    expect(
      arrowIcon(tester, 'Selesai Satu').semanticLabel,
      AppStrings.hideSubtasks,
    );
  });

  testWidgets('urutan sub-tugas mengikuti layar detail dan yang selesai '
      'bercoret', (tester) async {
    await pumpCalendar(tester, physicalSize: const Size(1200, 3000));
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    await tester.tap(arrowOf('Selesai Satu'));
    await tester.pumpAndSettle();

    // Urutan data (Zebra lebih dulu), bukan urutan judul.
    expect(
      tester.getTopLeft(find.text('Sub Zebra')).dy,
      lessThan(tester.getTopLeft(find.text('Sub Apel')).dy),
    );

    expect(
      tester.widget<Text>(find.text('Sub Apel')).style?.decoration,
      TextDecoration.lineThrough,
    );
    expect(
      tester.widget<Text>(find.text('Sub Zebra')).style?.decoration,
      isNot(TextDecoration.lineThrough),
    );
    expect(find.byIcon(AppIcons.checkCircle), findsOneWidget);
    expect(find.byIcon(AppIcons.circle), findsOneWidget);
  });

  testWidgets('ketuk sub-tugas di dalam kartu membuka detail induk',
      (tester) async {
    // Viewport lebih tinggi: baris sub-tugas kartu terakhir tidak tertutup
    // bilah navigasi bawah saat diketuk.
    await pumpCalendar(tester, physicalSize: const Size(1200, 3000));
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    await tester.tap(arrowOf('Selesai Satu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sub Zebra'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.detailTask), findsOneWidget);
    // Dua baris sub-tugas di layar detail = detail induknya.
    expect(find.byType(CheckboxListTile), findsNWidgets(2));

    AppRouter.router.pop();
    await tester.pumpAndSettle();
  });

  testWidgets('jumlah titik tidak berubah oleh penggabungan sub-tugas',
      (tester) async {
    await pumpCalendar(tester);

    // Hari 1 punya induk + sub-tugas bertipe sama: tetap satu titik.
    expect(
      tester.widget<CalendarDayCell>(dayCell(day1)).categories,
      [TaskCategory.task],
    );
    expect(
      tester.widget<CalendarDayCell>(dayCell(day2)).categories,
      [TaskCategory.task],
    );
  });

  testWidgets('keadaan kosong agenda rata tengah: judul dan deskripsi sejajar',
      (tester) async {
    await pumpCalendar(tester);
    await tester.tap(dayCell(DateTime(today.year, today.month, 10)));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noItemsOnDay), findsOneWidget);
    expect(find.text(AppStrings.noItemsOnDayDescription), findsOneWidget);

    final gridCenter =
        tester.getRect(find.byType(CalendarMonthGrid)).center.dx;
    expect(tester.getRect(find.text(AppStrings.noItemsOnDay)).center.dx,
        gridCenter);
    expect(
      tester.getRect(find.text(AppStrings.noItemsOnDayDescription)).center.dx,
      gridCenter,
    );
  });

  /// [count] item berjam pada hari ke-1, untuk menguji agenda panjang yang
  /// bergulir.
  List<Task> manyTasks(int count) => [
        for (var i = 1; i <= count; i++)
          Task(
            id: 'm$i',
            title: 'Agenda $i',
            type: TaskType.task,
            dueAt: DateTime(day1.year, day1.month, day1.day, 6 + i),
            createdAt: ts,
            updatedAt: ts,
          ),
      ];

  testWidgets('grid bulan, judul seksi, dan tombol tambah tetap saat agenda '
      'digulir', (tester) async {
    when(() => taskRepository.watchAllTasks())
        .thenAnswer((_) => Stream.value(manyTasks(15)));

    await pumpCalendar(tester);
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();
    expect(find.text('Agenda 1'), findsOneWidget);

    final gridTop = tester.getTopLeft(find.byType(CalendarMonthGrid)).dy;
    final titleTop = tester.getTopLeft(find.text(AppStrings.screenCalendar)).dy;
    final sectionTop = tester.getTopLeft(find.byType(SectionHeader)).dy;
    final addBottom =
        tester.getBottomLeft(find.byType(CalendarAddButton)).dy;
    final firstCardTop = tester.getTopLeft(cardOf('Agenda 1')).dy;

    await tester.drag(find.byType(Scrollable), const Offset(0, -300));
    await tester.pumpAndSettle();

    // Daftar agenda ikut bergulir...
    expect(
      tester.getTopLeft(cardOf('Agenda 1')).dy,
      lessThan(firstCardTop - 200),
    );
    // ...tetapi grid bulan (beserta nama bulan), judul seksi, dan tombol
    // tambah tetap di tempatnya.
    expect(tester.getTopLeft(find.byType(CalendarMonthGrid)).dy, gridTop);
    expect(find.text(IdDate.monthYear(today)), findsOneWidget);
    expect(tester.getTopLeft(find.text(AppStrings.screenCalendar)).dy, titleTop);
    expect(tester.getTopLeft(find.byType(SectionHeader)).dy, sectionTop);
    expect(tester.getBottomLeft(find.byType(CalendarAddButton)).dy, addBottom);
  });

  testWidgets('kartu agenda terakhir tidak tertutup bilah navigasi bawah',
      (tester) async {
    when(() => taskRepository.watchAllTasks())
        .thenAnswer((_) => Stream.value(manyTasks(15)));

    await pumpCalendar(tester);
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    // Gulir sampai dasar daftar agenda.
    await tester.drag(find.byType(Scrollable), const Offset(0, -3000));
    await tester.pumpAndSettle();

    final navTop = tester.getTopLeft(find.byType(AppBottomNav)).dy;
    expect(
      tester.getBottomLeft(cardOf('Agenda 15')).dy,
      lessThanOrEqualTo(navTop),
    );
  });

  testWidgets('layar pendek (320 x 640 dp): agenda panjang tidak meluap',
      (tester) async {
    when(() => taskRepository.watchAllTasks())
        .thenAnswer((_) => Stream.value(manyTasks(15)));

    await pumpCalendar(tester, physicalSize: const Size(960, 1920));
    expect(tester.takeException(), isNull);

    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Kartu terakhir tetap bisa dicapai dengan menggulir.
    await tester.drag(find.byType(Scrollable), const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Agenda 15'), findsOneWidget);
  });

  testWidgets('tugas seharian dari Kalender tampil "Sepanjang hari" di agenda',
      (tester) async {
    // Tugas seharian dari `?date=` tersimpan sebagai tanggal kalender UTC
    // (lihat `TaskDateUtils`).
    final allDay = Task(
      id: 'x',
      title: 'Tugas Seharian',
      type: TaskType.task,
      isAllDay: true,
      dueAt: DateTime.utc(day1.year, day1.month, day1.day),
      createdAt: ts,
      updatedAt: ts,
    );
    when(() => taskRepository.watchAllTasks())
        .thenAnswer((_) => Stream.value([allDay]));

    await pumpCalendar(tester);
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    final tile = tester.widget<ListItemTile>(
      find.ancestor(
        of: find.text('Tugas Seharian'),
        matching: find.byType(ListItemTile),
      ),
    );
    expect(tile.time, AppStrings.allDay);
    expect(find.text(AppStrings.allDay), findsOneWidget);
  });

  /// Kalender -> detail -> hapus (konfirmasi) sehingga snackbar "Urungkan"
  /// tampil di Kalender.
  Future<void> pumpToDeletedCalendar(WidgetTester tester) async {
    when(() => taskRepository.softDeleteTask('c'))
        .thenAnswer((_) async => ['c', 'd', 'e']);

    await pumpCalendar(tester);
    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Selesai Satu'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.detailTask), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.delete));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.deleteTaskTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.delete));
    await tester.pumpAndSettle();

    verify(() => taskRepository.softDeleteTask('c')).called(1);
    // Kembali ke Kalender dan muncul snackbar dengan aksi Urungkan.
    expect(find.text(AppStrings.screenCalendar), findsOneWidget);
    expect(find.text(AppStrings.taskDeleted), findsOneWidget);
  }

  testWidgets('hapus dari Kalender lalu Urungkan memulihkan induk dan '
      'sub-tugasnya', (tester) async {
    await pumpToDeletedCalendar(tester);

    await tester.tap(find.text(AppStrings.undo));
    await tester.pumpAndSettle();

    final restored = verify(() => taskRepository.restoreTasks(captureAny()))
        .captured
        .single as List<String>;
    expect(restored, ['c', 'd', 'e']);
  });

  testWidgets('snackbar Urungkan dari Kalender hilang setelah durasinya',
      (tester) async {
    await pumpToDeletedCalendar(tester);

    // Lewati durasi snackbar (6 detik) + animasi keluar.
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.taskDeleted), findsNothing);
    expect(find.text(AppStrings.undo), findsNothing);
    verifyNever(() => taskRepository.restoreTasks(any()));
  });

  // Butir 1: pintu masuk Kalender juga tidak boleh sempat menampilkan
  // "Item tidak ditemukan" selama penghapusan berjalan.
  testWidgets('hapus dari Kalender tidak sempat menampilkan "Item tidak '
      'ditemukan"', (tester) async {
    final stream = StreamController<List<Task>>.broadcast();
    final pendingDelete = Completer<List<String>>();
    addTearDown(stream.close);

    when(() => taskRepository.watchAllTasks())
        .thenAnswer((_) => stream.stream);
    when(() => taskRepository.softDeleteTask('c'))
        .thenAnswer((_) => pendingDelete.future);

    await pumpCalendar(tester);
    stream.add(tasks);
    await tester.pumpAndSettle();

    await tester.tap(dayCell(day1));
    await tester.pumpAndSettle();

    // Layar detail berlangganan aliran data sendiri; pancarkan ulang.
    await tester.tap(find.text('Selesai Satu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    stream.add(tasks);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.detailTask), findsOneWidget);

    // Konfirmasi hapus.
    await tester.tap(find.byIcon(AppIcons.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.delete));
    await tester.pumpAndSettle();

    // Baris hilang dari aliran data sebelum penghapusan selesai.
    stream.add(const []);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.taskNotFound), findsNothing);
    expect(find.text(AppStrings.detailTask), findsOneWidget);

    // Penghapusan selesai: kembali ke Kalender dengan snackbar Urungkan.
    pendingDelete.complete(['c', 'd', 'e']);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.screenCalendar), findsOneWidget);
    expect(find.text(AppStrings.detailTask), findsNothing);
    expect(find.text(AppStrings.taskDeleted), findsOneWidget);

    await tester.tap(find.text(AppStrings.undo));
    await tester.pumpAndSettle();

    final restored = verify(() => taskRepository.restoreTasks(captureAny()))
        .captured
        .single as List<String>;
    expect(restored, ['c', 'd', 'e']);
  });
}
