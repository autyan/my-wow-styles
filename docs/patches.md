# Third-Party Addon Patches

Third-party addon downloads and updates are owned by external platforms or
tools. This repository does not choose one required downloader, vendor complete
addon copies, or preserve direct archive URLs.

The repository records the personal addon selection, generated or staged
configuration, and local patches for specific upstream addon versions.

Patch rules:

- Patch directories are version-bound:

```text
patches/<version-key>/<AddonName>/<addon-version>/
```

- A patch applies only to the addon version named by its `manifest.json`.
- If the external tool updates an addon, do not silently reuse an older patch.
  Add or copy a patch directory for the new addon version after checking it.
- Patch files should be minimal compatibility fixes, not configuration
  preferences.
- Complete third-party addon source trees stay out of git.

Current patch:

- `tbc-anniversary-cn/ShadowedUnitFrames/v4.3.9-classic`: makes SUF's built-in
  Blizzard cast bar hiding skip nil frames and include `PlayerCastingBarFrame`
  on TBC Anniversary clients.
