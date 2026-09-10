# Sadar (Way of Life) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete Sadar application for conscious daily habits & fulfillment, featuring the classic Way of Life horizontal timeline grid, 1-tap quick action popover, daily fulfillment metrics, native timer integration, pattern awareness, and dual-mode execution (standalone runner & Launching Desk integration).

**Architecture:** Isar local-first embedded database with Riverpod state management. Modular architecture with models (`Habit`, `HabitEntry`, `DailyReflection`), a dedicated `SadarRepository`, high-performance custom horizontal grid widgets, deep link routing, and dual entry points (`main_sadar.dart` and `home_shell.dart`).

**Tech Stack:** Flutter, Dart 3.11+, Riverpod 2.5+, Isar 3.1+, Google Fonts, Flutter Local Notifications.

## Global Constraints
- Clean, token-efficient, robust code without over-engineering.
- Strict null safety, zero analyzer warnings.
- Responsive layout handling mobile portrait, tablet, and desktop viewports.
- Restrained visual aesthetic (no gamified score spam, authentic proof of life lived).

---

### Task 1: Core Data Models (`Habit`, `HabitEntry`, `DailyReflection`)

**Files:**
- Create: `lib/models/habit.dart`
- Create: `lib/models/habit_entry.dart`
- Create: `lib/models/daily_reflection.dart`
- Modify: `lib/data/isar_service.dart`

**Interfaces:**
- Produces: `Habit`, `HabitEntry`, `HabitStatus`, `HabitUnit`, `DailyReflection`
- Consumes: `isar`

- [ ] **Step 1: Create `lib/models/habit.dart`**
- [ ] **Step 2: Create `lib/models/habit_entry.dart`**
- [ ] **Step 3: Create `lib/models/daily_reflection.dart`**
- [ ] **Step 4: Run build_runner to generate `*.g.dart` schema files**
- [ ] **Step 5: Register schemas and initial seed data in `lib/data/isar_service.dart`**
- [ ] **Step 6: Commit Task 1**

---

### Task 2: Repository & State Management (`SadarRepository` & Providers)

**Files:**
- Create: `lib/data/repositories/sadar_repository.dart`
- Create: `lib/providers/sadar_providers.dart`
- Test: `test/sadar_repository_test.dart`

**Interfaces:**
- Produces: `SadarRepository`, `habitsStreamProvider`, `habitEntriesRangeProvider`, `dailyFulfillmentProvider`
- Consumes: `IsarService`, `Habit`, `HabitEntry`

- [ ] **Step 1: Write unit tests in `test/sadar_repository_test.dart`**
- [ ] **Step 2: Implement `SadarRepository` in `lib/data/repositories/sadar_repository.dart`**
- [ ] **Step 3: Implement Riverpod providers in `lib/providers/sadar_providers.dart`**
- [ ] **Step 4: Run tests to verify they pass**
- [ ] **Step 5: Commit Task 2**

---

### Task 3: Deep Link & Timer Integration

**Files:**
- Create: `lib/services/deep_link_service.dart`
- Create: `lib/features/sadar/widgets/sadar_timer_view.dart`

**Interfaces:**
- Produces: `DeepLinkService`, `SadarTimerView`
- Consumes: `FocusSessionView`, `Habit`

- [ ] **Step 1: Implement `DeepLinkService` for URL scheme parsing and dispatch**
- [ ] **Step 2: Implement `SadarTimerView` (standalone/fallback fullscreen clock timer)**
- [ ] **Step 3: Commit Task 3**

---

### Task 4: UI Components (Way of Life Pattern)

**Files:**
- Create: `lib/features/sadar/widgets/daily_fulfillment_banner.dart`
- Create: `lib/features/sadar/widgets/horizontal_timeline_grid.dart`
- Create: `lib/features/sadar/widgets/quick_action_sheet.dart`
- Create: `lib/features/sadar/widgets/habit_editor_sheet.dart`
- Create: `lib/features/sadar/widgets/awareness_view.dart`

**Interfaces:**
- Produces: `DailyFulfillmentBanner`, `HorizontalTimelineGrid`, `QuickActionSheet`, `HabitEditorSheet`, `AwarenessView`
- Consumes: `sadar_providers.dart`, `Habit`, `HabitEntry`

- [ ] **Step 1: Build `DailyFulfillmentBanner` with date and fulfillment progress**
- [ ] **Step 2: Build `HorizontalTimelineGrid` with day headers, habit rows, color blocks, and dog-ear folds**
- [ ] **Step 3: Build `QuickActionSheet` for 1-tap logging (Note, Yes, No, Skip, Start Timer)**
- [ ] **Step 4: Build `HabitEditorSheet` for creating and editing habits**
- [ ] **Step 5: Build `AwarenessView` for pattern awareness**
- [ ] **Step 6: Commit Task 4**

---

### Task 5: Main Screen & Integration (`sadar_home_screen.dart`, `main_sadar.dart`, `launching_page.dart`)

**Files:**
- Create: `lib/features/sadar/sadar_home_screen.dart`
- Create: `lib/main_sadar.dart`
- Modify: `lib/features/shell/launching_page.dart`
- Modify: `lib/features/shell/home_shell.dart`
- Test: `test/sadar_ui_test.dart`

**Interfaces:**
- Produces: `SadarHomeScreen`, `SadarApp` entry point, Launching Desk Hero Card

- [ ] **Step 1: Implement `SadarHomeScreen` pulling together all widgets**
- [ ] **Step 2: Implement `lib/main_sadar.dart` standalone runner**
- [ ] **Step 3: Integrate Sadar into `launching_page.dart` and `home_shell.dart`**
- [ ] **Step 4: Write and run widget tests in `test/sadar_ui_test.dart`**
- [ ] **Step 5: Commit Task 5**

---

### Task 6: Comprehensive Verification & Audit

- [ ] **Step 1: Run `flutter analyze` and fix any warnings**
- [ ] **Step 2: Run all unit and widget tests**
- [ ] **Step 3: Verify security, performance, and memory responsiveness**
- [ ] **Step 4: Commit and finalize walkthrough**
