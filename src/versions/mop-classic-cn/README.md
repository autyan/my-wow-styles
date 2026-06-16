# MoP Classic CN

Experimental version target for WoW China Mists of Pandaria Classic.

This version starts from a conservative addon set:

- `AutyanCore` with chat tools, copy panel, FPS anchor, config UI, and local outfit records.
- DBM official upstream packages for MoP raids, scenarios, dungeons, and world events.
- Details, TinyThreat, TomTom, Baganator, Syndicator, and TalentEmuX from the
  TBC-stable addon set where the addon already ships a MoP-compatible TOC.
- Leatrix Maps, TacoTip, TotemTimers, and NpcAbilities from their MoP Classic
  upstream packages.

TBC-stable addons not enabled yet:

- `Venari`: hunter mechanics and spell behavior need a dedicated MoP review.

High-risk TBC-specific pieces are intentionally disabled in the first pass:

- AutyanCore equipment stats panel is not loaded.
- Permanent BuffFrame `N/A` labels default off.
- Venari is not included until hunter mechanics are reviewed for MoP.

Do not copy TBC SavedVariables directly into this version. Create staged config
under `configs/mop-classic-cn/<profile>/` after the MoP client path and account
profile are known.
