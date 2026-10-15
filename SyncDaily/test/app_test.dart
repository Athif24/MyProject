import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/router/app_router.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/utils/greeting.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/core/widgets/app_bottom_nav.dart';
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
}
