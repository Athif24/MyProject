import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/router/app_router.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/features/calendar/presentation/widgets/calendar_add_button.dart';
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
}
