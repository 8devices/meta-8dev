require update-image.inc

DESCRIPTION = "SWUpdate compound image for base image"

IMAGE_DEPENDS = "8dev-image-base"

SWUPDATE_IMAGES:citron = "dtb efi system"

SWUPDATE_IMAGES_FSTYPES[dtb] = ".bin.gz"
SWUPDATE_IMAGES_FSTYPES[efi] = ".bin.gz"
SWUPDATE_IMAGES_FSTYPES[system] = ".img.gz"
