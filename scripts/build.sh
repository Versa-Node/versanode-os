#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_GEN_DIR="$ROOT/pi-gen"

echo ">> Using pi-gen from: $PI_GEN_DIR"

# Sync submodules if needed
if [ -f "$ROOT/.gitmodules" ]; then
  git submodule sync --recursive
  git submodule update --init --recursive
fi

# Inject stages for local builds (useful if running manually)
if [ -d "$ROOT/versanode-os-kmods" ]; then
  rsync -a --delete "$ROOT/versanode-os-kmods/" "$PI_GEN_DIR/stage2-kmods/"
fi
if [ -d "$ROOT/versanode-os-usermods" ]; then
  rsync -a --delete "$ROOT/versanode-os-usermods/" "$PI_GEN_DIR/stage9-usermods/"
fi

# Ensure scripts are executable
find "$PI_GEN_DIR" -type f -name '*.sh' -exec chmod +x {} \;

# Copy config
cp -f "$ROOT/config" "$PI_GEN_DIR/config"

# Read key values
IMG_NAME="$(grep -E '^IMG_NAME=' "$ROOT/config" | cut -d= -f2- | tr -d '"')"
STAGE_LIST="$(grep -E '^STAGE_LIST=' "$ROOT/config" | cut -d= -f2- | tr -d '"')"

export IMG_NAME="${IMG_NAME:-versanode-os}"
export IMG_DATE="$(date -u +%Y-%m-%d)"
export BUILD_WITH_DOCKER=1
export CLEAN=1

# Determine highest stage for export path
HIGHEST_STAGE="stage2"
for s in stage9 stage5 stage4 stage3 stage2 stage1; do
  if [[ "$STAGE_LIST" == *"$s"* ]]; then
    HIGHEST_STAGE="$s"; break
  fi
done

export EXPORT_ROOTFS_DIR="/pi-gen/work/${IMG_DATE}-${IMG_NAME}/${HIGHEST_STAGE}/rootfs"

echo ">> Building VersaNode OS..."
echo "   IMG_NAME=$IMG_NAME"
echo "   STAGE_LIST=$STAGE_LIST"
echo "   HIGHEST_STAGE=$HIGHEST_STAGE"
echo

cd "$PI_GEN_DIR"
sudo -E bash ./build.sh -c config
