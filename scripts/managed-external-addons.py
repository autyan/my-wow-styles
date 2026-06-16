#!/usr/bin/env python3
import json
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: scripts/managed-external-addons.py <version-key>")

    version_key = sys.argv[1]
    package_path = REPO_ROOT / "packages" / version_key / "package.json"
    if not package_path.exists():
        raise SystemExit(f"unknown package version: {version_key}")

    package = json.loads(package_path.read_text())
    seen = set()
    for addon in package.get("thirdPartyAddons", []):
        for directory in addon.get("directories", []):
            if directory in seen:
                continue
            seen.add(directory)
            print(directory)


if __name__ == "__main__":
    main()
