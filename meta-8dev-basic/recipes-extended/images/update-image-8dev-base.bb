require update-image.inc

DESCRIPTION = "SWUpdate compound image for base image"

IMAGE_DEPENDS = "8dev-image-base"

# Real deploy-dir artifacts (complete entries); must match the sw-description.
# esp-qcom-image + kernel dtb come transitively via 8dev-image-base's deps.
SWUPDATE_IMAGES:citron = "\
    8dev-image-base-${MACHINE}.rootfs.ext4.gz \
    esp-qcom-image-${MACHINE}.rootfs.vfat.gz \
    dtb-${QCOM_DTB_DEFAULT}-image.vfat \
"
