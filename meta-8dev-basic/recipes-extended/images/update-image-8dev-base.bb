require update-image.inc

DESCRIPTION = "SWUpdate compound image for base image"

IMAGE_DEPENDS = "8dev-image-base"

SWUPDATE_IMAGES:tobufi = "boot 8dev-image-base"
SWUPDATE_IMAGES:citron = "dtb efi system"

# Varflags ignore :override, so set unconditionally; keys are disjoint per
# machine and SWUPDATE_IMAGES selects which apply.
SWUPDATE_IMAGES_FSTYPES[boot] = ".img"
SWUPDATE_IMAGES_FSTYPES[8dev-image-base] = ".rootfs.ext4"
SWUPDATE_IMAGES_FSTYPES[dtb] = ".bin.gz"
SWUPDATE_IMAGES_FSTYPES[efi] = ".bin.gz"
SWUPDATE_IMAGES_FSTYPES[system] = ".img.gz"

# Compound update (rootfs + kernel/dtb + ESP); drop the default ".rootfs" suffix
# so the .swu name isn't misleading.
IMAGE_NAME_SUFFIX:citron = ""
