# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 8devices UAB
#

# Encode the ext4 image as a sparse image rather than building a second
# filesystem with make_ext4fs, whose ext4 predates metadata_csum, dir_index,
# flex_bg and 64bit. Fastboot and swupdate then install identical bytes.
#
# Option -s marks the unused tail DONT_CARE so the device skips it, saving
# significant mount of fastboot flashing time. Those blocks are unreachable
# through the filesystem, so the stale data left in them does not matter.
IMAGE_CMD:ext4-sparse() {
        img2simg -s ${IMGDEPLOYDIR}/${IMAGE_NAME}.ext4 \
            ${IMGDEPLOYDIR}/${IMAGE_NAME}.ext4-sparse
        simg2img ${IMGDEPLOYDIR}/${IMAGE_NAME}.ext4-sparse /dev/null
}

# Orders the two tasks and keeps the ext4 in place for this one to read, so it
# works whether or not the machine lists ext4 in IMAGE_FSTYPES.
IMAGE_TYPEDEP:ext4-sparse = "ext4"

do_image_ext4_sparse[depends] += "android-tools-native:do_populate_sysroot"

IMAGE_TYPES += "ext4-sparse"
