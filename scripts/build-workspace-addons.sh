#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_KEY="${1:-tbc-anniversary-cn}"

python3 "$REPO_ROOT/scripts/build-workspace-addons.py" "$VERSION_KEY"
