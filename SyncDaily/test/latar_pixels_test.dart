import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/router/app_router.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/core/widgets/app_bottom_nav.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/main.dart';

import 'helpers/fake_note_repository.dart';
import 'helpers/test_dependencies.dart';
import 'helpers/test_repositories.dart';

/// Ukuran layar uji (dp) dan lebar/tinggi gambar hasil render.
const int _width = 400;
const int _height = 800;

/// Bukti piksel: tidak ada area tak terlukis (yang tampil hitam di perangkat).
///
/// Pengukuran diambil pada frame **pertama** setelah data termuat, karena di
/// situlah tata letak lama menyusut dan menyisakan area gelap di bagian bawah.
/// Kalau hanya memakai `pumpAndSettle`, frame peralihan sudah terlewat.
///
/// Tes ini juga menjadi bukti untuk warna latar Scaffold: pada kode lama,
/// menjalankan tes ini dengan `scaffoldBackgroundColor` transparan **tetap
/// lulus** selama gradien halaman (`LayarLatar`) menutupi seluruh layar, jadi
/// warna itu memang tidak pernah terlihat.
void main() {
  late AppDatabase db;
  late FakeNoteRepository noteRepository;
  final root = GlobalKey();

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

  /// Membaca piksel (RGBA) frame yang terakhir dilukis.
  Future<Uint8List> renderPixels(WidgetTester tester) async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(root));
    late Uint8List bytes;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      bytes = data!.buffer.asUint8List();
      image.dispose();
    });
    return bytes;
  }

  Finder navItem(IconData icon) => find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.byIcon(icon),
      );

  /// Membuka aplikasi dari Beranda pada 400 x 800 dp.
  Future<void> pumpApp(WidgetTester tester) async {
    AppRouter.router.go('/home');
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RepaintBoundary(key: root, child: const SyncDailyApp()),
    );
    await tester.pumpAndSettle();
  }

  /// Mengetuk tab lalu menunggu sampai [loadedMarker] tampil, **tanpa**
  /// `pumpAndSettle`, dan mengembalikan piksel frame pertama itu.
  Future<Uint8List> firstLoadedFrame(
    WidgetTester tester, {
    required IconData tabIcon,
    required Finder loadedMarker,
  }) async {
    await tester.tap(navItem(tabIcon));
    var loaded = false;
    for (var i = 0; i < 8 && !loaded; i++) {
      await tester.pump();
      loaded = loadedMarker.evaluate().isNotEmpty;
    }
    expect(loaded, isTrue, reason: 'isi belum termuat setelah 8 frame');
    return renderPixels(tester);
  }

  void expectFullyPainted(Uint8List pixels, {required String label}) {
    expect(pixels.length, _width * _height * 4);

    final unpainted = <String>[];
    for (var y = 0; y < _height; y++) {
      for (var x = 0; x < _width; x++) {
        final alpha = pixels[(y * _width + x) * 4 + 3];
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

  /// Piksel di pita bawah yang dulu tampak hitam harus terlukis terang.
  void expectBrightBottom(Uint8List pixels, {required String label}) {
    const x = 200;
    const y = 700;
    final offset = (y * _width + x) * 4;
    final r = pixels[offset];
    final g = pixels[offset + 1];
    final b = pixels[offset + 2];
    final alpha = pixels[offset + 3];
    expect(alpha, 255, reason: 'pita bawah tak terlukis di $label');
    expect(
      (r + g + b) ~/ 3,
      greaterThan(200),
      reason: 'pita bawah gelap ($r,$g,$b) di $label',
    );
  }

  testWidgets('Beranda dan Pesan: seluruh layar terlukis penuh',
      (tester) async {
    await pumpApp(tester);
    expectFullyPainted(await renderPixels(tester), label: 'Beranda');

    await tester.tap(navItem(AppIcons.chat));
    await tester.pumpAndSettle();
    expectFullyPainted(await renderPixels(tester), label: 'Pesan');
  });

  testWidgets('Catatan kosong: frame pertama termuat sudah terlukis penuh',
      (tester) async {
    await pumpApp(tester);

    final pixels = await firstLoadedFrame(
      tester,
      tabIcon: AppIcons.notes,
      loadedMarker: find.text(AppStrings.noNotes),
    );
    expectFullyPainted(pixels, label: 'Catatan kosong (frame pertama termuat)');
    expectBrightBottom(pixels, label: 'Catatan kosong (frame pertama termuat)');

    await tester.pump();
    final stable = await renderPixels(tester);
    expectFullyPainted(stable, label: 'Catatan kosong (frame stabil)');
    expectBrightBottom(stable, label: 'Catatan kosong (frame stabil)');
  });

  testWidgets('Catatan terisi: frame pertama termuat sudah terlukis penuh',
      (tester) async {
    await noteRepository.upsertNote(
      Note(
        id: 'n1',
        title: 'Ide aplikasi',
        content: 'Isi catatan',
        color: NoteColor.pink,
        createdAt: DateTime.utc(2026, 10, 1, 8),
        updatedAt: DateTime.utc(2026, 10, 1, 8),
      ),
    );
    await pumpApp(tester);

    final pixels = await firstLoadedFrame(
      tester,
      tabIcon: AppIcons.notes,
      loadedMarker: find.text('Ide aplikasi'),
    );
    expectFullyPainted(pixels, label: 'Catatan terisi (frame pertama termuat)');
    expectBrightBottom(pixels, label: 'Catatan terisi (frame pertama termuat)');

    await tester.pump();
    expectFullyPainted(
      await renderPixels(tester),
      label: 'Catatan terisi (frame stabil)',
    );
  });

  testWidgets('Kalender: frame pertama termuat sudah terlukis penuh',
      (tester) async {
    await pumpApp(tester);

    final pixels = await firstLoadedFrame(
      tester,
      tabIcon: AppIcons.calendar,
      loadedMarker: find.text(AppStrings.noItemsOnDay),
    );
    expectFullyPainted(pixels, label: 'Kalender (frame pertama termuat)');

    await tester.pump();
    expectFullyPainted(
      await renderPixels(tester),
      label: 'Kalender (frame stabil)',
    );
  });
}
