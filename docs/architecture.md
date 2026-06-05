# Architecture

The project separates UI intent from addon implementation.

## Layers

1. Version definition
   - Stored under `src/versions/<version-key>/`.
   - Describes the game version, account/realm assumptions, addon set, and
     layout files supported by that version.

2. Abstract layout
   - Stored as JSON under `src/versions/<version-key>/layouts/`.
   - Uses a stable bottom-left coordinate system, independent of individual
     addon SavedVariables formats.

3. Addon renderers
   - Stored under `src/versions/<version-key>/renderers/`.
   - Convert abstract layout blocks into addon-specific settings such as
     Bartender4 bar positions or Shadowed Unit Frames unit positions.

4. Generated configs
   - Stored under `configs/<version-key>/<profile-name>/`.
   - These are files that can be copied into `WTF/Account/.../SavedVariables`.

## Current Renderer

The first renderer is implemented in `scripts/render-layout.py`.

It currently generates:

- `Bartender4.lua`
- `Masque.lua`
- `ShadowedUnitFrames.lua`

Run it through:

```bash
bash scripts/render-version.sh
```

## Current Rule

Do not manually tune addon files as the source of truth. Manual in-game tweaks
can be used for discovery, but the final reusable state should be captured in
the version layout JSON and renderer.

## Rendering Discipline

Addon renderers must respect addon ownership boundaries:

- Bartender4 owns action bar placement and button layout.
- Masque owns action button skinning, not placement.
- Shadowed Unit Frames owns unit-frame layout, media, bars, portraits, and hidden
  Blizzard unit-frame settings.
- Questie owns its tracker frame position and sizing.
- Details owns meter instances.
- BlizzMove and Skinner affect movable window behavior and supported frame skins,
  but they do not define the core combat layout.

Before writing generated configs over a hand-tuned game state, import or document
the current game state. Partial SavedVariables generation is allowed only when
the renderer deliberately preserves the rest of the existing profile.

See `docs/addon-rendering-principles.md` for the current rendering mechanism
research and design rules.
