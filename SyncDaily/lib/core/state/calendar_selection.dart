/// Tanggal yang sedang terpilih di layar Kalender pada sesi aplikasi ini.
///
/// Panel "Buat Baru" (lihat `AppShell`) memakainya supaya form yang dibuka dari
/// tab Kalender membawa tanggal terpilih, tanpa membuat `AppShell` bergantung
/// pada `CalendarCubit` (providernya hidup di bawah shell, jadi tidak dapat
/// dibaca dari sana).
///
/// Nilainya hanya diisi oleh `CalendarCubit`: saat layar Kalender mulai dan
/// setiap kali tanggal/bulan berganti. `AppShell` membacanya hanya ketika tab
/// Kalender yang sedang aktif, jadi tanggal Kalender tidak pernah terbawa ke
/// panel yang dibuka dari tab lain.
class CalendarSelection {
  DateTime? _selectedDate;

  /// Tanggal terpilih tanpa jam, atau null bila layar Kalender belum pernah
  /// mengisinya pada sesi ini.
  DateTime? get selectedDate => _selectedDate;

  /// Menyimpan [date] sebagai tanggal terpilih; jamnya dibuang.
  void select(DateTime date) =>
      _selectedDate = DateTime(date.year, date.month, date.day);
}
