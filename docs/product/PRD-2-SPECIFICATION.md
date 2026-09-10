# PRD 2 — SADAR Product Build Specification

**Status:** Approved Specification  
**Goal:** Build Sadar from concept → usable, reliable, polished product across platforms without over-engineering.

---

## 0. Product Core

> **Sadar makes you conscious of how you spend your day, then helps you act on it.**

**Core loop:**
```text
SADAR
  ↓
Choose what matters today
  ↓
Do it
  ↓
Mark it honestly
  ↓
See what you repeatedly do
  ↓
Become more conscious
  ↓
Build a fulfilled day
```

---

## 1. Product Relationship
- Connected, not coupled.
- Sadar can work independently (`lib/main_sadar.dart`).
- Seamlessly accessible within Focus Clock (`appMode == 'sadar'`).

---

## 2. Platforms
- **Web**: P0
- **Android**: P0
- **Windows**: P0
- **iOS / Linux**: P1

---

## 3. Core Features
- **Today Screen**: Quiet daily companion (Salutation, time, checklist, 2/6 done progress, in-line reflection card).
- **Daily Things**: Habits, Tasks, Practices.
- **Fast Completion**: 1-tap (<5 seconds), non-blocking, time-based or direct status.
- **Timer Engine**: Never rely on `setInterval()`; calculate strictly from timestamps (`startedAt`, `accumulatedDuration`, `currentTime`).
- **Fullscreen Focus Mode**: Minimal, large typography, breathing pulse, keep-awake, self-validation completion card.
- **Over-App / Floating Timer**: Windows always-on-top 280x150 draggable minimal widget with quick controls.
- **Daily Fulfillment & Reflection**: 4 emotional feelings (*Not satisfied*, *Okay*, *Good*, *Proud*), note, and dedicated **"Proud of Today"** prompt.
- **Awareness (Sadar)**: Observational patterns without judgment.
- **What I Repeat**: Descriptive accumulation of repeated days and minutes.
- **60-Second Onboarding**: 5-step serene priority selection.
- **Offline-First**: Embedded local database (Isar) with safe migrations and recovery.
