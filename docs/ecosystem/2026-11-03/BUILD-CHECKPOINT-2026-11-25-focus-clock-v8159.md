# Focus Clock dial clarity — owner preview v8159

**Date:** 25 Nov 2026  
**Release:** 0.5.67 / build 8159  
**Tag:** `v0.5.67-v8159`

## Change

On the 12-hour analog dial, the hour numerals now sit outside the bezel. The repeated minute numerals (00, 05, 10…) are removed; minute tick marks, clock hands, and the existing face colors remain. The 24-hour dial keeps its existing inner hour labels.

The release workflow now assembles one all-platform ZIP containing the Android APK, Windows and Linux apps, all three web exports, install instructions, a build manifest, and checksums.

## Verification

- `flutter analyze lib/features/focusclock/analog_clock_face.dart`: no issues.
- Android release APK built as versionCode 8159. APK signature verifies and matches the stable owner-preview key: `B8:AF:9D:95:BD:72:79:3E:81:7C:2B:EC:78:F3:E1:36:0D:96:45:6E:F4:7D:B5:26:0E:D0:D5:A1:99:34:FE:3E`.
- API 36 x86_64 emulator upgraded in place. Home and Jam screenshots show 1–12 outside the circle and no 00/05 minute numerals.
- Fitrah, Focus Clock, and Sadar web bundles built and passed `verify_web_bundle.sh`.
- Production deployments are READY; each `/version.json` reports 0.5.67 / 8159. Deployment IDs: Fitrah `dpl_6Zzk64nknNTDjSkAmGVcCRoPA47B`, Focus Clock `dpl_FnkFgBisGDDMTQxqqMzaufSHCQBU`, Sadar `dpl_3vhnRn2UFr2TqTtDGwZvihpJpy4i`.
- Tagged workflow [45616793651](https://github.com/AIZATFIR/Fitrah-Launcher/actions/runs/45616793651) succeeded: Android signature verification, Windows, Linux, all three web exports, and release publishing passed.
- The GitHub release contains eight assets, including `Focus_Clock_Ecosystem_0.5.67_v8159.zip` (125 MB) and `SHA256SUMS.txt`.

## Limits

Physical/OEM launcher behavior, TalkBack, sustained daily use, Play Store signing, cross-device sync, and live AI provider behavior remain unverified or incomplete. This is an owner preview, not ecosystem completion.
