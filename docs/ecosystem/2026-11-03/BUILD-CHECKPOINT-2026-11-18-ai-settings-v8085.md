# Build checkpoint — direct AI provider setup v8085

**Date:** 18 November 2026
**Version:** 0.5.10+8085
**Artifact:** [Android/web preview and install guide](../../../release_dist/2026-11-18-fitrah-ai-settings-preview-v8085/INSTALL.md)

## Delivered

The AI setup actions from Focus Clock chat now open Settings at the provider configuration section, rather than at the top of the unrelated clock preferences. The settings page scrolls to its existing AI section and reuses the existing BYOK controls. Phone-width layout constraints are fixed for the time-format and notification dropdowns, and the provider/model hint now wraps instead of overflowing.

## Verification

- Added a 390 × 844 widget regression for opening the provider controls on a phone. It exposed two existing layout failures on this route: a full-width settings dropdown in a ListTile, then a 203 px model-row overflow. The settings controls were constrained and the hint now wraps. Final focused test: **passed**.
- `flutter analyze --no-pub` on Settings, Home, HomeShell, and the route test: **no issues**.
- Android release APK built as `0.5.10+8085`; web JavaScript release build completed.
- API 36 x86_64 AVD upgraded in place; Fitrah Home role selected; saved LKS goal remained visible after pressing Home. Opening **Tanya AI → Pengaturan AI** visibly landed at provider, base URL, key, and model fields. Inspected log tail showed no fatal Android/Flutter error.

## Still open

This does not complete E0–E6 or the ecosystem goal. No provider key was submitted; real-model conversation, plan approval and session/history round-trip remain unverified. Physical/OEM phone, accessibility, production signing, browser persistence and seven-day owner use remain open.
