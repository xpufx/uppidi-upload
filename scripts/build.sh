#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# Uppidi build script
#   Builds the app for Android, Linux, and/or web.
#   Checks prerequisites before building.
#
# Usage:
#   bash scripts/build.sh               # show usage
#   bash scripts/build.sh android       # build Android APK
#   bash scripts/build.sh linux         # build Linux desktop
#   bash scripts/build.sh web           # build web bundle
#   bash scripts/build.sh all           # build all supported targets
# ──────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

pass() { echo -e "  ${GREEN}✔${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✘${NC} $1"; }

# ── Help / usage ──────────────────────────────────────────────
usage() {
	echo "Uppidi — Build Script"
	echo ""
	echo "Usage:  bash scripts/build.sh <target>"
	echo ""
	echo "Targets:"
	echo "  android    Build Android APK (release)"
	echo "  linux      Build Linux desktop (release)"
	echo "  web        Build web bundle (release)"
	echo "  all        Build all supported targets"
	echo ""
	echo "Prerequisites:"
	echo "  - Flutter SDK >= 3.16.0 (flutter must be on PATH)"
	echo "  - Android build: JDK 17+, Android SDK, ANDROID_HOME set"
	echo "  - Linux build:   gtk3-dev, cmake, clang, ninja-build, pkg-config"
	echo "  - Web build:     none beyond Flutter"
	echo ""
}

if [ $# -eq 0 ]; then
	usage
	exit 0
fi

TARGET="${1:-}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo ""
echo -e "${BOLD}═══ Uppidi Build ═══${NC}"
echo "  Project: $PROJECT_DIR"
echo "  Target:  $TARGET"
echo ""

# ── Check required: git ──────────────────────────────────────
echo -e "${BOLD}Checking prerequisites...${NC}"
GIT_OK=true
if ! command -v git &>/dev/null; then
	fail "git is not installed"
	GIT_OK=false
else
	pass "git found: $(git --version 2>&1 | head -1)"
fi

# ── Check required: flutter ──────────────────────────────────
FLUTTER_OK=true
if ! command -v flutter &>/dev/null; then
	fail "flutter is not on PATH"
	FLUTTER_OK=false
else
	FLUTTER_VERSION=$(flutter --version 2>&1 | head -1)
	pass "flutter found: $FLUTTER_VERSION"
fi

# ── Check target-specific prerequisites ──────────────────────
ANDROID_OK=true
LINUX_OK=true

case "$TARGET" in
android | all)
	# Check Java
	if ! command -v java &>/dev/null; then
		fail "java not found — required for Android builds (JDK 17+)"
		ANDROID_OK=false
	else
		JAVA_VER=$(java -version 2>&1 | head -1)
		pass "java found: $JAVA_VER"
	fi

	# Check ANDROID_HOME
	if [ -z "${ANDROID_HOME:-}" ]; then
		fail "ANDROID_HOME is not set"
		ANDROID_OK=false
	else
		pass "ANDROID_HOME = $ANDROID_HOME"
		if [ ! -d "$ANDROID_HOME" ]; then
			fail "ANDROID_HOME directory does not exist: $ANDROID_HOME"
			ANDROID_OK=false
		fi
	fi

	# Check Android SDK command-line tools
	if [ -n "${ANDROID_HOME:-}" ] && [ ! -d "$ANDROID_HOME/cmdline-tools" ] && [ ! -d "$ANDROID_HOME/tools" ]; then
		warn "Android SDK command-line tools not found in ANDROID_HOME"
		warn "  Run: flutter doctor --android-licenses"
	fi
	;;
esac

case "$TARGET" in
linux | all)
	# Check common Linux desktop dev libraries
	for cmd in cmake clang ninja pkg-config; do
		if ! command -v "$cmd" &>/dev/null; then
			warn "$cmd not found — Linux desktop build may fail"
			LINUX_OK=false
		fi
	done
	if command -v cmake &>/dev/null; then
		pass "cmake found: $(cmake --version 2>&1 | head -1)"
	fi
	if command -v clang &>/dev/null; then
		pass "clang found: $(clang --version 2>&1 | head -1)"
	fi
	if command -v ninja &>/dev/null; then
		pass "ninja found: $(ninja --version 2>&1 | head -1)"
	fi
	if command -v pkg-config &>/dev/null; then
		pass "pkg-config found: $(pkg-config --version 2>&1 | head -1)"
	fi
	;;
esac

echo ""

# ── Abort if required tools are missing ──────────────────────
if [ "$FLUTTER_OK" = false ]; then
	echo -e "${RED}Flutter is required for all targets. Install it from:${NC}"
	echo "  https://docs.flutter.dev/get-started/install"
	echo ""
	exit 1
fi

if [ "$TARGET" = "android" ] && [ "$ANDROID_OK" = false ]; then
	echo -e "${RED}Android prerequisites not met.${NC}"
	echo "  Install JDK 17+ and the Android SDK, then set ANDROID_HOME."
	echo ""
	exit 1
fi

# ── Flutter pub get ──────────────────────────────────────────
echo -e "${BOLD}Installing dependencies...${NC}"
flutter pub get
echo ""

# ── Build ────────────────────────────────────────────────────
build_android() {
	echo -e "${BOLD}Building Android APK (release)...${NC}"
	flutter build apk --release
	echo ""
	APK="build/app/outputs/flutter-apk/app-release.apk"
	if [ -f "$APK" ]; then
		pass "Android APK: $APK"
		ls -lh "$APK"
	else
		fail "Android APK not found at $APK"
	fi
}

build_linux() {
	echo -e "${BOLD}Building Linux desktop (release)...${NC}"
	flutter build linux --release
	echo ""
	LINUX_BUNDLE="build/linux/x64/release/bundle"
	if [ -d "$LINUX_BUNDLE" ]; then
		pass "Linux bundle: $LINUX_BUNDLE"
		ls -lh "$LINUX_BUNDLE"
	else
		fail "Linux bundle not found at $LINUX_BUNDLE"
	fi
}

build_web() {
	echo -e "${BOLD}Building web (release)...${NC}"
	flutter build web --release
	echo ""
	WEB_DIR="build/web"
	if [ -d "$WEB_DIR" ]; then
		pass "Web bundle: $WEB_DIR"
		ls -lh "$WEB_DIR/index.html"
	else
		fail "Web bundle not found at $WEB_DIR"
	fi
}

case "$TARGET" in
android)
	build_android
	;;
linux)
	build_linux
	;;
web)
	build_web
	;;
all)
	build_web
	echo ""
	build_linux
	echo ""
	build_android
	;;
*)
	echo -e "${RED}Unknown target: $TARGET${NC}"
	usage
	exit 1
	;;
esac

echo ""
echo -e "${GREEN}${BOLD}Done.${NC}"
