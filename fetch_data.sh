#!/usr/bin/env bash
# Download release v1 data assets (no authentication needed) and unpack into ./data/
# Usage: ./fetch_data.sh                 # all assets
#        ./fetch_data.sh part01 part02   # only assets whose name contains any of the given substrings
set -euo pipefail
REPO="meldar1986/bybit-1m-data"
TAG="v1"
BASE="https://github.com/${REPO}/releases/download/${TAG}"
cd "$(dirname "$0")"
mkdir -p data .dl
[ -f manifest.json ] || curl -fsSL "https://raw.githubusercontent.com/${REPO}/main/manifest.json" -o manifest.json
mapfile -t ASSETS < <(python3 -c 'import json;[print(k, v["sha256"]) for k,v in json.load(open("manifest.json"))["assets"].items()]')
for line in "${ASSETS[@]}"; do
  name="${line%% *}"; sha="${line##* }"
  if [ $# -gt 0 ]; then
    keep=0; for f in "$@"; do [[ "$name" == *"$f"* ]] && keep=1; done
    [ $keep -eq 1 ] || continue
  fi
  echo ">> $name"
  curl -fL --retry 5 --retry-delay 5 -o ".dl/$name" "$BASE/$name"
  echo "$sha  .dl/$name" | sha256sum -c -
  python3 -c 'import sys,zipfile;zipfile.ZipFile(sys.argv[1]).extractall("data")' ".dl/$name"
  rm -f ".dl/$name"
done
rmdir .dl 2>/dev/null || true
echo "done: $(ls data/ohlcv 2>/dev/null | wc -l) ohlcv files, $(ls data/funding 2>/dev/null | wc -l) funding files in ./data"
