# ADR E1 — Penyimpanan native dan web

**Status:** native Isar dipertahankan; Drift WASM menjadi adapter web produksi, gate E1 lintas perangkat/deploy tetap terbuka
**Tanggal:** 4 November 2026

## Konteks

Focus Clock butuh agenda, habit, dan sesi yang tetap tersimpan setelah app ditutup. Build memakai Isar 3.1.0+1, tetapi native Android x86_64 menunjukkan dialog kompatibilitas 16 KB. Generated collection IDs juga harus sama dengan hash nama koleksi agar Isar native dapat membuka store. Versi Isar yang ada tidak menyediakan operasi web yang dapat dipakai app; build web saja bukan bukti data web tersimpan.

## Keputusan sementara

- Pakai `isar_community` dan `isar_community_flutter_libs` 3.4.1 untuk jalur native saat ini. Migrasi package mempertahankan nama koleksi dan bentuk model; jangan ubah schema produk tanpa migration plan.
- Pakai generator `isar_community_generator` 3.4.1. Setelah `build_runner`, jalankan `dart run tool/fix_isar_schema_ids.dart` agar hash schema penuh tetap benar dan literal ID aman untuk dart2js.
- Untuk web, jangan menampilkan simpan sukses ketika browser storage belum ada. Pertahankan recovery screen; pilih Drift/WASM, adapter web, atau opsi lain setelah storage spike dan uji deploy.

## Bukti

- Isolated Linux native test membuka schema lengkap, menyimpan Activity, menutup store, lalu membaca data yang sama setelah reopen.
- Emulator Android 16 KB berhasil upgrade in-place dari app lama; settings database terbuka tanpa error Isar dan dialog 16 KB tidak muncul lagi.
- `libisar.so` x86_64 di APK split debug memiliki alignment `LOAD` 0x4000.
- Standard Flutter JS build berhasil. Runtime web tetap tidak punya store usable.

## Konsekuensi dan gerbang berikutnya

- Store Isar lama tetap pada database path yang sama. Buktikan round-trip data produk lama, backup/export/import, dan recovery sebelum migrasi model atau release.
- Package Community menyelesaikan masalah native yang teramati, bukan keputusan database lintas platform.
- E1 tidak lulus sampai web mempunyai storage durable yang diuji reload/offline, backup dapat dipulihkan, serta device riil lulus upgrade/reopen.

## Spike browser — 6 November 2026

Paket terisolasi [`tool/web_storage_spike`](../../../../tool/web_storage_spike/README.md) menjalankan Drift 2.35.3 di Chromium 150.0.7871.186. Enam tes browser membuktikan reopen, detik/date/status yang utuh, transaksi completion, rollback saat exception, perebutan singleton session dan watcher antar-koneksi. Journey tambahan memakai dua tab nyata serta page reload: goal/timer tetap ada, rollback terlihat dari tab lain, hanya satu start menang, dan completion bersamaan tidak menggandakan kontribusi. Aset worker/WASM berasal dari rilis yang sama dan diperiksa checksum; dependencies/commands/fixture/batas dicatat di README.

Tanpa header isolasi, backend terukur `sharedIndexedDb`; dengan COOP `same-origin` dan COEP `require-corp`, backend `opfsLocks`. Keduanya melewati journey dua tab. Mode `unsafeIndexedDb` dan `inMemory` ditolak sebelum penulisan. Dokumentasi resmi menjelaskan [pilihan mode dan kebutuhan hosting](https://drift.simonbinder.eu/platforms/web/); hasil lokal ini melengkapi, bukan menggantikan, pengujian target deploy.

**Keputusan lanjutan:** adapter browser Drift WASM telah diintegrasikan sambil mempertahankan Isar native. Repository memakai kontrak transaksi dan notifikasi commit yang sama; logika recurrence, ukuran habit dan completion tidak disalin ke implementasi browser. `all()` dengan filtering bersama cukup untuk tahap awal; histori besar memerlukan query terindeks yang diukur sebelum menjadi masalah pemakaian.

AppSettings ID 0, TimerSession ID 1, detik tepat, tanggal lokal dan field live harus terjaga. Alokasi ID tidak boleh memakai panjang list; hasil query berupa salinan terpisah. Codec backup memiliki redaksi kredensial dan normalisasi timer yang tidak cocok untuk live storage. Launcher preferences masih store terpisah sampai perubahan dengan kompensasi diputuskan.

Belum teruji: schema upgrade browser, quota/eviction, offline page startup dari cache, Safari/Firefox/mobile, auth dengan header isolasi, serta deployment. Bukti desktop Chromium tidak mengizinkan migrasi data Android atau klaim rilis web stabil.

## Integrasi browser produksi — 7 November 2026

Implementasi menghubungkan delapan model, lima repository, tiga entry point dan backup/recovery melalui `FocusStore`. Android tetap memakai Isar dan database path yang sama. Browser memakai records/counters/recovery SQLite Drift WASM dengan mode durable saja; codec live terpisah menjaga kredensial lokal, status timer berjalan, ID dan tanggal. Build source menyiapkan worker/WASM resmi Drift 2.35.3 dengan checksum tetap.

Bukti: journey Chromium 150 dari build web memakai model dan repository produksi. Dua tab memverifikasi satu pemenang saat memulai timer Habit dan Activity, kontribusi tepat 67 detik satu kali, start ulang sesudah completion, Activity tidak yatim, reload semua delapan model plus goal, recurrence/exclusion, rollback dan watcher, restore, kegagalan preferences dan recovery JSON yang dapat dibaca setelah reload. Mode terukur `sharedIndexedDb`. Suite native: 124 tes lulus; tes layar storage gagal/coba lagi lulus; analyzer bersih; Home JS release compile berhasil. APK arm64 release `build/app/outputs/flutter-apk/app-release.apk`, SHA-256 `329954a9300e810233e531ba9dd4d842b15939aae4d121094ac1041a5c8fcd47`; segmen LOAD `libisar.so` aligned 16 KB. Gate offline dari cache, eviction/quota, Safari/mobile, deploy dan perangkat fisik belum diuji; E1 belum ditutup.

Perintah journey: build target `tool/browser_storage/main.dart` ke direktori sementara, lalu `node tool/browser_storage/browser_journeys.mjs <direktori-build>`. Fixture hanya berisi data sintetis.
