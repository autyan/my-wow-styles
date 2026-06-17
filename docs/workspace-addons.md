# Workspace And Snapshot Addons

`AutyanCore` and `Venari` are source-owned by their own repositories. This
repository is the integration/package manager: it records addon choices, builds
local workspace addons, checks local third-party snapshots, and syncs selected
directories into game folders.

Third-party addons are not downloaded by these scripts and are not vendored in
this repository. Use any suitable external addon platform or tool to install and
update them. This repository records the selected addon set, generated or staged
configuration, and minimal local patches for specific upstream addon versions.

During migration, put already downloaded or archived addon directories under
`snapshots/<version>/Interface/AddOns/`, then run the local precheck and sync
scripts.

## Repositories

```text
../autyan-wow-core       AutyanCore source and per-version builds
../venari-wow-plugin     Venari source and release builder
my-wow-styles            manifests, layouts, configs, snapshot checks, sync scripts
```

## Package Manifests

Version manifests live in:

```text
packages/tbc-anniversary-cn/package.json
packages/mop-classic-cn/package.json
```

Each manifest has two roles:

- `workspaceAddons`: source repositories that this repo can build.
- `thirdPartyAddons`: selected external addons, their expected directory names,
  purpose, and human-friendly source hints.

The manifest deliberately avoids direct archive URLs. File IDs and direct zip
links are brittle; the durable value is remembering the selected addon set and
the directory layout needed for restore.

## Third-Party Patches

Local compatibility fixes live under:

```text
patches/<version-key>/<AddonName>/<addon-version>/
```

Patch directories are bound to the addon version named by their manifest. When
an external updater replaces the addon, re-check the patch against the new
version instead of applying an older patch implicitly.

## Workspace Build

```bash
scripts/build-workspace-addons.sh tbc-anniversary-cn
scripts/build-workspace-addons.sh mop-classic-cn
```

Environment overrides are supported:

```bash
AUTYANCORE_REPO=/path/to/autyan-wow-core
VENARI_REPO=/path/to/venari-wow-plugin
```

Output is written to:

```text
build/dist/<version>/Interface/AddOns/
build/dist/<version>/workspace-addons.lock.json
```

The workspace lock file records each source repo's branch, commit, remote, and
dirty state.

## Snapshot Precheck

Expected snapshot layout:

```text
snapshots/<version>/Interface/AddOns/<AddonName>/
```

Run:

```bash
scripts/check-addon-snapshot.py tbc-anniversary-cn snapshots/tbc-anniversary-cn/Interface/AddOns
```

The check reports:

- selected addon directories missing from the snapshot
- BigFoot markers in selected third-party addons
- TOC Interface values that do not include the target client interface

TOC mismatches are warnings because some addons ship multi-version files or rely
on the game's "Load out of date AddOns" option. BigFoot markers are errors for
selected addons because this package should not depend on BigFoot runtime glue.

## Sync

Workspace addons:

```bash
scripts/sync-workspace-addons.sh tbc-anniversary-cn
scripts/sync-workspace-addons.sh mop-classic-cn
```

Third-party addon snapshot:

```bash
scripts/sync-addon-snapshot.sh tbc-anniversary-cn snapshots/tbc-anniversary-cn/Interface/AddOns
scripts/sync-addon-snapshot.sh mop-classic-cn snapshots/mop-classic-cn/Interface/AddOns
```

Both sync scripts refuse to write while the target `WoWClassic.exe` client is
running. Snapshot sync backs up replaced addon directories as
`.autyan-backup-<AddonName>-<timestamp>` before copying.

MoP currently builds `AutyanCore` only. `Venari` remains disabled for MoP until
the Venari repository grows an explicit MoP build target.
