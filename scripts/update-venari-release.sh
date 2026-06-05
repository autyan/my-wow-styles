#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENARI_REPO="${VENARI_REPO:-/home/autyan/SourceCode/venari-wow-plugin}"
SRC_DIR="$VENARI_REPO/dist/release/Venari"
DST_DIR="$REPO_ROOT/src/versions/tbc-anniversary-cn/addons/Venari"

"$VENARI_REPO/scripts/build-release.sh"

rm -rf "$DST_DIR"
mkdir -p "$(dirname "$DST_DIR")"
cp -a "$SRC_DIR" "$DST_DIR"

echo "Updated Venari release in my-wow-styles: $DST_DIR"
