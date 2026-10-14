# SyncDaily — Kontrak API (v1)

Dipakai bersama oleh `SyncDaily` (Flutter) dan `BE-SyncDaily` (BackEnd). Perubahan kontrak HARUS memperbarui file ini lebih dulu dan diberi tahu ke pengguna.

## Prinsip
- **Local-first**: tugas, acara, pengingat, milestone, dan catatan PRIBADI hanya tinggal di HP (Drift/SQLite) dan tidak dikirim ke server.
- Server menyimpan: akun, proyek bersama, anggota, tugas proyek (yang ditugaskan), percakapan, pesan, token perangkat, dan notifikasi.
- Tugas proyek disinkronkan ke HP anggota. HP menjadwalkan pengingat lokal sendiri dari data sinkron, sehingga tetap berbunyi saat offline.

## Konvensi
- Base URL: `/api/v1`. Lokal (emulator Android): `http://10.0.2.2:<PORT>/api/v1`. Produksi (Vercel): `https://<proyek>.vercel.app/api/v1` (HTTPS wajib). Klien membaca base URL dari konfigurasi build. JSON, camelCase. Waktu: ISO 8601 UTC. ID: UUID.
- Auth: header `Authorization: Bearer <accessToken>`. Access token 15 menit, refresh token 30 hari dengan rotasi.
- Error: `{ "error": { "code": "VALIDATION_ERROR", "message": "...", "details": [] } }`. Kode umum: VALIDATION_ERROR, UNAUTHORIZED, FORBIDDEN, NOT_FOUND, CONFLICT, RATE_LIMITED.
- Paginasi: `?limit=20&cursor=<opaque>` -> `{ "items": [], "nextCursor": null }`.

## Peran dan izin
| Aksi | Ketua (leader) | Anggota (member) |
|---|---|---|
| Lihat proyek, tugas, anggota | ya | ya |
| Ubah/hapus proyek, tambah/keluarkan anggota, ganti ketua | ya | tidak |
| Buat/ubah/hapus tugas, ubah penanggung jawab dan jadwal | ya | tidak |
| Ubah STATUS tugas | ya | hanya tugas yang ditugaskan padanya |
| Komentar pada tugas | ya | ya |
Setiap endpoint WAJIB memeriksa keanggotaan dan peran di sisi server.

## Endpoint

### Auth
- `POST /auth/register` {name, email, password}
- `POST /auth/login` {email, password} -> {user, accessToken, refreshToken}
- `POST /auth/refresh` {refreshToken}
- `POST /auth/logout` {refreshToken}
- `POST /auth/forgot-password`, `POST /auth/reset-password`
- `GET /me`, `PATCH /me` (nama, avatar), `DELETE /me` (hapus akun beserta datanya)

### Perangkat
- `PUT /devices` {fcmToken, platform} -> daftar/ganti token. `DELETE /devices/:token` saat logout.

### Pengguna
- `GET /users/search?q=` -> cari pengguna (nama/email), tanpa data sensitif.

### Proyek
- `GET /projects?role=owned|received` | `POST /projects` {title, description, startDate, dueDate}
- `GET /projects/:id` | `PATCH /projects/:id` | `DELETE /projects/:id`
- `GET /projects/:id/members` | `DELETE /projects/:id/members/:userId` | `POST /projects/:id/transfer-leader` {userId}
- `POST /projects/:id/invitations` {userId | email} -> undangan
- `GET /invitations` (undangan untuk saya) | `POST /invitations/:id/accept` | `POST /invitations/:id/decline`

### Tugas proyek
- `GET /projects/:id/tasks` | `POST /projects/:id/tasks`
- Task: {id, projectId, parentTaskId?, title, description?, type (task|event|reminder|milestone), startAt?, endAt?, dueAt?, isAllDay, priority (low|medium|high), status (todo|in_progress|done), assigneeIds[], reminderOffsetsMinutes[], recurrence?, updatedAt, version}
- `PATCH /tasks/:id` (ketua: semua field) | `PATCH /tasks/:id/status` {status} (penanggung jawab) | `DELETE /tasks/:id`
- `GET /tasks/:id/comments` | `POST /tasks/:id/comments`
- **Sinkron**: `GET /sync?since=<ISO>` -> {projects[], members[], tasks[], deletedIds{projects[],tasks[]}, serverTime}. Konflik: server menang, kecuali perubahan status oleh penanggung jawab yang lebih baru. Gunakan field `version` untuk optimistic concurrency (409 CONFLICT bila beda).

### Notifikasi
- `GET /notifications?cursor=` | `POST /notifications/read` {ids[] | all:true}
- Tipe: task_assigned, schedule_changed, task_status_changed, project_invite, member_joined, message, system.
- Pengingat/deadline/acara dibuat LOKAL di HP, bukan dari server.

### Chat
- `GET /conversations` | `POST /conversations` {userId} (1-1) | grup proyek dibuat otomatis saat proyek dibuat
- `GET /conversations/:id/messages?cursor=` atau `?after=<messageId>` (ambil pesan yang tertinggal setelah reconnect) | `POST /conversations/:id/messages` {text, clientId}
- `POST /conversations/:id/read` {lastReadMessageId}
- `clientId` dibuat HP untuk mencegah pesan ganda saat kirim ulang.

## Realtime (Socket.IO)
Realtime hanya PEMERCEPAT, bukan sumber kebenaran. BackEnd dideploy di Vercel, dan WebSocket di sana masih beta sehingga koneksi bisa putus kapan saja. Klien WAJIB: reconnect otomatis, mengambil pesan tertinggal lewat `?after=` setiap kali tersambung kembali, dan mengandalkan push FCM saat aplikasi tidak aktif. Server menyiarkan lewat antarmuka `RealtimeGateway` agar penyedia realtime bisa diganti.

Koneksi dengan access token. Event server -> klien: `message:new`, `message:read`, `typing`, `notification:new`, `task:changed`. Klien -> server: `typing`, `message:read`. Pengiriman pesan lewat REST; Socket.IO untuk penyiaran.

## Push (FCM)
Kirim bila penerima tidak sedang terhubung. Payload `data`: {type, entityId, deepLink}. Contoh deepLink: `syncdaily://tasks/<id>`, `syncdaily://chat/<conversationId>`.

## Berkas dan lampiran
Server tidak menyimpan file di disk (hosting serverless). Lampiran (avatar, gambar chat) memakai storage eksternal; rinciannya ditetapkan saat fitur itu dikerjakan.

## Model data (tabel utama)
users, refresh_tokens, devices, projects, project_members (role), invitations, tasks (+ task_assignees), task_comments, notifications, conversations, conversation_members, messages. Semua punya createdAt dan updatedAt. Penghapusan tugas/proyek memakai soft delete agar bisa disinkronkan.
