# Source Layout

`src` contains reusable project definitions, not generated addon output.

- `shared/`: common schemas and concepts.
- `versions/`: supported game versions.

Each version should contain:

- `version.json`
- `addons/manifest.json`
- one or more `layouts/*.json`
- renderer notes or scripts for addon SavedVariables

