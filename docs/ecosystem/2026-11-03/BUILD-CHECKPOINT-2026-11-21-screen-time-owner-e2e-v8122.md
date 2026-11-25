# v8122 Android owner-flow recheck

**Date:** 21 November 2026
**Package:** `com.aizatfir.fitrah_launcher` 0.5.31 / versionCode 8122
**Environment:** API 36 x86_64 AVD, 1080 × 2400, 420 dpi, system font scale 2.0

## Verified

- Android resolves `com.aizatfir.fitrah_launcher/.MainActivity` as the default HOME activity. The Home key returns to the saved QA goal `Menang LKS Nasional QA` and daily choice `Latihan LKS`.
- **Mulai fokus** opens the shared focus timer at 29:57 with **Jeda**, **Selesai sekarang**, and **Batalkan timer** available. The QA session was canceled after inspection.
- At test start, **Tampilkan cue waktu layar** and **Batas harian lembut** were both off. Their saved choices were 120 minutes and 20 seconds.
- With Usage Access and overlay access already granted on this AVD, enabling the cue displayed its measured-minute pill on Chrome. Dragging it to the edge tucked it to a handle; tapping restored it; tapping **Tujuan** returned to the saved Fitrah Home.
- With a temporary 30-minute cap and 10-second wait, opening Chrome from Fitrah's app list showed an 88-minute measured total from synthetic AVD usage. The continue button was disabled during countdown. **Lihat tujuan** returned Home immediately. On retry, **Lanjutkan** became enabled only after the wait and then opened Chrome.
- After QA, both switches were returned to off, the limit to 120 minutes, and the wait to 20 seconds. Usage Access and overlay app-ops were already granted before this run and were left unchanged.

## Limits and follow-up

This confirms one v8122 emulator flow. The AVD's usage total is synthetic and does not establish real-life screen-time accuracy. The daily pause guards launches through Fitrah's app list; system and third-party launch paths remain available by design. Physical phone/OEM behavior, TalkBack, unavailable-stat recovery in a release session, reboot, and sustained daily use are still open. The cue scales with Android's 200% font setting and occupies a visibly larger part of the display; verify the intended compact feel on a 320 dp device and decide whether the floating control should have a visual size cap while preserving its accessible description.

Screenshots for Home, active timer, cue, tucked handle, and limit countdown are in the ignored local owner-preview folder `release_dist/2026-11-21-focus-clock-ai-privacy-v8122/`.
