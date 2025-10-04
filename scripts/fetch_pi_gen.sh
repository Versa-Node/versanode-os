#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_GEN_DIR="$ROOT/pi-gen"
REPO_URL="https://github.com/RPi-Distro/pi-gen.git"
BRANCH="bookworm"

if [[ ! -d "$PI_GEN_DIR/.git" ]]; then
  echo ">> Cloning pi-gen ($BRANCH) ..."
  git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$PI_GEN_DIR"
else
  echo ">> Updating pi-gen ..."
  git -C "$PI_GEN_DIR" fetch --depth=1 origin "$BRANCH"
  # Ensure branch exists locally and is tracking origin
  if ! git -C "$PI_GEN_DIR" rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
    git -C "$PI_GEN_DIR" checkout -b "$BRANCH" "origin/$BRANCH"
  else
    git -C "$PI_GEN_DIR" checkout "$BRANCH"
  fi
  git -C "$PI_GEN_DIR" reset --hard "origin/$BRANCH"
fi

# Remove any stray files named "stage*" in the root of pi-gen that can break globbing
find "$PI_GEN_DIR" -maxdepth 1 -type f -name 'stage*' -print -delete || true

# Ensure shell scripts are executable
find "$PI_GEN_DIR" -type f -name '*.sh' -exec chmod +x {} \;

echo ">> pi-gen ready: $PI_GEN_DIR"
