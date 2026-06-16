#!/usr/bin/env python3
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def run(command, cwd):
    subprocess.run(command, cwd=cwd, check=True)


def output(command, cwd):
    return subprocess.check_output(command, cwd=cwd, text=True).strip()


def repo_state(repo):
    commit = output(["git", "rev-parse", "--short", "HEAD"], repo)
    branch = output(["git", "branch", "--show-current"], repo)
    dirty = bool(output(["git", "status", "--short"], repo))
    remote = output(["git", "remote", "get-url", "origin"], repo) if (repo / ".git").exists() else ""
    return {
        "path": str(repo),
        "remote": remote,
        "branch": branch,
        "commit": commit,
        "dirty": dirty,
    }


def resolve_repo(addon):
    env_name = addon.get("repoEnv")
    if env_name and os.environ.get(env_name):
        return Path(os.environ[env_name]).expanduser().resolve()
    return (REPO_ROOT / addon["repoPath"]).resolve()


def copy_artifact(addon, repo, version_key, lock_entries):
    artifact = repo / addon["artifact"]
    if not artifact.is_dir():
        raise SystemExit(f"{addon['name']} artifact not found: {artifact}")

    out_root = REPO_ROOT / "build" / "dist" / version_key / "Interface" / "AddOns"
    target = out_root / addon["name"]
    if target.exists():
        shutil.rmtree(target)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(artifact, target)

    state = repo_state(repo)
    state.update({
        "name": addon["name"],
        "artifact": str(artifact),
        "output": str(target),
    })
    lock_entries.append(state)
    print(f"built {addon['name']} -> {target}")


def build_version(version_key):
    package_path = REPO_ROOT / "packages" / version_key / "package.json"
    if not package_path.exists():
        raise SystemExit(f"unknown package version: {version_key}")

    package = json.loads(package_path.read_text())
    if package["versionKey"] != version_key:
        raise SystemExit(f"package key mismatch in {package_path}")

    lock_entries = []
    for addon in package.get("workspaceAddons", []):
        if not addon.get("enabled", True):
            print(f"skipping {addon['name']}: {addon.get('reason', 'disabled')}")
            continue

        repo = resolve_repo(addon)
        if not repo.is_dir():
            raise SystemExit(f"{addon['name']} repo not found: {repo}")

        build = addon.get("build")
        if build:
            run(build, repo)
        copy_artifact(addon, repo, version_key, lock_entries)

    lock_path = REPO_ROOT / "build" / "dist" / version_key / "workspace-addons.lock.json"
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    lock_path.write_text(json.dumps({
        "versionKey": version_key,
        "addons": lock_entries,
    }, indent=2, ensure_ascii=False) + "\n")
    print(f"wrote {lock_path}")


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: scripts/build-workspace-addons.py <version-key>")
    build_version(sys.argv[1])


if __name__ == "__main__":
    main()
