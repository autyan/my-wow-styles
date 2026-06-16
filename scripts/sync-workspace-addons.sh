#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_KEY="${1:-tbc-anniversary-cn}"
WOW_BASE="${WOW_BASE:-/home/autyan/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/2665554533/pfx/drive_c/Program Files (x86)/World of Warcraft}"

case "$VERSION_KEY" in
  tbc-anniversary-cn)
    GAME_DIR="${WOW_GAME_DIR:-_anniversary_}"
    ;;
  mop-classic-cn)
    GAME_DIR="${WOW_GAME_DIR:-_classic_}"
    ;;
  *)
    echo "unknown version: $VERSION_KEY" >&2
    exit 2
    ;;
esac

if pgrep -af -i 'WoWClassic\.exe' | grep -F "\\$GAME_DIR\\" >/dev/null; then
  echo "WoW $GAME_DIR is still running. Exit that game client before syncing workspace addons."
  exit 1
fi

rm -rf "$REPO_ROOT/build/dist/$VERSION_KEY/Interface/AddOns"
"$REPO_ROOT/scripts/build-workspace-addons.sh" "$VERSION_KEY"

SRC_ROOT="$REPO_ROOT/build/dist/$VERSION_KEY/Interface/AddOns"
DST_ROOT="$WOW_BASE/$GAME_DIR/Interface/AddOns"

if [[ ! -d "$SRC_ROOT" ]]; then
  echo "missing build output: $SRC_ROOT" >&2
  exit 1
fi

mkdir -p "$DST_ROOT"
for addon in "$SRC_ROOT"/*; do
  [[ -d "$addon" ]] || continue
  name="$(basename "$addon")"
  rm -rf "$DST_ROOT/$name"
  cp -a "$addon" "$DST_ROOT/$name"
  echo "synced $name -> $DST_ROOT/$name"
done

echo "workspace addons synced for $VERSION_KEY"
