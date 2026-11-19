# Checkpoint — AI continues the saved goal v8093

**Date:** 19 Nov 2026
**Version:** 0.5.17+8093
**Download:** [Android install notes](../../../release_dist/2026-11-19-focus-goal-replan-v8093/INSTALL.md)

## Change

Opening **Tanya AI** from the pinned Home goal now carries its stable goal ID and revision through tool-call and JSON-envelope provider paths. The approval card identifies that the saved goal and practice schedule will be updated. Approval updates the same goal and reuses its timed habit/source; it replaces only unfinished rows from the prior AI plan. Completed activity rows are retained as history and changed to one-off records; activities with measured time or terminal focus-session references are retained. A stale goal revision rejects the transaction. Unrelated commitments remain protected by conflict checking.

## Verification

- Regression first: the new replan test failed because the second plan created a second habit. After implementation, the test verifies one goal, one habit/source, one active replanned block, the preserved completed activity, and revision increment.
- `flutter test test/goal_plan_application_test.dart test/ai_action_proposal_test.dart --no-pub`: **26 passed**. The provider tests verify saved goal ID/revision survive both response formats.
- `flutter test test/ai_chat_approval_widget_test.dart --no-pub`: **3 passed**.
- Scoped analyzer across the 8 affected Dart/test files: **no issues**.
- `flutter build apk --release --no-pub`: succeeded in 160.6 seconds. APK v2 signature verified; fingerprint matches v8092. Package metadata is `com.aizatfir.fitrah_launcher`, versionCode 8093, minSdk 24, targetSdk 35.
- Installed v8093 over the existing API36 x86_64 QA AVD. RoleManager still reports Fitrah as Android HOME; the saved LKS goal/action were visible. With `POST_NOTIFICATION` set to `ignore`, **Mulai fokus** opened the timer at 29:57 without a permission prompt; appops remained `ignore`. The QA timer was canceled and Fitrah remained HOME. Screenshots: [Home](../../../release_dist/2026-11-19-focus-goal-replan-v8093/QA_Home_v8093.png), [active timer](../../../release_dist/2026-11-19-focus-goal-replan-v8093/QA_Timer_v8093.png).
- SHA-256: `b10fb6c2367f6b44f0821ad584244129b548820b024e2b79c432460d7a6b2624`.

## Remaining

The emulator run verifies only one API36 x86_64 path. Real provider calls, physical/OEM usability, TalkBack, owner daily use, web persistence, sync, WhatsApp/MCP and the wider E0–E11 ecosystem gates remain open.
