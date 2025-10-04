#!/bin/bash -e
# Every custom stage must copy the previous stage rootfs so the next stage sees it.
if [ ! -d "${ROOTFS_DIR}" ]; then
  copy_previous
fi
