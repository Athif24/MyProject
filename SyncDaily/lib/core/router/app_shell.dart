import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_daily/core/widgets/app_bottom_nav.dart';
import 'package:sync_daily/core/widgets/app_new_item_panel.dart';

/// Kerangka tab aplikasi: halaman aktif, navigasi bawah, dan panel "Buat Baru".
///
/// Panel hidup di sini (bukan sebagai rute) supaya navigasi bawah tetap
/// tergambar di atas latar gelap panel, sehingga tombol + dapat berputar
/// menjadi x dan tetap dapat diketuk. Konsekuensinya tombol kembali di Android
/// perlu dicegat lewat [PopScope] agar menutup panel, bukan keluar aplikasi.
class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isPanelOpen = false;

  void _openPanel() {
    if (_isPanelOpen) {
      return;
    }
    setState(() => _isPanelOpen = true);
  }

  void _closePanel() {
    if (!_isPanelOpen) {
      return;
    }
    setState(() => _isPanelOpen = false);
  }

  void _togglePanel() {
    if (_isPanelOpen) {
      _closePanel();
    } else {
      _openPanel();
    }
  }

  /// Ubin aktif: panel ditutup lebih dulu, lalu form dibuka. Karena panel
  /// tertutup sebelum rute berpindah, panel tetap tertutup saat pengguna
  /// kembali dari form.
  void _selectNewItem(AppNewItemKind kind) {
    _closePanel();
    switch (kind) {
      case AppNewItemKind.task:
        context.push('/tasks/new?type=task');
        break;
      case AppNewItemKind.event:
        context.push('/tasks/new?type=event');
        break;
      case AppNewItemKind.reminder:
        context.push('/tasks/new?type=reminder');
        break;
      case AppNewItemKind.milestone:
        context.push('/tasks/new?type=milestone');
        break;
      case AppNewItemKind.note:
        context.push('/notes/new');
        break;
      case AppNewItemKind.project:
        // Ubin nonaktif tidak pernah dikirim panel; jaga-jaga saja.
        break;
    }
  }

  void _goToTab(int index) {
    _closePanel();
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
    }
  }

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

    return PopScope(
      // Saat panel terbuka, tombol kembali menutup panel; saat tertutup,
      // perilaku kembali tidak berubah.
      canPop: !_isPanelOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _closePanel();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            AppNewItemPanel(
              isOpen: _isPanelOpen,
              onClose: _closePanel,
              onSelected: _selectNewItem,
            ),
          ],
        ),
        // Tombol sementara untuk membuka galeri komponen. Hanya ada saat debug
        // (kDebugMode konstanta -> dihapus saat build rilis), jadi tidak muncul
        // di build produksi.
        //
        // Ditaruh kecil di kiri bawah, tepat di atas navigasi bawah: sudut kanan
        // atas dipakai ikon header (ganti tampilan Catatan, lonceng Beranda, panah
        // bulan Kalender), sedangkan bawah-tengah dipakai tombol + ungu pada
        // navigasi. Tombol + ungu Catatan/Kalender ada di dalam isi layar
        // (bukan di sini), jadi tidak tertutup.
        //
        // Saat panel "Buat Baru" terbuka tombol ini disembunyikan: slot FAB
        // digambar di atas isi body sehingga posisinya (kiri bawah) akan
        // menutupi ubin panel.
        floatingActionButton: kDebugMode && !_isPanelOpen
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
          isOpen: _isPanelOpen,
          onTap: (index) {
            if (index == 4) {
              _togglePanel();
              return;
            }
            _goToTab(index);
          },
        ),
      ),
    );
  }
}
