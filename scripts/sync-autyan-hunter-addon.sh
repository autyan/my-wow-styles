#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WOW_ROOT="${WOW_ROOT:-/home/autyan/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/2665554533/pfx/drive_c/Program Files (x86)/World of Warcraft/_anniversary_}"
SRC_DIR="$REPO_ROOT/src/versions/tbc-anniversary-cn/addons/Venari"
DST_DIR="$WOW_ROOT/Interface/AddOns/Venari"
OLD_DST_DIR="$WOW_ROOT/Interface/AddOns/AutyanHunter"
ADDONS_TXT="${ADDONS_TXT:-$WOW_ROOT/WTF/Account/683545805#1/无情/Autyan/AddOns.txt}"
ACCOUNT_SV_DIR="${ACCOUNT_SV_DIR:-$WOW_ROOT/WTF/Account/683545805#1/SavedVariables}"

mkdir -p "$DST_DIR"
cp "$SRC_DIR/Venari.toc" "$DST_DIR/Venari.toc"
cp "$SRC_DIR/VenariLocale.lua" "$DST_DIR/VenariLocale.lua"
cp "$SRC_DIR/VenariPetFoodDB.lua" "$DST_DIR/VenariPetFoodDB.lua"
cp "$SRC_DIR/Venari.lua" "$DST_DIR/Venari.lua"
rm -rf "$DST_DIR/Media"
cp -R "$SRC_DIR/Media" "$DST_DIR/Media"
rm -rf "$OLD_DST_DIR"

if [[ -f "$ADDONS_TXT" ]]; then
  sed -i '/^AutyanHunter: /d;/^Venari: /d' "$ADDONS_TXT"
  printf '\nVenari: enabled\n' >> "$ADDONS_TXT"
fi

if [[ -f "$ACCOUNT_SV_DIR/AutyanHunter.lua" && ! -f "$ACCOUNT_SV_DIR/Venari.lua" ]]; then
  cp "$ACCOUNT_SV_DIR/AutyanHunter.lua" "$ACCOUNT_SV_DIR/Venari.lua"
fi
if [[ -f "$ACCOUNT_SV_DIR/AutyanHunter.lua" ]]; then
  mv "$ACCOUNT_SV_DIR/AutyanHunter.lua" "$ACCOUNT_SV_DIR/AutyanHunter.lua.migrated"
fi

echo "Synced Venari to: $DST_DIR"
echo "Start the game client again to load the renamed addon."
