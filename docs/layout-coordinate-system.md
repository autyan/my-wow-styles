# Layout Coordinate System

Layouts use a bottom-left origin before being converted to addon coordinates.

## Reference Canvas

The default reference canvas is:

```text
width: 1920
height: 1080
origin: bottom-left
```

This is not the physical monitor resolution. It is a stable design canvas used
to describe relationships between UI regions.

## Coordinate Meaning

Each block uses:

```json
{
  "x": 0,
  "y": 0,
  "w": 300,
  "h": 120,
  "anchor": "BOTTOMLEFT"
}
```

- `x`, `y`: bottom-left position on the reference canvas.
- `w`, `h`: intended block size.
- `anchor`: semantic anchor used by renderers when translating to addon data.

## Layout Zones

- Left lower: chat.
- Left middle: reserved future raid/healer frames.
- Lower center-left: player, pet, primary combat bars.
- Lower center-right: target, target target, focus.
- Right top: minimap, quest tracker, utility bars.
- Right lower: damage/threat meters.

## Edit Mode Caveat

Blizzard HUD Edit Mode and Bartender4 unlock mode expose temporary editing
overlays. These overlays are useful for measuring ownership and collisions, but
they are not the final UI.

Specifically, default Blizzard buff/debuff frames shown in HUD Edit Mode should
not be treated as addon-rendered buff styling. They remain Blizzard HUD elements
unless a later addon explicitly hides or replaces them.

## Conversion

Renderers convert reference-canvas blocks into addon-specific coordinates.
For example:

- Bartender4 can use `BOTTOM`, `BOTTOMLEFT`, or `TOPRIGHT` anchors.
- Shadowed Unit Frames can use `BOTTOM` positions for unit frames.
- Quest trackers and meter windows can use right-edge blocks.
