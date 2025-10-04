# VersaNode OS

<p align="center">
  <!-- Workflows -->
  <a href="https://github.com/Versa-Node/versanode-os/actions/workflows/ci.yml">
    <img src="https://github.com/Versa-Node/versanode-os/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI (lint & sanity)" />
  </a>
  <a href="https://github.com/Versa-Node/versanode-os/actions/workflows/build-release.yml">
    <img src="https://github.com/Versa-Node/versanode-os/actions/workflows/build-release.yml/badge.svg?branch=main" alt="Build & Release (pi-gen)" />
  </a>
  <a href="https://github.com/Versa-Node/versanode-os/actions/workflows/pr-labeler.yml">
    <img src="https://github.com/Versa-Node/versanode-os/actions/workflows/pr-labeler.yml/badge.svg?branch=main" alt="PR Labeler" />
  </a>
  <a href="https://github.com/Versa-Node/versanode-os/actions/workflows/release-drafter.yml">
    <img src="https://github.com/Versa-Node/versanode-os/actions/workflows/release-drafter.yml/badge.svg?branch=main" alt="Release Drafter" />
  </a>
</p>


Custom Raspberry Pi OS image builder powered by [pi-gen](https://github.com/RPi-Distro/pi-gen).  
This repo produces a bootable `.img` (and `.img.xz`) you can flash to an SD card for Raspberry Pi devices.

> ✅ Works on Linux hosts (native or WSL2) with Docker. Artifacts appear in `pi-gen/deploy/`.
> ✅ Includes a custom stage `stage1-kmods` where you can add kernel modules and tweaks.
> ✅ Ships with a ready-to-use `config` so **anyone can build from scratch**.

---

## Table of Contents

- [Requirements](#requirements)
- [Quick Start (build the image)](#quick-start-build-the-image)
- [Config: what the knobs do](#config-what-the-knobs-do)
- [Cloning this repo (with submodules)](#cloning-this-repo-with-submodules)
- [Updating submodules later](#updating-submodules-later)
- [Customize the image (stage1-kmods)](#customize-the-image-stage1-kmods)
- [Flash the image to an SD card (Windows/macOS/Linux)](#flash-the-image-to-an-sd-card-windowsmacoslinux)
- [Troubleshooting](#troubleshooting)
- [Clean builds & rebuilding](#clean-builds--rebuilding)
- [Security notes](#security-notes)
- [Repository layout](#repository-layout)
- [License](#license)

---

## Requirements

- **OS:** Linux host (Debian/Ubuntu recommended) or **Windows with WSL2** (Ubuntu) + Docker Desktop (WSL integration enabled).  
- **Tools:** `git`, **Docker** (daemon running), `sudo` access.
- **Resources:** 25–40 GB free disk, stable internet. 8 GB RAM recommended.

> You do **not** need QEMU manually; pi-gen handles it inside Docker.

---

## Quick Start (build the image)

> These commands assume a fresh clone. If you already cloned, jump to step 2.

1) **Clone with submodules**
```bash
git clone --recurse-submodules https://github.com/Versa-Node/versanode-os.git
cd versanode-os
# If you forgot --recurse-submodules:
git submodule update --init --recursive
```

2) **Review `config`** (already provided). Defaults target **Bookworm** and **arm64**:
```ini
IMG_NAME=versanode-os
RELEASE=bookworm
ARCH=arm64
ENABLE_SSH=1
FIRST_USER_NAME=pi
FIRST_USER_PASS=raspberry
DISABLE_FIRST_BOOT_USER_RENAME=1
DEBIAN_FRONTEND=noninteractive
APT_LISTCHANGES_FRONTEND=none
STAGE_LIST="stage0 stage1 stage1-kmods stage2 stage3 stage4 stage5 export-image"
```
> Tip: Change `ARCH=armhf` for 32‑bit devices; change `RELEASE=trixie` if you want Debian 13-based RPi OS.

3) **Build (inside `pi-gen`, using Docker)**
```bash
cd pi-gen
sudo CLEAN=1 BUILD_WITH_DOCKER=1 CONFIG=../config bash ./build.sh
```

4) **Artifacts**
```bash
ls ../deploy/
# e.g. 2025-10-04-versanode-os.img  (and/or) 2025-10-04-versanode-os.img.xz
```

---

## Config: what the knobs do

Key variables in `config`:

- `IMG_NAME` – base name of output image files.
- `RELEASE` – Raspberry Pi OS release (`bookworm` recommended; `trixie` also supported).
- `ARCH` – `arm64` for Pi 4/5 (64-bit); `armhf` for 32-bit models.
- `ENABLE_SSH=1` – creates `/boot/firmware/ssh` so SSH is enabled on first boot.
- `FIRST_USER_NAME`, `FIRST_USER_PASS` – default account.
- `DISABLE_FIRST_BOOT_USER_RENAME=1` – **disables the interactive “rename user” wizard** that can break headless builds.
- `DEBIAN_FRONTEND=noninteractive`, `APT_LISTCHANGES_FRONTEND=none` – prevent interactive prompts during image creation.
- `STAGE_LIST` – order of build stages (includes our `stage1-kmods`).  
- Optional Wi‑Fi provisioning (headless):
  ```ini
  WPA_ESSID="YourSSID"
  WPA_PASSWORD="YourPassword"
  WPA_COUNTRY="US"
  ```
- Optional locale/timezone/keyboard (defaults shown):
  ```ini
  LOCALE_DEFAULT="en_US.UTF-8"
  TIMEZONE="Etc/UTC"
  KEYBOARD_KEYMAP="us"
  KEYBOARD_LAYOUT="us"
  KEYBOARD_MODEL="pc105"
  ```

> After editing, rebuild to apply changes.

---

## Cloning this repo (with submodules)

Always clone with submodules so `pi-gen` and custom stages are present:   

```bash
git clone --recurse-submodules https://github.com/Versa-Node/versanode-os.git
cd versanode-os
git submodule update --init --recursive
```

If submodule URLs change later:
```bash
git submodule sync --recursive
git submodule update --init --recursive
```

---

## Updating submodules later

To pull the *latest* upstream of `pi-gen` and your custom stage:
```bash
# fetch latest commits for submodules’ tracked branches
git submodule update --remote --recursive

# record the new submodule commits in this repo
git add pi-gen stages/stage1-kmods
git commit -m "Bump submodules"
git push
```

> This keeps everyone on the same pinned submodule commits when they clone your repo.

---

## Customize the image (stage1-kmods)

Your customizations live in: `stages/stage1-kmods/`

Typical subfolders (pi-gen conventions):
```
stages/stage1-kmods/
├─ prerun.sh                  # optional; runs before the stage
├─ 00-kmods/
│  ├─ 00-packages             # space/newline separated package list (installed via apt)
│  ├─ 00-run.sh               # arbitrary shell script run inside chroot
│  └─ files/                  # copied into the image (keep paths relative)
└─ files/                      # stage-wide files copied into rootfs
```

Examples:
- Put packages to install into `00-kmods/00-packages` (one per line).
- Drop files into `files/` and reference correct destination path (pi-gen copies into `rootfs/`).
- Use `00-kmods/00-run.sh` for system tweaks, enabling services, etc.

> Add more numbered steps (`01-*`, `02-*`) if you need ordering inside the stage.

---

## Flash the image to an SD card (Windows/macOS/Linux)

**Option A — Raspberry Pi Imager (recommended)**
1. Download & open **Raspberry Pi Imager**.
2. *Choose OS* → **Use custom** → select your `.img` or `.img.xz` in `pi-gen/deploy/`.
3. *Choose storage* → your SD card.
4. Click the gear icon (optional first-boot settings) – you can set hostname, Wi‑Fi, SSH, user.
5. **Write** → wait until verify completes.

**Option B — balenaEtcher**
1. Open **balenaEtcher** → *Flash from file* → pick `.img`/`.img.xz`.
2. Select target (SD card) → **Flash**.

**First boot**
- Default creds (if you kept defaults): `pi` / `raspberry`
- Change password on first login: `passwd`
- SSH (headless): `ssh pi@raspberrypi.local` (or use the IP from your router).

---

## Troubleshooting

**Rename wizard prompt / “rename-user could not determine which user to rename”**  
Cause: the first-boot rename wizard was triggered in a non‑interactive build step.  
Fix: ensure your `config` has **both**:
```ini
DISABLE_FIRST_BOOT_USER_RENAME=1
FIRST_USER_NAME=pi
FIRST_USER_PASS=raspberry
```
Rebuild after changing.

**Errors like “Unable to chroot/chdir … stage2/rootfs”**  
Cause: earlier stages didn’t complete, or `STAGE_LIST` skipped `stage0`/`stage1`.  
Fix: use the provided `STAGE_LIST` and start from a clean build (see below).

**Patches like `01-useradd.diff` fail to apply**  
Cause: running a patch step when the target file/stage rootfs doesn’t exist yet.  
Fix: don’t cherry-pick stages; run from `stage0`. Clean and rebuild.

**APT prompts / apt-listchanges pauses the build**  
Fix: set in `config`:
```ini
DEBIAN_FRONTEND=noninteractive
APT_LISTCHANGES_FRONTEND=none
```

**Disk space**  
The build can consume 20–40 GB. Ensure enough free space (especially under Docker).

**Release vs. repo**  
If you see `trixie` in logs while you expect `bookworm`, verify `RELEASE=bookworm` in `config` and rebuild clean.

---

## Clean builds & rebuilding

```bash
# from repo root
sudo rm -rf pi-gen/work pi-gen/deploy

# fresh build
cd pi-gen
sudo CLEAN=1 BUILD_WITH_DOCKER=1 CONFIG=../config bash ./build.sh
```

> If you edited submodules, commit/push their changes and advance the submodule pointers in this repo (`git add <submodule>` then commit).

---

## Security notes

- **Change default passwords** after first boot (`passwd`).  
- Consider creating a new user and disabling password SSH auth:
  ```bash
  sudo adduser <you>
  sudo usermod -aG sudo <you>
  sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  sudo systemctl restart ssh
  ```

---

## Repository layout

```
versanode-os/
├─ config                     # build configuration used by pi-gen
├─ pi-gen/                    # submodule: upstream RPi-Distro/pi-gen (the builder)
├─ stages/
│  └─ stage1-kmods/          # submodule: your customizations
├─ scripts/                   # helper scripts (if any)
├─ Makefile                   # optional shortcuts (if present)
└─ deploy/                    # build artifacts appear here after a run
```

---

## License

- pi-gen is licensed by its authors (see `pi-gen/LICENSE`).
- All files in this repository are under the license stated in `LICENSE` at the repo root (adjust to your project).

---

### Handy Commands (cheat sheet)

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/<your-username>/versanode-os.git
cd versanode-os
git submodule update --init --recursive

# Build
cd pi-gen
sudo CLEAN=1 BUILD_WITH_DOCKER=1 CONFIG=../config bash ./build.sh

# Clean
sudo rm -rf ../pi-gen/work ../pi-gen/deploy

# Bump submodules to latest remote
cd /path/to/versanode-os
git submodule update --remote --recursive
git add pi-gen stages/stage1-kmods
git commit -m "Bump submodules" && git push

# Where outputs appear
ls pi-gen/deploy/
```

---

**Happy hacking!** 🐧🛠️
