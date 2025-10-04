# Contributing

Thanks for considering a contribution!

## Getting started
1. Fork and clone the repo.
2. Ensure submodules are initialized:
   ```bash
   git submodule update --init --recursive
   ```
3. Make a feature branch from `main`:
   ```bash
   git checkout -b feat/my-change
   ```

## Development hints
- Build locally on Ubuntu with Docker:
  ```bash
  CLEAN=1 BUILD_WITH_DOCKER=1 CONFIG=./config sudo -E bash pi-gen/build.sh
  ```
- Keep changes to upstream `pi-gen` isolated to your custom stages (e.g., `stages/stage1-kmods`).

## Linting
CI runs basic `shellcheck` on repo scripts and stages:
```bash
shellcheck scripts/**/*.sh stages/**/*.sh
```

## PRs
- Keep PRs focused.
- Update README/config/examples when behavior changes.
- All PRs should pass CI.

## Releases
- Tag with `vX.Y.Z` to trigger the build-and-release workflow.
