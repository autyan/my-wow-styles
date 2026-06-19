# Addon Selection

Current visual pillars:

- Parrot2: combat feedback style anchor.
- Bartender4 + Masque: action button layout and skinning.
- Shadowed Unit Frames: player, pet, target, focus frames.
- Bagnon: bag integration.
- Skinner: default window visual cleanup.
- BlizzMove: movable Blizzard frames.

Current function candidates:

- Questie: task and quest helper for Classic/TBC.
- TomTom: waypoint arrow/navigation companion for Questie.
- Leatrix Maps: lightweight world map enhancements.
- BetterBlizzStats: item level, bag/gear tooltip, durability and gear stats.
- DBM: dungeon/raid alerts.
- Details + TinyThreat: damage and threat meters.
- TalentEmuX / alaTalentEmu: in-game talent simulator with import/export and
  spellID-based talent tooltips.

Landed in source:

- Details, Details_DataStorage, Details_EncounterDetails, Details_TinyThreat.
- TomTom.
- Leatrix Maps (`Leatrix_Maps-2.5.x-bcc`, TBC TOC interface 20505). CurseForge
  Linux Alpha currently exposes the BCC Anniversary instance as `Classic`
  rather than TBC/BCC Classic, so it may install the wrong `1.15.x` Classic Era
  package. Do not use the `1.15.x` package for TBC Anniversary; it lacks
  Outland/TBC map data and its startup guard rejects TBC clients.
- TalentEmuX from `alexqu0822/TalentEmu` tag `260507`. The TBC TOC is
  `Interface: 20505`, version `205r.260507`.

Rejected after local testing:

- TalentPlanner (`TalentPlanner-v4.3.1`). It is a talent point sequence
  follower/importer, not a free talent simulator. The live install has been
  removed and the character addon entry is disabled.
- Talented + Talented_Data. The TBC trees could be patched, but Chinese talent
  tooltips depended on stale localization/static data, so it was replaced by
  TalentEmuX.
- Leatrix Maps `12.0.21`. That archive was the Retail build
  (`Interface: 120005, 120007`), not a TBC build.
- Leatrix Maps `1.15.x`. That archive is the Classic Era build
  (`Interface: 115xx`), not a TBC build. A TOC-only patch can make it load, but
  it does not add the missing TBC map data.

Avoid pulling BigFoot back in as a hard dependency unless the project explicitly
switches to a BigFoot-compatible distribution mode.
