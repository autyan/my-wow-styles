#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_KEY="${VERSION_KEY:-tbc-anniversary-cn}"
PROFILE_NAME="${PROFILE_NAME:-Autyan}"

WOW_ROOT="${WOW_ROOT:-/home/autyan/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/2665554533/pfx/drive_c/Program Files (x86)/World of Warcraft/_anniversary_}"
ACCOUNT="${ACCOUNT:-683545805#1}"
SV_DIR="$WOW_ROOT/WTF/Account/$ACCOUNT/SavedVariables"

CONFIG_DIR="${CONFIG_DIR:-$REPO_ROOT/configs/$VERSION_KEY/$PROFILE_NAME}"

if pgrep -af -i 'WoWClassic\.exe' >/dev/null; then
  echo "WoW is still running. Exit the game client before applying SavedVariables."
  exit 1
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$SV_DIR"

for addon in Bartender4 Masque ShadowedUnitFrames; do
  if [[ ! -f "$CONFIG_DIR/$addon.lua" ]]; then
    continue
  fi
  if [[ -f "$SV_DIR/$addon.lua" ]]; then
    cp "$SV_DIR/$addon.lua" "$SV_DIR/$addon.lua.pre-autyan-layout-$timestamp.bak"
  fi
  cp "$CONFIG_DIR/$addon.lua" "$SV_DIR/$addon.lua"
done

echo "Applied Autyan WoW layout to: $SV_DIR"
