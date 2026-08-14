# My WoW Styles

Personal World of Warcraft UI integration project.

The active target is **WoW China TBC Anniversary**. An experimental
**WoW China Mists of Pandaria Classic** version scaffold also exists for
compatibility migration work.

## Goals

- Build a compact personal UI package centered on Parrot2-style combat feedback.
- Keep the layout hunter-first while reserving the left side for future healer
  raid frames.
- Prefer mature addons and store reusable layout intent, addon choices, and
  migration notes in source-controlled version definitions.
- Keep third-party addon files and fragile direct download links out of source
  control; use local snapshots for migration and restore.
- Generate per-addon SavedVariables from stable layout data instead of editing
  every addon by hand.

## Repository Structure

```text
docs/                         Project notes and layout rules
packages/                     Version manifests: addon choices and workspace inputs
profiles/                     Local machine profile examples
snapshots/                    Local addon snapshot input directory, ignored by git
src/
  shared/                     Cross-version schemas and shared concepts
  versions/
    tbc-anniversary-cn/       Current supported game version
    mop-classic-cn/           Experimental MoP Classic migration target
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

## Experimental Version

- Version key: `mop-classic-cn`
- Game: WoW China Mists of Pandaria Classic
- Status: experimental scaffold; do not copy TBC SavedVariables directly.

## Workflow

AutyanCore and Venari are maintained in separate addon source repositories:

```text
~/SourceCode/autyan-wow-core
~/SourceCode/venari-wow-plugin
```

This repository acts as the integration/package manager. It records which
third-party addons are part of the personal package, but it does not download or
vendor those addons. For migrations, download addons manually or copy a known
good `Interface/AddOns` snapshot, then let the repo run prechecks and sync the
selected directories.

Build workspace addons from their source repositories with:

```bash
bash scripts/build-workspace-addons.sh tbc-anniversary-cn
bash scripts/build-workspace-addons.sh mop-classic-cn
```

Build and sync the managed package to the local game AddOns directory with:

```bash
bash scripts/sync-workspace-addons.sh tbc-anniversary-cn
bash scripts/sync-workspace-addons.sh mop-classic-cn
```

Precheck and sync a local third-party addon snapshot with:

```bash
scripts/check-addon-snapshot.py tbc-anniversary-cn snapshots/tbc-anniversary-cn/Interface/AddOns
bash scripts/sync-addon-snapshot.sh tbc-anniversary-cn snapshots/tbc-anniversary-cn/Interface/AddOns
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
See [docs/workspace-addons.md](docs/workspace-addons.md) for the AutyanCore and
Venari multi-branch build flow.

For the latest local handoff state, see
[docs/current-state.md](docs/current-state.md).
