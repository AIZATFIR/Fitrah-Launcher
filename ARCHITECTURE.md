# System Architecture: Focus Clock & Sadar

This document describes the architectural boundaries, layers, domain contracts, and reliability principles of the codebase.

---

## 1. High-Level System Overview

```text
┌────────────────────────────────────────────────────────┐
│                      APP RUNNERS                       │
│   lib/main.dart (Focus Clock)   lib/main_sadar.dart    │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                    INTEGRATION LAYER                   │
│   FocusSessionContract v1  /  DeepLinkService          │
│                 (Connected, Not Coupled)               │
└──────────────┬───────────────────────────┬─────────────┘
               │                           │
┌──────────────▼─────────────┐┌────────────▼─────────────┐
│      FOCUS CLOCK ENGINE    ││       SADAR DOMAIN       │
│  - Analog Clock Face       ││  - Today View Companion  │
│  - Time-block Scheduling   ││  - Daily Habits & Things │
│  - Drag & Drop Canvas      ││  - Anti-Drift Timer      │
│  - Routine Blueprints      ││  - Desktop Floating Mode │
│  - Instant & Precision Mode││  - "What I Repeat"       │
│  - Audio / Storytelling    ││  - Awareness Analytics   │
│                            ││  - Daily Reflection      │
└──────────────┬─────────────┘└────────────┬─────────────┘
               │                           │
┌──────────────▼───────────────────────────▼─────────────┐
│                 DATA & PERSISTENCE LAYER               │
│   - Isar Embedded NoSQL Database (Offline-First)       │
│   - SecureStorageService (Platform Credentials)        │
│   - NotificationService (System Sound & Notifications) │
└────────────────────────────────────────────────────────┘
```

---

## 2. Dependency Rules

1. **Clean Layer Separation**:
   `UI / Presentation → Riverpod Providers → Repositories / Contracts → Local Storage / Database`
2. **Never**: UI directly accessing low-level storage or database singletons.
3. **Decoupled Integration**: Focus Clock and Sadar do not import each other's database implementations or internal timers. They exchange structured data via `FocusSessionContract v1`.

---

## 3. Reliability & Engineering Guarantees

1. **Anti-Drift Timer**: Elapsed time is always calculated dynamically from system timestamps (`startedAt`, `accumulatedDuration`, `currentTime`). Never relies on tick decrements.
2. **Crash & Restart Recovery**: Active timer sessions are persisted continuously to local storage. If the app is closed or the device sleeps, resuming recalculates exact remaining time.
3. **Historical Immutability**: Historical entries preserve snapshot targets (`targetSnapshot`) and actual durations (`actualDurationMinutes`). Future edits to habit definitions never corrupt past records.
4. **Idempotent Operations**: Rapid double taps or duplicate callbacks are guarded to prevent duplicate entries or corrupted metrics.
5. **Offline First**: 100% of core actions function without network access.
