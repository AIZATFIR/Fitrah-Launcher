# Fitrah Launcher

Distraction-free digital minimalism home launcher for Android, Linux, and Windows. Built on the philosophy of human fitrah, conscious attention, and intentional computing.

---

## Overview

Modern mobile operating systems are optimized to extract human attention through high-saturation visual clutter, algorithmic recommendation loops, and aggressive badge notifications.

Fitrah Launcher redesigns the primary device interface into a calm, functional instrument. It combines analog time-blocking with habit awareness and streamlined application navigation into a coherent three-screen spatial model.

```
+---------------------------+---------------------------+---------------------------+
|        SLIDE LEFT         |       CENTER (HOME)       |        SLIDE RIGHT        |
|     Focus Clock Face      |     Fitrah Dashboard      |     Minimalist Drawer     |
|                           |                           |                           |
| * 24h / 12h Analog Dial   | * Minimalist Date & Time  | * Niagara-style List      |
| * Visual Time-Blocking    | * Ongoing Main Event Hero | * A-Z Alphabet Scrubber   |
| * Direct Arc Drag-to-Plan | * Today's Scheduled Blocks| * Real-time Text Search   |
| * Routine Templates       | * Sadar Habit Fulfillment | * Pinned Favorites        |
| * Deep Work Segments      | * 4-Slot Essential Dock   | * Zero Notification Dots  |
+---------------------------+---------------------------+---------------------------+
```

---

## Core Capabilities

### 1. Spatial Three-Screen Navigation
* **Center (Home Dashboard)**: An executive display showing current time, the ongoing primary event with remaining duration countdown, today's schedule boxes, daily habit check-ins, and a four-icon utility dock.
* **Slide Left (Focus Clock Face)**: Direct access to an interactive 720-minute analog clock dial where scheduled activities appear as physical segments. Drag directly on the circumference to define and adjust blocks.
* **Slide Right (Minimalist Drawer)**: A linear application index inspired by the Niagara interface. Features an integrated vertical A-Z alphabet scrubber with haptic feedback, real-time filtering, and custom pinning.

### 2. Fitrah Philosophy & Digital Health
* **Zero Algorithmic Clutter**: No news feeds, no endless vertical shorts, and no predictive recommendation engines.
* **No Badge Traps**: Red badge counters and attention hooks are eliminated entirely.
* **Systematic Rest & Focus**: Integrates ultradian rhythms (90-minute focus blocks) and deliberate breaks to align device interaction with human biology.
* **Local-First & Private**: Operational entirely offline. All activity and habit data is stored securely on-device via local embedded storage.

---

## Downloads

Official binary releases are published on GitHub Releases:

| Platform | Target Package | Architecture |
|---|---|---|
| **Android** | `Fitrah-Launcher-v0.1-Android.apk` | ARM64 / ARMv7 / x86_64 |
| **Linux** | `Fitrah-Launcher-v0.1-Linux-x64.tar.gz` | x86_64 |
| **Windows** | `focus-clock-windows.zip` | x86_64 |
| **Web** | `Fitrah-Launcher-v0.1-Web.zip` | WebAssembly / HTML5 |

Releases: [https://github.com/AIZATFIR/Fitrah-Launcher/releases](https://github.com/AIZATFIR/Fitrah-Launcher/releases)

---

## Installation & Setup

### Android Home Launcher Setup
1. Download and install `Fitrah-Launcher-v0.1-Android.apk` on your device.
2. Open device **Settings** -> **Apps** -> **Default Apps** -> **Home App**.
3. Select **Fitrah Launcher** as your default home application.
4. Swipe left to manage your schedule on the clock dial; swipe right to browse and search installed applications.

---

## Technical Stack

* **Framework**: Flutter (Engine 3.x, Dart 3.x)
* **Local Storage**: Isar Database / SharedPreferences / Secure Storage
* **Android Native Layer**: Kotlin `MethodChannel` (`fitrah_launcher/apps`)
  * `android.intent.category.HOME`
  * `android.intent.category.DEFAULT`
  * `android.permission.QUERY_ALL_PACKAGES`
* **State Management**: Flutter Riverpod
* **Typography**: Clean variable monospace and sans-serif system fonts

---

## Building from Source

### Prerequisites
* Flutter SDK (version 3.24 or newer)
* Android SDK (API 34+) / JDK 17
* CMake 3.15+ (for Linux and Windows builds)

### Development Setup
```bash
# Clone the repository
git clone https://github.com/AIZATFIR/Fitrah-Launcher.git
cd Fitrah-Launcher

# Fetch dependencies
flutter pub get

# Run code generator
dart run build_runner build --delete-conflicting-outputs

# Execute test suite
flutter test

# Run application on connected device
flutter run
```

### Production Compilation
```bash
# Build Android APK
flutter build apk --release

# Build Windows executable
flutter build windows --release

# Build Linux bundle
flutter build linux --release

# Build Web distribution
flutter build web --release
```

---

## License

This project is open source under the MIT License.
