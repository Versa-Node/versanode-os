#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_GEN_DIR="$ROOT/pi-gen"

echo ">> Using pi-gen from: $PI_GEN_DIR"

# ---------------------------------------------------------------------------
# 🧩 Sync submodules
# ---------------------------------------------------------------------------
if [ -f "$ROOT/.gitmodules" ]; then
  git submodule sync --recursive
  git submodule update --init --recursive
fi

# ---------------------------------------------------------------------------
# 🧰 Install required dependencies
# ---------------------------------------------------------------------------
echo ">> Checking and installing pi-gen build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  coreutils quilt parted qemu-user-static debootstrap zerofree zip dosfstools e2fsprogs \
  libarchive-tools libcap2-bin grep rsync xz-utils file git curl bc gpg pigz xxd bmap-tools \
  kpartx kmod arch-test ca-certificates

echo "✅ Dependencies installed."

# ---------------------------------------------------------------------------
# 🧱 Prepare custom stages
# ---------------------------------------------------------------------------
mkdir -p "$PI_GEN_DIR/stage8" "$PI_GEN_DIR/stage9"

if [ -d "$ROOT/versanode-os-kmods" ]; then
  echo ">> Injecting stage8 (kmods)..."
  rsync -a --delete "$ROOT/versanode-os-kmods/" "$PI_GEN_DIR/stage8/"
  echo "✅ Injected versanode-os-kmods -> stage8"
fi

if [ -d "$ROOT/versanode-os-usermods" ]; then
  echo ">> Injecting stage9 (usermods)..."
  rsync -a --delete "$ROOT/versanode-os-usermods/" "$PI_GEN_DIR/stage9/"
  echo "✅ Injected versanode-os-usermods -> stage9"
fi

# ---------------------------------------------------------------------------
# 🚧 Prevent early exports from stock stages
# ---------------------------------------------------------------------------
touch "$PI_GEN_DIR/stage3/SKIP"        || true
touch "$PI_GEN_DIR/stage4/SKIP"        || true
touch "$PI_GEN_DIR/stage5/SKIP"        || true
touch "$PI_GEN_DIR/stage2/SKIP_IMAGES" || true
touch "$PI_GEN_DIR/stage4/SKIP_IMAGES" || true
touch "$PI_GEN_DIR/stage5/SKIP_IMAGES" || true

# Export only after our final custom stage (stage9)
cat > "$PI_GEN_DIR/stage9/EXPORT_IMAGE" <<'EOF'
IMG_SUFFIX=""
if [ "${USE_QEMU}" = "1" ]; then
  IMG_SUFFIX="${IMG_SUFFIX}-qemu"
fi
EOF

# ---------------------------------------------------------------------------
# 🧹 Ensure scripts are executable and Unix formatted
# ---------------------------------------------------------------------------
find "$PI_GEN_DIR" -type f -name '*.sh' -exec chmod +x {} \;
find "$PI_GEN_DIR" -type f -name '*.sh' -exec sed -i 's/\r$//' {} \;

# ---------------------------------------------------------------------------
# ⚙️ Copy config into pi-gen
# ---------------------------------------------------------------------------
echo ">> Copying config into pi-gen/config..."
cp -f "$ROOT/config" "$PI_GEN_DIR/config"
chmod 644 "$PI_GEN_DIR/config"

# ---------------------------------------------------------------------------
# 🧾 Extract key values for logs
# ---------------------------------------------------------------------------
IMG_NAME="$(grep -E '^IMG_NAME=' "$PI_GEN_DIR/config" | cut -d= -f2- | tr -d '"')"
STAGE_LIST="$(grep -E '^STAGE_LIST=' "$PI_GEN_DIR/config" | cut -d= -f2- | tr -d '"')"
export IMG_NAME="${IMG_NAME:-versanode-os}"
export IMG_DATE="$(date -u +%Y-%m-%d)"
export BUILD_WITH_DOCKER=1
export CLEAN=1

# ---------------------------------------------------------------------------
# 🧮 Determine highest stage for display (for logging)
# ---------------------------------------------------------------------------
HIGHEST_STAGE="stage2"
for s in stage9 stage8 stage5 stage4 stage3 stage2 stage1; do
  if [[ "${STAGE_LIST:-}" == *"$s"* ]]; then
    HIGHEST_STAGE="$s"
    break
  fi
done

# ---------------------------------------------------------------------------
# 🚀 Build
# ---------------------------------------------------------------------------
echo ">> Building VersaNode OS..."
echo "   IMG_NAME=$IMG_NAME"
echo "   STAGE_LIST=${STAGE_LIST:-<not set>}"
echo "   HIGHEST_STAGE=$HIGHEST_STAGE"
echo

cd "$PI_GEN_DIR"
sudo -E bash ./build.sh -c config
