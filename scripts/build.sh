#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_GEN_DIR="$ROOT/pi-gen"

# 1) Ensure pi-gen is present (and cleanly reset to upstream bookworm)
"$ROOT/scripts/fetch_pi_gen.sh"

# 2) Sync our custom stage into pi-gen (non-destructive, reproducible)
rsync -a --delete "$ROOT/stages/stage1-kmods/" "$PI_GEN_DIR/stage1-kmods/"

# 3) Ensure all shell scripts are executable
find "$PI_GEN_DIR" -type f -name '*.sh' -exec chmod +x {} \;
find "$ROOT/stages" -type f -name '*.sh' -exec chmod +x {} \;

# 4) Build with Docker (recommended path)
export BUILD_WITH_DOCKER=1
export CLEAN=1
export CONFIG="$ROOT/config"

echo ">> Starting pi-gen build (Docker) ..."
echo "   config: $CONFIG"
echo "   stages: $(grep '^STAGE_LIST' "$CONFIG" | cut -d= -f2-)"
echo

# Run build
cd "$PI_GEN_DIR"
sudo -E bash ./build.sh
