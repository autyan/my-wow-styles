#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
BIGFOOT_TEXT_MARKERS = ("BigFoot", "BigFoot_UI")
BIGFOOT_HARD_MARKERS = (
    "X-Revision: BigFoot",
    "Dependencies: BigFoot",
    "RequiredDeps: BigFoot",
    "Category: BigFoot_UI",
)
SCAN_EXTENSIONS = {".toc", ".lua", ".xml"}


def load_package(version_key):
    package_path = REPO_ROOT / "packages" / version_key / "package.json"
    if not package_path.exists():
        raise SystemExit(f"unknown package version: {version_key}")
    package = json.loads(package_path.read_text())
    if package["versionKey"] != version_key:
        raise SystemExit(f"package key mismatch in {package_path}")
    return package


def selected_directories(package):
    for addon in package.get("thirdPartyAddons", []):
        for directory in addon.get("directories", []):
            yield addon["name"], directory


def toc_interface_values(addon_dir):
    values = []
    for toc_path in addon_dir.glob("*.toc"):
        for line in toc_path.read_text(errors="ignore").splitlines():
            match = re.match(r"^##\s*Interface:\s*(.+)$", line)
            if match:
                values.extend(part.strip() for part in match.group(1).split(","))
    return values


def scan_bigfoot(addon_dir):
    errors = []
    warnings = []
    for path in addon_dir.rglob("*"):
        if not path.is_file() or path.suffix not in SCAN_EXTENSIONS:
            continue
        text = path.read_text(errors="ignore")
        for marker in BIGFOOT_HARD_MARKERS:
            if marker in text:
                errors.append((path, marker))
                break
        else:
            for marker in BIGFOOT_TEXT_MARKERS:
                if marker in text:
                    warnings.append((path, marker))
                    break
    return errors, warnings


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: scripts/check-addon-snapshot.py <version-key> <addons-root>")

    version_key = sys.argv[1]
    addons_root = Path(sys.argv[2]).expanduser().resolve()
    if not addons_root.is_dir():
        raise SystemExit(f"addons root not found: {addons_root}")

    package = load_package(version_key)
    interface = str(package.get("interface", ""))
    errors = []
    warnings = []

    for group, directory in selected_directories(package):
        addon_dir = addons_root / directory
        if not addon_dir.is_dir():
            errors.append(f"missing {directory} ({group})")
            continue

        bigfoot_errors, bigfoot_warnings = scan_bigfoot(addon_dir)
        for path, marker in bigfoot_errors:
            errors.append(f"{directory}: BigFoot marker {marker!r} in {path.relative_to(addons_root)}")
        for path, marker in bigfoot_warnings:
            warnings.append(f"{directory}: BigFoot text {marker!r} in {path.relative_to(addons_root)}")

        interfaces = toc_interface_values(addon_dir)
        if interface and interfaces and interface not in interfaces:
            warnings.append(f"{directory}: TOC Interface {', '.join(interfaces)} does not include {interface}")

    if warnings:
        print("warnings:")
        for warning in warnings:
            print(f"  - {warning}")

    if errors:
        print("errors:")
        for error in errors:
            print(f"  - {error}")
        raise SystemExit(1)

    print(f"snapshot precheck passed for {version_key}: {addons_root}")


if __name__ == "__main__":
    main()
