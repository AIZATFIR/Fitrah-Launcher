# Focus Clock preview 41 — 14 November 2026

Source base: `b7ff628`; this artifact includes uncommitted working-tree changes.

Preview 41 adds approval-first individual AI schedule changes, false completion-claim suppression, conflict-safe in-memory updates, cancellation of pending actions on new chat, and compact chat controls for narrow screens.

## Verification

- Full Flutter suite: **336 passed** serially with `flutter test --concurrency=1`.
- Focused AI approval/service and widget tests: **6 passed**. The widget test exercises proposal display, cancel without write, approval with one write, and overflow at 320dp.
- `flutter analyze`: no issues.
- Android arm64 release APK built as versionName `0.5.3`, versionCode `41`, minSDK `24`, targetSDK `35`, compileSDK `36`. APK metadata and v2 signature verified with the existing Android Debug certificate (SHA-256 `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`). Personal preview only; not suitable for Play/public release.
- `libisar.so` LOAD segments retain 16 KB alignment (`0x4000`).
- Web JavaScript release bundle compiled; ZIP integrity/checksums passed. The blank Home first-render was reviewed in the v41 local web preview; chat behavior is covered by widget tests.
- No Android runtime or physical-phone install was run for v41. Browser interaction/reload, TalkBack navigation and personal database upgrade remain unverified.

## Artifacts

- `release_dist/2026-11-14-focus-clock-preview-41/Focus-Clock-Ecosystem-Android-arm64-preview.apk`
- `release_dist/2026-11-14-focus-clock-preview-41/Focus-Clock-Ecosystem-Web-JS-preview.zip`
- `release_dist/2026-11-14-focus-clock-preview-41/BUILD-MANIFEST.json`
- `release_dist/2026-11-14-focus-clock-preview-41/SHA256SUMS`

This is a local preview, not a public release. E0–E6 remain open. AI goal understanding/editable atomic plans, cross-device sync, WhatsApp, MCP, open source publication and daily-use observation remain future work.
