#!/bin/bash
set -e

cd /home/oktay/code/uppidi

GIT_HASH=$(git rev-parse --short HEAD)
VERSION=$(grep 'version:' pubspec.yaml | head -1 | awk '{print $2}')
FILENAME="${VERSION}-${GIT_HASH}-release.apk"

echo "==> Building release APK @ ${GIT_HASH}..."
flutter build apk --release --dart-define=GIT_HASH=$GIT_HASH

echo "==> Copying to server..."
cp build/app/outputs/flutter-apk/app-release.apk "/tmp/$FILENAME"

# Update index
cat > /tmp/index.html << EOF
<!DOCTYPE html>
<html><head><title>uppidi builds</title></head><body>
<h1>uppidi v${VERSION}</h1>
<ul>
  <li><a href="app-debug.apk">debug (188MB)</a></li>
  <li><a href="${FILENAME}">release (54MB) @ ${GIT_HASH}</a></li>
</ul>
</body></html>
EOF

# Ensure server is running
curl -s -o /dev/null http://10.20.30.24:8081/ 2>/dev/null || setsid python3 -m http.server 8081 --bind 0.0.0.0 --directory /tmp </dev/null &>/dev/null &

echo "==> http://10.20.30.24:8081/${FILENAME}"
