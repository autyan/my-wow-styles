# Current State

This document is the handoff note for future sessions. Read it before changing
the addon pack.

## Target

- Project: personal World of Warcraft addon/UI pack.
- Current supported version: `tbc-anniversary-cn`.
- Game: WoW China TBC Anniversary.
- Current character profile: `Autyan - 无情`.
- Primary class focus: hunter.
- Visual anchor: Parrot2-style combat feedback, compact and functional.

Local WoW path:

```text
/home/autyan/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/2665554533/pfx/drive_c/Program Files (x86)/World of Warcraft/_anniversary_
```

Important paths:

```text
Interface/AddOns
WTF/Account/683545805#1/无情/Autyan/AddOns.txt
WTF/Account/683545805#1/SavedVariables
```

Display basis:

```text
GxWindowedResolution: 3780x2092
useUiScale: 1
uiScale: 0.79999995231628
```

## Layout

The current layout is usable and should be preserved unless the user explicitly
asks for a reset.

- Chat stays bottom-left.
- Player, pet, target, target target, and focus stay in the lower-middle HUD
  area above the action bars.
- The left side must remain available for future healer raid frames.
- Quest tracking stays on the right edge.
- Details damage meter is bottom-right.
- Tiny Threat should become a second Details window, not replace the damage
  meter.
- TrinketMenu is intended near the target frame, where the target-frame-right
  space is still available.
- Future hunter helper UI should sit between the action bars and Details.

## Installed Addon Direction

Current selected responsibilities:

- `AutyanCore`: tiny local fixes and project-specific UI behavior.
- `Parrot`: combat feedback.
- `Bartender4`: action bars.
- `Masque`: button skinning.
- `ShadowedUnitFrames`: unit frames.
- `Bagnon`: bags.
- `DBM-Core`: encounter alerts.
- `BlizzMove`: movable Blizzard windows.
- `Skinner`: Blizzard window skinning.
- `Questie`: quest helper.
- `BetterBlizzStats` + `ClassicItemBorders`: character gear/stats presentation.
- `VendorPrice`: tooltip sell prices.
- `OmniCC` + `ClassicAuraDurations`: cooldown and aura duration numbers.
- `Details` + `Details_TinyThreat`: damage and threat.
- `MinimapButtonCollector`: minimap button collector.
- `AtlasLootClassic`: loot/source browser.
- `TrinketMenu`: trinket management.
- `Dejunk`: auto-sell workflow.

`Raven` is installed but disabled. Keep it disabled while using the lighter
OmniCC + ClassicAuraDurations + AutyanCore path.

`HidingBar` and `Feed_Me` have been removed. Current preference is
`MinimapButtonCollector` for minimap button collection and Venari's own pet
feeding logic for hunter pet food.

## AutyanCore

Current deployed version: `0.2.1`.

Source:

```text
src/versions/tbc-anniversary-cn/addons/AutyanCore
```

Deployed to:

```text
Interface/AddOns/AutyanCore
```

Current commands:

```text
/autyan fps
/autyan fps <x> <y>
/autyan buffna on
/autyan buffna off
/autyan buffna debug
/autyan castbar off
/autyan castbar on
/autyan joinbf
/autyan joinbf2
```

Important behavior:

- Permanent default BuffFrame aura labels use green `N/A`.
- The implementation hooks default aura button `Update` and `UpdateDuration`
  and uses each button's `buttonInfo`. Avoid returning to manual UnitBuff
  scanning for this feature.
- `N/A` green is `SetTextColor(0, 1, 0, 1)`, equivalent to standard WoW
  bright green.
- FPS anchor is managed by SavedVariables.
- Class-colored chat and guild roster text are enabled.
- BigFoot world-channel auto-join is intentionally disabled. Only manual
  `/autyan joinbf` and `/autyan joinbf2` exist.

Current saved variable shape:

```lua
AutyanCoreDB = {
  chatClassColors = true,
  guildClassColors = true,
  permanentAuraText = true,
  buffNA = false,
  bigFootAutoJoin = false,
  bigFootChannelBase = "大脚世界频道",
  hidePlayerCastBar = false,
  fps = {
    enabled = true,
    point = "TOPRIGHT",
    relativePoint = "TOPRIGHT",
    x = -450,
    y = -745,
  },
}
```

## AutyanHunter

Current deployed version: `0.3.3`.

Source:

```text
src/versions/tbc-anniversary-cn/addons/AutyanHunter
```

Deployed to:

```text
Interface/AddOns/AutyanHunter
```

Current commands:

```text
/ah
/ah status
/ah diag
/ah refresh
/ah clickdebug on
/ah clickdebug off
/ah show
/ah hide
/ah lock
/ah unlock
/ah debug
/ah nodebug
/ah reset
/ah scale <num>
```

Important behavior:

- Compact radial hunter HUD skeleton.
- Visual direction is a Necrosis-inspired class sphere, using project-local
  original TGA media under `AutyanHunter/Media`; do not reuse Necrosis media.
  The HUD background should remain transparent. Do not show the addon bounding
  rectangle while unlocked.
- Spell icons and the pet portrait use WoW `MaskTexture`/`AddMaskTexture` with
  project-local `circle-alpha-mask.tga`, following the same masking approach
  used by Masque. Do not fake circular clipping by drawing dark overlay corners.
- Trap buttons should not all show active outer rings. Cooldowns and usability
  are shown through cooldown overlays and icon desaturation; active outer rings
  are reserved for the current aspect.
- Aspect and trap buttons resolve the highest learned spell rank where rank data
  is known. This avoids binding a level 45 hunter to only the TBC max-rank
  spell IDs.
- Clickable spell buttons currently use conservative secure macro attributes
  (`type1=macro`, `macrotext1=/cast <localized spell>`) rather than direct
  `type=spell`, matching the reliable pattern used by simple mature helper
  buttons.
- `/ah diag` prints secure button state and key attributes for debugging
  clickability issues in-game.
- `/ah clickdebug on` enables button `PostClick` messages so we can distinguish
  hitbox/layering problems from secure macro execution problems.
- `/ah refresh` forces care macro refresh and updates selected food/bandage
  state outside combat.
- Position, lock state, scale, debug state, and visibility are saved in
  `AutyanHunterDB`.
- User layout data is intentionally minimal and should not be overwritten by
  generated SavedVariables.
- Source updates can be copied to AddOns with
  `scripts/sync-autyan-hunter-addon.sh`; in-game testing then needs `/reload`,
  not a full client exit.
- Current logic is a probe layer plus secure button shell: pet
  existence/death/health/happiness with pet portrait, combat state, localized
  Auto Shot auto-repeat ring, debug output, upper care bar, 3 aspect buttons, 3
  trap buttons, and the lower utility row. It is not yet a full shot-timing or
  independent food-selection implementation.
- Auto Shot timing now listens to `COMBAT_LOG_EVENT_UNFILTERED` for the player's
  localized Auto Shot damage/miss events and resets the ring timer from those
  real events. START/STOP_AUTOREPEAT still controls whether auto-repeat is
  active.
- Auto Shot visual feedback is intentionally discrete rather than smooth: a
  36-bead ring starts at the six-o'clock bead, active beads light one by one
  with a headward brightness gradient, the six-o'clock bead is special and ramps
  from red toward high white through the cycle, the moving front bead carries a
  white lead glow, and confirmed Auto Shot events trigger a six-o'clock
  supernova-style burst plus the outward pulse.
- Auto Shot timing is cooldown-anchor led: `GetSpellCooldown(75)` is the
  preferred source for the current cycle, combat log Auto Shot events trigger
  the pulse and record factual shots, and `lastAutoShot + UnitRangedDamage`
  remains only as a fallback when the cooldown anchor is unavailable. This keeps
  the animation waiting on the not-yet-fired shot instead of chasing a previous
  prediction.
- Pet tooltip/diagnostics include pet name, level, health percentage, and
  happiness state when available.
- Pet portrait has a dedicated inner separator texture so the portrait is
  visually distinct from the happiness-colored center orb.
- The five lower utility buttons are currently a single parallel row; avoid
  dropping two buttons into a second row unless the overall sphere geometry is
  redesigned.
- Upper care bar:
  - Pet food button left click uses Venari's own secure macro and selected-food
    logic. The button icon and tooltip use the selected food when available.
    The button shows the selected food count through a `NumberFontNormalSmall`
    overlay string in a high-level count frame above cooldown.
  - Bandage button left click uses the best available bandage on the player;
    right click uses the same bandage on the live pet. The button icon, tooltip,
    overlay count, cooldown, and desaturation reflect the selected bandage. The
    selected bandage count is reused from `bestBandage()` so selection and
    display cannot diverge on a second item count lookup. Bandage icon lookup
    prefers `C_Item.GetItemIconByID`, matching the item path used by mature
    action-button implementations such as Bartender4's LibActionButton.
    Bandage visual refresh is allowed during combat lockdown, but secure macro
    attributes are updated only outside combat. Care refresh is event-driven
    rather than periodic from the Auto Shot ticker to reduce protected-frame
    taint risk.
  - Care macros are refreshed on login, entering world, bag updates, and leaving
    combat, with light throttling. Spell-list changes also request a refresh.

## Known Local Patches

### ShadowedUnitFrames

There is a local safety patch in:

```text
Interface/AddOns/ShadowedUnitFrames/ShadowedUnitFrames.lua
```

Reason: enabling SUF's "hide Blizzard cast bar" appeared to work after
`/reload` but could break SUF after a cold login. The likely cause is SUF's
hide-Blizzard-frame path touching a nil cast bar frame during cold startup.

Patch intent:

- `basicHideBlizzardFrames()` and `hideBlizzardFrames()` skip nil frames.
- Cast-bar hiding uses `CastingBarFrame or PlayerCastingBarFrame`.

Keep this local patch unless an upstream update makes it unnecessary.

### Parrot2

Parrot had noisy missing spell trigger messages for spell IDs `51124` and
`59052`. The local deployed addon was patched to suppress the missing-trigger
spam. Do not revert unless troubleshooting Parrot itself.

## Details And Threat

`Details_TinyThreat` is enabled. The plugin itself says it is selected from the
Details orange cogwheel plugin menu.

Recommended setup:

- Bottom-right Details window remains damage.
- Add a second narrow Details window and select `Tiny Threat`.
- Place the Tiny Threat window above Details or near the future hunter helper.

## TrinketMenu

Installed version: `12.0.5`.

Source:

```text
https://github.com/Resike/TrinketMenu/releases/tag/12.0.5
```

The TOC includes interface `20505`, so it is appropriate for TBC Anniversary.
Use it as the mature standalone trinket solution. Do not fold trinket logic into
the future hunter helper unless the user explicitly changes direction.

## Future Hunter Helper

The user wants a custom hunter UI built by us, informed by mature addon logic.
Do not simply install a large all-in-one helper and accept its UI.

Current UX concept:

- A central large circular custom icon.
- Around it: smaller circular helper icons.
- The central icon represents pet state/actions.
- Left click concept: smart pet action, such as summon, revive, dismiss, or
  pet-state-specific action.
- Right click concept: less frequent pet/class action.
- Outer icons can represent aspect, pet status, hunter mark, sting, auto-shot
  timing, misdirection, defensive/utility cooldowns, or warnings.
- Hover animation is acceptable if restrained: opacity, slight scale, or radial
  reveal. Avoid distracting movement during combat.

Recommended technical direction:

- Build a new small version-scoped addon, likely `AutyanHunter`.
- Use mature addon code as reference for logic, not for UI.
- Prioritize auto-shot timing and pet status first.
- Keep the UI compact, between the action bars and the Details area.

Candidate mature logic references to inspect later:

- `WeaponSwingTimer` for auto-shot/swing timing.
- `FloAspectBar Classic` for aspect button logic. It reportedly supports TBC
  Anniversary interface `20505`; verify before installing.
- Mature hunter helper addons for behavior references only; Venari owns pet
  feeding behavior now.

## Operational Notes

- Before editing SavedVariables, check whether WoW is running.
- If WoW is running, avoid SavedVariables edits unless the user accepts that the
  game may overwrite them on exit.
- For local addon source edits, update files under `src/versions/...` first,
  run `luac -p`, then sync to the WoW AddOns directory.
- For new addon installs, verify TOC interface numbers, copy to AddOns, update
  `AddOns.txt`, and update `manifest.json`.
