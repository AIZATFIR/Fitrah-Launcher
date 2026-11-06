# ADR E1 — Penyimpanan native dan web

**Status:** native Isar dipertahankan; Drift WASM dipilih sebagai kandidat adapter browser setelah spike, integrasi produksi masih terbuka
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

**Keputusan lanjutan:** lanjutkan adapter browser berbasis Drift WASM sambil mempertahankan Isar native. Repository memakai kontrak transaksi dan notifikasi commit yang sama; logika recurrence, ukuran habit dan completion tidak disalin ke implementasi browser. Kontrak minimal menyediakan read snapshot, typed get/all/put/delete, write transaction, committed-change stream dan capability durable. `all()` dengan filtering bersama cukup untuk tahap awal; histori besar memerlukan query terindeks yang diukur sebelum menjadi masalah pemakaian.

AppSettings ID 0, TimerSession ID 1, detik tepat, tanggal lokal dan field live harus terjaga. Alokasi ID tidak boleh memakai panjang list; hasil query berupa salinan terpisah. Codec backup memiliki redaksi kredensial dan normalisasi timer yang tidak cocok untuk live storage. Launcher preferences masih store terpisah sampai perubahan dengan kompensasi diputuskan.

Belum teruji: integrasi Flutter dan delapan model lengkap, schema upgrade, backup/import/recovery, quota/eviction, offline page startup dari cache, Safari/Firefox/mobile, auth dengan header isolasi, serta deployment. Spike tidak menutup E1 atau mengizinkan migrasi data Android. Implementasi adapter menjadi langkah berikutnya; release menunggu bukti gate tersebut.
