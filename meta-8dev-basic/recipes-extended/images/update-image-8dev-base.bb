require update-image.inc

DESCRIPTION = "SWUpdate compound image for base image"

IMAGE_DEPENDS = "8dev-image-base"
SWUPDATE_IMAGES = "boot 8dev-image-base"

SWUPDATE_IMAGES_FSTYPES[boot] = ".img"
SWUPDATE_IMAGES_FSTYPES[8dev-image-base] = ".rootfs.ext4"
