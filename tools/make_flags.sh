#!/bin/bash
# Downloads flag-icons (lipis, MIT) 4x3 SVGs and rasterizes them to PNGs bundled with the app.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="Sources/LangBar/Flags"
TMP="$(mktemp -d)"
mkdir -p "$OUT"

# country codes used by the language registry
CODES=(gb ru es fr de it pt nl pl ua tr sa il jp kr cn ro cz)

for code in "${CODES[@]}"; do
  url="https://cdn.jsdelivr.net/gh/lipis/flag-icons/flags/4x3/${code}.svg"
  curl -sL -o "$TMP/${code}.svg" "$url"
  size=$(wc -c < "$TMP/${code}.svg")
  if [ "$size" -lt 100 ]; then echo "⚠️  $code looks too small ($size bytes)"; fi
  rm -f "$TMP/${code}.svg.png"
  qlmanage -t -s 240 -o "$TMP" "$TMP/${code}.svg" >/dev/null 2>&1
  # qlmanage fits the 4:3 flag (240x180) into a padded 240x240 square; crop the centre back out.
  # (Center-crop, not -trim, so solid white borders like JP/KR aren't eaten.)
  magick "$TMP/${code}.svg.png" -gravity center -crop 240x180+0+0 +repage "$OUT/${code}.png"
  printf "  %-3s -> %s (%s)\n" "$code" "$OUT/${code}.png" "$(sips -g pixelWidth -g pixelHeight "$OUT/${code}.png" 2>/dev/null | grep -i pixel | tr -d '\n' | sed 's/  */ /g')"
done
rm -rf "$TMP"
echo "✅ $(ls "$OUT" | wc -l | tr -d ' ') flags in $OUT"
