# Venari Design Alignment

## Reference Read

The target screenshot uses a Necrosis-like hunter sphere layout with these
visual anchors:

- Large central pet portrait orb with thick concentric metal and green status
  rings.
- Discrete outer shot beads on a much wider radius than the pet orb.
- Two upper resource panels, each with internal item slots and heavy gold/iron
  bevels.
- A left vertical aspect panel with circular primary/secondary controls.
- A right 2x2 trap panel with square icon cells and visible grid separation.
- A lower utility tray with five square cells in one continuous metal frame.

The previous Venari implementation already had the correct functional
composition, but the visual system was still compact:

- `UI_BASE_SCALE = 0.74`, `CENTER_SIZE = 68`, and `SHOT_RING_RADIUS = 46`
  produced a small clustered HUD.
- The v2 assets were thin outline panels without the target's heavier inner
  compartment structure.
- Trap and utility icons were circle-masked, while the reference uses square
  spell cells for those controls.
- The center portrait ring was too small relative to the outer auto-shot beads.

## Implemented Direction

This pass keeps the secure button and macro behavior unchanged, and only changes
the visual/layout layer.

- Added `scripts/generate-venari-media.py` so v3 TGA assets are reproducible.
- Generated v3 panels for resource, aspect, trap, utility, center ring, square
  button, and shot beads.
- Increased the HUD scale and root layout area.
- Expanded the center orb and auto-shot bead radius.
- Repositioned modules into the target composition: resources above, aspect
  panel left, trap panel right, utility tray below.
- Preserved circular clipping for aspect buttons and pet portrait.
- Removed circular clipping from trap and utility buttons so spell icons read as
  square cells.

## Verification Notes

Local checks performed:

- `luac -p src/versions/tbc-anniversary-cn/addons/Venari/Venari.lua`
- Pillow-generated v3 media contact sheet.
- Offline layout preview composited from the generated TGA assets.

Game-client checks still needed after syncing:

- `/reload` with Venari enabled.
- Validate frame size and default saved position at the player's active
  resolution.
- Confirm clickable regions still match the visual buttons.
- Confirm cooldown overlays and count text remain above icons after the larger
  visual scale.
