# Handoff builder: Focus Clock ecosystem

Gunakan prompt ini untuk memulai implementasi sesudah pemilik memilih arah dokumen. Jangan menyebut draft sebagai sudah disetujui jika percakapan belum mencatat keputusan itu.

```text
Kerjakan Focus Clock ecosystem di /home/aizatfir/Project/Fitrah-Launcher.

Baca docs/ecosystem/2026-11-03/README.md, OWNER-INTENT.md, lalu dokumen
yang dibutuhkan slice aktif: PRD, EXPERIENCE, DESIGN, ARCHITECTURE dan
BUILD-ROADMAP. Baca instruksi repo dan git status terbaru sebelum edit.

Inti produk: visualize tujuan, keadaan hari, habits dan tindakan berikutnya.
Habits tetap inti. Pertahankan basis dial yang telah dipilih pemilik.
Satu app harus mempunyai satu jalur data dan satu pengelola sesi fokus.

Mulai milestone pertama yang belum lulus. Bila belum ada bukti E0,
kerjakan E0; jangan langsung mengganti Home atau migrasi database.
Tentukan satu vertical slice, requirement ID, file, data yang disentuh,
kontrak yang dipakai dan gate selesai. Usulan distribusi, komposisi Home
dan teknologi baru tetap mengikuti keputusan pemilik yang terbaru.

Gunakan repository/engine existing yang dapat diperbaiki. Jangan membuat
HabitModel, BlockItem atau countdown owner baru di UI. Goal, TodaySelection,
rencana jadwal, actual session dan check-in manual memiliki arti berbeda.
Durasi target tidak boleh menjadi durasi aktual; callback ganda tidak boleh
menambah bukti dua kali.

Simpan backup sebelum upgrade data. Jangan menghapus/reset DB, mengganti
schema IDs, applicationId atau signing key untuk memudahkan build.
Jangan memberi success ketika data masih hanya di memory atau ketika aksi
platform disimulasikan. Tangani hasil gagal di layar dan pertahankan draft.

Verifikasi slice dengan checks yang relevan: domain/state/migration tests
untuk logic, screenshot dan accessibility untuk UI, serta device checks
untuk kemampuan Android. Laporkan command dan hasil yang benar-benar
dijalankan. Build berhasil tidak membuktikan alur fitur telah selesai.

Selesaikan slice dan berhenti memperluas scope ketika gate lulus. Handoff
harus memuat perubahan, FR/AD yang dipenuhi, bukti, batas yang belum diperiksa,
dan milestone berikutnya. Jangan deploy/push berdasarkan kutipan prompt lama.
```

## Keadaan akhir run perencanaan 3 November

Paket draft ini sudah tersedia bersama mockup. Aplikasi belum diubah oleh run ini; E0 belum dijalankan sebagai implementation milestone. Tiga dirty generated files dalam `build/web` sudah ada sebelum perencanaan dan tetap dipertahankan. Tidak ada APK build, app test suite atau deploy pada run ini.

Doc checks: tautan relatif, urutan FR, linter architecture dan placeholder scan telah diperiksa. Prototype JS dan alur lokal start/pause/resume/end, check-in manual, catatan, navigasi dan overflow 320/375/430 px telah diperiksa melalui Chromium. Pemeriksaan itu tidak membuktikan persistence, timer atau launcher Android yang sesungguhnya.
