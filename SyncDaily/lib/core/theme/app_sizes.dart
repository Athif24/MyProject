class AppSizes {
  const AppSizes._();

  static const double pagePadding = 24;
  static const double itemSpacing = 8;
  static const double sectionGap = 24;
  static const double cardGap = 12;

  /// Padding dalam kartu item (mis. [ListItemTile]).
  static const double cardPadding = 12;
  static const double navHeight = 68;
  static const double navIconBox = 46;
  static const double navItemPadding = 8;

  /// Jarak kiri/kanan pill navigasi bawah terhadap tepi layar.
  static const double navHorizontalMargin = 16;

  /// Jarak bawah pill navigasi bawah terhadap tepi aman layar.
  static const double navBottomMargin = 20;
  static const double fab = 60;
  static const double fabLift = 14;
  static const double searchField = 48;
  static const double minTouchTarget = 44;
  static const double avatar = 48;
  static const double listItemIcon = 44;
  static const double iconButton = 44;
  static const double unreadDot = 8;
  static const double unreadBadgeMin = 18;
  static const double statChartHeight = 32;
  static const double iconSmall = 18;
  static const double badgeOverlap = 4;

  // Kalender (grid bulan).
  static const double calendarCellHeight = 44;
  static const double calendarDayCircle = 32;
  static const double calendarDot = 5;
  static const double calendarDotGap = 3;
  static const double calendarSubtaskGap = 4;

  /// Ikon panah buka/tutup daftar subtugas di kartu agenda.
  static const double calendarArrowIcon = 22;

  /// Tinggi kartu catatan pada grid dua kolom layar Catatan.
  static const double noteCardHeight = 178;

  /// Banyak baris isi singkat pada kartu catatan.
  static const int notePreviewLines = 3;

  // Panel "Buat Baru" (dibuka tombol + pada navigasi bawah).
  //
  // TODO(design): kekuatan blur dan ukuran ikon ubin panel belum dirinci di
  // DESIGN.md; sementara mengikuti gaya komponen yang ada.
  //
  /// Kekuatan blur latar panel. Setel ke 0 untuk memakai lapisan gelap saja
  /// (tanpa blur) bila terasa berat di perangkat kelas bawah; tata letak panel
  /// tidak berubah karena lapisan ini memenuhi seluruh layar.
  static const double panelBlur = 8;

  /// Sisi kotak ikon ubin panel.
  static const double panelTileIconBox = 48;

  /// Ukuran ikon ubin panel.
  static const double panelTileIcon = 22;

  /// Jarak panel melayang terhadap pill navigasi bawah.
  static const double panelGapAboveNav = 12;
}
