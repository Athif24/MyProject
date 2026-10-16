import 'package:flutter/widgets.dart';

/// Melepas fokus (mis. kolom cari) setiap kali rute berpindah.
///
/// Kenapa perlu: layar di dalam shell tetap hidup saat rute lain ditumpuk di
/// atasnya (`maintainState` pada halaman `NoTransitionPage`). Kolom teks yang
/// sedang fokus tetap dicatat sebagai "anak terfokus" oleh `FocusScope` rutenya,
/// sehingga begitu rute itu aktif kembali, fokus (dan keyboard) dipulihkan
/// sendiri tanpa disentuh pengguna.
///
/// `FocusNode.unfocus()` — dipanggil di sini saat kolom masih fokus, sebelum
/// rute baru dibangun — mengosongkan catatan itu, jadi fokus tidak dipulihkan
/// saat pengguna kembali. Ditempatkan di observer rute agar berlaku untuk semua
/// layar, bukan disalin di tiap layar.
///
/// Didaftarkan pada `AppRouter` lewat `GoRouter.observers`.
class AppRouteObserver extends NavigatorObserver {
  /// Lepaskan fokus utama (bila ada) supaya tidak diingat oleh `FocusScope`
  /// rute yang ditinggalkan.
  void _releaseFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _releaseFocus();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _releaseFocus();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _releaseFocus();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _releaseFocus();
  }
}

/// Instance bersama yang dipakai `AppRouter`.
final AppRouteObserver appRouteObserver = AppRouteObserver();
