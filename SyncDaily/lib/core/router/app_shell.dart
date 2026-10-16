import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_daily/core/widgets/app_bottom_nav.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/chat')) {
      currentIndex = 1;
    } else if (location.startsWith('/notes')) {
      currentIndex = 2;
    } else if (location.startsWith('/calendar')) {
      currentIndex = 3;
    } else {
      currentIndex = 0;
    }

    return Scaffold(
      extendBody: true,
      body: child,
      // Tombol sementara untuk membuka galeri komponen. Hanya ada saat debug
      // (kDebugMode konstanta -> dihapus saat build rilis), jadi tidak muncul
      // di build produksi.
      //
      // Ditaruh kecil di kiri bawah, tepat di atas navigasi bawah: sudut kanan
      // atas dipakai ikon header (ganti tampilan Catatan, lonceng Beranda, panah
      // bulan Kalender), sedangkan bawah-tengah dipakai tombol + ungu pada
      // navigasi. Tombol + ungu Catatan/Kalender ada di dalam isi layar
      // (bukan di sini), jadi tidak tertutup.
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              heroTag: 'debug-gallery-fab',
              tooltip: 'Galeri Komponen',
              onPressed: () => context.go('/debug/components'),
              child: const Icon(Icons.widgets_outlined),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/chat');
              break;
            case 2:
              context.go('/notes');
              break;
            case 3:
              context.go('/calendar');
              break;
            case 4:
              // Pintu masuk sementara (F4a). F7 menggantinya dengan panel
              // "Buat baru".
              context.push('/tasks/new');
              break;
          }
        },
      ),
    );
  }
}
