#!/bin/bash
set -e

export ANDROID_HOME="$HOME/.android"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$HOME/.flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

cd /home/xpufx/code/uppidi

# ── Parse args ─────────────────────────────────────────────────
DEV=false
for arg in "$@"; do
	case "$arg" in
	--dev) DEV=true ;;
	esac
done

if [ "$DEV" = true ]; then
	BUILD_TYPE="release"
	DEV_DEFINE="--dart-define=DEV_PROVIDERS=true"
	CDN_DEFINE="--dart-define=CDN_URL=http://10.20.30.24"
else
	BUILD_TYPE="release"
	DEV_DEFINE=""
	CDN_DEFINE=""
fi
BUILD_MODE="--$BUILD_TYPE"

# ── Version sync ──────────────────────────────────────────────
VERSION=$(grep 'version:' pubspec.yaml | head -1 | awk '{print $2}')
VERSION_FILE="lib/core/version.dart"
echo "==> Syncing version to ${VERSION_FILE} (${VERSION})..."
sed -i "s/const String appVersion = '[0-9.+]*';/const String appVersion = '${VERSION}';/" "$VERSION_FILE"
git add "$VERSION_FILE" 2>/dev/null
echo "   ✅ Version synced"

# ── Hardcoded string check ──────────────────────────────────
echo "==> Checking for hardcoded strings..."
HARDCODED=$(grep -rn "Text(\'\|label: \'\|title: \'\|hintText: \'\|tooltip: \'\|child: Text(\'\|subtitle: Text(\'" lib/ --include="*.dart" |
	grep -v "l10n\." |
	grep -v "const\|static\|final\|String \|AppLocalizations\|RegExp\|gitHash\|appVersion\|GIT_HASH\|CHANGELOG\|changeLogText\|Proxy\|URL\|API\|OK\|iOS\|HTTP\|SOCKS\|FormatException\|Upload\|Provider\|Settings\|History\|Test\|Share\|Shared\|formatSize\|formatTime\|AppLogo\|Icon(\|Icons\." |
	grep -v "English\|Türkçe\|Italiano\|Uppidi\|uppidi" |
	grep -v "share_template\|template\|variables\|examples\|[\"']%[a-z]" |
	grep -E "['\"][A-Za-z]{3,}" ||
	true)
if [ -n "$HARDCODED" ]; then
	echo "❌ Found hardcoded English strings in UI code:"
	echo "$HARDCODED"
	echo "   Replace with l10n.* or add to ARB files."
	exit 1
fi
echo "   ✅ No hardcoded strings found"

# ── Capture git hash BEFORE changelog commit ─────────────────
# This ensures artifact filenames match the tag/release commit.
GIT_HASH=$(git rev-parse --short HEAD)

# ── Refresh changelog (no commit — avoids spam in git log) ──
echo "# Changelog" >CHANGELOG.md
echo "" >>CHANGELOG.md
git log --oneline --format="- %s" | head -30 >>CHANGELOG.md
echo "   ✅ Changelog refreshed (unstaged)"
ARTIFACTS_DIR="/home/xpufx/code/uppidi/.caddy-artifacts"
mkdir -p "$ARTIFACTS_DIR"

# ── Stale symlink cleanup ──────────────────────────────────
# Remove dangling symlinks left by other build methods (e.g. build.sh).
find "$ARTIFACTS_DIR" -xtype l -delete 2>/dev/null
echo "   ✅ Stale symlinks cleaned"

# ── Provider favicons (from repo, no re-download needed) ────
# Favicons are tracked in git under assets/favicons/.
# To refresh them, run: bash scripts/download_favicons.sh
echo "==> Using provider favicons from repo (assets/favicons/)..."
ls assets/favicons/*.png 2>/dev/null || echo "   (none found)"

# ── Android APK (split-per-abi) ───────────────────────────
echo "==> Building Android APKs @ ${GIT_HASH} (${BUILD_TYPE})..."
flutter build apk $BUILD_MODE --split-per-abi --dart-define=GIT_HASH=$GIT_HASH $CDN_DEFINE $DEV_DEFINE

echo "==> Deploying APKs..."
APK_DIR="build/app/outputs/flutter-apk"
for apk in "$APK_DIR"/app-*-${BUILD_TYPE}.apk; do
	[ -f "$apk" ] || continue
	abi=$(basename "$apk" | sed "s/^app-//; s/-${BUILD_TYPE}\.apk$//")
	dst="uppidi-upload-${VERSION}-${GIT_HASH}-android-${abi}.apk"
	cp "$apk" "${ARTIFACTS_DIR}/${dst}"
	ln -sf "$dst" "${ARTIFACTS_DIR}/uppidi-upload-latest-android-${abi}.apk"
	echo "    ${dst}"
done

echo "==> Writing version file..."
echo "$GIT_HASH" >"${ARTIFACTS_DIR}/latest.txt"

echo "==> Cleaning old APKs (keep latest 1 per ABI)..."
for abi in arm64-v8a armeabi-v7a x86_64; do
	ls -t "${ARTIFACTS_DIR}"/uppidi-upload-*-android-${abi}.apk 2>/dev/null | tail -n +2 | xargs -r rm -f
done

# ── Linux ──────────────────────────────────────────────────
LINUX_NAME="uppidi-upload-${VERSION}-${GIT_HASH}-linux.tar.gz"

echo "==> Building Linux release @ ${GIT_HASH} (${BUILD_TYPE})..."
flutter build linux $BUILD_MODE --dart-define=GIT_HASH=$GIT_HASH $CDN_DEFINE $DEV_DEFINE

echo "==> Packaging Linux release..."
tar -czf "${ARTIFACTS_DIR}/${LINUX_NAME}" -C "build/linux/x64/${BUILD_TYPE}/bundle" .

echo "==> Updating latest symlink..."
ln -sf "${LINUX_NAME}" "${ARTIFACTS_DIR}/uppidi-upload-latest-linux.tar.gz"

echo "==> Cleaning old Linux builds (keep latest 1)..."
ls -t "${ARTIFACTS_DIR}"/uppidi-upload-*-linux.tar.gz 2>/dev/null | tail -n +2 | xargs -r rm -f

# ── AppImage ─────────────────────────────────────────────────
if [ "$DEV" = false ] && [ -f "$(dirname "$0")/build-appimage.sh" ]; then
	echo "==> Building AppImage..."
	bash "$(dirname "$0")/build-appimage.sh" \
		--no-flutter-build \
		"--hash=${GIT_HASH}"
fi

echo ""
echo "==> Done (${BUILD_TYPE})"
echo "    uppidi-upload-${VERSION}-${GIT_HASH}-android-{arm64-v8a,armeabi-v7a,x86_64}.apk"
echo "    ${LINUX_NAME}"

# ── Tag release (only once per version) ──────────────────────────
if [ "$DEV" = false ]; then
	TAG="v${VERSION}"
	if git rev-parse "$TAG" &>/dev/null; then
		echo "==> Tag ${TAG} already exists — skipping"
	else
		echo "==> Tagging ${TAG} at ${GIT_HASH}..."
		git tag "$TAG" "$GIT_HASH"
		echo "   ✅ Tagged ${TAG} → ${GIT_HASH}"
		echo ""
		echo "   Push with: git push origin ${TAG}"
	fi
fi

# ── Feature test checklist ───────────────────────────────────
echo ""
echo "==> Test Checklist"
echo ""
cat <<'CHECKLIST'
[ ] Upload: Pick file, preview shows, Upload button works
[ ] Upload: Speed/progress animation during upload
[ ] Upload: Retry button appears on failure, preview stays
[ ] Upload: Cancel clears state, can upload again
[ ] Share: Share icon opens templated message dialog
[ ] Share: Info popup shows template variables + examples
[ ] Providers: Test All + individual test buttons work
[ ] Providers: Enable/disable toggle, reflects in Upload dropdown
[ ] History: Records visible, delete + copy + share work
[ ] Settings: Theme mode (System/Light/Dark) switches correctly
[ ] Settings: Color presets apply instantly
[ ] Settings: About card → View Changelog opens dialog
[ ] Theme: Logo changes between light/dark mode
[ ] Theme: Navigation buttons have visible colors
[ ] Localization: Change language, no hardcoded English text
[ ] Desktop: Drag-and-drop a file onto the upload area
CHECKLIST
echo ""
echo "Happy testing! (${GIT_HASH})"

true # ensure script always exits 0 after checklist
