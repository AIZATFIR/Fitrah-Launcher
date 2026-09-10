# PRD 3 — SADAR

## Engineering, Architecture, Reliability & Product Quality Specification

**Status:** Approved Baseline  
**Priority:** P0  
**Objective:** Build Sadar as a reliable, maintainable, cross-platform product without over-engineering.

---

# 1. NON-NEGOTIABLE PRODUCT PRINCIPLES

Sadar must always prioritize:
1. **Awareness over productivity**
2. **Action over planning**
3. **Consistency over intensity**
4. **Reflection over judgment**
5. **Reality over gamification**
6. **Reliability over visual novelty**
7. **Simplicity over feature count**
8. **User data over algorithmic assumptions**

Core loop:
```text
SEE → CHOOSE → DO → NOTICE → REPEAT → BECOME
```

---

# 2. PRODUCT ARCHITECTURE

Sadar and Focus Clock are:
```text
CONNECTED
NOT COUPLED
```

Sadar owns:
* habits
* daily intentions
* completion
* reflection
* repetition analysis
* fulfilled-day state

Focus Clock owns:
* focus sessions
* timer mechanics
* focus-mode behavior
* time-block execution

Integration occurs exclusively through the **Focus Session Contract** (`FocusSessionContract v1`).

---

# 3. DOMAIN MODEL & DATA INTEGRITY

### Domain Entities
- **Habit**: id, name, type, target, unit, frequency, isArchived, createdAt, updatedAt.
- **DailyEntry / HabitEntry**: id, habitId, dateString, status, completedAt, actualDurationMinutes, targetSnapshot, source, createdAt, updatedAt.
- **TimerSession**: id, habitId, habitName, startedAt, endedAt, targetSeconds, accumulatedDurationSeconds, status.
- **DailyReflection**: id, dateString, feeling, proudOfToday, note, updatedAt.

### Section 59 & 60: Historical Immutability
- Never derive important historical truth solely from mutable current settings.
- When a habit changes its target duration/count in the future, past entries preserve their `targetSnapshot` and `actualDurationMinutes`.

---

# 4. TIME & DATE ENGINEERING
- Never rely on `setInterval` or ticker ticks as the authoritative clock.
- Elapsed time is always strictly:
  `elapsed = accumulatedDuration + (now - startedAt)`
- Survives app restart, backgrounding, sleep, and clock changes.
- **Midnight Edge Case (§75)**: Sessions crossing midnight are attributed to the `startedAt` date while recording the exact `completedAt` timestamp.

---

# 5. TIMER STATE MACHINE & IDEMPOTENCY
- Deterministic transitions:
  `IDLE → RUNNING → PAUSED → RUNNING → COMPLETED`
  `RUNNING → CANCELLED`
- Invalid transitions (e.g. `COMPLETED → RUNNING`) are rejected.
- Operations are protected by idempotency guards against rapid duplicate executions.

---

# 6. OFFLINE-FIRST & STORAGE
- 100% of core interactions (view today, start timer, complete, reflect, history) operate offline with local Isar persistence.
- Layer separation: `UI → Providers → Repository → Isar Storage`.

---

# 7. TESTING STRATEGY
- **Unit & Domain Tests**: Test state machine, date calculations, midnight boundary, historical immutability, and duplicate completion idempotency.
- **Contract Tests**: Verify versioned contract serialization and handling.
- **UI Widget Tests**: Verify all tabs, empty states, and loading states.
