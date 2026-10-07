# Building Uppidi

## Prerequisites

### Required for all platforms
- **Git** — to clone the repository
- **Flutter SDK** >= 3.16.0 (includes Dart >= 3.0.0)
  - Install from: https://docs.flutter.dev/get-started/install
  - Make sure `flutter` is on your PATH

### For Android builds
- **Java JDK 17+** — required by the Kotlin compiler
  - Ubuntu/Debian: `sudo apt install openjdk-17-jdk`
  - Arch: `sudo pacman -S jdk17-openjdk`
  - macOS: `brew install openjdk@17`
- **Android SDK** — command-line tools + platform-tools
  - Install via `flutter doctor --android-licenses` or manually from developer.android.com
  - Set `ANDROID_HOME` environment variable (e.g. `$HOME/Android/Sdk`)

### For Linux desktop builds
- **GTK 3 development libraries**
  - Ubuntu/Debian: `sudo apt install libgtk-3-dev cmake clang ninja-build pkg-config`
  - Fedora: `sudo dnf install gtk3-devel cmake clang ninja-build pkg-config`
  - Arch: `sudo pacman -S gtk3 cmake clang ninja pkg-config`
- **Linux toolchain** — cmake, clang, ninja-build, pkg-config

### For web builds
No additional prerequisites — Flutter handles web builds out of the box.

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/xpufx/uppidi-upload.git
cd uppidi-upload

# 2. Get dependencies
flutter pub get

# 3. Choose your build target

# Android APK (arm64)
flutter build apk --release --target-platform android-arm64

# Android APK (all architectures)
flutter build apk --release

# Linux desktop
flutter build linux --release

# Web
flutter build web
```

Build outputs:
- **Android**: `build/app/outputs/flutter-apk/app-release.apk`
- **Linux**: `build/linux/x64/release/bundle/`
- **Web**: `build/web/`

---

## Build Script

An automated build script is provided at `scripts/build.sh`. It checks prerequisites, installs dependencies, and builds the requested target:

```bash
# Show available targets
bash scripts/build.sh

# Build for a specific target
bash scripts/build.sh android
bash scripts/build.sh linux
bash scripts/build.sh web

# Build all supported targets
bash scripts/build.sh all
```

Run it without arguments to see usage and detected environment.

---

## Provider Health Checks

The scheduled provider health check probes the anonymous providers with the
live upload path and produces `providers.json`. Normal test runs
skip live endpoints (`SKIP_LIVE_TESTS=1`); the health job runs the dedicated
live runner:

```bash
# Local dry run — probes providers and prints the manifest, writes nothing:
RUN_HEALTH_CHECK=1 flutter test test/health_check_test.dart

# Write the manifest (atomic temp file + rename):
RUN_HEALTH_CHECK=1 HEALTH_OUTPUT=/path/to/providers.json \
  flutter test test/health_check_test.dart
```

The runner reads any existing manifest from `HEALTH_INPUT` (defaults to
`HEALTH_OUTPUT`) so `failureCount`/`since` survive between runs. A provider is
disabled only after 2 consecutive failures and re-enabled on the next success.

CI: `.forgejo/workflows/health.yml` runs every 6 hours on the self-hosted
`debian-bookworm-flutter` runner.

### `providers.json` output

The manifest is currently produced by the health workflow as a build artifact
only (`providers.json`, attached to each run). There is no static CDN origin
wired up yet, so nothing consumes it automatically. When a real static origin
exists, add publishing to that origin and wire the app's `CDN_URL` build-time
define to it.
