# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 8devices UAB
#

IMAGE_CMD:ext4-sparse() {
        make_ext4fs \
            -o -s \
            -l "${ROOTFS_SIZE}K" \
            ${EXTRA_IMAGECMD} \
            -B ${IMGDEPLOYDIR}/${IMAGE_NAME}.ext4-sparse.map \
            ${IMGDEPLOYDIR}/${IMAGE_NAME}.ext4-sparse ${IMAGE_ROOTFS}
        simg2img ${IMGDEPLOYDIR}/${IMAGE_NAME}.ext4-sparse /dev/null
        ln -sf ${IMAGE_NAME}.ext4-sparse.map ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.ext4-sparse.map
}

EXTRA_IMAGECMD:ext4-sparse ?= ""

do_image_ext4_sparse[depends] += "android-tools-native:do_populate_sysroot"

IMAGE_TYPES += "ext4-sparse"
