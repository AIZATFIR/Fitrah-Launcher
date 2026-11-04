---
name: Focus Clock ecosystem
description: Usulan visual Flutter Android yang mengutamakan isi pengguna, dial waktu dan kebiasaan.
status: owner-approved-hierarchy-preserve-existing-palette-and-clockface
created: 2026-11-03
updated: 2026-11-03
colors:
  source: LauncherSettings.themePalette and existing Focus Clock palette definitions
  preserve: [fino_green, sky_blue, ocean_blue, full_book]
  bookpaper: Warm Bookpaper (Amber Obsidian)
  clockface: Reuse existing AnalogClockFace and its selected warm journal theme
typography:
  goal:
    fontFamily: Inter
    fontSize: 24sp
    fontWeight: 500
    lineHeight: 1.3
  title:
    fontFamily: Inter
    fontSize: 20sp
    fontWeight: 500
    lineHeight: 1.35
  body:
    fontFamily: Inter
    fontSize: 16sp
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: Inter
    fontSize: 14sp
    fontWeight: 500
    lineHeight: 1.4
  time:
    fontFamily: Inter
    fontSize: 32sp
    fontWeight: 400
    lineHeight: 1.2
rounded:
  sm: 8dp
  md: 12dp
  lg: 20dp
spacing:
  unit: 4dp
  page: 20dp
  group: 24dp
  row: 12dp
components:
  goal-cue:
    foreground: '{colors.on-surface}'
    typography: '{typography.goal}'
  active-session:
    background: '{colors.surface-container}'
    foreground: '{colors.on-surface}'
    radius: '{rounded.md}'
  primary-action:
    background: '{colors.primary}'
    foreground: '{colors.on-primary}'
    radius: '{rounded.md}'
---

## Brand & Style

Hierarki Home pada mockup telah disetujui pemilik. Pertahankan pilihan palet Focus Clock yang ada, termasuk Warm Bookpaper/Amber Obsidian, serta analog clock face dan tema Warm Journal/Parchment. Mockup menentukan susunan isi, bukan pengganti identitas warna atau dial. Pemilik memilih pengalaman yang terasa tenang, jelas dan mudah dikuasai. “Low cortisol” dipakai sebagai bahasa preferensi, bukan klaim kesehatan.

Yang khas: arah hidup, peta waktu lingkaran dan bukti kebiasaan terlihat sebagai satu hubungan. Jangan menyamarkan produk sebagai kumpulan dashboard cards. Habits mempunyai tempat di Home dan destination utamanya sendiri.

Material 3 menjadi dasar komponen/interaksi Android. Apple Design dipakai untuk purpose, hierarchy, accessibility dan craft; tidak meniru navigasi iOS atau Liquid Glass pada launcher Android. Referensi lokal yang dipakai: `apple-design/references/hig/design-principles.md` bagian Simplicity dan `layout.md` bagian Visual hierarchy; cross-platform memakai `Semantics`, `TextScaler` dan Android touch targets.

## Colors

Palet aktif mengikuti `LauncherSettings.themePalette`; pilihan yang ada dipertahankan, termasuk sage, sky blue, ocean blue, dan full book. `full_book` memakai clockface theme 7 (Pastel Book/Warm Journal), agar pilihan bookpaper menampilkan dial yang dipilih untuk tema itu. Jangan menimpa pilihan ini dengan satu skema sage global. Periksa kontras pada setiap kombinasi palet dan wallpaper sebelum mengklaim aksesibilitas.

Accent dipakai untuk aksi utama dan state aktif. Status selesai, dilewati dan paused mempunyai label serta ikon/pola. Error dipakai untuk kesalahan teknis yang membutuhkan pemulihan; habit yang belum dilakukan tidak berwarna error.

## Typography

Pertahankan tipografi dan jarak yang sudah terasa nyaman pada Focus Clock. Inter yang sudah dipakai tetap menjadi baseline UI sekarang; gunakan ruang, ukuran teks dan hierarki seperti referensi bacaan Quran.com sebagai inspirasi readability, bukan menyalin tampilan/brand. Jangan menambah font display atau menunggu Google Fonts network saat startup.

Pakai role frontmatter untuk user content. Judul Goal dapat membungkus; judul Habit dua baris atau lebih sesuai ruang. Hindari semua huruf kapital untuk isi panjang, kata yang terlalu rapat, dan teks 10–11 sp sebagai pembawa informasi inti. Angka durasi memakai tabular figures, tanpa tick animation yang membuat seluruh layar bergerak.

Clock numerals adalah bagian komponen custom, namun informasi waktunya juga tersedia dalam teks accessible. `TextScaler` sistem tidak diblokir; jangan membungkus seluruh layar dengan scale paksa 1.0 atau mengecilkan teks agar muat.

## Layout & Spacing

Komposisi Home berikut adalah hierarki yang disetujui pemilik. Ukuran dial Home menyesuaikan tinggi layar; dial penuh tetap ada di Jadwal. Pada teks besar, konten dapat scroll dan dial mengecil melalui layout, bukan mengecilkan font.

```text
Compact Android
┌───────────────────────────────────┐
│ Selasa, 3 November        Settings │
│ Tujuan: teks milik user            │
│                                   │
│ [dial ringkas]  Status sekarang    │
│                tindakan/petunjuk  │
│                [Mulai/Lanjutkan]  │
│ Berikutnya: agenda yang sebenarnya │
│                                   │
│ Kebiasaan hari ini        [Semua]  │
│ Nama habit         bukti  [aksi]   │
│ Nama habit         bukti  [aksi]   │
│ Nama habit         bukti  [aksi]   │
│ [Catat sesuatu]                    │
│                                   │
│ Hari Ini | Jadwal | Habits | Apps  │
└───────────────────────────────────┘

Regular companion
┌───────┬─────────────────────────┬─────────────────────┐
│ Nav   │ Tujuan dan status sesi   │ Habits hari ini     │
│ rail  │ Dial / agenda terpilih   │ bukti dan aksi      │
│       │ Aksi mulai/lanjut/akhir  │ Detail bila dipilih │
└───────┴─────────────────────────┴─────────────────────┘
```

Android Home tidak mempunyai lima tombol besar di sisi kiri dan lima di kanan dial. Satu ikon berlabel mengakses tampilan jadwal; cari, tema dan mode jam masuk tempat sesuai konteks. Waktu salat opsional tampil satu ringkasan yang dapat dibuka, bukan lima tile padat yang selalu mengambil header.

Padding 20 dp dan skala 4 dp adalah pilihan proyek. Layout berdasarkan available width/height, system insets dan keyboard, bukan nama perangkat. Di bawah 600 dp satu kolom; mulai 600 dp layout boleh memakai rail jika masih terbaca; dua pane hanya saat kontennya mendapat ruang cukup, usulan mulai 840 dp. Breakpoint ini seed yang harus dicek pada 320 dp, landscape dan resize, bukan klaim semua tablet sama.

## Elevation & Depth

Gunakan ruang dan alignment sebagai grouping utama. Kartu tonal hanya untuk status sesi atau input yang benar-benar membutuhkan batas. Daftar habits berupa rows; jangan setiap row menjadi kartu besar bershadow. Satu modal sheet pada satu waktu; jangan menumpuk form dalam form.

Wallpaper, blur dan gradient bukan fondasi keterbacaan. Solid surface tetap lengkap ketika efek dimatikan.

## Shapes

Radius mengikuti fungsi: input/aksi 12 dp, sheet 20 dp, bentuk lingkaran untuk dial dan kontrol yang memang bulat. Bentuk pill untuk status singkat atau selector; jangan menjadikan semua tombol dan container pill.

## Components

| Komponen | Bentuk Flutter dan isi utama |
|---|---|
| Goal cue | Teks langsung di Home; `InkWell`/button berlabel “Ubah tujuan” untuk edit, tanpa quote dekoratif |
| Dial | Reuse `AnalogClockFace`; tanda sekarang, blok, interval dan caption; `Semantics` ringkasan + daftar alternatif |
| Session summary | `surface-container`, judul, state dan waktu; satu primary `FilledButton`, pause/end sebagai aksi konteks |
| Habit row | Judul, target/unit, actual/manual state, satu aksi sesuai jenis; detail lewat row; target sentuh minimal 48 dp |
| Habit history | Grid sekunder di Habits; hari/status punya label; tidak bergantung warna saja; akses daftar untuk teks besar |
| Main navigation | `NavigationBar` compact dan `NavigationRail` bila lebar cukup; label Hari Ini, Jadwal, Habits, Aplikasi |
| Editor | `TextFormField`, unit selector, validasi inline; save state terlihat; destructive action terpisah |
| Drawer aplikasi | `SearchBar`, list dengan label/app icon aktual, favorit berurutan; error/retry mempunyai ruang yang sama |
| Feedback | Inline state bila kegagalan menetap; `SnackBar` hanya untuk feedback singkat dan undo yang tidak menjadi satu-satunya akses pemulihan |

Home dan Habits memakai row habit yang sama secara behavior. History grid tidak perlu tampil penuh pada Home agar aksi harian terbaca; user tetap dapat mencapai seluruh habit lewat destination Habits.

## Do's and Don'ts

- Utamakan teks Goal, judul habit, status aktual dan petunjuk fisik milik user.
- Pertahankan dial sebagai ciri produk, dengan daftar setara untuk aksesibilitas.
- Saat running, pause dan target-reached harus bisa dibedakan tanpa warna.
- Dukung terang/gelap dan font besar sebelum efek/palette tambahan.
- Jangan menanamkan habit “Programmer”, jam tidur atau jadwal salat seolah user sudah memilihnya.
- Jangan tampilkan score energi, streak warning atau emoji dekoratif yang agent karang.
- Jangan mengganti keseluruhan Home saat memperbaiki timer/database.

Mockup di [mockups/today.html](mockups/today.html) memperlihatkan hierarki yang disetujui, bukan pixel contract atau implementasi Flutter. Warna, pilihan bookpaper, dan clock face Focus Clock yang sudah ada tetap menjadi acuan identitas.

Acuan platform yang diperiksa pada 3 November: [Android accessibility](https://developer.android.com/guide/topics/ui/accessibility/apps), [Flutter accessibility](https://docs.flutter.dev/ui/accessibility), [Android edge-to-edge](https://developer.android.com/develop/ui/views/layout/edge-to-edge). Android dengan target SDK 35+ membutuhkan penanganan insets pada perangkat Android 15+; `SafeArea`/viewInsets harus diperiksa pada build nyata.
