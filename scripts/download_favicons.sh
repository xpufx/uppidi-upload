#!/bin/bash
# Downloads favicons for all upload providers and saves them as PNG assets.
# Uses Google's favicon service which always returns a 64x64 PNG.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets/favicons"
mkdir -p "$ASSETS_DIR"

# Exact runtime providerId -> domain mapping
# providerId must match what the provider class returns so the asset lookup works.
declare -A DOMAINS
DOMAINS[httpbin]="httpbin.org"
DOMAINS[catbox]="catbox.moe"
DOMAINS[tmpfilelink]="tmpfile.link"
DOMAINS[freeimage_freeimage_host]="freeimage.host"
DOMAINS[uguu_uguu_se]="uguu.se"
DOMAINS[tempsh]="temp.sh"
DOMAINS[frisk]="frisk.page"
DOMAINS[litterbox]="litterbox.catbox.moe"
DOMAINS[fileditch]="new.fileditch.com"
DOMAINS[gofile]="gofile.io"

echo "==> Downloading provider favicons..."

for id in "${!DOMAINS[@]}"; do
	domain="${DOMAINS[$id]}"
	out="$ASSETS_DIR/$id.png"
	url="https://www.google.com/s2/favicons?domain=$domain&sz=64"

	echo -n "  $id ($domain) ... "
	if curl -sL --connect-timeout 5 --max-time 10 "$url" -o "$out" && [ -s "$out" ]; then
		echo "done ($(du -h "$out" | cut -f1))"
	else
		echo "failed — creating fallback"
		# Minimal 1x1 transparent PNG
		printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x0aIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\x09\x2c\x6c\xc3\x00\x00\x00\x00IEND\xaeB`\x82' >"$out"
	fi
done

echo ""
echo "Done — all favicons in assets/favicons/"
