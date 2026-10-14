# SyncDaily (Flutter) — Instruksi untuk OpenCode

Aplikasi Android pengingat dan perencana tugas dengan proyek kelompok, catatan, kalender, notifikasi, dan chat. Saat ini yang dikerjakan adalah Fase 1: aplikasi LOKAL (belum memakai BackEnd).

## Wajib dibaca sebelum bekerja
- `../docs/DESIGN.md` — panduan visual (ikuti persis).
- `../docs/API.md` — kontrak BackEnd (dipakai mulai Fase 2).

## Stack
- Flutter stable, Dart. Target: Android saja.
- State: flutter_bloc. Navigasi: go_router. DI: get_it.
- Database lokal: Drift (SQLite).
- Notifikasi lokal: flutter_local_notifications + timezone (zona waktu perangkat; default Asia/Jakarta).
- Izin: permission_handler. Format tanggal: intl (id_ID).
- Font Plus Jakarta Sans dibundel di assets (jangan mengunduh saat runtime).
- Dependency baru hanya setelah bertanya kepada pengguna.

## Struktur (feature-first)
```
lib/
  core/        theme/, router/, widgets/ (komponen bersama), notifications/, utils/, di/
  features/<nama>/
    data/          (tabel Drift, DAO, repository impl)
    domain/        (entity, repository interface)
    presentation/  (bloc/cubit, pages, widgets)
```
Fitur: home, tasks, calendar, notes, notifications, projects, chat, auth, settings.

## Aturan
- UI mengikuti `DESIGN.md`. Semua warna, radius, dan gaya teks lewat theme; dilarang hardcode hex atau ukuran di widget.
- Teks UI dalam Bahasa Indonesia. Semua teks UI disimpan di `lib/core/strings/app_strings.dart` (kelas `AppStrings`); seluruh layar wajib memakainya, jangan menulis teks langsung di widget.
- Tidak ada logika bisnis di widget. Widget hanya menampilkan state dan mengirim event.
- Repository menyembunyikan sumber data, supaya nanti bisa menambah sinkronisasi server tanpa menulis ulang UI.
- Base URL API (mulai Fase 2) dibaca dari konfigurasi build (`--dart-define=API_BASE_URL=...`), jangan di-hardcode. Produksi wajib HTTPS.
- Waktu disimpan UTC di database, ditampilkan sesuai zona waktu perangkat.
- Semua tombol ikon punya label semantik. Target sentuh minimal 44 dp.
- Tangani state: loading, kosong (empty state sesuai gaya desain), dan error.
- Android: tangani izin notifikasi (Android 13 ke atas) dan alarm tepat waktu (Android 12 ke atas) dengan alur yang jelas; pastikan pengingat dijadwalkan ulang setelah HP restart.
- Tulis tes untuk bloc, repository, dan logika jadwal pengingat/pengulangan.
- Sebelum menyatakan selesai: jalankan `flutter analyze`. Untuk perubahan UI, verifikasi manual dengan `flutter run` di HP (tampilan, animasi, target sentuh). Untuk logika (bloc, repository, jadwal pengingat/pengulangan), wajib jalankan `flutter test`. Laporkan hasilnya.
- Kerjakan satu bagian per permintaan. Jika permintaan ambigu, ajukan satu pertanyaan singkat sebelum menulis kode.
- Jika prompt berkata "tanyakan dulu", berhenti dan tunggu jawaban sebelum menjalankan langkah itu.
- Jangan mengerjakan bagian prompt lain di luar yang diminta.
- Di akhir tiap tugas: ringkas apa yang berubah, cara mencobanya, dan hal yang belum dikerjakan.
