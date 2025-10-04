
# versanode-os (drop-in pi-gen wrapper)

This repo wraps **Raspberry Pi's pi-gen** so you can build a Raspberry Pi OS image with one extra custom stage (`stage1-kmods`).
It uses Docker (the recommended way), so it works on any modern Linux without polluting your host.

## Quick start
```bash
# 1) Unzip, cd in, and build
cd versanode-os
./scripts/build.sh

# Optional: Use Makefile helpers
make setup   # fetch/update pi-gen only
make build   # build image (same as scripts/build.sh)
make clean   # clean work/deploy artifacts
```

When the build finishes successfully, look for images under:
```
pi-gen/deploy/
```

## Requirements
- Linux host with **Docker** and **git** installed
- ~20GB free disk space; good network
- `sudo` privileges (to run the dockerized build script)

## What this includes
- `config` — minimal pi-gen config: Bookworm, armhf, SSH enabled, and explicit stage list
- `stages/stage1-kmods` — a safe custom stage placed between stage1 and stage2
  - It *copies the previous stage rootfs* in `prerun.sh` (critical)
  - Contains a no-op substage you can customize later
- `scripts/build.sh` — idempotent runner that fetches the correct pi-gen branch, restores upstream stages, injects `stage1-kmods`, and builds with Docker

## Notes
- We **pin to the `bookworm` branch** of `RPi-Distro/pi-gen` and reset to upstream each run to avoid any local drifts causing “rootfs not found” or patch errors.
- If you want 64-bit images for Pi 4/5, change `ARCH=arm64` in `config`.
- If you add more custom stages, ensure each has a `prerun.sh` that does `copy_previous`.
