# Build record — superseded v8091

**Date:** 19 Nov 2026
**Version:** 0.5.16+8091
**Download:** [Android install notes](../../../release_dist/2026-11-19-fit-actual-apps-v8091/INSTALL.md)

## Correction

The advertised dock change was applied to `FitrahHomeView`, but the active launcher shell renders `FocusClockHomeView`. Runtime tracing confirmed the app was displaying the Focus Clock goal-first Home; the code change had no effect on it and was reverted. Do not use v8091 as evidence for a dock feature. This remains a build-only history record.

## Build evidence

- Flutter Android release build completed successfully; universal APK size 74,771,264 bytes.
- APK metadata reports package `com.aizatfir.fitrah_launcher`, version `0.5.16`, versionCode `8091`, minSdk 24.
- Local debug signature retained for personal-preview in-place install compatibility.

## Limits

The package was installed over v8085 on the API36 AVD and preserved the LKS goal. It is superseded, and does not prove any dock improvement. Physical/OEM behavior and the full E0–E11 ecosystem goal remain open.
