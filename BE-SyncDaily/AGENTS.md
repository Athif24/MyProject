# BE-SyncDaily — Instruksi untuk OpenCode

BackEnd aplikasi mobile SyncDaily (pengingat dan perencana tugas, dengan proyek kelompok dan chat). Pemilik proyek berfokus di Front-End dan baru belajar BackEnd, jadi: tulis kode sederhana, mudah dibaca, dan jelaskan keputusan penting dengan singkat.

## Wajib dibaca sebelum bekerja
- `../docs/API.md` — kontrak API (sumber kebenaran). Jangan mengubah kontrak tanpa memperbarui file itu dan memberi tahu pengguna.

## Stack
- Node.js LTS, TypeScript (strict), Express
- PostgreSQL + Prisma (semua perubahan skema lewat migrasi Prisma). Lokal: PostgreSQL di komputer dengan database `syncdaily_dev`. Produksi: PostgreSQL cloud (calon: Neon atau Supabase). Jangan memakai fitur yang khusus untuk satu penyedia.
- Validasi: zod. Auth: JWT access + refresh token dengan rotasi, password di-hash dengan bcrypt.
- Realtime: Socket.IO, dibungkus antarmuka `RealtimeGateway` (lihat bagian Vercel). Push: firebase-admin (FCM).
- Hosting: Vercel (Express berjalan sebagai satu Vercel Function).
- Keamanan: helmet, cors dengan daftar origin eksplisit, express-rate-limit (ketat di endpoint auth; lihat catatan store di bagian Vercel).
- Log: pino. Tes: vitest + supertest.
- Tambah dependency baru hanya jika perlu, dan sebut alasannya.

## Struktur
```
src/
  app.ts        (membuat dan MENGEKSPOR instance Express, tanpa listen)
  server.ts     (hanya untuk jalan lokal: app.listen)
  config/        (env tervalidasi zod)
  middleware/    (auth, error handler, validate)
  modules/<nama>/ routes.ts, controller.ts, service.ts, schema.ts
  lib/           (prisma, fcm, realtime)
prisma/schema.prisma
vercel.json
```
Modul: auth, users, devices, projects, tasks, notifications, chat.
Alur: route -> validasi zod -> controller tipis -> service (logika + cek izin) -> Prisma.

## Deploy di Vercel (WAJIB dipatuhi)
- Ekspor instance Express sebagai default export dari `src/app.ts`. `src/server.ts` hanya dipakai lokal (`app.listen`). Ikuti dokumentasi "Express on Vercel" untuk titik masuk yang didukung, dan jangan memanggil `listen` di lingkungan Vercel.
- Tidak ada disk permanen: jangan menyimpan file di server (hanya `/tmp` sementara). Unggahan file memakai storage eksternal (ditentukan nanti).
- Tidak ada proses latar, `setInterval`, atau state penting di memori antar request. Tugas terjadwal memakai Vercel Cron (didaftarkan di `vercel.json`), dan endpoint cron WAJIB dilindungi `CRON_SECRET`.
- Database produksi: PostgreSQL terkelola yang berada di luar Vercel. Pakai satu instance PrismaClient yang dipakai ulang, batasi jumlah koneksi, dan pastikan `prisma generate` berjalan saat build. Gunakan connection string dengan pooling untuk aplikasi (`DATABASE_URL`) dan koneksi langsung untuk migrasi (`DIRECT_URL`, lewat `directUrl` di schema.prisma). Untuk pengembangan lokal langsung pakai PostgreSQL lokal; TANYAKAN penyedia cloud mana yang dipilih sebelum menulis konfigurasi produksi.
- Handler harus singkat. Rate limit dengan store di memori tidak andal di serverless: gunakan store bersama (misal Redis) atau fitur firewall Vercel, dan tanyakan pilihannya ke pengguna.
- Realtime: WebSocket di Vercel Functions masih public beta, koneksi terputus saat durasi maksimum fungsi tercapai, dan tiap koneksi menempel pada satu instance. Konsekuensinya:
  - REST adalah sumber kebenaran; realtime hanya pemercepat. Klien harus bisa reconnect dan mengambil pesan tertinggal lewat `?after=` (lihat API.md).
  - Semua kode realtime lewat antarmuka `RealtimeGateway` supaya mudah diganti (misal Pusher, Ably, atau Firebase) bila beta bermasalah.
  - Jika memakai Socket.IO, klien wajib `transports: ['websocket']`. Penyiaran antar-instance membutuhkan pub/sub bersama (misal Redis adapter); tanyakan pilihannya ke pengguna sebelum menulis.
- Variabel lingkungan diatur di dashboard Vercel (`vercel env pull` untuk lokal). Kredensial Firebase lewat env var (JSON yang di-base64), BUKAN path file.
- Jangan menambah fitur yang bergantung pada server yang selalu hidup.

## Aturan
- Cek izin (anggota/peran) di service untuk SETIAP aksi pada proyek dan tugas. Ini bagian paling penting; buat tes untuk setiap aturan di tabel izin pada API.md.
- Jangan pernah mengembalikan password hash, token, atau data pengguna lain yang tidak perlu.
- Semua input divalidasi. Jangan menyusun SQL dari string; gunakan Prisma.
- Rahasia hanya di `.env` (jangan di-commit). Selalu perbarui `.env.example`.
- Format error seragam sesuai API.md. Jangan membocorkan stack trace ke klien.
- Perubahan tabel: buat migrasi, jangan edit database manual.
- Sebelum menyatakan selesai: jalankan `npm run lint`, `npm run typecheck`, `npm test`, dan laporkan hasilnya.
- Kerjakan satu bagian per permintaan. Jika permintaan ambigu, ajukan satu pertanyaan singkat sebelum menulis kode.
- Di akhir tiap tugas: ringkas apa yang berubah, cara mencobanya (contoh perintah curl), dan hal yang belum dikerjakan.

## Variabel lingkungan
DATABASE_URL, DIRECT_URL, JWT_ACCESS_SECRET, JWT_REFRESH_SECRET, PORT (lokal saja), CORS_ORIGINS, FIREBASE_SERVICE_ACCOUNT_BASE64, CRON_SECRET, REDIS_URL (opsional, jika dipakai)
