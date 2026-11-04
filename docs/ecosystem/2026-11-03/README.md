# Focus Clock ecosystem: rencana agar enak dipakai

Tanggal: 3 November 2026. Status: **build berjalan bertahap; hierarki Home disetujui pemilik**. Bootstrap storage memiliki recovery slice pertama; baseline dan batas gate ada di [implementation/BASELINE.md](implementation/BASELINE.md).

Tujuan kerja: saat membuka HP, Fahim melihat hal yang ia pedulikan, memahami keadaan harinya, lalu bisa melakukan tindakan yang tepat. Habits, visualisasi waktu, dan akses aplikasi mendukung alur itu dalam satu pengalaman yang dapat dikuasai.

## Rekomendasi yang perlu diputuskan

Bangun satu aplikasi Android utama lebih dahulu dari repository `Fitrah-Launcher`, dengan modul Focus Clock, Sadar, dan launcher. Semua layar memakai data yang sama dan satu pengelola sesi fokus. Pertahankan dial yang sudah dipilih pemilik. Sajikan habits di Home, dengan detail riwayat dan pengaturan di layar tersendiri. Pemakaian sebagai launcher bersifat opsional.

Setelah aplikasi ini tahan dipakai sehari-hari, bagikan domain yang sama ke web dan desktop. Sinkronisasi lintas perangkat mendapat protokol tersendiri; membuka aplikasi lewat tautan tidak dianggap sinkronisasi. Aplikasi mandiri Focus Clock dan Sadar tetap menjadi arah lanjutan yang mungkin, bukan tiga implementasi yang harus dipelihara sekaligus sekarang.

Ini acuan arsitektur dan penyusunan layar. Pemilik menetapkan fungsi visualize, pentingnya habits, pengalaman yang tenang, kebutuhan integrasi, serta menyetujui hierarki mockup Home. Warna, variasi bookpaper, dan dial mengikuti pilihan Focus Clock yang sudah ada. Teknologi penyimpanan baru masih menunggu bukti E1.

## Baca sesuai kebutuhan

| Dokumen | Dipakai untuk |
|---|---|
| [OWNER-INTENT.md](OWNER-INTENT.md) | Menjaga maksud pemilik dan batas interpretasi agent |
| [PRD.md](PRD.md) | Menentukan perilaku, prioritas, dan kriteria penerimaan produk |
| [DESIGN.md](DESIGN.md) | Menjaga hierarki visual, tipografi, warna dan komponen |
| [EXPERIENCE.md](EXPERIENCE.md) | Menentukan navigasi, keadaan layar, dan alur penggunaan |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Menentukan pemilik data, timer, transaksi, platform dan sinkronisasi |
| [BUILD-ROADMAP.md](BUILD-ROADMAP.md) | Menjalankan build bertahap dengan syarat lulus yang jelas |
| [EVIDENCE.md](EVIDENCE.md) | Memisahkan temuan kode saat ini dari rencana dan klaim lama |
| [BUILDER-HANDOFF.md](BUILDER-HANDOFF.md) | Memberi builder berikutnya titik mulai, aturan dan bukti selesai |
| [mockups/today.html](mockups/today.html) | Melihat hierarki Home, habits, dial dan status fokus sebagai usulan visual |

Mulai dari PRD untuk produk; gunakan roadmap ketika akan mengerjakan kode. Mockup memakai data contoh, bukan bukti aplikasi sudah berfungsi.

## Urutan build

1. **E0: amankan baseline dan build.** Rekam keadaan saat ini, data, schema, entry point dan referensi visual.
2. **E1: data yang benar-benar tersimpan.** Tetapkan kontrak repository dan penyimpanan Android/web melalui percobaan terbatas; buktikan pemulihan data.
3. **E2: satu sesi fokus.** Perbaiki penghitung waktu, pemulihan, kredit durasi, dan pencegahan sesi ganda.
4. **E3: satu alur habits dan waktu.** Habit, task, jadwal, dan sesi mempunyai hubungan ID yang jelas.
5. **E4: Home yang berguna.** Tujuan, keadaan sekarang, dial dan habits terbaca; semua aksi tersambung ke jalur E1–E3.
6. **E5: launcher Android yang selesai.** Aplikasi asli, favorit persisten, role Home, Back, dan kegagalan yang terlihat.
7. **E6: dipakai setiap hari.** Pulihkan sesi, uji perangkat, aksesibilitas, backup dan upgrade sebelum release pribadi stabil.
8. **E7–E8: companion dan ekosistem.** Web/desktop yang menyimpan data, lalu sinkronisasi jika kebutuhan lintas perangkat sudah terbukti.

Pilot U0 sudah dapat dipakai sesudah E3a: Goal, habit timed/binary, sesi tahan restart dan dial membaca data yang sama. E4 merapikan Home; E3b menyelesaikan compatibility jenis/data lain. E5–E6 membuatnya layak menggantikan Home harian Android. Gate tiap tahap menentukan kapan maju; tanggal kalender tidak menggantikan bukti.

## Cara mencegah pengulangan rombak total

- Satu perubahan menyelesaikan satu alur nyata, misalnya habit → mulai → pause → tutup app → lanjut → catatan durasi.
- Review screenshot memakai data Fahim yang realistis, termasuk judul panjang, daftar kosong dan ukuran teks besar. Satu tampilan disepakati sebelum menyebar ke semua layar.
- Agent menyebut ID requirement dan bukti pemeriksaan pada handoff. Tombol, toast dan screenshot tidak cukup sebagai bukti fitur selesai.
- Perubahan arah produk masuk ke PRD dan catatan keputusan sebelum kode. Jangan mengganti UI yang telah disetujui melalui refactor sampingan.
- Data yang belum tersimpan harus mempunyai keadaan gagal yang bisa dipulihkan. Jangan membuat versi produksi tampak tersimpan saat berjalan di memory.

## Hal yang belum diputuskan pemilik

| Usulan | Default untuk merencanakan | Kapan perlu keputusan |
|---|---|---|
| Aplikasi utama | Fitrah Android; Focus Clock/Sadar sebagai modul | Sebelum E0 memilih jalur distribusi |
| Home | Tujuan, status sekarang, dial dan habits dalam satu hierarki | Review mockup sebelum E4 |
| Gaya visual | Pertahankan palet pilihan (termasuk Warm Bookpaper/Amber) dan dial analog | Mockup menetapkan hierarki; warna dan gaya dial tidak diganti |
| Penyimpanan baru | Belum dipilih; E1 membuktikan kandidat | Sebelum migrasi schema/domain |
| Sinkronisasi | Opsional setelah lokal stabil; provider belum dipilih | Sebelum E8 |
| Perangkat acuan | Satu HP harian Fahim dan satu HP/emulator yang berbeda | Sebelum mengukur performa E6 |

Dokumen ini ditulis sebagai satu acuan yang dapat direvisi. Tidak ada janji bahwa produk tidak akan membutuhkan perbaikan lagi. Sasaran akhirnya jelas: alat sehari-hari yang dapat dipercaya, dengan perubahan kecil yang terukur.

## Pemeriksaan draft

Review terpisah memeriksa kecocokan teknologi, batas antar modul, kebutuhan pemilik dan struktur/prose. Perbaikan yang diterapkan: persisted TodaySelection, aturan eligibility/urutan habit, pilot U0 sebelum rilis lengkap, identity occurrence/import, durasi serta status manual, receipt idempotency, reminder reconciliation dan owner epoch untuk handoff masa depan. Laporan review tersimpan di `reviews/`; temuan awal di situ bukan semuanya isu yang masih terbuka.

Linter arsitektur tidak menemukan masalah mekanis. Tautan relatif dan urutan FR lulus pemeriksaan. Mockup berjalan di Chromium tanpa JS error pada alur contoh yang diperiksa dan tidak memiliki horizontal page overflow pada 320/375/430 px. APK dan logic produksi belum diuji pada run dokumen ini.
