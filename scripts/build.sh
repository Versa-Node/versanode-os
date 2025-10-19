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

# Inject VersaNode stages
if [ -d "$ROOT/versanode-os-kmods" ]; then
  echo ">> Injecting stage8 (kmods)..."
  rsync -a --delete "$ROOT/versanode-os-kmods/" "$PI_GEN_DIR/stage8/"
fi

if [ -d "$ROOT/versanode-os-usermods" ]; then
  echo ">> Injecting stage9 (usermods)..."
  rsync -a --delete "$ROOT/versanode-os-usermods/" "$PI_GEN_DIR/stage9/"
fi

# Ensure all scripts are executable and Unix format
find "$PI_GEN_DIR" -type f -name '*.sh' -exec chmod +x {} \;
find "$PI_GEN_DIR" -type f -name '*.sh' -exec sed -i 's/\r$//' {} \;

# Copy config into pi-gen
echo ">> Copying config into pi-gen/config..."
cp -f "$ROOT/config" "$PI_GEN_DIR/config"
chmod 644 "$PI_GEN_DIR/config"

# Extract key values (for logs)
IMG_NAME="$(grep -E '^IMG_NAME=' "$PI_GEN_DIR/config" | cut -d= -f2- | tr -d '"')"
STAGE_LIST="$(grep -E '^STAGE_LIST=' "$PI_GEN_DIR/config" | cut -d= -f2- | tr -d '"')"
export IMG_NAME="${IMG_NAME:-versanode-os}"
export IMG_DATE="$(date -u +%Y-%m-%d)"
export BUILD_WITH_DOCKER=1
export CLEAN=1

# Determine highest stage for export path
HIGHEST_STAGE="stage2"
for s in stage9 stage8 stage5 stage4 stage3 stage2 stage1; do
  if [[ "$STAGE_LIST" == *"$s"* ]]; then
    HIGHEST_STAGE="$s"; break
  fi
done

echo ">> Building VersaNode OS..."
echo "   IMG_NAME=$IMG_NAME"
echo "   STAGE_LIST=$STAGE_LIST"
echo "   HIGHEST_STAGE=$HIGHEST_STAGE"
echo

cd "$PI_GEN_DIR"
sudo -E bash ./build.sh -c config
