# ADR E1 — Penyimpanan native dan web

**Status:** keputusan sementara untuk Android; storage web masih terbuka
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
