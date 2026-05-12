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
#   bash scripts/build.sh linux         # build Linux desktop + AppImage
#   bash scripts/build.sh web           # build web bundle
#   bash scripts/build.sh all           # build all supported targets
# ──────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

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
	echo "  linux      Build Linux desktop (release) + AppImage"
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

# ── Shared helpers ────────────────────────────────────────────
# Extract app version from pubspec.yaml (e.g. "1.2.0+3").
app_version() {
	grep '^version:' pubspec.yaml | sed 's/version: *//' | tr -d ' '
}

# Short git hash from HEAD.
git_hash() {
	git log -1 --format='%h' 2>/dev/null || echo 'unknown'
}

# Deploy a build artifact to .caddy-artifacts/ with proper naming and latest symlink.
# Usage: deploy_artifact <src> <platform-ext>
#   <src>          Path to the built file.
#   <platform-ext> e.g. "linux.tar.gz", "android-arm64-v8a.apk", "x86_64.AppImage"
deploy_artifact() {
	local src="$1"
	local plat_ext="$2"
	local ver
	ver="$(app_version)"
	local hash
	hash="$(git_hash)"
	local dest_dir="${PROJECT_DIR}/.caddy-artifacts"
	mkdir -p "$dest_dir"

	local filename="uppidi-upload-${ver}-${hash}-${plat_ext}"
	local dest="${dest_dir}/${filename}"

	cp "$src" "$dest"
	pass "deployed: ${filename} ($(du -h "$dest" | cut -f1))"

	# Update latest symlink for this platform.
	local link="${dest_dir}/uppidi-upload-latest-${plat_ext}"
	ln -sf "$filename" "$link"
	pass "updated:  ${link} → ${filename}"
}

echo ""
echo -e "${BOLD}═══ Uppidi Build ═══${NC}"
echo "  Project: $PROJECT_DIR"
echo "  Target:  $TARGET"
echo "  Version: $(app_version)-$(git_hash)"

# ── Reminder: update CHANGELOG.md ─────────────────────────────
LAST_TAG=$(git tag -l 'v*' --sort=-version:refname 2>/dev/null | head -1)
if [ -n "$LAST_TAG" ]; then
	# If CHANGELOG.md wasn't modified since the last tag, remind the user.
	CL_MOD_TIME=$(git log -1 --format='%ct' "$LAST_TAG" -- CHANGELOG.md 2>/dev/null || echo 0)
	TAG_TIME=$(git log -1 --format='%ct' "$LAST_TAG" 2>/dev/null || echo 0)
	if [ "$CL_MOD_TIME" -le "$TAG_TIME" ]; then
		warn "CHANGELOG.md hasn't been updated since $LAST_TAG"
		warn "  Edit CHANGELOG.md to document changes for this release."
	fi
fi
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
	if ! command -v java &>/dev/null; then
		fail "java not found — required for Android builds (JDK 17+)"
		ANDROID_OK=false
	else
		JAVA_VER=$(java -version 2>&1 | head -1)
		pass "java found: $JAVA_VER"
	fi

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

	if [ -n "${ANDROID_HOME:-}" ] && [ ! -d "$ANDROID_HOME/cmdline-tools" ] && [ ! -d "$ANDROID_HOME/tools" ]; then
		warn "Android SDK command-line tools not found in ANDROID_HOME"
		warn "  Run: flutter doctor --android-licenses"
	fi
	;;
esac

case "$TARGET" in
linux | all)
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
	echo -e "${BOLD}Building Android APKs (release, split-per-abi)...${NC}"
	flutter build apk --release --split-per-abi
	echo ""
	APK_DIR="build/app/outputs/flutter-apk"
	COUNT=0
	for apk in "$APK_DIR"/app-*-release.apk; do
		[ -f "$apk" ] || continue
		# Extract ABI from filename: app-arm64-v8a-release.apk → arm64-v8a
		abi=$(basename "$apk" | sed 's/^app-//; s/-release\.apk$//')
		deploy_artifact "$apk" "android-${abi}.apk"
		COUNT=$((COUNT + 1))
	done
	if [ "$COUNT" -eq 0 ]; then
		fail "No APKs found in $APK_DIR"
	fi
}

build_linux() {
	echo -e "${BOLD}Building Linux desktop (release)...${NC}"
	flutter build linux --release
	echo ""
	BUNDLE="build/linux/x64/release/bundle"
	if [ ! -d "$BUNDLE" ]; then
		fail "Linux bundle not found at $BUNDLE"
		return
	fi
	pass "Linux bundle: $BUNDLE"

	# Package as tar.gz
	TARFILE="${PROJECT_DIR}/build/uppidi-upload-$(app_version)-$(git_hash)-linux.tar.gz"
	mkdir -p "$(dirname "$TARFILE")"
	tar -czf "$TARFILE" -C "$(dirname "$BUNDLE")" "$(basename "$BUNDLE")"
	ls -lh "$TARFILE"
	deploy_artifact "$TARFILE" "linux.tar.gz"

	# Build AppImage
	echo ""
	if [ -f "${PROJECT_DIR}/scripts/build-appimage.sh" ]; then
		bash "${PROJECT_DIR}/scripts/build-appimage.sh" --no-flutter-build
	else
		warn "scripts/build-appimage.sh not found — skipping AppImage"
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

# ── Print download URLs ───────────────────────────────────────
# Detect Caddy server IP (serves .caddy-artifacts on port 80)
CADDY_IP=$(ip -4 addr show 2>/dev/null | grep -oP 'inet \K[0-9.]+' | grep -v '127.0.0.1' | head -1)
if [ -n "$CADDY_IP" ]; then
	BASE_URL="http://$CADDY_IP"
else
	BASE_URL="http://$(hostname)"
fi

echo ""
echo -e "${BOLD}Download URLs:${NC}"
for f in "$PROJECT_DIR"/.caddy-artifacts/uppidi-upload-"$(app_version)"-*.{apk,AppImage,tar.gz}; do
	[ -f "$f" ] || continue
	name=$(basename "$f")
	echo "  $BASE_URL/$name"
done

echo ""
echo -e "${GREEN}${BOLD}Done.${NC}"
