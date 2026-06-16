# Source Layout

`src` contains reusable project definitions, not generated addon output.

- `shared/`: common schemas and concepts.
- `versions/`: supported game versions.
  - `tbc-anniversary-cn`: active TBC Anniversary target.
  - `mop-classic-cn`: experimental MoP Classic migration target.

Workspace addon source does not live here anymore. `AutyanCore` is sourced from
`../autyan-wow-core`, and `Venari` is sourced from `../venari-wow-plugin`.
Third-party addon snapshots also do not live here; put local migration snapshots
under `../snapshots/<version>/Interface/AddOns/`. Version package membership
lives in `../packages/*/package.json`; build output is generated under
`../build/dist`.

Each version may contain:

- `version.json`
- one or more `layouts/*.json`
- renderer notes or scripts for addon SavedVariables
