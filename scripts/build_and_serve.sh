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
echo "==> Building Android APK @ ${GIT_HASH}..."
flutter build apk --release --split-per-abi --dart-define=GIT_HASH=$GIT_HASH

echo "==> Copying APKs to ${ARTIFACTS_DIR}..."
APK_DIR="build/app/outputs/flutter-apk"
for abi in arm64-v8a armeabi-v7a x86_64; do
  SRC="${APK_DIR}/app-${abi}-release.apk"
  DST="uppidi-${VERSION}-${GIT_HASH}-android-${abi}.apk"
  if [ -f "$SRC" ]; then
    cp "$SRC" "${ARTIFACTS_DIR}/${DST}"
    echo "    ${DST}"
  fi
done

echo "==> Cleaning old APKs (keep latest 5 per ABI)..."
for abi in arm64-v8a armeabi-v7a x86_64; do
  ls -t "${ARTIFACTS_DIR}"/*-${abi}.apk 2>/dev/null | tail -n +6 | xargs -r rm -f
done

# ── Linux ──────────────────────────────────────────────────
LINUX_NAME="uppidi-${VERSION}-${GIT_HASH}-linux.tar.gz"

echo "==> Building Linux release @ ${GIT_HASH}..."
flutter build linux --release --dart-define=GIT_HASH=$GIT_HASH

echo "==> Packaging Linux release..."
tar -czf "${ARTIFACTS_DIR}/${LINUX_NAME}" -C build/linux/x64/release/bundle .

echo "==> Cleaning old Linux builds (keep latest 5)..."
ls -t "${ARTIFACTS_DIR}"/*-linux.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm -f

echo ""
echo "==> Done"
echo "    ${ARTIFACTS_DIR}/${APK_NAME}"
echo "    ${ARTIFACTS_DIR}/${LINUX_NAME}"
