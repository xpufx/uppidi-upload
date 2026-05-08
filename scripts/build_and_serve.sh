#!/bin/bash
set -e

export ANDROID_HOME="$HOME/.android"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$HOME/.flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

cd /home/xpufx/code/uppidi

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

# ── Auto-generate changelog ──────────────────────────────────
echo "==> Updating CHANGELOG.md..."
echo "# Changelog" >CHANGELOG.md
echo "" >>CHANGELOG.md

git log --oneline --format="- %s" | head -30 >>CHANGELOG.md
git add CHANGELOG.md 2>/dev/null
git commit -m "docs: auto-update changelog" --no-verify 2>/dev/null || true
echo "   ✅ Changelog updated"

GIT_HASH=$(git rev-parse --short HEAD)
ARTIFACTS_DIR="/home/xpufx/code/uppidi/.caddy-artifacts"
mkdir -p "$ARTIFACTS_DIR"

# ── Android APK ────────────────────────────────────────────
echo "==> Building Android APK (arm64) @ ${GIT_HASH}..."
flutter build apk --release --target-platform android-arm64 --dart-define=GIT_HASH=$GIT_HASH --dart-define=CDN_URL=http://10.20.30.24

echo "==> Copying APK to ${ARTIFACTS_DIR}..."
APK_DIR="build/app/outputs/flutter-apk"
SRC="${APK_DIR}/app-release.apk"
DST="uppidi-upload-${VERSION}-${GIT_HASH}-android-arm64-v8a.apk"
cp "$SRC" "${ARTIFACTS_DIR}/${DST}"
echo "    ${DST}"

echo "==> Updating latest symlink..."
ln -sf "${DST}" "${ARTIFACTS_DIR}/uppidi-upload-latest-android-arm64-v8a.apk"

echo "==> Writing version file..."
echo "$GIT_HASH" >"${ARTIFACTS_DIR}/latest.txt"

echo "==> Cleaning old APKs (keep latest 5)..."
ls -t "${ARTIFACTS_DIR}"/uppidi-upload-*-android-*.apk 2>/dev/null | tail -n +6 | xargs -r rm -f

# ── Linux ──────────────────────────────────────────────────
LINUX_NAME="uppidi-upload-${VERSION}-${GIT_HASH}-linux.tar.gz"

echo "==> Building Linux release @ ${GIT_HASH}..."
flutter build linux --release --dart-define=GIT_HASH=$GIT_HASH --dart-define=CDN_URL=http://10.20.30.24

echo "==> Packaging Linux release..."
tar -czf "${ARTIFACTS_DIR}/${LINUX_NAME}" -C build/linux/x64/release/bundle .

echo "==> Updating latest symlink..."
ln -sf "${LINUX_NAME}" "${ARTIFACTS_DIR}/uppidi-upload-latest-linux.tar.gz"

echo "==> Cleaning old Linux builds (keep latest 5)..."
ls -t "${ARTIFACTS_DIR}"/uppidi-upload-*-linux.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm -f

echo ""
echo "==> Done"
echo "    ${DST}"
echo "    ${LINUX_NAME}"

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
echo "Happy testing!"

true # ensure script always exits 0 after checklist
