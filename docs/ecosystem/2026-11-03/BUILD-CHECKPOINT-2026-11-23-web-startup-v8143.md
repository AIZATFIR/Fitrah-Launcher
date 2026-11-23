# Web startup cue and owner preview — v8143

23 November 2026 · `0.5.51+8143` · source `0372325`

## Change

A cold production open showed a blank white page while Flutter downloaded and initialized. The shared web entry page now paints a small Obsidian Bookpaper clock immediately, announces loading to assistive technology, and removes the cue when Flutter sends its first-frame event. Reduced-motion preferences keep the cue still. This applies to Fitrah, Focus Clock, and Sadar.

## Build and delivery

- Universal Android APK built for `com.aizatfir.fitrah_launcher`, min API 24, target API 35, version code 8143.
- APK verified with Android APK Signature Scheme v2. It uses the local Android Debug owner-preview certificate, not Play Store signing.
- Fitrah, Focus Clock, and Sadar JavaScript bundles built and passed `scripts/verify_web_bundle.sh`.
- Production deployments: Focus Clock `dpl_85wjEXQx8aSVv7L1VUDHvCPNkijW`, Fitrah `dpl_4kCPE6wrpcumpmbSEMAttrmk7GcT`, Sadar `dpl_68x6BAMuqYakY2fxYpSYomW9dB2n`.
- Browser check on Focus Clock showed the loading cue during startup, followed by the analog clock page; the loading cue was removed after Flutter rendered.
- Automated test suites were not run. No physical Android phone was connected.

## Scope still open

This preview improves web startup feedback. It does not implement cross-device sync; Android and web continue to use separate local data. Physical phone/OEM behavior, TalkBack, live provider behavior, and sustained owner use still need real-device evidence. Fitrah remains a personal APK preview, not a production-signed app-store release.
