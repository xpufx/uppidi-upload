#!/bin/bash
set -e

export ANDROID_HOME="$HOME/.android"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$HOME/.flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

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

# ── Bare string check (no Text('...') without l10n.*) ──────
echo "==> Checking for bare UI strings..."
if ! dart run scripts/check_bare_strings.dart 2>&1; then
	exit 1
fi

# ── Raw storage check (FlutterSecureStorage outside config_provider) ──
echo "==> Checking for direct storage access..."
if ! dart run scripts/check_raw_storage.dart 2>&1; then
	exit 1
fi

# ── Wide config check (Map<String, String> in upload signatures) ──
echo "==> Checking for wide config types..."
dart run scripts/check_wide_config.dart 2>&1 || true

# ── Localization check (gen-l10n reports untranslated keys) ─
echo "==> Checking for untranslated localization keys..."
GEN_OUTPUT=$(flutter gen-l10n 2>&1 || true)
if echo "$GEN_OUTPUT" | grep -qi "untranslated\|not translated\|missing\|warning"; then
	echo "❌ Untranslated localization keys found:"
	echo "$GEN_OUTPUT"
	echo "   Add the missing keys to the relevant ARB files."
	exit 1
fi
echo "   ✅ All localization keys translated across all locales"

# ── Capture git hash BEFORE changelog commit ─────────────────
# This ensures artifact filenames match the tag/release commit.
GIT_HASH=$(git rev-parse --short HEAD)
# Compact timestamp as Android versionCode: yyMMddHHmm, always increasing, git-proof.
BUILD_NUM=$(date +%y%j%H%M)

# ── Refresh changelog (no commit — avoids spam in git log) ──
echo "# Changelog" >CHANGELOG.md
echo "" >>CHANGELOG.md
git log --oneline --format="- %s" | head -30 >>CHANGELOG.md
echo "   ✅ Changelog refreshed (unstaged)"
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null || echo "")
case "$GIT_DIR" in
*/worktrees/*)
	WORKTREE_NAME=$(basename "$PROJECT_ROOT")
	MAIN_REPO_DIR="${GIT_DIR%/worktrees/*}"
	MAIN_REPO_DIR="${MAIN_REPO_DIR%/.git}"
	ARTIFACTS_DIR="${MAIN_REPO_DIR}/.caddy-artifacts/worktrees/${WORKTREE_NAME}"
	;;
*)
	ARTIFACTS_DIR="${PROJECT_ROOT}/.caddy-artifacts"
	;;
esac
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
flutter build apk $BUILD_MODE --split-per-abi \
	--build-number=$BUILD_NUM --build-name=$VERSION \
	--dart-define=GIT_HASH=$GIT_HASH $CDN_DEFINE $DEV_DEFINE

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
	# Only match versioned files (starts with a digit), not symlinks like latest-*
	ls -t "${ARTIFACTS_DIR}"/uppidi-upload-[0-9]*-android-${abi}.apk 2>/dev/null | tail -n +2 | xargs -r rm -f
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
ls -t "${ARTIFACTS_DIR}"/uppidi-upload-[0-9]*-linux.tar.gz 2>/dev/null | tail -n +2 | xargs -r rm -f

# ── AppImage ─────────────────────────────────────────────────
if [ -f "$(dirname "$0")/build-appimage.sh" ]; then
	echo "==> Building AppImage..."
	bash "$(dirname "$0")/build-appimage.sh" \
		--no-flutter-build \
		"--hash=${GIT_HASH}" \
		"--artifacts-dir=${ARTIFACTS_DIR}"

	echo "==> Cleaning old AppImages (keep latest 1)..."
	ls -t "${ARTIFACTS_DIR}"/uppidi-upload-[0-9]*-x86_64.AppImage 2>/dev/null | tail -n +2 | xargs -r rm -f
fi

# ── Flatpak ──────────────────────────────────────────────────
if command -v flatpak-builder &>/dev/null; then
	echo "==> Building Flatpak..."
	FLATPAK_SRC="flatpak-src"
	mkdir -p "$FLATPAK_SRC/lib"
	cp -r "build/linux/x64/${BUILD_TYPE}/bundle"/* "$FLATPAK_SRC/"
	cp /lib/x86_64-linux-gnu/libsecret-1.so.0 "$FLATPAK_SRC/lib/" 2>/dev/null || true
	for sz in 48 64 128; do
		srcdir="$FLATPAK_SRC/share/icons/hicolor/${sz}x${sz}/apps"
		mkdir -p "$srcdir"
		convert "$FLATPAK_SRC/share/icons/hicolor/256x256/apps/com.uppidi.uppidi.png" \
			-resize ${sz}x${sz} "$srcdir/com.uppidi.uppidi.png" 2>/dev/null || true
	done
	mkdir -p "$FLATPAK_SRC/share/metainfo"
	sed -e "s/__VERSION__/$VERSION/g" \
		-e "s/__DATE__/$(date -I)/g" \
		com.uppidi.uppidi.metainfo.xml \
		>"$FLATPAK_SRC/share/metainfo/com.uppidi.uppidi.metainfo.xml"
	FLATPAK_NAME="uppidi-upload-${VERSION}-${GIT_HASH}-linux.flatpak"
	flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
	flatpak install -y --noninteractive --user flathub \
		org.freedesktop.Platform//24.08 \
		org.freedesktop.Sdk//24.08 2>/dev/null || true
	if flatpak-builder --disable-rofiles-fuse --force-clean --repo=repo --default-branch="$VERSION" build-dir com.uppidi.uppidi.yml 2>&1; then
		flatpak build-bundle repo "${ARTIFACTS_DIR}/${FLATPAK_NAME}" com.uppidi.uppidi "$VERSION"
		ln -sf "$FLATPAK_NAME" "${ARTIFACTS_DIR}/uppidi-upload-latest-linux.flatpak"
		echo "    ${FLATPAK_NAME}"
		echo "==> Cleaning old Flatpaks (keep latest 1)..."
		ls -t "${ARTIFACTS_DIR}"/uppidi-upload-[0-9]*-linux.flatpak 2>/dev/null | tail -n +2 | xargs -r rm -f
	else
		echo "   ⏭️  Flatpak build failed — skipping"
	fi
else
	echo "   ⏭️  flatpak-builder not found — skipping Flatpak"
fi

echo ""
echo "==> Done (${BUILD_TYPE})"
echo "    uppidi-upload-${VERSION}-${GIT_HASH}-android-{arm64-v8a,armeabi-v7a,x86_64}.apk"
echo "    uppidi-upload-${VERSION}-${GIT_HASH}-linux.tar.gz"
echo "    uppidi-upload-${VERSION}-${GIT_HASH}-linux.flatpak"

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

echo ""
echo "Happy testing! (${GIT_HASH})"

true # ensure script always exits 0 after checklist
