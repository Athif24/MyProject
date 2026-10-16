import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/router/app_router.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_theme.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/core/widgets/app_avatar.dart';
import 'package:sync_daily/core/widgets/app_bottom_nav.dart';
import 'package:sync_daily/core/widgets/app_icon_button.dart';
import 'package:sync_daily/core/widgets/empty_state.dart';
import 'package:sync_daily/core/widgets/list_item_tile.dart';
import 'package:sync_daily/core/widgets/section_header.dart';
import 'package:sync_daily/core/widgets/unread_badge.dart';
import 'package:sync_daily/core/widgets/unread_dot.dart';
import 'package:sync_daily/main.dart';

import 'helpers/reset_app_state.dart';
import 'helpers/test_dependencies.dart';
import 'helpers/test_repositories.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  late AppDatabase db;

  setUpAll(() async {
    await IdDate.ensureInitialized();
  });

  setUp(() async {
    await resetGlobalTestState();
    db = await setUpInMemoryDependencies();
    registerMockRepositories();
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  testWidgets('AppAvatar menampilkan inisial dari nama', (tester) async {
    await tester.pumpWidget(_wrap(const AppAvatar(name: 'Ayu Lestari')));
    await tester.pump();
    expect(find.text('AL'), findsOneWidget);
  });

  testWidgets('AppAvatar nama satu kata memakai dua huruf', (tester) async {
    await tester.pumpWidget(_wrap(const AppAvatar(name: 'Dimas')));
    await tester.pump();
    expect(find.text('DI'), findsOneWidget);
  });

  testWidgets('AppAvatar grup menampilkan ikon', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppAvatar(name: 'Tim Desain', isGroup: true)),
    );
    await tester.pump();
    expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
  });

  testWidgets('UnreadBadge menyembunyikan diri saat nol', (tester) async {
    await tester.pumpWidget(_wrap(const UnreadBadge(count: 0)));
    await tester.pump();
    expect(find.byType(UnreadBadge), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('UnreadBadge menampilkan angka dan batas maksimum',
      (tester) async {
    await tester.pumpWidget(_wrap(const UnreadBadge(count: 5)));
    await tester.pump();
    expect(find.text('5'), findsOneWidget);

    await tester.pumpWidget(_wrap(const UnreadBadge(count: 120)));
    await tester.pump();
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('UnreadDot tampil', (tester) async {
    await tester.pumpWidget(_wrap(const UnreadDot()));
    await tester.pump();
    expect(find.byType(UnreadDot), findsOneWidget);
  });

  testWidgets('AppIconButton memicu onTap dan punya label semantik',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        AppIconButton(
          icon: Icons.notifications_outlined,
          semanticLabel: 'Notifikasi',
          onTap: () => tapped = true,
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('Notifikasi'), findsOneWidget);

    await tester.tap(find.byType(AppIconButton));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('SectionHeader menampilkan judul dan trailing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SectionHeader(
          title: 'Projects',
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Projects'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('EmptyState rata tengah: judul dan deskripsi sejajar',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Ditulis di dalam Column berperataan kiri seperti pemakaian di layar
    // (Kalender, Beranda, daftar): EmptyState sendiri yang memusatkan teksnya.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [EmptyState(title: 'A', description: 'B')],
          ),
        ),
      ),
    );
    await tester.pump();

    final titleRect = tester.getRect(find.text('A'));
    final descriptionRect = tester.getRect(find.text('B'));
    final screenCenter =
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;

    expect(titleRect.center.dx, screenCenter);
    expect(descriptionRect.center.dx, screenCenter);
  });

  testWidgets('ListItemTile menampilkan judul, subjudul, dan waktu',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 360,
          child: ListItemTile(
            avatarName: 'Ayu Lestari',
            title: 'Ayu Lestari',
            subtitle: 'Besok lanjut desainnya',
            time: '11.20',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Ayu Lestari'), findsOneWidget);
    expect(find.text('Besok lanjut desainnya'), findsOneWidget);
    expect(find.text('11.20'), findsOneWidget);
    expect(find.byType(UnreadBadge), findsNothing);
    expect(find.byType(UnreadDot), findsNothing);
  });

  testWidgets('ListItemTile menampilkan badge saat ada jumlah belum dibaca',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 360,
          child: ListItemTile(
            icon: Icons.alarm_outlined,
            title: 'Pengingat',
            unreadCount: 4,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(UnreadBadge), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.byType(UnreadDot), findsNothing);
  });

  testWidgets('ListItemTile menampilkan titik saat ditandai belum dibaca',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 360,
          child: ListItemTile(
            icon: Icons.flag_outlined,
            title: 'Milestone',
            isUnread: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(UnreadDot), findsOneWidget);
    expect(find.byType(UnreadBadge), findsNothing);
  });

  testWidgets('Bottom nav terbuka memakai latar ink pada tombol +',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppBottomNav(
          currentIndex: 0,
          isOpen: true,
          onTap: (_) {},
        ),
      ),
    );
    await tester.pump();

    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppColors.ink);
    expect(decoration.gradient, isNull);
  });

  testWidgets('Galeri komponen dapat dibuka lewat rute debug', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();

    AppRouter.router.go('/debug/components');
    await tester.pumpAndSettle();

    expect(find.text('Galeri Komponen'), findsOneWidget);
  });

  testWidgets('Galeri dibuka lewat tombol debug lalu kembali tanpa error',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SyncDailyApp());
    // Router global bersifat singleton; normalkan ke Beranda dulu.
    AppRouter.router.go('/home');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.widgets_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Galeri Komponen'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Galeri Komponen'), findsNothing);
  });
}
