#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# Uppidi AppImage build script
#   Builds the Flutter Linux release and wraps it as an AppImage.
#
# Usage:
#   bash scripts/build-appimage.sh              # full build
#   bash scripts/build-appimage.sh --no-flutter-build  # skip flutter build
# ──────────────────────────────────────────────────────────────
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}✔${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✘${NC} $1"; }

SKIP_FLUTTER=false
if [ "${1:-}" = "--no-flutter-build" ]; then
	SKIP_FLUTTER=true
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="${PROJECT_DIR}/tools"
APPDIR="${PROJECT_DIR}/build/AppDir"

# ── Version helpers (mirrored from build.sh) ──────────────────
app_version() {
	grep '^version:' "${PROJECT_DIR}/pubspec.yaml" | sed 's/version: *//' | tr -d ' '
}
git_hash() {
	cd "$PROJECT_DIR" && git log -1 --format='%h' 2>/dev/null || echo 'unknown'
}

VER="$(app_version)"
HASH="$(git_hash)"

echo ""
echo -e "${BOLD}═══ Uppidi AppImage Build ═══${NC}"
echo "  Version: ${VER}-${HASH}"
echo ""

# ── Step 0: Ensure appimagetool ─────────────────────────────────
echo -e "${BOLD}Preparing appimagetool...${NC}"
APPIMAGETOOL=""
if command -v appimagetool &>/dev/null; then
	APPIMAGETOOL="$(command -v appimagetool)"
	pass "appimagetool found on PATH"
elif [ -f "${TOOLS_DIR}/appimagetool" ]; then
	APPIMAGETOOL="$(realpath "${TOOLS_DIR}/appimagetool")"
	pass "appimagetool found in tools/"
elif [ -x /usr/lib/x86_64-linux-gnu/appimagetool/appimagetool ]; then
	APPIMAGETOOL="/usr/lib/x86_64-linux-gnu/appimagetool/appimagetool"
	pass "appimagetool found (system)"
else
	warn "appimagetool not found — attempting download..."
	mkdir -p "$TOOLS_DIR"
	DOWNLOAD="${TOOLS_DIR}/appimagetool.AppImage"
	wget -q -O "$DOWNLOAD" \
		"https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
	chmod +x "$DOWNLOAD"

	cd "$TOOLS_DIR"
	if "$DOWNLOAD" --appimage-extract 2>/dev/null; then
		mv squashfs-root/usr/bin/appimagetool "$DOWNLOAD"
		rm -rf squashfs-root
		APPIMAGETOOL="$DOWNLOAD"
	else
		APPIMAGETOOL="$DOWNLOAD"
	fi
	cd "$PROJECT_DIR"
	pass "appimagetool prepared"
fi

if file "$APPIMAGETOOL" 2>/dev/null | grep -q "AppImage"; then
	export APPIMAGE_EXTRACT_AND_RUN=1
	warn "appimagetool is itself an AppImage — using APPIMAGE_EXTRACT_AND_RUN=1"
fi

# ── Step 1: Build Flutter Linux release (optional) ─────────────
if [ "$SKIP_FLUTTER" = false ]; then
	echo ""
	echo -e "${BOLD}Step 1: Building Flutter Linux release...${NC}"
	cd "$PROJECT_DIR"
	flutter build linux --release 2>&1 | tail -3
	pass "Flutter Linux build complete"
fi

BUNDLE="${PROJECT_DIR}/build/linux/x64/release/bundle"
if [ ! -d "$BUNDLE" ]; then
	fail "Bundle not found at $BUNDLE"
	fail "  Run without --no-flutter-build, or run 'flutter build linux --release' first."
	exit 1
fi
pass "Bundle exists at $BUNDLE"

# ── Step 2: Create AppDir from bundle ──────────────────────────
echo ""
echo -e "${BOLD}Step 2: Creating AppDir...${NC}"

rm -rf "$APPDIR"
mkdir -p "$APPDIR"

# Copy bundle contents.
cp -rp "$BUNDLE"/* "$APPDIR/"
pass "Bundle contents copied to AppDir"

# Add required AppImage metadata files.
cp "${PROJECT_DIR}/linux/com.uppidi.uppidi.desktop" "$APPDIR/"
pass ".desktop file added"

cp "${PROJECT_DIR}/linux/AppRun" "$APPDIR/"
chmod +x "$APPDIR/AppRun"
pass "AppRun added"

ln -sf "data/icon.png" "$APPDIR/.DirIcon"
pass ".DirIcon symlink created"

ln -sf "data/icon.png" "$APPDIR/com.uppidi.uppidi.png"
pass "root icon symlink created"

echo ""
echo "AppDir structure:"
find "$APPDIR" -maxdepth 2 -not -path '*/flutter_assets/*' -not -path '*/share/icons/hicolor/*' | sort | sed "s|$APPDIR|  AppDir|"

# ── Step 3: Build the AppImage ─────────────────────────────────
echo ""
echo -e "${BOLD}Step 3: Building AppImage...${NC}"

OUTPUT="${PROJECT_DIR}/uppidi-upload-${VER}-${HASH}-x86_64.AppImage"

"$APPIMAGETOOL" "$APPDIR" "$OUTPUT" 2>&1

echo ""
if [ ! -f "$OUTPUT" ]; then
	fail "AppImage not created — check errors above"
	exit 1
fi

chmod +x "$OUTPUT"
pass "AppImage built: $(ls -lh "$OUTPUT" | awk '{print $5}')"
echo "  $OUTPUT"

# ── Step 4: Deploy to .caddy-artifacts/ ────────────────────────
echo ""
echo -e "${BOLD}Step 4: Deploying to .caddy-artifacts/...${NC}"

DEST_DIR="${PROJECT_DIR}/.caddy-artifacts"
mkdir -p "$DEST_DIR"

FILENAME="uppidi-upload-${VER}-${HASH}-x86_64.AppImage"
DEST="${DEST_DIR}/${FILENAME}"
LINK="${DEST_DIR}/uppidi-upload-latest-x86_64.AppImage"

cp "$OUTPUT" "$DEST"
pass "deployed: ${FILENAME} ($(du -h "$DEST" | cut -f1))"

ln -sf "$FILENAME" "$LINK"
pass "updated:  ${LINK} → ${FILENAME}"

# ── Done ───────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}Done.${NC}"
echo ""
echo "  AppImage:    $OUTPUT"
echo "  Deployed:    $DEST"
echo "  Latest:      $LINK"
echo "  To run:      $OUTPUT"
echo "  To register: $OUTPUT --register-app"
echo ""
