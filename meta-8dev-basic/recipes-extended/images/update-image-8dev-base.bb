require update-image.inc

COMPATIBLE_MACHINE = "citron"

DESCRIPTION = "SWUpdate compound image for base image"

IMAGE_DEPENDS = "8dev-image-base"

# Must match the sw-description. esp-qcom-image and the kernel dtb arrive
# transitively through 8dev-image-base.
SWUPDATE_IMAGES:citron = "\
    8dev-image-base-${MACHINE}.rootfs.ext4.gz \
    esp-qcom-image-${MACHINE}.rootfs.vfat.gz \
    dtb-${QCOM_DTB_DEFAULT}-image.vfat \
"
