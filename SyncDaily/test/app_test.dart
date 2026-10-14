import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/widgets/app_bottom_nav.dart';
import 'package:sync_daily/main.dart';

void main() {
  testWidgets('App membangun dan menampilkan layar Beranda', (tester) async {
    await tester.pumpWidget(const SyncDailyApp());
    await tester.pump();

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('Bottom nav dapat berpindah antar tab', (tester) async {
    await tester.pumpWidget(const SyncDailyApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pump();
    expect(find.text('Pesan'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.note_alt_outlined));
    await tester.pump();
    expect(find.text('Catatan'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pump();
    expect(find.text('Kalender'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('Tombol + menampilkan snackbar sementara', (tester) async {
    await tester.pumpWidget(const SyncDailyApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('Buat baru - akan diimplementasikan'), findsOneWidget);
  });

  testWidgets('Bottom nav tidak overflow pada layar sempit 320dp',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SyncDailyApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });
}
