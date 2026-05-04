#!/bin/bash
set -e

export ANDROID_HOME="$HOME/.android"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$HOME/.flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

cd /home/oktay/code/uppidi

GIT_HASH=$(git rev-parse --short HEAD)
VERSION=$(grep 'version:' pubspec.yaml | head -1 | awk '{print $2}')
ARTIFACTS_DIR="/home/oktay/code/uppidi/.caddy-artifacts"
mkdir -p "$ARTIFACTS_DIR"

# ── Android APK ────────────────────────────────────────────
echo "==> Building Android APK (arm64) @ ${GIT_HASH}..."
flutter build apk --release --target-platform android-arm64 --dart-define=GIT_HASH=$GIT_HASH

echo "==> Copying APK to ${ARTIFACTS_DIR}..."
APK_DIR="build/app/outputs/flutter-apk"
SRC="${APK_DIR}/app-release.apk"
DST="uppidi-upload-${VERSION}-${GIT_HASH}-android-arm64-v8a.apk"
cp "$SRC" "${ARTIFACTS_DIR}/${DST}"
echo "    ${DST}"

echo "==> Updating latest symlink..."
ln -sf "${DST}" "${ARTIFACTS_DIR}/uppidi-upload-latest-android-arm64-v8a.apk"

echo "==> Cleaning old APKs (keep latest 5)..."
ls -t "${ARTIFACTS_DIR}"/*-android-*.apk 2>/dev/null | tail -n +6 | xargs -r rm -f

# ── Linux ──────────────────────────────────────────────────
LINUX_NAME="uppidi-upload-${VERSION}-${GIT_HASH}-linux.tar.gz"

echo "==> Building Linux release @ ${GIT_HASH}..."
flutter build linux --release --dart-define=GIT_HASH=$GIT_HASH

echo "==> Packaging Linux release..."
tar -czf "${ARTIFACTS_DIR}/${LINUX_NAME}" -C build/linux/x64/release/bundle .

echo "==> Updating latest symlink..."
ln -sf "${LINUX_NAME}" "${ARTIFACTS_DIR}/uppidi-upload-latest-linux.tar.gz"

echo "==> Cleaning old Linux builds (keep latest 5)..."
ls -t "${ARTIFACTS_DIR}"/*-linux.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm -f

echo ""
echo "==> Done"
echo "    ${DST}"
echo "    ${LINUX_NAME}"
