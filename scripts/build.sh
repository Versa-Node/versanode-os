#!/usr/bin/env bash
# Pull submodules if the repo has any
if [ -f .gitmodules ]; then
  git submodule sync --recursive
  git submodule update --init --recursive
fi

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_GEN_DIR="$ROOT/pi-gen"

echo ">> Using pi-gen submodule at: $PI_GEN_DIR"

# 1) Inject our custom stage into pi-gen (reproducible)
rsync -a --delete "$ROOT/stages/stage1-kmods/" "$PI_GEN_DIR/stage1-kmods/"

# 2) Ensure all shell scripts are executable
find "$PI_GEN_DIR" -type f -name '*.sh' -exec chmod +x {} \;
find "$ROOT/stages" -type f -name '*.sh' -exec chmod +x {} \;

# 3) Build with Docker
export BUILD_WITH_DOCKER=1
export CLEAN=1

# ---- CONFIG: copy into pi-gen so Docker can read it locally ----
if [ ! -f "$ROOT/config" ]; then
  echo "ERROR: missing $ROOT/config" >&2
  exit 2
fi
cp -f "$ROOT/config" "$PI_GEN_DIR/config"

# Read values we need
IMG_NAME_VAL="$(grep -E '^IMG_NAME=' "$ROOT/config" | cut -d= -f2- | tr -d '"')"
STAGE_LIST_VAL="$(grep -E '^STAGE_LIST=' "$ROOT/config" | cut -d= -f2- | tr -d '"')"

export IMG_NAME="${IMG_NAME_VAL:-versanode-os}"
export IMG_DATE="$(date -u +%Y-%m-%d)"

# Highest stage present (export-image is always last)
HIGHEST_STAGE="stage2"
if   [[ "${STAGE_LIST_VAL:-}" =~ stage5 ]]; then HIGHEST_STAGE="stage5"
elif [[ "${STAGE_LIST_VAL:-}" =~ stage4 ]]; then HIGHEST_STAGE="stage4"
elif [[ "${STAGE_LIST_VAL:-}" =~ stage3 ]]; then HIGHEST_STAGE="stage3"
elif [[ "${STAGE_LIST_VAL:-}" =~ stage2 ]]; then HIGHEST_STAGE="stage2"
elif [[ "${STAGE_LIST_VAL:-}" =~ stage1 ]]; then HIGHEST_STAGE="stage1"
fi

# Path must be what the container sees (/pi-gen/…)
export EXPORT_ROOTFS_DIR="/pi-gen/work/${IMG_DATE}-${IMG_NAME}/${HIGHEST_STAGE}/rootfs"
export TARGET_IMAGE_SIZE="${TARGET_IMAGE_SIZE:-4096}"

echo ">> Starting pi-gen build (Docker) ..."
echo "   IMG_NAME=${IMG_NAME}"
echo "   IMG_DATE=${IMG_DATE}"
echo "   HIGHEST_STAGE=${HIGHEST_STAGE}"
echo "   EXPORT_ROOTFS_DIR=${EXPORT_ROOTFS_DIR}"
echo

cd "$PI_GEN_DIR"
# -E preserves env; pass the local 'config' we just copied
sudo -E bash ./build.sh -c config
