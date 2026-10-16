import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/router/app_router.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/core/widgets/app_bottom_nav.dart';
import 'package:sync_daily/core/widgets/app_chip.dart';
import 'package:sync_daily/core/widgets/app_new_item_panel.dart';
import 'package:sync_daily/main.dart';

import 'helpers/test_dependencies.dart';
import 'helpers/test_repositories.dart';

/// Nama keenam ubin panel, sesuai urutan tampil.
const List<String> tileLabels = [
  AppStrings.newPanelTask,
  AppStrings.newPanelEvent,
  AppStrings.newPanelReminder,
  AppStrings.newPanelMilestone,
  AppStrings.newPanelNote,
  AppStrings.newPanelProject,
];

/// Tes panel "Buat Baru" pada tombol + navigasi bawah.
///
/// Menguji pembukaan/penutupan (tombol +, ketuk latar, tombol kembali), rute
/// tiap ubin, ubin Proyek yang tidak aktif, tata letak pada 320 dp, serta bukti
/// piksel bahwa tidak ada area tak terlukis (hitam) saat panel dibuka, ditutup,
/// dan saat berpindah tab.
void main() {
  late AppDatabase db;
  final root = GlobalKey();

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

  Finder plusButton() => find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.byIcon(AppIcons.add),
      );

  Finder navItem(IconData icon) => find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.byIcon(icon),
      );

  /// Teks ubin di dalam panel (bukan teks lain di layar).
  Finder tile(String label) => find.descendant(
        of: find.byType(AppNewItemPanel),
        matching: find.text(label),
      );

  AppBottomNav nav(WidgetTester tester) =>
      tester.widget<AppBottomNav>(find.byType(AppBottomNav));

  /// Apakah chip tipe pada form tugas aktif untuk [label].
  bool isTypeChipActive(WidgetTester tester, String label) =>
      tester.widgetList<AppChip>(find.byType(AppChip)).any(
            (chip) => chip.label == label && chip.isActive,
          );

  /// Membuka aplikasi dari Beranda; [rootKey] dipakai tes piksel.
  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(400, 800),
    Key? rootKey,
  }) async {
    AppRouter.router.go('/home');
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const app = SyncDailyApp();
    await tester.pumpWidget(
      rootKey == null ? app : RepaintBoundary(key: rootKey, child: app),
    );
    await tester.pumpAndSettle();
  }

  /// Mengetuk + lalu memajukan animasi per frame, memeriksa luapan tiap frame.
  Future<void> openPanel(WidgetTester tester) async {
    await tester.tap(plusButton());
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        tester.takeException(),
        isNull,
        reason: 'luapan saat panel dibuka (frame $i)',
      );
    }
    expect(find.text(AppStrings.newPanelTitle), findsOneWidget);
  }

  /// Mengetuk + (saat panel terbuka menjadi x) lalu memajukan animasi.
  Future<void> closePanel(WidgetTester tester) async {
    await tester.tap(plusButton());
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        tester.takeException(),
        isNull,
        reason: 'luapan saat panel ditutup (frame $i)',
      );
    }
    expect(find.text(AppStrings.newPanelTitle), findsNothing);
  }

  /// Membaca piksel (RGBA) frame yang terakhir dilukis.
  Future<Uint8List> renderPixels(WidgetTester tester, Key rootKey) async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(rootKey));
    late Uint8List bytes;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      bytes = data!.buffer.asUint8List();
      image.dispose();
    });
    return bytes;
  }

  /// Tidak ada piksel transparan: seluruh layar terlukis (tidak ada area hitam).
  void expectFullyPainted(
    Uint8List pixels, {
    required int width,
    required int height,
    required String label,
  }) {
    expect(pixels.length, width * height * 4);

    final unpainted = <String>[];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final alpha = pixels[(y * width + x) * 4 + 3];
        if (alpha != 255 && unpainted.length < 5) {
          unpainted.add('($x,$y) alpha=$alpha');
        }
      }
    }

    expect(
      unpainted,
      isEmpty,
      reason: 'ada area tak terlukis di $label; contoh: ${unpainted.join(', ')}',
    );
  }

  testWidgets('tombol + membuka panel dan berubah menjadi x', (tester) async {
    await pumpApp(tester);
    expect(find.text(AppStrings.newPanelTitle), findsNothing);

    await openPanel(tester);

    // Judul dan keenam ubin tampil.
    for (final label in tileLabels) {
      expect(tile(label), findsOneWidget, reason: 'ubin $label tidak tampil');
    }
    expect(tile(AppStrings.comingSoon), findsOneWidget);

    // Tombol + berputar 45 derajat dan berlatar ink, tetap di dalam navigasi.
    expect(nav(tester).isOpen, isTrue);
    expect(plusButton(), findsOneWidget);
    final rotation = tester.widget<AnimatedRotation>(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.byType(AnimatedRotation),
      ),
    );
    expect(rotation.turns, 0.125);
    final fab = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect((fab.decoration as BoxDecoration).color, AppColors.ink);
  });

  testWidgets('ketuk latar gelap menutup panel', (tester) async {
    await pumpApp(tester);
    await openPanel(tester);

    // Titik di bagian atas layar, jauh dari panel.
    await tester.tapAt(const Offset(200, 100));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.newPanelTitle), findsNothing);
    expect(nav(tester).isOpen, isFalse);
  });

  testWidgets('ketuk tombol x menutup panel', (tester) async {
    await pumpApp(tester);
    await openPanel(tester);

    await closePanel(tester);

    expect(nav(tester).isOpen, isFalse);
    expect(nav(tester).currentIndex, 0);
  });

  testWidgets('tombol kembali menutup panel, bukan keluar aplikasi',
      (tester) async {
    await pumpApp(tester);
    await openPanel(tester);

    // Jalur yang sama dengan tombol kembali Android pada aplikasi ber-Router:
    // RouterDelegate.popRoute() -> Navigator.maybePop().
    final handled = await AppRouter.router.routerDelegate.popRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue, reason: 'pop ditahan agar aplikasi tidak keluar');
    expect(find.text(AppStrings.newPanelTitle), findsNothing);
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(AppRouter.router.state.uri.toString(), '/home');
  });

  testWidgets('ubin Tugas membuka form tugas bertipe Tugas', (tester) async {
    await pumpApp(tester);
    await openPanel(tester);

    await tester.tap(tile(AppStrings.newPanelTask));
    await tester.pumpAndSettle();

    expect(AppRouter.router.state.uri.toString(), '/tasks/new?type=task');
    expect(find.text(AppStrings.newItem), findsOneWidget);
    expect(isTypeChipActive(tester, AppStrings.newPanelTask), isTrue);
    // Tanpa fokus otomatis: keyboard tidak muncul.
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('ubin Acara membuka form tugas bertipe Acara', (tester) async {
    await pumpApp(tester);
    await openPanel(tester);

    await tester.tap(tile(AppStrings.newPanelEvent));
    await tester.pumpAndSettle();

    expect(AppRouter.router.state.uri.toString(), '/tasks/new?type=event');
    expect(isTypeChipActive(tester, AppStrings.newPanelEvent), isTrue);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('ubin Pengingat membuka form tugas bertipe Pengingat',
      (tester) async {
    await pumpApp(tester);
    await openPanel(tester);

    await tester.tap(tile(AppStrings.newPanelReminder));
    await tester.pumpAndSettle();

    expect(AppRouter.router.state.uri.toString(), '/tasks/new?type=reminder');
    expect(isTypeChipActive(tester, AppStrings.newPanelReminder), isTrue);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('ubin Milestone membuka form tugas bertipe Milestone',
      (tester) async {
    await pumpApp(tester);
    await openPanel(tester);

    await tester.tap(tile(AppStrings.newPanelMilestone));
    await tester.pumpAndSettle();

    expect(AppRouter.router.state.uri.toString(), '/tasks/new?type=milestone');
    expect(isTypeChipActive(tester, AppStrings.newPanelMilestone), isTrue);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('ubin Catatan membuka form catatan baru', (tester) async {
    await pumpApp(tester);
    await openPanel(tester);

    await tester.tap(tile(AppStrings.newPanelNote));
    await tester.pumpAndSettle();

    expect(AppRouter.router.state.uri.toString(), '/notes/new');
    expect(find.text(AppStrings.noteNew), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('ubin Proyek tampil tidak aktif dan tidak menavigasi',
      (tester) async {
    await pumpApp(tester);
    await openPanel(tester);

    expect(tile(AppStrings.comingSoon), findsOneWidget);

    await tester.tap(tile(AppStrings.newPanelProject));
    await tester.pumpAndSettle();

    expect(AppRouter.router.state.uri.toString(), '/home');
    expect(find.text(AppStrings.newPanelTitle), findsOneWidget);
    expect(AppRouter.router.canPop(), isFalse);
  });

  testWidgets('panel tertutup setelah memilih ubin dan tetap tertutup saat '
      'kembali dari form', (tester) async {
    await pumpApp(tester);
    await openPanel(tester);

    await tester.tap(tile(AppStrings.newPanelTask));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.newPanelTitle), findsNothing);
    expect(find.text(AppStrings.newItem), findsOneWidget);

    AppRouter.router.pop();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.newPanelTitle), findsNothing);
    expect(nav(tester).isOpen, isFalse);
    expect(AppRouter.router.state.uri.toString(), '/home');
  });

  testWidgets('berpindah tab saat panel terbuka menutup panel', (tester) async {
    await pumpApp(tester);
    await openPanel(tester);

    await tester.tap(navItem(AppIcons.notes));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.newPanelTitle), findsNothing);
    expect(nav(tester).isOpen, isFalse);
    expect(nav(tester).currentIndex, 2);
  });

  testWidgets('tombol galeri debug disembunyikan selama panel terbuka',
      (tester) async {
    await pumpApp(tester);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await openPanel(tester);

    // Slot FAB digambar di atas isi body, jadi tombol galeri akan menutupi
    // ubin kiri bawah kalau tetap tampil.
    expect(
      find.byType(FloatingActionButton),
      findsNothing,
      reason: 'tombol galeri debug menutupi ubin panel',
    );

    await closePanel(tester);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('panel tidak meluap pada 320 x 640 dp', (tester) async {
    await pumpApp(tester, size: const Size(320, 640));
    await openPanel(tester);

    final navTop = tester.getRect(find.byType(AppBottomNav)).top;
    for (final label in tileLabels) {
      final rect = tester.getRect(tile(label));
      expect(rect.left, greaterThanOrEqualTo(0), reason: '$label keluar kiri');
      expect(rect.right, lessThanOrEqualTo(320), reason: '$label keluar kanan');
      expect(rect.top, greaterThanOrEqualTo(0), reason: '$label keluar atas');
      expect(
        rect.bottom,
        lessThanOrEqualTo(navTop),
        reason: '$label tertutup navigasi bawah',
      );
    }

    await closePanel(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('400 x 800: seluruh layar terlukis saat panel dibuka, ditutup, '
      'dan berpindah tab', (tester) async {
    const width = 400;
    const height = 800;
    await pumpApp(tester, rootKey: root);
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'Beranda',
    );

    await tester.tap(plusButton());
    await tester.pump(const Duration(milliseconds: 80));
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'panel dibuka (tengah animasi)',
    );
    await tester.pumpAndSettle();
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'panel terbuka',
    );

    await tester.tap(plusButton());
    await tester.pump(const Duration(milliseconds: 80));
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'panel ditutup (tengah animasi)',
    );
    await tester.pumpAndSettle();
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'panel tertutup',
    );

    await tester.tap(navItem(AppIcons.notes));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'Catatan',
    );

    await tester.tap(navItem(AppIcons.calendar));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'Kalender',
    );
  });

  testWidgets('320 x 640: seluruh layar terlukis saat panel dibuka, ditutup, '
      'dan berpindah tab', (tester) async {
    const width = 320;
    const height = 640;
    await pumpApp(tester, size: const Size(320, 640), rootKey: root);
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'Beranda',
    );

    await tester.tap(plusButton());
    await tester.pump(const Duration(milliseconds: 80));
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'panel dibuka (tengah animasi)',
    );
    await tester.pumpAndSettle();
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'panel terbuka',
    );

    await tester.tap(plusButton());
    await tester.pump(const Duration(milliseconds: 80));
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'panel ditutup (tengah animasi)',
    );
    await tester.pumpAndSettle();
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'panel tertutup',
    );

    await tester.tap(navItem(AppIcons.notes));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'Catatan',
    );

    await tester.tap(navItem(AppIcons.calendar));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    expectFullyPainted(
      await renderPixels(tester, root),
      width: width,
      height: height,
      label: 'Kalender',
    );
  });
}
