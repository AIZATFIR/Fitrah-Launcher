---
title: Focus Clock ecosystem
status: draft-for-owner-review
created: 2026-11-03
updated: 2026-11-21
---

# PRD: Focus Clock ecosystem

## 1. Tujuan dan batas dokumen

Rencana ini memberi Fahim dan builder berikutnya satu pengertian tentang produk yang harus selesai. [OWNER-INTENT](OWNER-INTENT.md) merekam asal kebutuhan; [EVIDENCE](EVIDENCE.md) menunjukkan celah implementasi saat ini. Detail teknis berada di ARCHITECTURE, tampilan di DESIGN, alur di EXPERIENCE, dan urutan kerja di BUILD-ROADMAP.

Hasil yang dicari: Fahim membuka layar, mengingat sesuatu yang berarti, tahu keadaan harinya, dan dapat mulai atau melanjutkan tindakan tanpa membuka beberapa aplikasi untuk memahami konteksnya.

**[ASSUMPTION A1]** Satu aplikasi Flutter Android menjadi produk utama pertama. Pemilik sudah memakai penggabungan fungsi sebagai solusi praktis; penetapan repo dan bentuk distribusi jangka panjang masih usulan. Aplikasi boleh dipakai sebagai companion biasa sebelum dijadikan launcher.

## 2. Pengguna dan situasi

Fahim adalah pengguna acuan pertama: ia mengerjakan LKS/belajar, bersekolah, mempunyai kesempatan singkat di sela kegiatan, ingin menjaga ibadah, kebugaran, minat dan istirahat. Isi contoh bukan default yang app tanamkan ke akun baru.

Orang lain dapat memakai tujuan dan kegiatan berbeda. Produk membantu keputusan mereka tanpa mewajibkan penilaian energi, kategori agama, profil kepribadian atau integrasi AI.

### Perjalanan acuan

| ID | Situasi dan hasil yang diharapkan |
|---|---|
| UJ-1 | Fahim membuka HP saat jam kosong. Home menampilkan tujuan, habit LKS yang belum disentuh, dan sesi aktif bila ada. Ia memilih LKS, melihat petunjuk miliknya “Buka laptop”, lalu memulai sesi. |
| UJ-2 | Fahim pindah ke aplikasi lain, mengunci HP, lalu membuka Fitrah kembali. Judul dan sisa sesi tetap sama; ia dapat pause atau lanjut dari status yang sama. |
| UJ-3 | Fahim hanya mempunyai sedikit tenaga. Ia memilih tindakan kecil atau istirahat, mengubah rencana tanpa kehilangan catatan sebelumnya atau mendapat hukuman. |
| UJ-4 | Fahim selesai membaca tanpa timer. Ia mencatat jumlah/selesai secara manual. Riwayat membedakan catatan itu dari menit yang diukur timer. |
| UJ-5 | Fahim merencanakan kegiatan melalui dial. Home dan tampilan jadwal melihat blok yang sama; blok tidak dianggap sudah dilakukan hanya karena waktunya lewat. |
| UJ-6 | Fahim menutup hari, melihat tindakan yang sudah dicatat dan menulis refleksi singkat. Hari kosong atau dilewati tetap terlihat sebagai konteks, bukan kegagalan karakter. |
| UJ-7 | Kelak Fahim membuka companion laptop untuk sesi dari HP. App menjelaskan apakah perangkat terhubung dan siapa pemilik sesi; klaim sinkron mengikuti acknowledgement data, bukan keberhasilan membuka URL. |

UJ-1 sampai UJ-6 diturunkan dari konteks pemilik, bukan wawancara observasi baru. Rincian langkah adalah usulan yang akan diperiksa saat review UX.

## 3. Kosakata produk

| Istilah | Arti |
|---|---|
| Tujuan / Goal | Arah bermakna yang user tulis. Bisa beberapa; satu dapat dipilih sebagai cue utama. |
| Habit | Tindakan berulang dengan aturan jadwal dan target sendiri; durasi, jumlah, biner, progression atau hybrid yang sudah dibutuhkan produk. |
| Task | Tindakan sekali selesai, boleh berada di inbox atau dijadwalkan. |
| Blok jadwal / ScheduleBlock | Alokasi waktu yang direncanakan; boleh mengacu ke satu Habit atau Task. |
| Sesi fokus / FocusSession | Catatan pelaksanaan dengan waktu mulai, pause, lanjut, akhir dan durasi aktual. |
| Catatan habit / HabitEntry | Status serta bukti harian untuk habit pada tanggal tertentu. Catatan manual dan kontribusi sesi mempunyai asal yang jelas. |
| Cue | Ringkasan tujuan, keadaan dan tindakan yang dapat dipilih; user tetap dapat mengganti pilihannya. |
| Hari Ini | Tampilan ringkasan untuk tanggal lokal saat ini, berbeda dari tanggal historis yang sedang dibuka. |
| Sadar | Modul pemenuhan habit, riwayat pengulangan dan refleksi. |
| Focus Clock | Modul visualisasi waktu, jadwal dan pelaksanaan fokus. |
| Fitrah | Lapisan Home dan akses aplikasi yang menghubungkan modul tersebut. |

## 4. Kebutuhan fungsional

### Niat dan kejelasan

**FR-01 — Tujuan milik user.** User dapat membuat, mengedit, mengarsipkan dan memilih cue Goal. Habit/Task dapat terhubung ke Goal; hubungan opsional. Kosong tetap boleh. Mengarsipkan Goal tidak menghapus bukti pelaksanaan.

**FR-02 — Tindakan fisik yang jelas.** Habit/Task dapat menyimpan petunjuk singkat seperti “Buka laptop”. Home memakai teks milik user dan menyediakan aksi yang benar-benar dapat app lakukan, misalnya “Mulai fokus”.

**FR-03 — Status sekarang tunggal.** Home, dial, habits dan tampilan sesi membaca sesi aktif yang sama. Sesi paused terlihat sebagai paused, tidak digantikan rekomendasi baru. Agenda berlabel “Terjadwal”; app tidak menganggap user benar-benar melakukannya tanpa sesi/check-in.

**FR-04 — Pilihan berikutnya yang dapat dikuasai.** User dapat memilih/pin tindakan untuk Hari Ini dan menggantinya. Pilihan tindakan disimpan per tanggal dan referensi habit/task, terpisah dari Goal utama; setelah restart pilihannya tetap ada. Default cue: sesi aktif/paused, pilihan user yang belum selesai, blok terjadwal saat ini, lalu blok berikutnya. Bila tidak ada, tawarkan memilih habit/tindakan. App tidak mengarang prioritas atau moral score.

**FR-04a — Pendamping tujuan opsional.** User dapat bercerita dengan bahasanya sendiri atau menjawab pertanyaan singkat seperti “Apa tujuanmu?” Pendamping memahami tujuan, batas waktu, komitmen yang sudah ada, waktu luang, kebutuhan istirahat, dan tindakan berulang; ia bertanya hanya untuk informasi yang memang mengubah rencana. Untuk contoh “menang LKS nasional IT Software Solution”, pendamping membantu mengurai kesiapan dan mengusulkan jadwal harian yang dapat disesuaikan. Rencana selalu berupa pratinjau yang dapat diedit dan disetujui user sebelum mengubah jadwal/habit. **Chat bersifat sementara di memori proses: jangan menyimpan transkrip ke database, preferences, backup atau backend app; setelah proses app ditutup, chat tidak dipulihkan.** Tujuan/rencana yang user setujui adalah data produk terpisah. Saat provider eksternal digunakan, teks dan konteks yang diperlukan dikirim ke endpoint pilihan user; retensi di layanan provider mengikuti kebijakan provider tersebut. User boleh melewati AI dan menyusun manual. Ketiadaan model, jaringan atau API key tidak menghalangi Focus Clock inti.

**FR-04b — Tidak terikat vendor/model.** Percakapan dan proposal memakai kontrak domain terstruktur yang sama untuk setiap provider. Identitas/gaya model tidak mengubah data, hak aksi atau validasi. Model tidak boleh membuat blok langsung, menandai kegiatan selesai, atau menganggap jadwal sebagai tindakan terlaksana tanpa persetujuan/aksi user. Ketika provider gagal atau jawaban tidak valid, rencana yang sudah ada tetap utuh dan user mendapat jalur manual.

### Habits dan tindakan

**FR-05 — Habit dekat di Home.** Home menampilkan habit yang occurrence-nya berlaku hari ini atau sudah mempunyai bukti hari ini, mengikuti urutan yang dipilih user. Yang selesai/dilewati tetap terlihat dan tidak melompat urutan setelah tap. Daftar dapat scroll; akses “Semua” membuka Habits dengan seluruh daftar dan riwayat. Pada lebar 320 dp/teks besar, row membungkus dan scroll, bukan menyusut atau hilang. Detail progression/hybrid dibuka sesuai kebutuhan; habit tidak disembunyikan sebagai fitur sekunder yang sulit dicapai.

**FR-06 — Pencatatan sesuai jenis target.** User dapat mencatat biner, jumlah atau durasi dengan unit yang jelas. Timer tidak mengubah target hitungan menjadi menit. Progression/hybrid menampilkan langkah aktif, rest dan unit sebenarnya; handler yang belum mendukungnya tidak boleh menawarkan Play yang menyesatkan.

**FR-07 — Status yang jujur.** User dapat menandai selesai, belum dilakukan, dilewati atau menghapus tanda. Sesi parsial menyimpan progres parsial. Penghentian timer tidak otomatis menyatakan target habit terpenuhi. Edit/correction mempertahankan asal manual atau terukur.

**FR-08 — Riwayat tanpa hukuman.** User melihat hari dan jumlah/durasi yang dicatat. Ringkasan memasukkan habit yang memang berlaku pada tanggal itu; arsip atau perubahan target hari ini tidak menulis ulang masa lalu. Skip/rest tidak memutus “nilai diri”; tanpa badge, ranking, atau penalti streak.

**FR-09 — Inbox dan catatan.** User dapat menangkap Task atau Note tanpa mengisi jadwal. Menjadwalkan Task mempertahankan identitas Task tersebut. Daily note dan refleksi tersimpan; app menampilkan keadaan menyimpan, tersimpan atau gagal bila relevan.

### Visualisasi waktu dan pelaksanaan

**FR-10 — Dial tetap inti.** Pertahankan dial analog Flutter yang sudah dipilih. Blok waktu, jarum sekarang dan AM/PM/24 jam memiliki arti konsisten. Daftar tekstual menyediakan informasi dan aksi yang setara untuk pembaca layar atau user yang lebih nyaman dengan daftar.

**FR-11 — Jadwal dapat dipercaya.** User membuat, mengedit, memindahkan dan menghapus blok melalui dial atau editor. Semua layar segera membaca hasil penyimpanan yang sama. Batas siang/malam dan tengah malam tidak menghasilkan blok nol menit. Bentrok punya pilihan perbaikan yang jelas; kejadian berulang dapat diedit satu occurrence atau seri.

**FR-12 — Satu sesi aktif per ruang kerja lokal.** Memulai sesi dari habit, task, blok, Home atau shortcut mempunyai hasil yang sama. Double tap tidak membuat dua sesi. Jika sesi lain aktif, user melihat sesi tersebut dan dapat melanjutkan atau mengakhirinya sebelum mulai baru.

**FR-13 — Pause, lanjut, akhir dan pemulihan.** Selama background/sleep atau penghentian proses, reopen memulihkan durasi dari catatan waktu, bukan jumlah tick. “Akhiri sesi” menyimpan waktu aktual. App membedakan selesai target, berhenti lebih awal, dibatalkan dan membutuhkan rekonsiliasi waktu.

**FR-14 — Bukti pelaksanaan.** Sesi menyimpan Goal/Habit/Task/Blok yang terkait beserta snapshot judul dan target. Selesai dua kali hanya menambah satu kontribusi. Sesi berbeda dalam satu hari dapat dijumlahkan; check-in manual tetap dapat dikoreksi tanpa menghapus sesi.

**FR-15 — Pengingat opsional.** User dapat melihat status notifikasi/pengingat, mengaktifkannya melalui izin sistem, dan tetap memakai inti app saat izin ditolak. Force stop, reboot, alarm tidak tepat dan keterbatasan browser dijelaskan ketika memengaruhi fitur. Full-screen/lock-screen intrusive presentation bukan default.

### Fitrah dan konteks hidup

**FR-16 — Launcher asli.** Pada Android, user dapat mencari/membuka aplikasi terpasang, memilih favorit, mengubah urutannya, dan membuka app info. Kegagalan punya feedback dan retry; app contoh hanya ada dalam demo. Favorit bertahan setelah restart. Pemilihan default Home melalui UI Android dan diverifikasi kembali.

**FR-17 — Mengakses modul tanpa kehilangan konteks.** User dapat melihat Hari Ini, jadwal, riwayat habit dan aplikasi sambil sesi tetap berjalan. Back menutup sheet/keyboard terlebih dahulu, lalu kembali ke Home. Gesture memiliki padanan kontrol yang terlihat.

**FR-18 — Waktu salat dan istirahat.** Tampilkan waktu salat hanya dengan sumber yang jujur: manual atau provider/lokasi yang kelak dipilih user. Jadwal bawaan tidak boleh tampak sebagai waktu lokal akurat. Istirahat dapat direncanakan/dicatat; tidak diberi framing gagal produktif.

**FR-19 — Refleksi pribadi.** User dapat menulis refleksi akhir hari dan melihat buktinya. Pertanyaan boleh dilewati. App tidak memberi penilaian agama atau mengasumsikan selesai ibadah dari jam/notifikasi.

### Data dan ekosistem

**FR-20 — Penyimpanan dan backup.** Create/update/complete hanya dianggap tersimpan setelah durable commit. User dapat mengekspor data dengan versi schema dan mengimpor melalui preview, validasi dan deteksi duplikasi. Kegagalan DB tidak mengganti data nyata dengan mode memory yang tampak normal.

**FR-21 — Companion yang jujur.** Web/desktop menyediakan tujuan, habits, jadwal dan sesi yang didukung. Aksi Android-only disembunyikan atau diterangkan di konteks platform; tidak ada launch success palsu. Core offline dibuktikan setelah instalasi/cache awal yang diperlukan platform.

**FR-22 — Sinkronisasi bertahap.** Kelak user dapat menghubungkan perangkat secara eksplisit; app menunjukkan lokal, menunggu sinkron, terhubung atau konflik. Perangkat offline tetap dapat mencatat kegiatan. Dua sesi offline yang bertumpuk tetap dipertahankan sampai user merekonsiliasi; sinkron tidak menghapus bukti untuk menjaga ilusi satu sesi.

## 5. Kualitas dan kriteria penerimaan

Nilai berikut adalah **[ASSUMPTION A2] target evaluasi usulan**, bukan hasil pengukuran app sekarang.

| ID | Target dan cara memeriksa |
|---|---|
| NFR-01 | Inti berjalan tanpa akun/AI/network setelah setup platform. Mode pesawat: buat habit, jadwalkan, mulai/pause/akhir sesi, buka ulang dan lihat riwayat. |
| NFR-02 | Dari Home yang sudah terisi, sesi pilihan user mulai dalam satu tap; pilihan tanpa cue memerlukan maksimal membuka satu daftar dan memilih. Mengedit atau meminta izin sistem tidak masuk metrik start rutin. |
| NFR-03 | Fahim dapat menyebut tujuan, status sekarang dan tindakan pilihan dalam sekitar lima detik pada uji glance; target dinilai observasi, bukan klaim “nol deciding fatigue”. |
| NFR-04 | Tidak ada tambahan kredit durasi akibat background, callback ganda atau berhenti cepat. Durasi internal integer detik; pembulatan tampilan tidak menambah bukti. |
| NFR-05 | Ukuran interaksi Android minimal 48 dp; teks 200%, lebar 320 dp, TalkBack, keyboard dan landscape mempunyai alur yang bisa diselesaikan. |
| NFR-06 | Teks biasa kontras minimal 4.5:1, ikon penting/teks besar 3:1; status punya label/shape selain warna. Motion mengikuti preferensi sistem. |
| NFR-07 | Target cold start interaktif p95 ≤2 detik, warm resume ≤500 ms pada perangkat acuan yang direkam E0. Pengukuran release/profile dengan dataset realistis; bila gagal, optimasi bukan menghapus state gagal. |
| NFR-08 | Upgrade dan backup round-trip mempertahankan ID, status, target snapshot serta total durasi; jumlah kehilangan/duplikasi pada fixture yang disepakati harus nol. |

Keberhasilan pemakaian: Fahim memakai build pribadi setidaknya tujuh hari, membuat/melanjutkan sesi dan mencatat habits miliknya tanpa kembali ke mock/rekonstruksi data. Ukur juga keluhan, aksi yang membingungkan dan kebutuhan membuka settings. Durasi menatap app, jumlah notifikasi dan panjang streak bukan sasaran keberhasilan.

## 6. Scope build pertama dan arah lanjutan

**Pilot pertama yang sudah bisa dipakai (U0):** sesudah E3a, satu Goal cue dan TodaySelection yang tersimpan, habit timed/binary milik Fahim, satu sesi tahan restart dengan actual duration, dial/jadwal membaca sumber yang sama, dan backup. Pilot memakai UI existing yang diperbaiki secukupnya. Pengelolaan jenis habit lain yang belum tersambung diberi status dukungan jujur; data existing tetap bisa dibaca/ekspor dan tidak dikonversi. Ini checkpoint pemakaian, belum pengganti launcher harian yang sudah lulus E6.

**Rilis pribadi lengkap (E6):** FR-01 sampai FR-20 untuk Android dengan satu jalur data, dial terpilih, jenis habit existing, inbox/catatan, akses aplikasi, reminder/recovery sesuai capability dan backup. E3b menyelesaikan compatibility yang tersisa sebelum rilis ini. E3 tidak boleh mengganti jenis lama menjadi timed atau membuang datanya.

**Companion berikutnya:** FR-21 setelah storage web lulus. Riwayat/fitur yang belum setara harus ditandai pada matriks kemampuan. FR-22 menyusul sebagai pekerjaan ekosistem tersendiri.

**AI pendamping (tahap sesudah loop core dapat dipercaya):** percakapan curhat → tujuan → rencana yang disetujui → jadwal/habit → cue Home → sesi dan bukti. FR-04a/04b adalah kebutuhan produk; pelaksanaan provider menunggu kontrak Today/Goal/Schedule/session dan jalur mutasi durable agar AI tidak menulis ke model lokal yang berbeda. Model/provider bersifat dapat diganti dan BYOK opsional. Google Calendar sync, floating window desktop, app blocking, IoT fisik dan pemisahan tiga APK tetap ditunda. Data/konfigurasi lama dipertahankan saat migrasi; fitur lama yang belum didukung mempunyai jalur baca/ekspor yang jujur.

**Arah ekosistem yang pemilik minta:** setelah core harian nyaman, AI agent di aplikasi memakai key/provider pilihan user; kemudian integrasi WhatsApp dan MCP agar Focus Clock dapat dihubungkan ke tools lain; lalu source dirapikan sebagai open source dengan lisensi dan distribusi yang benar. Ini bukan syarat agar offline Focus Clock berfungsi. Setiap integrasi mengikuti kontrak proposal/approval FR-04b; detail auth, scope data, transport dan biaya diselesaikan dalam milestone masing-masing sebelum implementasi.

## 7. Asumsi dan keputusan pemilik

| ID | Usulan/ketidakpastian | Pemilik keputusan dan pemicu |
|---|---|---|
| A1 | Android satu app utama dalam repo Fitrah | Fahim, sebelum E0 mengunci build/distribusi |
| A2 | Anggaran interaksi/performa di §5 | Fahim + builder, kalibrasi perangkat E0 dan evaluasi E4/E6 |
| A3 | Home menampilkan dial + status + habits, tampilan detail tersedia | Fahim, review mockup sebelum E4 |
| A4 | Energy tag manual opsional, tanpa inference energi otomatis | Fahim, setelah kebutuhan core terpenuhi; tidak memblokir E0–E6 |
| A5 | Nama rilis tetap Fitrah Launcher sementara; Focus Clock nama ekosistem | Fahim, sebelum release publik; jangan ganti applicationId karena nama tampilan |
| A6 | Firebase dipilih untuk sinkronisasi lintas perangkat; login opsional dan sync opt-in | Fahim, 25 Nov 2026. Implementasi E8 tetap menunggu security rules, data contract, outbox/merge, dan consent flow. |

Asumsi adalah rancangan untuk ditinjau; tidak boleh diberi status owner-approved oleh agent berikutnya tanpa keputusan pemilik.
