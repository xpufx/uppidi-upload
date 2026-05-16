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
OVERRIDE_HASH=""
for arg in "$@"; do
	case "$arg" in
	--no-flutter-build) SKIP_FLUTTER=true ;;
	--hash=*) OVERRIDE_HASH="${arg#--hash=}" ;;
	esac
done

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="${PROJECT_DIR}/tools"
APPDIR="${PROJECT_DIR}/build/AppDir"

# ── Version helpers (mirrored from build.sh) ──────────────────
app_version() {
	grep '^version:' "${PROJECT_DIR}/pubspec.yaml" | sed 's/version: *//' | tr -d ' '
}
git_hash() {
	if [ -n "$OVERRIDE_HASH" ]; then
		echo "$OVERRIDE_HASH"
	else
		cd "$PROJECT_DIR" && git log -1 --format='%h' 2>/dev/null || echo 'unknown'
	fi
}

VER="$(app_version)"
HASH="$(git_hash)"

echo ""
echo -e "${BOLD}═══ Uppidi AppImage Build ═══${NC}"
echo "  Version: ${VER}-${HASH}"
echo ""

# ── Step 0: Ensure AppImage runtime ─────────────────────────────
echo -e "${BOLD}Preparing AppImage runtime...${NC}"
RUNTIME="${TOOLS_DIR}/appimageruntime"
if [ -f "$RUNTIME" ]; then
	pass "AppImage runtime found in tools/"
else
	warn "runtime not found — downloading..."
	mkdir -p "$TOOLS_DIR"
	wget -q -O "$RUNTIME" \
		"https://github.com/AppImage/AppImageKit/releases/download/continuous/runtime-x86_64"
	chmod +x "$RUNTIME"
	pass "runtime downloaded (static ELF, not an AppImage)"
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

# Add AppStream metainfo
mkdir -p "$APPDIR/usr/share/metainfo"
cp "${PROJECT_DIR}/linux/com.uppidi.uppidi.appdata.xml" "$APPDIR/usr/share/metainfo/"
pass "AppStream metainfo added"

# Install desktop file in standard path for AppStream validation
mkdir -p "$APPDIR/usr/share/applications"
cp "${PROJECT_DIR}/linux/com.uppidi.uppidi.desktop" "$APPDIR/usr/share/applications/"
pass "desktop file installed in standard path"

echo ""
echo "AppDir structure:"
find "$APPDIR" -maxdepth 2 -not -path '*/flutter_assets/*' -not -path '*/share/icons/hicolor/*' | sort | sed "s|$APPDIR|  AppDir|"

# ── Step 3: Build the AppImage (mksquashfs + runtime) ──────────
echo ""
echo -e "${BOLD}Step 3: Building AppImage...${NC}"

OUTPUT="${PROJECT_DIR}/uppidi-upload-${VER}-${HASH}-x86_64.AppImage"
SFS="${PROJECT_DIR}/.tmp.squashfs"

# Create SquashFS filesystem (write to temp, then prepend runtime)
mksquashfs "$APPDIR" "$SFS" -noappend -comp gzip -quiet

# Build final AppImage: runtime then squashfs
cat "$RUNTIME" "$SFS" >"$OUTPUT"
rm -f "$SFS"
chmod +x "$OUTPUT"

if [ ! -f "$OUTPUT" ]; then
	fail "AppImage not created"
	exit 1
fi
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
