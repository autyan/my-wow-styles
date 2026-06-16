#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_KEY="${1:-tbc-anniversary-cn}"
SNAPSHOT_ADDONS_ROOT="${2:-$REPO_ROOT/snapshots/$VERSION_KEY/Interface/AddOns}"
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
  echo "WoW $GAME_DIR is still running. Exit that game client before syncing addon snapshots."
  exit 1
fi

"$REPO_ROOT/scripts/check-addon-snapshot.py" "$VERSION_KEY" "$SNAPSHOT_ADDONS_ROOT"

DST_ROOT="$WOW_BASE/$GAME_DIR/Interface/AddOns"
mkdir -p "$DST_ROOT"

while IFS= read -r addon; do
  [[ -n "$addon" ]] || continue
  if [[ ! -d "$SNAPSHOT_ADDONS_ROOT/$addon" ]]; then
    echo "missing snapshot addon directory: $SNAPSHOT_ADDONS_ROOT/$addon" >&2
    exit 1
  fi
  if [[ -d "$DST_ROOT/$addon" ]]; then
    backup="$DST_ROOT/.autyan-backup-${addon}-$(date +%Y%m%d-%H%M%S)"
    mv "$DST_ROOT/$addon" "$backup"
    echo "backed up $addon -> $backup"
  fi
  cp -a "$SNAPSHOT_ADDONS_ROOT/$addon" "$DST_ROOT/$addon"
  echo "synced snapshot $addon -> $DST_ROOT/$addon"
done < <("$REPO_ROOT/scripts/managed-external-addons.py" "$VERSION_KEY")

echo "addon snapshot synced for $VERSION_KEY"
