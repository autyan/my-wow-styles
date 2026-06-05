# Addon Rendering Principles

This document records how the current addon stack renders UI, how state is
persisted, and what the project renderer must respect.

## Screenshot Interpretation

Screenshots taken while both Blizzard HUD Edit Mode and Bartender4 unlock mode
are active are diagnostic screenshots, not final visual screenshots.

In that mixed state:

- Blizzard HUD elements can show large translucent edit rectangles.
- Blizzard buff and debuff frames are shown at their default HUD-edit size unless
  another addon has explicitly replaced them.
- Shadowed Unit Frames can show fake party or raid preview units.
- Bartender4 shows green overlay frames, labels, snap grid, and empty buttons.

Do not use those temporary edit overlays as evidence of the final visual style.
Use them only to identify ownership, occupied zones, and collision risks.

## Ownership Map

Each visible region belongs to a different renderer. The project must not treat
the UI as one flat coordinate plane written into one SavedVariables file.

| Region | Owner | SavedVariables | Notes |
| --- | --- | --- | --- |
| Action buttons | Bartender4 | `Bartender4DB` | Replaces Blizzard action bars with secure BT4 bars. |
| Action button skin | Masque | `MasqueDB` | Skins button regions registered by Bartender4. |
| Player/pet/target/focus frames | Shadowed Unit Frames | `ShadowedUFDB` | Builds frames from unit config, widget config, positions, and hidden Blizzard settings. |
| Quest tracker | Questie | `QuestieConfig` | Uses `Questie_BaseFrame`; position and sizing are separate tracker settings. |
| Damage/threat meters | Details | `Details222` | Instance windows have independent positions, skins, row settings, and displayed attributes. |
| Movable Blizzard windows | BlizzMove | `BlizzMoveDB` | Adds drag/scale behavior to registered Blizzard frames; it is not a skin system. |
| Window skins | Skinner | `SkinnerDB` | Skins supported Blizzard/addon frames; coverage depends on addon-specific skin modules. |
| Default HUD buffs/debuffs | Blizzard HUD | Blizzard account/character layout data | Not controlled by Bartender4 or SUF unless explicitly hidden/replaced. |

## Bartender4

Bartender4 hides Blizzard's action bar frames and builds its own secure frames.
Important fields:

- `ActionBars.profiles[profile].actionbars[barId].enabled`
- `position.point`, `position.x`, `position.y`, `position.scale`
- `rows`, `padding`, `buttons`, `buttonOffset`
- `position.growHorizontal`, `position.growVertical`
- global profile flags: `lock`, `buttonlock`, `snapping`

Bar IDs are semantic and must be preserved. In Classic/TBC mappings:

- `1` is the main action bar.
- `3` maps to `MULTIACTIONBAR3BUTTON%d`.
- `4` maps to `MULTIACTIONBAR4BUTTON%d`.
- `5` maps to `MULTIACTIONBAR2BUTTON%d`.
- `6` maps to `MULTIACTIONBAR1BUTTON%d`.
- `7` to `10` are disabled by default but can still be configured.

Design rule: never assume the "four core bars" are `1`, `2`, `3`, and `4`.
Capture the actual bar IDs used by the player before rendering.

Renderer rule: the Bartender renderer must support exact bar IDs, enabled state,
rows, padding, growth direction, scale, and lock state. It should also be able to
import the current in-game state before generating a new preset.

## Masque

Masque does not place buttons. Bartender4 registers groups with Masque, and
Masque skins the regions of each button.

Design rule: Masque is the visual skin layer for button icons, borders,
backdrops, gloss, shadow, and normal textures. It cannot fix bad bar placement.

Renderer rule: Masque config should be generated after Bartender bar ownership is
known, so all active groups get the same skin intent.

## Shadowed Unit Frames

SUF has a two-stage configuration model:

1. It creates defaults and then loads a default layout if no layout is marked as
   loaded.
2. It builds unit frames from `units`, `positions`, `hidden`, media, bars,
   portraits, text, indicators, and auras.

Important fields:

- `loadedLayout`
- `positions[unit]`
- `units[unit].enabled`, `width`, `height`, `scale`
- `units[unit].portrait.enabled`, `type`, `width`, `order`
- `bars.texture`, `bars.spacing`, `backdrop`, `font`
- `hidden.player`, `hidden.pet`, `hidden.target`, `hidden.focus`,
  `hidden.buffs`, `hidden.party`, `hidden.raid`

Default SUF positions anchor player near top-left, target to player, pet to
player, and party below player. If the project writes only partial SUF state, SUF
can merge or preserve default layout behavior.

Design rule: SUF must be treated as a complete visual preset, not a small
position patch. Player, pet, target, target-of-target, and focus need one shared
visual grammar: flat bars, stable scale, explicit anchors, and deliberate
portrait policy.

Renderer rule: SUF generation must write a complete enough profile for the units
we own, including `loadedLayout`, `hidden`, media, frame sizes, portrait policy,
and absolute positions. For later healer support, party and raid frames must be
separate semantic zones, not children accidentally anchored to the player frame.

## Questie

Questie creates `Questie_BaseFrame` for the tracker. Key profile fields:

- `TrackerLocation`: `{ point, "UIParent", relativePoint, x, y }`
- `TrackerWidth`, `TrackerHeight`
- `trackerWidthRatio`, `trackerHeightRatio`
- tracker font sizes and font names
- `trackerLocked`, `trackerBackdropEnabled`, `trackerBorderEnabled`
- `moveHeaderToBottom`, `trackerSetpoint`

Design rule: the quest tracker is a right-edge information column. It is not a
combat-core element and should not compete with player/pet/target frames.

Renderer rule: position, width, height, font size, and lock state should be
captured and rendered. The renderer should not infer its final position from a
mixed Blizzard HUD edit screenshot.

## Details

Details stores each meter as an instance. Important fields:

- `instances[index].__pos`
- instance width and height
- `skin`
- background and titlebar settings
- row texture, row height, font, and alpha
- displayed attribute and plugin mode

Design rule: damage and threat should be first-class layout blocks. A single
damage window is not enough for the intended hunter layout; threat needs either a
second Details instance or a reliable TinyThreat view.

Renderer rule: Details should be handled by a dedicated renderer, not left as an
untracked manual side effect.

## BlizzMove And Skinner

BlizzMove and Skinner solve different problems.

- BlizzMove gives movable behavior to supported Blizzard frames and registered
  addon frames.
- Skinner changes supported frame visuals.

Design rule: "movable windows" and "modern window appearance" are separate
requirements. Both must be validated per frame type.

Renderer rule: do not expect Skinner to make every frame look identical, and do
not expect BlizzMove to persist a complete design layout for every window.

## Project-Level Rules

1. Source of truth is abstract layout plus addon-specific renderers, not manual
   SavedVariables edits.
2. Manual in-game tuning is allowed as discovery, but must be imported before the
   next render.
3. Mixed edit-mode screenshots are for ownership and collision diagnosis only.
4. Every renderer must preserve addon semantics. Bar IDs, unit names, and window
   instances are not interchangeable.
5. Use bottom-left design coordinates for project intent, then convert to each
   addon's native anchor format.
6. Separate layout ownership from visual skin ownership.
7. A renderer must either generate a complete profile for the part it owns or
   patch an existing profile intentionally. Partial replacement is the main cause
   of incoherent results.
8. Lock states are part of the preset. During tuning, frames can be unlocked; in
   shared presets, the expected lock state must be explicit.

## Immediate Implications

- The current Bartender layout should be imported before any further generation.
- The current SUF renderer is insufficient because SUF needs a complete unit-frame
  preset, not only positions.
- Questie and Details need their own renderers or capture/patch steps.
- Blizzard default buffs/debuffs are currently not owned by the addon stack; they
  should be left out of final-plugin judgments until we decide whether to replace
  or keep them.
