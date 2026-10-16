import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/router/app_router.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/features/home/presentation/widgets/stat_card.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_summary.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/main.dart';

import '../../../helpers/reset_app_state.dart';
import '../../../helpers/test_dependencies.dart';
import '../../../helpers/test_repositories.dart';

/// Tes widget alur daftar -> detail -> hapus -> Urungkan.
///
/// Memakai repository tiruan (bukan Drift), mengikuti pola tes widget lain di
/// proyek ini: query stream Drift meninggalkan timer saat dibatalkan di dalam
/// `flutter_test` (lihat catatan di `test/helpers/test_repositories.dart`).
void main() {
  late AppDatabase db;
  late MockTaskRepository taskRepository;

  setUpAll(() async {
    await IdDate.ensureInitialized();
    registerFallbackValue(<String>[]);
  });

  setUp(() async {
    await resetGlobalTestState();
    db = await setUpInMemoryDependencies();
    registerMockRepositories();

    final task = Task(
      id: 't1',
      title: 'Tugas hari ini',
      type: TaskType.task,
      dueAt: DateTime.now(),
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

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
          today: 1,
          schedule: 0,
          allTasks: 1,
          projectsOwned: 0,
          projectsReceived: 0,
        ),
      ),
    );
    when(() => taskRepository.watchAllTasks())
        .thenAnswer((_) => Stream.value([task]));
    when(() => taskRepository.softDeleteTask(any()))
        .thenAnswer((_) async => ['t1']);
    when(() => taskRepository.restoreTasks(any())).thenAnswer((_) async {});
    when(() => taskRepository.getReminders(any()))
        .thenAnswer((_) async => []);
    when(() => taskRepository.getRecurrence(any()))
        .thenAnswer((_) async => null);

    getIt.unregister<TaskRepository>();
    getIt.registerSingleton<TaskRepository>(taskRepository);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  /// Beranda -> daftar -> detail -> hapus (konfirmasi) sehingga snackbar
  /// "Urungkan" tampil di daftar. Router global direset dulu agar tiap tes
  /// mulai dari Beranda.
  Future<void> pumpToDeletedList(WidgetTester tester) async {
    AppRouter.router.go('/home');

    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();

    // Ketuk kartu statistik "Hari ini" -> daftar tugas.
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is StatCard && widget.label == AppStrings.statToday,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tugas hari ini'), findsOneWidget);

    // Ketuk item -> detail.
    await tester.tap(find.text('Tugas hari ini'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.detailTask), findsOneWidget);

    // Hapus: dialog konfirmasi lalu konfirmasi.
    await tester.tap(find.byIcon(AppIcons.delete));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.deleteTaskTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.delete));
    await tester.pumpAndSettle();

    verify(() => taskRepository.softDeleteTask('t1')).called(1);
    // Kembali ke daftar dan muncul snackbar dengan aksi Urungkan.
    expect(find.text(AppStrings.taskDeleted), findsOneWidget);
  }

  testWidgets('judul daftar memakai huruf kapital di awal tiap kata',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AppRouter.router.go('/home');
    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is StatCard && widget.label == AppStrings.statToday,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hari Ini'), findsOneWidget);

    AppRouter.router.go('/home');
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is StatCard && widget.label == AppStrings.statAllTasks,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Semua Tugas'), findsOneWidget);
  });

  testWidgets('keadaan kosong daftar: judul dan deskripsi rata tengah',
      (tester) async {
    when(() => taskRepository.watchAllTasks())
        .thenAnswer((_) => Stream.value(const <Task>[]));

    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AppRouter.router.go('/home');
    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is StatCard && widget.label == AppStrings.statToday,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noTasksToday), findsOneWidget);
    final titleRect = tester.getRect(find.text(AppStrings.noTasksToday));
    final descriptionRect =
        tester.getRect(find.text(AppStrings.noTasksTodayDescription));
    final screenCenter =
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;

    expect(titleRect.center.dx, descriptionRect.center.dx);
    expect(titleRect.center.dx, screenCenter);
  });

  testWidgets('ketuk kartu, buka detail, hapus, urungkan', (tester) async {
    await pumpToDeletedList(tester);

    await tester.tap(find.text(AppStrings.undo));
    await tester.pumpAndSettle();

    final restored = verify(() => taskRepository.restoreTasks(captureAny()))
        .captured
        .single as List<String>;
    expect(restored, ['t1']);
  });

  // Butir 1: setelah Hapus dikonfirmasi, layar detail tidak boleh sempat
  // menampilkan "Item tidak ditemukan" walau baris sudah hilang dari aliran
  // data sementara penghapusan masih berjalan.
  testWidgets('tidak ada "Item tidak ditemukan" selama proses hapus',
      (tester) async {
    final tasks = StreamController<List<Task>>.broadcast();
    final pendingDelete = Completer<List<String>>();
    addTearDown(tasks.close);

    final task = Task(
      id: 't1',
      title: 'Tugas hari ini',
      type: TaskType.task,
      dueAt: DateTime.now(),
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    when(() => taskRepository.watchAllTasks())
        .thenAnswer((_) => tasks.stream);
    when(() => taskRepository.softDeleteTask(any()))
        .thenAnswer((_) => pendingDelete.future);

    AppRouter.router.go('/home');

    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();

    // Daftar baru berlangganan aliran data setelah halaman dibuka, jadi data
    // dipancarkan sesudahnya (controller broadcast tidak menyimpan nilai
    // terakhir).
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is StatCard && widget.label == AppStrings.statToday,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    tasks.add([task]);
    await tester.pumpAndSettle();
    expect(find.text('Tugas hari ini'), findsOneWidget);

    // Layar detail juga berlangganan aliran data; pancarkan ulang.
    await tester.tap(find.text('Tugas hari ini'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    tasks.add([task]);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.detailTask), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.delete));
    await tester.pumpAndSettle();

    // Hapus masih berjalan (future belum selesai); baris hilang dari aliran
    // data lebih dulu.
    tasks.add(const []);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.taskNotFound), findsNothing);
    expect(find.text(AppStrings.detailTask), findsOneWidget);

    // Hapus selesai: halaman langsung kembali ke daftar + snackbar Urungkan.
    pendingDelete.complete(['t1']);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.detailTask), findsNothing);
    expect(find.text(AppStrings.taskDeleted), findsOneWidget);

    await tester.tap(find.text(AppStrings.undo));
    await tester.pumpAndSettle();

    // Snackbar membawa id yang terhapus.
    final restored = verify(() => taskRepository.restoreTasks(captureAny()))
        .captured
        .single as List<String>;
    expect(restored, ['t1']);
  });

  testWidgets('snackbar Urungkan hilang setelah durasinya', (tester) async {
    await pumpToDeletedList(tester);

    // Lewati durasi snackbar (6 detik) + animasi keluar.
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.taskDeleted), findsNothing);
    expect(find.text(AppStrings.undo), findsNothing);
    verifyNever(() => taskRepository.restoreTasks(any()));
  });

  testWidgets('Urungkan masih memulihkan item sebelum snackbar hilang',
      (tester) async {
    await pumpToDeletedList(tester);

    // Masih di dalam durasi tampil.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text(AppStrings.taskDeleted), findsOneWidget);
    expect(find.text(AppStrings.undo), findsOneWidget);

    await tester.tap(find.text(AppStrings.undo));
    await tester.pumpAndSettle();

    final restored = verify(() => taskRepository.restoreTasks(captureAny()))
        .captured
        .single as List<String>;
    expect(restored, ['t1']);
  });
}
