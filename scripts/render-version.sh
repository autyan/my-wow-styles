#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_KEY="${VERSION_KEY:-tbc-anniversary-cn}"
PROFILE_NAME="${PROFILE_NAME:-Autyan}"
PROFILE_KEY="${PROFILE_KEY:-Autyan - 无情}"

python3 "$REPO_ROOT/scripts/render-layout.py" \
  --version-key "$VERSION_KEY" \
  --profile-name "$PROFILE_NAME" \
  --profile-key "$PROFILE_KEY"

