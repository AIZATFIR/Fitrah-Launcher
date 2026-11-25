---
name: Focus Clock ecosystem experience
status: draft-for-owner-review
created: 2026-11-03
updated: 2026-11-23
sources:
  - PRD.md
  - DESIGN.md
---

# Rancangan pengalaman

## Foundation

Satu aplikasi Android dengan Focus Clock, Sadar dan Fitrah sebagai modul. User boleh mulai sebagai companion biasa. Menjadi default launcher adalah pilihan terpisah yang dibantu sistem Android. Web/desktop mendapat domain core ketika persistence dan capability-nya siap.

PRD menetapkan kebutuhan, DESIGN menetapkan tampilan, dokumen ini mengikat interaksi. Semua layout baru di sini adalah usulan A3 sampai pemilik meninjau contoh visual. {colors.on-surface} dan {typography.body} merujuk token DESIGN.

## Information Architecture

| Surface | Cara masuk | Tugas dan batas |
|---|---|---|
| Hari Ini | Home/app open, tombol Home Android | Goal cue, actual session atau agenda berlabel, dial ringkas, habit relevan hari ini, capture singkat |
| Jadwal | Destination Jadwal atau dial Home | Dial penuh yang dipertahankan, AM/PM/24h, daftar agenda, create/edit blocks, presets/routines melalui aksi kontekstual |
| Habits | Destination Habits atau “Semua” pada Home | Semua habit, check-in, minggu/riwayat, edit/arsip, progression/hybrid sesuai unit |
| Aplikasi | Destination Aplikasi; swipe up opsional | Favorit dan search app Android; unavailable state di platform lain |
| Sesi fokus | Start/resume atau session summary | Judul, sumber habit/task, actual/remaining, pause/resume/end; full-screen opsional |
| Goal detail | Goal cue atau item terkait | Ubah tujuan, petunjuk tindakan dan hubungan habit/task; arsip tanpa menghapus history |
| Pendamping tujuan | Tombol “Bantu susun rencana” dari Goal/Hari Ini | Mendengar cerita, merangkum maksud, meminta detail yang perlu, lalu menampilkan proposal yang bisa diedit; tidak menulis jadwal sebelum disetujui |
| Inbox & catatan | “Catat sesuatu”, lalu lihat inbox | Tangkap Task/Note, jadwalkan existing item, cari/edit; ringkas di Home, bukan editor besar permanen |
| Reflection/history detail | Habits/history, akhir hari opsional | Bukti periode, catatan pribadi; tanpa kuis wajib sebelum app bisa dipakai |
| Settings & data | Satu tombol Settings berlabel | Appearance, Home role, notifikasi, sumber salat, backup/import, status storage/sync |

Main destinations tetap sama ketika navigation bar menjadi rail. Swipe ke destination adalah shortcut dengan tombol padanan. Menambah menu lain memerlukan tugas yang tidak dapat dipenuhi daftar ini.

Home tidak menjadi daftar semua fitur. Habits dengan occurrence yang berlaku hari ini atau bukti hari ini tetap terlihat dan dapat ditandai di sana; daftar detail, pengelolaan target dan history mendapat ruang sendiri. Urutan habit mengikuti pilihan user; yang selesai/skip tidak melompat posisi. Seluruh daftar dapat scroll; jangan menyembunyikan habit karena sudah ada tiga row. Akses “Semua” membuka pengelolaan/riwayat dan habits yang tidak terjadwal hari ini.

## Voice and Tone

Bahasa awal Indonesia yang lugas, mengikuti gaya isi user. Penggantian bahasa menu tidak mengubah catatan user. Kata “Fokus” berarti sesi yang dipilih, bukan penilaian bahwa semua aktivitas lain buruk.

| Keadaan | Copy usulan |
|---|---|
| Goal kosong | “Apa yang ingin kamu ingat?” + “Tulis tujuan” |
| Habit belum disentuh | “Belum tercatat hari ini” |
| Sesi aktif | “Sedang fokus · LKS” |
| Jadwal saat ini, belum ada sesi | “Terjadwal sekarang · LKS” |
| Paused | “Dijeda · LKS” + “Lanjutkan” |
| Berhenti awal | “Tercatat 8 menit” dengan asal “timer”; tidak “45 menit selesai” |
| Izin ditolak | “Pengingat belum aktif” + “Atur pengingat”; app tetap dapat dipakai |
| Save gagal | “Belum tersimpan. Coba lagi.” draft tetap terlihat |
| Salat manual | “Waktu salat manual” dan akses ubah sumber/jam |
| Refleksi | “Apa yang terasa berarti hari ini?”; user boleh menggantinya dengan prompt pribadi |

**Ruang untuk berpikir:** Kolom tujuan, niat, jurnal, refleksi, kebiasaan dan catatan dimulai kosong. Jangan taruh contoh jawaban, prompt panjang atau sample pilihan di dalam maupun tepat di bawahnya. Saat mengedit, isi yang memang ditulis user tetap tampil. Pakai satu label singkat bila fungsi kolom belum jelas; bantuan tambahan hanya muncul saat diperlukan untuk melanjutkan.

Hindari teguran “kamu malas”, urgensi merah untuk habit terlewat, claim energi akurat, dan skor agama. Pengingat mengikuti jadwal serta izin user, bukan jam yang agent anggap ideal.

## Component Patterns

**Goal cue:** satu pinned Goal di Home; Goal lain tetap dapat dibuka. Tidak ada wizard wajib untuk tiap pagi. Mengganti pin memperbarui cue, tidak memutus riwayat habit.

**Pendamping tujuan (tahap berikutnya):** mulai dari cerita bebas atau “Apa tujuanmu?”, misalnya “menang LKS nasional IT Software Solution”. Pendamping memantulkan pemahamannya dalam satu ringkasan yang mudah dikoreksi, lalu bertanya seperlunya tentang tenggat, kondisi saat ini, sekolah/komitmen, waktu yang tersedia dan istirahat. Ia memberi satu draft rencana yang realistis beserta alasan singkat dan pilihan ubah; hanya “Terapkan rencana” membuat perubahan durable. Provider dapat diganti tanpa mengubah alur atau kontrak data. Jika AI gagal, draft lokal/entry manual tetap dapat dipakai. Tidak menjanjikan kemenangan dan tidak menyamakan identitas dengan satu hasil lomba: tujuan adalah arah yang dipilih user, kebiasaan adalah keputusan/tindakan berulang, hasil akhir tetap tidak dijamin.

**Now/next:** active session mendahului semua cue, termasuk paused. Sesudahnya TodaySelection yang belum selesai, agenda saat ini dan agenda berikutnya. TodaySelection disimpan per tanggal, berbeda dari pinned Goal; pilihan bertahan saat restart dan dapat diganti. Jika belum ada pilihan, daftar habit menunggu aksi user; app tidak menunjuk habit secara moral/AI. “Berikutnya” adalah agenda atau pilihan berlabel sumber, bukan perintah.

**Habit row:** satu aksi utama menurut jenis. Timed → Mulai/Lanjutkan; binary → Tandai; count → Catat jumlah; progression/hybrid → buka langkah yang relevan dengan kontrol unit. Setiap row membuka detail/history. Undo/check-in edit tetap tersedia melalui detail setelah snackbar hilang.

**Dial:** tap block membuka detail, edit memakai data yang sama dengan Home. Drag mempunyai preview rentang dan Save/Cancel atau undo yang jelas. List view menyediakan create/edit identik. Tampilkan rencana berbeda dari actual sessions secara label/pola; jangan melapiskan terlalu banyak lapisan warna.

**Session:** satu state global, satu session summary yang dapat diakses dari tiap destination. Start tidak memunculkan dua timer. Bila user menekan habit lain, tampilkan sesi saat ini dan pilihan kembali/akhiri; jangan pause/replace diam-diam. End session menampilkan actual recorded time, dengan opsi koreksi terpisah bila dibutuhkan.

**Capture:** satu input ringkas memilih Task/Note. Save ke storage dulu, lalu feedback. Membuka scheduling dari inbox membawa ID Task asli; tidak membuat judul duplikat dalam model lokal.

## State Patterns

| State | Perilaku yang harus dipenuhi |
|---|---|
| First run | Home langsung berguna dengan kosong yang jujur; “Tulis tujuan”/“Tambah habit” tersedia. Minta izin saat fungsi terkait dipakai. Tidak seed persona tidur/programmer/salat seolah dipilih. |
| Loading storage | Tampilkan persiapan singkat; jangan mengganti user content dengan sample data. Waktu nyata boleh tampil dengan data status loading yang jelas. |
| Storage recovery | Tampilkan masalah dan retry/backup yang tersedia. Jangan memberi sukses save palsu atau reset otomatis. Draft yang sedang diketik tetap dapat disalin/ekspor. |
| No Goal | Daftar habits/jadwal tetap berfungsi; cue mengundang menulis, tidak memblokir. |
| No habit today | “Belum ada kebiasaan untuk hari ini”; akses tambah/lihat semua; bukan score 0% merah. |
| Offline | Operasi lokal tetap tersimpan. Status cloud, bila E8 ada, menyebut menunggu sinkron; tanpa modal global yang menghalangi kerja. |
| Write busy | Aksi yang sama menunggu hasil, idempotency guard melindungi double tap; layar lain tetap dapat dibaca. |
| Write failed | Pulihkan kontrol, tunjukkan retry dengan input yang sama; tidak hilangkan draft/modal. |
| Session recovered | State dan durasi yang dapat dipercaya muncul; command notification memakai session ID/revision yang sama. |
| Clock/reboot uncertain | Tampilkan “Periksa catatan sesi”; pertahankan checkpoint dan tawarkan review waktu, bukan kredit penuh otomatis. |
| Target reached | Simpan actual dan target snapshot. Timed fulfillment diturunkan dari bukti; count/progression memerlukan catatan unit sebenarnya. |
| New local day | Home berganti Hari Ini, history terpilih tetap history. Sesi tengah malam tetap memiliki tanggal mulai. Tidak menghapus progress sesi atau check-in kemarin. |
| Missing installed app | Favorit ditandai tidak tersedia dengan hapus/pilih lagi. Launch failure terlihat dan daftar dapat refresh ketika kembali ke app. |
| Unsupported capability | Jangan tampilkan aksi seolah sukses. Web Aplikasi menjelaskan Android-only; companion navigation core tetap ada. |
| Import conflict | Preview jumlah item, konflik dan perubahan, dengan Cancel; data lama tetap ada sampai commit berhasil. |

## Interaction Primitives

- Tap memanggil satu command dengan operation ID; success datang dari durable commit. Haptic tidak dipakai sebagai bukti save.
- Back/Escape: tutup keyboard atau top sheet dahulu; kembali dari detail/sesi ke destination sebelumnya; Back dari destination lain kembali Home. Default Home tidak keluar ke desktop lain tanpa aksi yang jelas.
- Long press dapat membuka app options atau context menu; aksi penting juga tersedia lewat kontrol berlabel.
- Tidak ada modal bertingkat. Editor panjang boleh full-screen; Save/Cancel terlihat, keyboard tidak menutup tombol terakhir.
- Hanya bagian angka/session yang membutuhkan tick yang refresh setiap detik. Daftar habit tidak pindah, berkedip atau rebuild dekorasi karena tick.
- Motion singkat menjelaskan perpindahan; reduced motion menghilangkan animasi nonesensial. Peringatan tidak bergantung bunyi atau getaran saja.

## Accessibility Floor

- Android target sentuh minimal 48×48 dp. Grid harian yang padat menyediakan tombol buka detail/list setara, tidak memaksa tap kotak mikro.
- Hormati font 200% dan preferensi motion. Di ukuran besar, tambah tinggi row, wrap labels dan scroll; jangan mengorbankan aksi Save atau Home.
- `Semantics` menyebut nama habit, tanggal, status, unit dan aksi. Pembaca layar tidak mendapat seluruh ticker diumumkan setiap detik.
- Dial punya ringkasan dan daftar agenda operable yang setara; drag bukan satu-satunya cara mengatur waktu.
- Contrast dan focus mengikuti DESIGN; desktop/web keyboard dapat mencapai semua aksi, dengan focus visible dan urutan baca yang masuk akal.

## Responsive & Platform

Android menjadi perangkat validasi utama. Pengaturan default Home, app launch dan notifikasi memakai jalur sistem; keputusan izin tidak dipalsukan. Hormati system bars/cutout/gesture insets dan keyboard.

Web/desktop mempertahankan goals, habits, schedule dan ledger, memakai capability untuk menyesuaikan fitur OS. Wide layout memperlihatkan dial dan habits berdampingan; tidak memperpanjang satu kolom sampai teks sulit dibaca. Companion yang belum terhubung menampilkan “Data di perangkat ini”, bukan “sinkron”.

Home widget/ongoing notification adalah permukaan ringkas sesudah local core stabil. Teks privacy-sensitive pada lock screen mengikuti pilihan user dan pengaturan sistem; visual cue lock screen tidak mensyaratkan app mengambil alih layar kunci.

## Key Flows

**UJ-1, jam kosong:** Fahim membuka Home → melihat Goal dan habit LKS → memilih Mulai → command membuat durable session → state running terlihat dan tersedia dari Jadwal/Habits. Petunjuk “Buka laptop” tetap teks user; belum ada otomasi laptop yang diasumsikan.

**UJ-2, sambung sesi:** dari notifikasi atau app open, Fahim melihat session ID yang sama → pause → app ditutup → buka lagi → paused tetap paused → resume → end lebih awal → actual tercatat sekali, habit menunjukkan bukti parsial.

**UJ-3, tenaga rendah:** Fahim membuka daftar habits → memilih tindakan kecil/istirahat atau melewati occurrence → app menyimpan status tanpa warning moral. Goal tetap terlihat; app tidak menebak energi dari jam atau kegiatan terakhir.

**UJ-4, tindakan tanpa timer:** Fahim memilih Catat pada habit → melihat target/unit serta catatan yang sudah ada → memasukkan jumlah/tanda manual → commit → status manual terlihat. Minutes tidak dibuat dari target jika ia hanya menandai binary done.

**UJ-5, merencanakan:** Fahim tap/drag dial atau buka form → memilih habit/task existing opsional → preview rentang/bentrok → Save → Home/Jadwal membaca blok yang sama → durasi aktual baru tercatat ketika sesi dilakukan.

**UJ-6, tutup hari:** Fahim membuka Habits/history → melihat bukti measured/manual/skip → menulis refleksi jika ingin → state Tersimpan → reopen menunjukkan data sama. Perubahan target besok tidak menulis ulang angka hari ini.

**UJ-7, companion masa depan:** Fahim menghubungkan perangkat → melihat status sinkron → laptop meminta handoff session online → HP melepaskan ownership dan server mengakui revision baru → laptop dapat melanjutkan. Bila offline, laptop tidak mengaku mengontrol timer HP; sesi baru lokal ditandai untuk rekonsiliasi bila overlap.

**UJ-8, cerita menjadi rencana:** user menulis “Aku ingin menang LKS nasional IT Software Solution, tapi sekolah dan tugas lain juga banyak” → pendamping merangkum tujuan dan menanyakan hanya tenggat/kondisi yang belum diketahui → user mengoreksi → pendamping menunjukkan draft latihan, sekolah, istirahat, dan ruang fleksibel → user mengedit/menyetujui → Home menampilkan tujuan serta satu langkah berikut → user menjalankan sesi → bukti waktu nyata tersimpan. Tidak ada perubahan jadwal sebelum persetujuan.

## Lingkup referensi visual

Home/dial/habits serta status idle/running/paused/empty dirujuk [mockups/today.html](mockups/today.html). Mockup adalah data contoh lokal, tidak menguji storage atau Flutter. Aplikasi drawer, editor, data recovery, import, reflection dan settings masih berupa kontrak perilaku dalam dokumen ini; buat screenshot referensi slice terkait sebelum implementasi UI-nya disetujui.
