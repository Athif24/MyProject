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

  // Form tugas/acara/pengingat/milestone
  static const String formTitleTask = 'Tugas';
  static const String formTitleEvent = 'Acara';
  static const String formTitleReminder = 'Pengingat';
  static const String formTitleMilestone = 'Milestone';
  static const String newItem = 'Buat baru';
  static const String editItem = 'Ubah';
  static const String save = 'Simpan';
  static const String type = 'Tipe';
  static const String title = 'Judul';
  static const String description = 'Deskripsi';
  static const String priority = 'Prioritas';
  static const String project = 'Proyek';
  static const String subtask = 'Sub-tugas';
  static const String recurrence = 'Pengulangan';
  static const String reminderLabel = 'Pengingat';
  static const String allDay = 'Sepanjang hari';
  static const String startAt = 'Mulai';
  static const String endAt = 'Selesai';
  static const String dueDate = 'Tenggat';
  static const String dueTarget = 'Target';
  static const String noProject = 'Tanpa proyek';
  static const String addSubtask = 'Tambah sub-tugas';
  static const String titleRequired = 'Judul wajib diisi';
  static const String startRequired = 'Waktu mulai wajib diisi';
  static const String endRequired = 'Waktu selesai wajib diisi';
  static const String dueRequired = 'Tenggat wajib diisi';
  static const String endBeforeStart = 'Waktu selesai tidak boleh sebelum mulai';
  static const String none = 'Tidak';
  static const String daily = 'Harian';
  static const String weekly = 'Mingguan';
  static const String monthly = 'Bulanan';
  static const String remind10Min = '10 menit sebelum';
  static const String remind1Hour = '1 jam sebelum';
  static const String remind1Day = '1 hari sebelum';
  static const String remindOnTime = 'Tepat waktu';
  static const String priorityLow = 'Rendah';
  static const String priorityMedium = 'Sedang';
  static const String priorityHigh = 'Tinggi';
  static const String removeSubtask = 'Hapus sub-tugas';
  static const String editSubtask = 'Ubah sub-tugas';
  static const String pickDate = 'Pilih tanggal';
  static const String pickTime = 'Pilih waktu';
  static const String unsavedTitle = 'Buang perubahan?';
  static const String unsavedBody = 'Perubahan yang belum disimpan akan hilang.';
  static const String keepEditing = 'Lanjut mengubah';
  static const String discard = 'Buang';
}
