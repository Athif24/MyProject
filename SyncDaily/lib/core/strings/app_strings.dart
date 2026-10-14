/// Seluruh teks UI aplikasi (Bahasa Indonesia) agar mudah diubah di satu
/// tempat, sesuai AGENTS.md.
///
/// Layar baru WAJIB memakai kelas ini, bukan menulis teks langsung di widget.
class AppStrings {
  const AppStrings._();

  // Sapaan Beranda (lihat `core/utils/greeting.dart`).
  static const String greetingMorning = 'Selamat pagi';
  static const String greetingAfternoon = 'Selamat siang';
  static const String greetingEvening = 'Selamat sore';
  static const String greetingNight = 'Selamat malam';

  // Beranda: header dan judul seksi.
  static const String notifications = 'Notifikasi';
  static const String overview = 'Overview';
  static const String projects = 'Projects';
  static const String filterPeriod = 'Filter periode';
  static const String filterProjectTime = 'Filter waktu proyek';

  // Nama bawaan pengguna.
  static const String defaultUserName = 'Pengguna';

  // Filter periode Overview.
  static const String periodThisWeek = 'Minggu ini';
  static const String periodThisMonth = 'Bulan ini';
  static const String periodAll = 'Semua';

  // Tab seksi Projects.
  static const String projectTabMine = 'Proyek saya';
  static const String projectTabReceived = 'Diterima';

  /// Contoh: `Proyek saya (3)`.
  static String tabWithCount(String tab, int count) => '$tab ($count)';

  // Kartu statistik.
  static const String statToday = 'Hari ini';
  static const String statSchedule = 'Jadwal';
  static const String statProjects = 'Proyek';
  static const String statAllTasks = 'Semua tugas';

  // Kartu proyek.
  static const String projectMenu = 'Menu proyek';
  static const String edit = 'Edit';
  static const String delete = 'Hapus';
  static const String cancel = 'Batal';

  /// Contoh: `3 Task`.
  static String taskCount(int count) => '$count Task';

  /// Contoh: `2 Sub-task`.
  static String subtaskCount(int count) => '$count Sub-task';

  // Keadaan kosong.
  static const String noProjects = 'Belum ada proyek';
  static const String noProjectsDescription =
      'Proyek yang Anda buat akan tampil di sini.';
  static const String noReceivedProjects = 'Belum ada proyek yang diterima';
  static const String noReceivedProjectsDescription =
      'Proyek dari orang lain akan tampil di sini setelah tersinkronisasi.';
  static const String withoutDate = 'Tanpa tanggal';

  // Keadaan error.
  static const String loadFailedTitle = 'Gagal memuat data';
  static const String loadFailedDescription =
      'Terjadi kesalahan saat membaca data. Coba lagi.';
  static const String retry = 'Coba lagi';

  // Aksi yang belum tersedia.
  static const String comingSoon = 'Segera hadir';

  // Dialog hapus proyek.
  static const String deleteProjectTitle = 'Hapus proyek?';
  static String deleteProjectBody(String projectTitle) =>
      '"$projectTitle" beserta seluruh tugasnya akan dihapus.';
  static const String projectDeleted = 'Proyek dihapus';
}
