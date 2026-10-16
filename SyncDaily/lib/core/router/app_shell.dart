import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/state/calendar_selection.dart';
import 'package:sync_daily/core/utils/id_date.dart';
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

  /// Cermin tanggal terpilih di Kalender, dipakai ubin panel dari tab Kalender.
  final CalendarSelection _calendarSelection = getIt<CalendarSelection>();

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
  ///
  /// [date] hanya terisi bila panel dibuka dari tab Kalender (tanggal
  /// terpilih di sana, lihat [_panelDate]); catatan tidak pernah membawa
  /// tanggal.
  void _selectNewItem(AppNewItemKind kind, {DateTime? date}) {
    _closePanel();
    switch (kind) {
      case AppNewItemKind.task:
        context.push(_taskRoute('task', date));
        break;
      case AppNewItemKind.event:
        context.push(_taskRoute('event', date));
        break;
      case AppNewItemKind.reminder:
        context.push(_taskRoute('reminder', date));
        break;
      case AppNewItemKind.milestone:
        context.push(_taskRoute('milestone', date));
        break;
      case AppNewItemKind.note:
        context.push('/notes/new');
        break;
      case AppNewItemKind.project:
        // Ubin nonaktif tidak pernah dikirim panel; jaga-jaga saja.
        break;
    }
  }

  /// Rute form tugas bertipe [type]; membawa tanggal Kalender bila ada.
  String _taskRoute(String type, DateTime? date) {
    final base = '/tasks/new?type=$type';
    return date == null ? base : '$base&date=${IdDate.isoDate(date)}';
  }

  /// Tanggal terpilih di Kalender untuk panel yang baru dibuka, hanya bila
  /// lokasi [location] berada di tab Kalender. Dari tab lain hasilnya selalu
  /// null, sehingga tanggal Kalender tidak pernah terbawa walaupun nilai di
  /// [CalendarSelection] masih ada.
  DateTime? _panelDate(String location) =>
      location.startsWith('/calendar') ? _calendarSelection.selectedDate : null;

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
              onSelected: (kind) =>
                  _selectNewItem(kind, date: _panelDate(location)),
            ),
          ],
        ),
        // Tombol sementara untuk membuka galeri komponen. Hanya ada saat debug
        // (kDebugMode konstanta -> dihapus saat build rilis), jadi tidak muncul
        // di build produksi.
        //
        // Ditaruh kecil di kiri bawah, tepat di atas navigasi bawah: sudut kanan
        // atas dipakai ikon header (ganti tampilan Catatan, lonceng Beranda, panah
        // bulan Kalender). Tombol + ungu sudah tidak ada di layar manapun (satu
        // pintu tambah = tombol + pada navigasi), jadi tidak ada yang tertutup.
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
