DESCRIPTION = "SWUpdate compound image"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit swupdate

SRC_URI = "\
    file://sw-description \
    file://change_boot_slot.sh \
"

IMAGE_DEPENDS = "8dev-image-base virtual/kernel"
SWUPDATE_IMAGES = "8dev-image-base aImage"

SWUPDATE_IMAGES_FSTYPES[8dev-image-base] = ".rootfs.ext4"
SWUPDATE_IMAGES_FSTYPES[aImage] = ".gz"
