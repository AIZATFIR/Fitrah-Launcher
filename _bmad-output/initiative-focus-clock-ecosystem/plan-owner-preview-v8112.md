---
title: 'Package the current Focus Clock owner preview'
type: chore
ticket: ''
created: '2026-11-20'
status: 'built'
baseline_revision: '1866bf39d0a0b266d7cbbc7ccb77f9c20fe4fe37'
route: 'full'
route_source: 'pinned'
risk: 'medium'
review: 'quick'
review_source: 'pinned'
lenses_ran: [quick]
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/BUILD-ROADMAP.md'
  - 'docs/ecosystem/2026-11-03/BUILD-CHECKPOINT-2026-11-20-prayer-source-v8111.md'
---

<frozen-after-approval reason="Owner explicitly requested installable phone previews and authorized continued ecosystem building">

## Intent

**Problem:** The latest installable preview is v8111, while later committed work improves AI chat delivery: failed turns can be retried against the same selected provider, and failed turns no longer poison later chat context. That improvement is not yet available in an APK the owner can install.

**Approach:** Produce a new, versioned owner-preview package from the current committed source for Android and web. Keep the familiar install path and make the artifact’s provenance, integrity, and unverified limits clear.

## Boundaries & Constraints

**Always:** Build from the exact current commit and record that full revision. Increment Android versionCode so an existing same-signature preview can upgrade. Build the universal APK and Flutter Web JavaScript bundle, verify package metadata/signature/archive integrity and SHA-256 checksums, and provide concise install steps. Keep release artifacts outside git.

**Never:** Claim the ecosystem is finished, claim physical-device/TalkBack/live-provider verification without evidence, change signing keys, publish or push, or bundle secrets/user data. Do not change runtime behavior in this packaging slice.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Reproducible source | Clean committed tree and recorded SHA | Both deliverables identify the same source and new versionCode | Stop packaging if git is dirty or build fails |
| Android artifact | Release universal APK | APK metadata and signature verify; same local debug signer supports preview upgrades | Report signer class and require backup before signer changes |
| Web preview | Flutter release JS output | ZIP contains hostable build and README identifies Android-only features | Do not label local browser storage as cloud sync |
| Integrity | Completed package directory | SHA256SUMS validates every deliverable and archive opens | Regenerate manifest/checksums after any artifact change |

</frozen-after-approval>

## Code Map

- `pubspec.yaml` -- source version and Android versionCode; change patch/build code only for this preview.
- `android/app/build.gradle` and Android manifest -- application identity, min SDK, signing configuration and package metadata; preserve identity/signing.
- `build/app/outputs/flutter-apk/` -- release APK output; ignored from git.
- `build/web/` -- Flutter web output; create ZIP without adding ignored generated files to source control.
- `release_dist/2026-11-20-focus-clock-owner-preview-v8112/` -- ignored deliverables, checkpoint, install notes, manifest, and checksums.
- `docs/ecosystem/2026-11-03/BUILD-ROADMAP.md` -- append truthful checkpoint evidence and remaining ecosystem gates.
- Existing v8111 package/install/checkpoint are the format reference; do not overwrite or delete them.

## Tasks & Acceptance

**Execution:**
- [x] `pubspec.yaml` -- increment versionCode to 8112, preserving semantic version and package ID.
- [x] Build outputs and `release_dist/...v8112/` -- produce universal release APK and web ZIP from the recorded HEAD; write install notes, manifest, checkpoint and SHA256SUMS.
- [x] `docs/ecosystem/2026-11-03/BUILD-ROADMAP.md` -- record exactly what was built and checked; retain open physical-phone, accessibility, provider, and sustained-use gates.

**Acceptance Criteria:**
- Given the current committed source, when both targets build, then each artifact reports version 0.5.28+8112 and package identity `com.aizatfir.fitrah_launcher` remains unchanged.
- Given the package directory, when checksums and APK metadata/signature are inspected, then every published local artifact matches its recorded digest and the APK verifies as a local owner preview.
- Given the owner reads install notes, then they can install the Android preview and understand that release signing, physical-device confirmation, live AI, accessibility, and ecosystem completion are still open.

## Implementation Notes

Built v8112 from source revision `1866bf39d0a0b266d7cbbc7ccb77f9c20fe4fe37`; only `pubspec.yaml` metadata was changed for this package. Universal APK and JS web ZIP are in ignored `release_dist/2026-11-20-focus-clock-owner-preview-v8112/`. APK package/version/min/target and v2 signature independently verified; signer SHA-256 matches v8111. Web ZIP includes README and index. All package checksums and ZIP integrity pass. No device, live provider, TalkBack, or sustained-use verification performed.

## Plan Change Log


## Review Triage Log

- Quick review: 0 findings; reviewer confirmed the diff, local artifacts, and acceptance claims are consistent on inspection.


## Verification

**Commands:**
- `flutter build apk --release --no-pub` -- release APK builds at the new version.
- `flutter build web --release --no-pub` -- Flutter Web JS bundle builds.
- `aapt dump badging`, `apksigner verify --print-certs`, `unzip -t`, and `sha256sum -c SHA256SUMS` -- verify package metadata, signer, archives and checksums.
- `git diff --check` and `git status --short` -- source patch is clean; release artifacts remain ignored.
