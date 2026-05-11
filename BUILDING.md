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
