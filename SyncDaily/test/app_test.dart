import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/router/app_router.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/utils/greeting.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/core/widgets/app_add_button.dart';
import 'package:sync_daily/core/widgets/app_bottom_nav.dart';
import 'package:sync_daily/core/widgets/app_icon_button.dart';
import 'package:sync_daily/features/calendar/presentation/widgets/calendar_add_button.dart';
import 'package:sync_daily/main.dart';

import 'helpers/test_dependencies.dart';
import 'helpers/test_repositories.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    await IdDate.ensureInitialized();
  });

  setUp(() async {
    db = await setUpInMemoryDependencies();
    registerMockRepositories();
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  testWidgets('App membangun dan menampilkan layar Beranda', (tester) async {
    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.text(Greeting.forTime(DateTime.now())), findsOneWidget);
  });

  testWidgets('Bottom nav dapat berpindah antar tab', (tester) async {
    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();
    expect(find.text('Pesan'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.note_alt_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Catatan'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Kalender'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text(Greeting.forTime(DateTime.now())), findsOneWidget);
  });

  testWidgets('Tombol + membuka form buat baru', (tester) async {
    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.add));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.newItem), findsOneWidget);

    // Router bersifat global antar tes: tutup form agar tes berikutnya mulai
    // dari Beranda.
    AppRouter.router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('Bottom nav tidak overflow pada layar sempit 320dp',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('Tombol galeri debug di kiri bawah tidak menutupi ikon header '
      'maupun tombol +', (tester) async {
    const width = 400.0;
    tester.view.physicalSize = const Size(width * 3, 800 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();

    final fab = tester.getRect(find.byType(FloatingActionButton));
    final nav = tester.getRect(find.byType(AppBottomNav));

    // Kiri bawah, tepat di atas navigasi bawah.
    expect(fab.left, lessThan(width / 2));
    expect(fab.right, lessThanOrEqualTo(width / 2));
    expect(fab.bottom, lessThanOrEqualTo(nav.top));

    // Tombol + ungu pada navigasi bawah juga tidak tertutup.
    expect(
      fab.overlaps(
        tester.getRect(
          find.descendant(
            of: find.byType(AppBottomNav),
            matching: find.byIcon(AppIcons.add),
          ),
        ),
      ),
      isFalse,
    );

    // Tiap tab shell: tidak ada ikon header atau tombol + yang tertutup FAB
    // (lonceng Beranda, ganti tampilan Catatan, panah bulan & + Kalender).
    for (final tab in const [
      Icons.home_outlined,
      Icons.chat_bubble_outline,
      Icons.note_alt_outlined,
      Icons.calendar_today_outlined,
    ]) {
      await tester.tap(find.byIcon(tab));
      await tester.pumpAndSettle();

      final targets = find.byWidgetPredicate(
        (widget) =>
            widget is AppIconButton ||
            widget is AppAddButton ||
            widget is CalendarAddButton,
      );
      for (final target in targets.evaluate()) {
        expect(
          fab.overlaps(
            tester.getRect(find.byElementPredicate((e) => e == target)),
          ),
          isFalse,
          reason: 'FAB menutupi ikon/tombol pada tab $tab',
        );
      }
    }
  });
}
