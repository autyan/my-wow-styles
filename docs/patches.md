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

Current patches:

- `tbc-anniversary-cn/ShadowedUnitFrames/v4.3.9-classic`: makes SUF's built-in
  Blizzard cast bar hiding skip nil frames, includes `PlayerCastingBarFrame`,
  and applies the debuff-color API fix from upstream PR #74 without changing
  the official `20505` TOC metadata used by external addon updates.
- `mop-classic-cn/ShadowedUnitFrames/v4.3.9-classic`: makes SUF's built-in
  Blizzard cast bar hiding skip nil frames and include `PlayerCastingBarFrame`
  on MoP Classic clients.
- `tbc-anniversary-cn/TacoTip/v0.4.7`: updates the TOC `Interface` value to
  `20505` for TBC Anniversary clients without changing TacoTip tooltip
  behavior.
- `tbc-anniversary-cn/Parrot/v2.3.5-classic`: updates the TOC `Interface`
  value to `20505` for TBC Anniversary clients.
