# Keadaan kode dan referensi

Audit sumber: 3 November 2026, repository Fitrah `HEAD 1de34da`, branch `master`. Pada awal run ada perubahan lokal pada tiga artifact generated `build/web`: MaterialIcons, flutter_bootstrap dan main.dart.js. Run ini mempertahankannya. Bukti di bawah adalah pembacaan source/history, bukan hasil test/build/perangkat saat run ini.

Path kode pada tabel relatif terhadap `/home/aizatfir/Project/Fitrah-Launcher`, kecuali dinyatakan lain. Nomor baris menunjukkan snapshot audit dan dapat bergeser setelah implementasi.

## Temuan yang menentukan prioritas

| ID | Bukti | Dampak untuk build |
|---|---|---|
| EV-01 | `lib/main.dart:7,36,66`; `features/launcher/fitrah_launcher_shell.dart:78`; `main_fitrah.dart` berbeda bootstrap/theme | Satu app sudah memuat tiga pengalaman; pilih satu entrypoint, jangan membangun runner keempat |
| EV-02 | `features/launcher/widgets/focus_clock_home_view.dart:116,150,279,370`; file 4.750 baris | Local BlockItem/HabitModel/notes/inbox menduplikasi model persisten; ganti bindings bertahap |
| EV-03 | Home `:420` seed repo hanya bila kosong; `:590–605` upsert tidak ditunggu lalu ID lokal baru ditambah | Home dan dial dapat berbeda; save success dan ID harus satu jalur |
| EV-04 | Habit Play dari Home membuka `SadarTimerView`; Home free/preset dan QuickTimerHub kini juga membaca serta mengubah sesi melalui `timerEngineProvider` | Habit grid, free/preset, scheduled Activity, QuickTimerHub, command palette, voice-created Activity, FocusSessionView dan YPT memakai satu owner |
| EV-05 | `SadarTimerView`, Home, QuickTimerHub, FocusSessionView and `SadarYptFocusView` use `timerEngineProvider`; only the foreground app guard and UI animation retain local timers | All existing timer entry points share one persisted active session; YPT keeps its target-plus-overtime behavior and app guard |
| EV-06 | `sadar_timer_engine.dart:190,245` finishEarly/actual; Home `:640,672` done/minimum 15 menit | Stop awal dapat diberi target penuh atau durasi buatan; pisahkan target dari actual |
| EV-07 | `TimerSession.attributionLocalDate`; engine captures it at start, restores it and uses it at habit completion; Isar close/reopen fixture retains it | New sessions keep their original local credit date across restore; legacy sessions without the field fall back to saved `startedAt`; monotonic/clock-change recovery remains unverified |
| EV-08 | `SadarTimerEngine` completion is atomic; `SadarTimerView` and `SadarYptFocusView` use it for habit sessions. YPT's app guard remains a separate foreground-app poll; daily entry still has no per-session ledger | YPT overtime and completion now share the engine; no timer entry point remains as an independent countdown owner, while session detail/ledger is still absent |
| EV-09 | `data/isar_service.dart` web init/open; `settings_repository.dart:10,35`; `isar_community-3.4.1/lib/src/web/isar_web.dart:22` | Reload durability belum ada. Migrasi ke Isar Community 3.4.1 memperbaiki jalur native; versi ini tetap melempar `UnsupportedError` untuk operasi Isar web, maka produksi web memakai layar recovery tanpa silent memory fallback |
| EV-10 | Fitrah `models/app_settings.dart` tidak mempunyai focusGoal; `/home/aizatfir/Project/Focus Clock - Claude/lib/models/app_settings.dart:42` mempunyai field itu | Implementasi goal sebelumnya adalah input migrasi/reference, belum fitur Fitrah saat ini |
| EV-11 | `app_launcher_service.dart:72,78,237,246`; `minimalist_app_drawer.dart:128` | Fake apps saat gagal, success simulasi platform lain, volatile favorites dan hasil native yang diabaikan |
| EV-12 | Native `MainActivity.kt:82,158,168` lists/launches apps; `:53` lockscreen flags; manifest `src/fitrah` menunjuk package activity lama | Kemampuan launch nyata ada; flags activity bukan widget lockscreen; audit source set/flavor diperlukan |
| EV-13 | `package.json:6` build hanya echo, `:11` deploy:focus merujuk build:focus yang tak ada; Vercel memakai npm run build | Deploy dapat memakai bundle salah/stale; release metadata dan output isolation dibutuhkan |
| EV-14 | Commit `fadbf10` rewrites generated schema names and IDs; host test reproduced `IllegalArg: Collection id is invalid`; current generated IDs did not equal `xxh3(schema.name)`; `0583587` later retained bounded IDs for dart2js | Isar validates the full hash on native. Keep collection names stable, regenerate exact hashes, then split wide integer literals into constant arithmetic expressions for JS compilation. Device database backup/migration is still unverified. |
| EV-15 | `services/focus_session_contract.dart` request/result terdefinisi; pencarian caller tidak menemukan penggunaan di alur app saat ini | Keberadaan kontrak bukan bukti ekosistem tersambung |
| EV-16 | 4 Nov follow-up: `completeTimerSession` makes/adds the HabitEntry and deletes TimerSession in one native Isar write transaction; Linux reopen fixture checks two completions aggregate 18 actual/value minutes with target snapshot 20. Restore-first start, failed completion retry, durable pause/cancel failures, `SadarTimerView` and Home habit Play session paths are covered. A prior full suite of 85 tests, analyzer, unified launcher APK arm64 and web JS builds passed; latest timer-owner changes have a separate 44-test focused run | Android process-death, reboot/clock, notifications and physical device QA remain unverified; web persistence remains unsupported |
| EV-17 | 4–5 Nov single-owner slices: `TimerSession` stores nullable source kind, Activity ID, running checkpoint and immutable attribution local date; legacy source-less rows restore as habits. Home non-habit controls, QuickTimerHub, command palette, voice-created Activity timers, FocusSessionView and SadarYptFocusView use `timerEngineProvider`. YPT source kind is appended to the persisted enum; overtime survives restore, and failed completion remains retryable. Activity completion writes actual seconds and exact Activity completion with active-session removal. Preset completion creates Activity row(s) and clears the active session in one Isar transaction. Failure injection leaves sessions intact; retries commit once. Tests cover date attribution through restored completion and Isar close/reopen. Full suite: 106 tests; analyzer clean | Monotonic/reboot, operation receipts, history ledger, notifications and physical device checks remain open |

Beberapa issue di atas saling terkait, bukan lima belas proyek terpisah. E1/E2/E3 memperbaiki owner data, transaksi dan sesi; E4 menyajikan hasilnya di UI.

## Aset yang dipertahankan

- `AnalogClockFace` dan `core/time_math.dart`: basis dial yang sudah dipilih pemilik; adaptasi data lebih kecil daripada mengganti visualisasi.
- `Activity` recurrence, excluded dates dan group ID: informasi legacy yang perlu dipertahankan ketika adapter blok logis dibangun.
- Sadar `Habit`, `HabitEntry`, snapshot targets, repository dan grid history: basis habit nyata; perbaiki integrasi dan perhitungan yang salah.
- `SadarTimerEngine` timestamp recovery: bagian yang dapat diperbaiki/digunakan, tanpa mempertahankan bug credit dan tanggal.
- Native app launch, icon cache dan launcher settings persistence: kemampuan Android yang sudah ada.
- Goal text/UI kecil dalam repo Focus Clock lama: bukti bahwa cue persisten dapat ditambahkan tanpa merombak dial; bukan alasan menyalin seluruh app lama.

## Rujukan teknis yang diperiksa

| Sumber primer | Batas yang dipakai pada rancangan |
|---|---|
| [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide) | Repository menjadi source of truth; cross-domain orchestration tidak perlu memaksa repository saling bergantung |
| [Flutter offline-first](https://docs.flutter.dev/app-architecture/design-patterns/offline-first) | Local/remote services di belakang repository; offline dan sinkron mempunyai semantics yang harus dipilih |
| [Android storage/security](https://developer.android.com/privacy-and-security/security-best-practices) | Private app storage terpisah per app; tiga package bukan satu database |
| [Content providers](https://developer.android.com/guide/topics/providers/content-providers) | Cross-process sharing memerlukan API/izin/data owner yang sengaja dibuat |
| [Android App Links](https://developer.android.com/training/app-links/about) | Tautan membuka content/routing; tidak menggantikan protokol sync |
| [Isar exact tag 3.1.0+1 web open source](https://raw.githubusercontent.com/isar/isar/3.1.0%2B1/packages/isar/lib/src/web/open.dart) | Versi yang dipakai mempunyai unsupported web path; cache lokal mengandung exception yang sama |
| [SystemClock](https://developer.android.com/reference/android/os/SystemClock) | Elapsed realtime monotonic mencakup sleep; reboot reset perlu recovery policy |
| [Alarms](https://developer.android.com/develop/background-work/services/alarms) | End alert di luar proses memakai kemampuan OS, bukan ticker Flutter yang dijamin hidup |
| [Exact alarm access](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms) | Exact delivery bergantung access dan use case; app perlu fallback sesuai kemampuan |
| [Notification permission](https://developer.android.com/develop/ui/compose/notifications/notification-permission) | Notification visibility Android memerlukan consent sesuai OS; core tetap berjalan ketika ditolak |
| [Foreground service types](https://developer.android.com/develop/background-work/services/fgs/service-types) | Foreground service bukan perbaikan generik; shortService/dataSync tidak boleh dipilih asal untuk timer panjang |
| [Android 15 behavior](https://developer.android.com/about/versions/15/behavior-changes-all) | Force stop membatalkan pending intents; jangan menjanjikan alarm setelah force stop |
| [RoleManager](https://developer.android.com/reference/android/app/role/RoleManager) | Default Home role diminta/diverifikasi melalui sistem; membuka settings bukan bukti role diberikan |
| [Android accessibility](https://developer.android.com/guide/topics/ui/accessibility/apps) | Touch targets, contrast dan labels untuk Android |
| [Flutter accessibility](https://docs.flutter.dev/ui/accessibility) | Framework menyediakan Semantics dan dukungan assistive tech yang tetap perlu dipakai serta diperiksa |
| [Android edge-to-edge](https://developer.android.com/develop/ui/views/layout/edge-to-edge) | Insets/system bars untuk target SDK 35+ pada Android 15+ harus ditangani |

Nama class/domain dan urutan milestone adalah rekomendasi proyek yang diturunkan dari temuan ini. Dokumentasi Flutter/Android tidak mewajibkan nama GoalRepository atau SessionCoordinator. Paket Isar lokal telah diperiksa melalui source; belum ada browser save/reload test pada run perencanaan ini.

## Trade-off yang dipertimbangkan

Satu aplikasi modular menurunkan biaya koordinasi saat ini, tetapi menambah tanggung jawab menjaga boundary dalam repository yang sama. Karena itu ARCHITECTURE melarang salinan state per layar, bukan sekadar mengubah nama folder. Backend bersama dapat mendukung companion kelak, tetapi membawa akun, konflik dan operasional; E8 menerima pekerjaan itu hanya setelah penggunaan lokal stabil.

Penyimpanan lintas platform menjadi pertanyaan nyata karena versi Isar existing; memilih dependency pengganti sebelum memahami data legacy akan menambah risiko. E1 membatasi spike lalu mengunci satu pilihan. Schema/time/session invariants tetap sama untuk setiap kandidat.

## Batas audit dan review

Tidak ada test suite app, build APK, perangkat Android, deploy, remote git fetch atau ukur performa pada run ini. Handoff Antigravity serta laporan lama tidak menjadi bukti runtime sekarang. Linter arsitektur, cross-link relatif, urutan FR dan scan placeholder sudah diperiksa. Mockup diperiksa di Chromium pada alur state lokal dan lebar 320/375/430 px; hasil itu bukan bukti kondisi aplikasi Flutter. Ringkasan review dan perbaikan ada di README serta `reviews/`.
