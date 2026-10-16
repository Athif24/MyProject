import 'package:flutter/material.dart';

/// Peta nama semantik ikon ke [IconData].
///
/// Semua layar HANYA memakai [AppIcons] agar set ikon bisa diganti di satu
/// tempat (mis. beralih ke ikon rounded atau custom) tanpa menyentuh widget.
/// Sementara ini memakai ikon Material bergaya garis (outline).
class AppIcons {
  const AppIcons._();

  static const IconData home = Icons.home_outlined;
  static const IconData chat = Icons.chat_bubble_outline;
  static const IconData notes = Icons.note_alt_outlined;
  static const IconData calendar = Icons.calendar_today_outlined;
  static const IconData bell = Icons.notifications_outlined;
  static const IconData search = Icons.search;
  static const IconData clock = Icons.access_time;
  static const IconData flag = Icons.flag_outlined;
  static const IconData folder = Icons.folder_outlined;
  static const IconData check = Icons.check;
  static const IconData checkCircle = Icons.check_circle_outline;
  static const IconData circle = Icons.radio_button_unchecked;
  static const IconData back = Icons.arrow_back;
  static const IconData add = Icons.add;
  static const IconData more = Icons.more_horiz;
  static const IconData edit = Icons.edit_outlined;
  static const IconData close = Icons.close;
  static const IconData delete = Icons.delete_outline;
  static const IconData chevronLeft = Icons.chevron_left;
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData dropdown = Icons.keyboard_arrow_down;

  /// Ganti tampilan daftar/grid di layar Catatan.
  static const IconData gridView = Icons.grid_view_outlined;
  static const IconData listView = Icons.view_list_outlined;

  /// Penanda catatan yang disematkan.
  static const IconData pin = Icons.push_pin_outlined;

  /// Panah buka/tutup daftar subtugas di kartu agenda Kalender. Diputar 180
  /// derajat oleh widget saat daftarnya terbuka.
  static const IconData expand = Icons.expand_more;

  /// Ubin "Acara" pada panel "Buat Baru".
  static const IconData event = Icons.event_outlined;
}
