#!/usr/bin/env bash
# Pull submodules if the repo has any
if [ -f .gitmodules ]; then
  git submodule sync --recursive
  git submodule update --init --recursive
fi

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_GEN_DIR="$ROOT/pi-gen"

# 1) Ensure pi-gen is present (and cleanly reset to upstream)
if [ ! -d "$PI_GEN_DIR" ] || [ -z "$(ls -A "$PI_GEN_DIR")" ]; then
  "$ROOT/scripts/fetch_pi_gen.sh"
else
  echo ">> Using existing pi-gen submodule at $PI_GEN_DIR"
fi


# 2) Sync our custom stage into pi-gen (non-destructive, reproducible)
rsync -a --delete "$ROOT/stages/stage1-kmods/" "$PI_GEN_DIR/stage1-kmods/"

# 3) Ensure all shell scripts are executable
find "$PI_GEN_DIR" -type f -name '*.sh' -exec chmod +x {} \;
find "$ROOT/stages" -type f -name '*.sh' -exec chmod +x {} \;

# 4) Build with Docker (recommended path)
export BUILD_WITH_DOCKER=1
export CLEAN=1
export CONFIG="$ROOT/config"

# ---- NEW: export the variables prerun.sh expects ----
# Read IMG_NAME and STAGE_LIST from config
IMG_NAME_VAL="$(grep -E '^IMG_NAME=' "$CONFIG" | cut -d= -f2- | tr -d '"')"
STAGE_LIST_VAL="$(grep -E '^STAGE_LIST=' "$CONFIG" | cut -d= -f2- | tr -d '"')"

# Fallbacks
export IMG_NAME="${IMG_NAME_VAL:-versanode-os}"
export IMG_DATE="$(date -u +%Y-%m-%d)"

# Pick the highest stage present in STAGE_LIST (export-image always last)
# e.g., lite: stage0 stage1 stage2 export-image  => use stage2
HIGHEST_STAGE="stage2"
if [[ "${STAGE_LIST_VAL:-}" =~ stage5 ]]; then HIGHEST_STAGE="stage5"
elif [[ "${STAGE_LIST_VAL:-}" =~ stage4 ]]; then HIGHEST_STAGE="stage4"
elif [[ "${STAGE_LIST_VAL:-}" =~ stage3 ]]; then HIGHEST_STAGE="stage3"
elif [[ "${STAGE_LIST_VAL:-}" =~ stage2 ]]; then HIGHEST_STAGE="stage2"
elif [[ "${STAGE_LIST_VAL:-}" =~ stage1 ]]; then HIGHEST_STAGE="stage1"
fi

# IMPORTANT: path must be what the container sees (pi-gen’s docker uses /pi-gen as cwd)
export EXPORT_ROOTFS_DIR="/pi-gen/work/${IMG_DATE}-${IMG_NAME}/${HIGHEST_STAGE}/rootfs"

# Optional (helps some variants): ensure TARGET_IMAGE_SIZE is not empty
export TARGET_IMAGE_SIZE="${TARGET_IMAGE_SIZE:-4096}"

echo ">> Starting pi-gen build (Docker) ..."
echo "   config: $CONFIG"
echo "   stages: ${STAGE_LIST_VAL:-<unknown>}"
echo "   IMG_NAME=${IMG_NAME}"
echo "   IMG_DATE=${IMG_DATE}"
echo "   EXPORT_ROOTFS_DIR=${EXPORT_ROOTFS_DIR}"
echo

# Run build
cd "$PI_GEN_DIR"
# -E preserves our env through sudo; pi-gen's docker wrapper passes env into the container
sudo -E bash ./build.sh -c "$CONFIG"
