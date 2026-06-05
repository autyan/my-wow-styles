# My WoW Styles

Personal World of Warcraft UI integration project.

The current target is **WoW China TBC Anniversary** only. The repository is
structured for future multi-version support, but no other game version is
supported yet.

## Goals

- Build a compact personal UI package centered on Parrot2-style combat feedback.
- Keep the layout hunter-first while reserving the left side for future healer
  raid frames.
- Prefer mature addons and store reusable layout intent in source-controlled
  version definitions.
- Generate per-addon SavedVariables from stable layout data instead of editing
  every addon by hand.

## Repository Structure

```text
docs/                         Project notes and layout rules
profiles/                     Local machine profile examples
src/
  shared/                     Cross-version schemas and shared concepts
  versions/
    tbc-anniversary-cn/       Current supported game version
      addons/                 Addon manifest and selection notes
      layouts/                Version-specific abstract layouts
      renderers/              Per-addon conversion notes/scripts
      savedvariables/         Version-specific SavedVariables notes
configs/                      Generated or staged addon SavedVariables
scripts/                      Local helper scripts
```

## Current Supported Version

- Version key: `tbc-anniversary-cn`
- Game: WoW China TBC Anniversary
- Current character profile: `Autyan - 无情`

## Workflow

Venari is maintained in a separate repository:

```text
~/SourceCode/venari-wow-plugin
```

This repository stores only the Venari release artifact under the versioned
addon directory. Refresh it from the Venari repository with:

```bash
bash scripts/update-venari-release.sh
```

Render staged addon configs from the source layout:

```bash
bash scripts/render-version.sh
```

Apply staged configs to the local WoW WTF directory:

```bash
bash scripts/apply-autyan-wow-layout.sh
```

The apply script refuses to write while `WoWClassic.exe` is running.

See [docs/architecture.md](docs/architecture.md) and
[docs/layout-coordinate-system.md](docs/layout-coordinate-system.md).

For the latest local handoff state, see
[docs/current-state.md](docs/current-state.md).
