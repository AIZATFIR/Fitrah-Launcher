# Technical Design Specification: Sadar (Way of Life)

**Date**: 2026-09-10  
**Feature**: Sadar — Conscious Daily Habits & Fulfillment Companion  
**Target Area**: Standalone App (`lib/main_sadar.dart` & `sadar/`), Focus Clock Integration (`lib/features/sadar/`, Deep Linking, Isar Data Models)  

---

## 1. Vision & Core Philosophy

**Sadar** is a standalone, single-purpose companion application connected to the **Focus Clock** ecosystem. Its primary purpose is to help users consciously fulfill their day through repeated, intentional actions.

It answers one central question every day:
> **“Did I live today in a way I can be proud of?”**

### 1.1 Guiding Principles
1. **Make the Unconscious Conscious**:
   > *"Until you make the unconscious conscious, it will direct your life and you will call it fate."*
   The app reveals behavioral patterns without judgment or shame. It highlights what users repeatedly do and repeatedly avoid.
2. **Repetition Shapes Life**:
   > *"We are what we repeatedly do."*
   Hundreds of quiet, repeated sessions build a life pattern. No single day dictates failure.
3. **Atomic Habits (~33% Philosophy)**:
   Make cues obvious, friction minimal (<10 seconds to log), and tracking visually satisfying.
4. **No Gamified Productivity Theater**:
   No XP spam, no cartoon levels, no aggressive streak pressure. True satisfaction comes from visible, accumulated evidence of personal integrity.

---

## 2. Product Architecture & Focus Clock Connection

Sadar is designed as a **focused, single-purpose companion app** that communicates seamlessly with Focus Clock.

```text
┌──────────────────────────────────────────────────────────────┐
│                        SADAR APP                             │
│  - Horizontal Daily Grid (Way of Life pattern)               │
│  - Yes / No / Skip / Note recording                          │
│  - Daily Fulfillment Bar ("X / Y meaningful actions done")   │
│  - Built-in Fallback Timer                                   │
└──────────────────────────────┬───────────────────────────────┘
                               │
            Deep Link / App Scheme: `focusclock://timer`
                               │
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                     FOCUS CLOCK APP                          │
│  - Native Fullscreen Dial Timer                              │
│  - Persistent Notification & Background Execution            │
│  - Display Over Other Apps (Floating Overlay)                │
│  - Completion Callback: `sadar://completed`                  │
└──────────────────────────────────────────────────────────────┘
```

### 2.1 Communication Protocol (Deep Link)
* **Launch Timer from Sadar**:
  ```text
  focusclock://timer?habitId={id}&title={name}&duration={minutes}&icon={emoji}&color={colorHex}&callback={callbackUri}
  ```
* **Return on Completion**:
  ```text
  sadar://completed?habitId={id}&duration={minutes}&status=completed
  ```
* **Offline / Standalone Fallback**: If Focus Clock is not installed, Sadar executes its own built-in, graceful timer view without breaking the user flow.

---

## 3. Data Models (Isar & Local-First)

All data is stored locally in an embedded database (Isar) with Cloud Firestore sync capability.

### 3.1 `Habit` (`lib/models/habit.dart`)
Represents an ongoing habit definition:
* `id` (`Id`): Auto-incremented primary key.
* `name` (`String`): Habit name (e.g., "Quranic Arabic", "French", "Exercise").
* `iconKey` (`String`): Emoji icon (e.g., "📖", "🇫🇷", "🏃", "🧘").
* `target` (`int`): Quantity target (e.g., 20, 1, 10).
* `unit` (`HabitUnit` enum):
  * `min`: Timed duration measured in minutes.
  * `count`: Quantitative count (pages, pushups).
  * `binary`: Simple Yes/No completion.
* `timerEnabled` (`bool`): Whether this habit triggers a countdown timer.
* `colorValue` (`int`): Primary accent color for UI tags.
* `recurrence` (`String`): `'daily'`, `'weekdays'`, `'custom'`.
* `orderIndex` (`int`): Display ordering.
* `isArchived` (`bool`): Default `false`.
* `createdAt` (`DateTime`).
* `updatedAt` (`DateTime`).

### 3.2 `HabitEntry` (`lib/models/habit_entry.dart`)
Represents the status of a specific habit on a given date:
* `id` (`Id`): Auto-incremented key.
* `habitId` (`int`): Reference to `Habit.id` (indexed).
* `dateString` (`String`): Normalized date format `YYYY-MM-DD` (indexed).
* `status` (`HabitStatus` enum):
  * `yes`: Fulfilled (Green `#22C55E`).
  * `no`: Missed / Acknowledged (Red `#EF4444`).
  * `skip`: Planned Rest / Skipped (Muted Cyan/Gray `#64748B`).
  * `unmarked`: No entry recorded yet.
* `valueCompleted` (`int`): Actual minutes or count accomplished.
* `note` (`String?`): Optional short reflection note (triggers the visual top-right "dog-ear" fold on the cell).
* `updatedAt` (`DateTime`).

### 3.3 `DailyReflection` (`lib/models/daily_reflection.dart`)
* `dateString` (`String`): Normalized date `YYYY-MM-DD` (primary index).
* `proudNote` (`String`): Short self-validation answer to *"What are you proud of today?"*.
* `completedCount` (`int`): Number of habits fulfilled.
* `totalCount` (`int`): Total active habits for that day.

---

## 4. User Experience & Visual Interface

### 4.1 Daily Home & Horizontal Timeline (Way of Life Pattern)
* **Header**:
  * Date display (e.g. `Friday, September 11`).
  * Inquiry: *"How will you fulfill today?"*.
  * Daily Fulfillment progress indicator: `4 / 5 meaningful actions completed`.
* **Horizontal Date Matrix**:
  * Column headers with day abbreviations (`M T W T F S S`) and date numbers.
  * Horizontal scrollable week strip. Today is highlighted with an accent ring.
* **Habit Rows**:
  * Left: Habit icon, name, and target badge (`French · 20 min`).
  * Center-Right: Contiguous colored status cells for each date.
    * 🟩 Green for `yes`.
    * 🟥 Red for `no`.
    * 🟦 Slate for `skip`.
    * ⬜ Transparent card stroke for `unmarked`.
    * 📐 Small corner dog-ear indicator on the cell when a note is attached.

### 4.2 1-Tap Quick Action Popover
Tapping any date cell reveals an instant floating interaction sheet:
1. **[ 📝 Note ]**: Add/edit a 1-sentence note or observation.
2. **[ ✅ Yes ]**: Mark complete (Green).
3. **[ ❌ No ]**: Consciously acknowledge incomplete (Red) without judgment.
4. **[ ↩️ Skip ]**: Mark intentional rest (Muted Slate).
5. **[ ▶️ Start Focus ]**: (For timed habits) Immediately launch the Focus Clock native timer!

### 4.3 Pattern Awareness & History View
A dedicated, calm awareness tab answering:
* **"What do I repeatedly do?"**: High-frequency fulfilled habits with cumulative hours and session counts.
* **"What am I neglecting?"**: Habits with consecutive missed days, presented neutrally:
  > *"Exercise has been inconsistent this week."* (No shaming, pure awareness).

---

## 5. Technical Implementation Details

### 5.1 Project Layout
* **`lib/models/`**: Add `habit.dart`, `habit_entry.dart`, `daily_reflection.dart` with Isar annotations.
* **`lib/data/repositories/sadar_repository.dart`**: Repository managing CRUD for habits, queries by date range, and fulfillment metrics.
* **`lib/features/sadar/`**:
  * `sadar_home_screen.dart`: Main screen with horizontal timeline grid.
  * `widgets/horizontal_timeline_grid.dart`: High-performance custom painter / row builder for daily cells.
  * `widgets/quick_action_sheet.dart`: 1-tap action popover.
  * `widgets/habit_editor_dialog.dart`: Create/edit habit in <30 seconds.
  * `widgets/daily_fulfillment_banner.dart`: Restrained fulfillment bar.
  * `widgets/awareness_view.dart`: Pattern awareness & repetition statistics.
* **`lib/services/deep_link_service.dart`**: Handles URL scheme routing between Focus Clock and Sadar.
* **`lib/main_sadar.dart`**: Standalone runner for the dedicated Sadar app.
* **Focus Clock Integration**: Add Sadar directly to `lib/features/shell/launching_page.dart` as a first-class mode alongside Simple Mode and Focus Clock Mode.

---

## 6. Verification & Test Plan

1. **Model & Repository Unit Tests**:
   * CRUD operations for `Habit` and `HabitEntry`.
   * Date normalization (`YYYY-MM-DD`) and multi-day range queries.
   * Fulfillment calculation logic (avoiding negative or punishing scores).
2. **Deep Link Verification**:
   * Parsing and dispatching `focusclock://timer` parameters.
   * Handling return callbacks `sadar://completed`.
3. **UI & State Verification**:
   * Smooth horizontal scrolling and date cell tap interactions.
   * State transitions (unmarked $\to$ yes $\to$ no $\to$ skip).
   * Note dog-ear rendering and persistence.
   * Dark mode and Light mode aesthetic compliance.
