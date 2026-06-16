# Addon Snapshots

Place local addon snapshots here when preparing a migration or restore.

Expected layout:

```text
snapshots/
  tbc-anniversary-cn/
    Interface/
      AddOns/
        Bartender4/
        DBM-Core/
        ...
```

Snapshot contents are ignored by git. This repository records addon choices and
directory expectations, while the snapshot itself stays local unless a separate
archive is intentionally shared outside normal source control.
