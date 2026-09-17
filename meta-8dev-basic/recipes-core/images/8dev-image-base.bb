SUMMARY = "8devices base image for bring-up and debugging"

LICENSE = "MIT"

IMAGE_LINGUAS = ""

COPY_LIC_MANIFEST = "0"
COPY_LIC_DIRS = "0"

CORE_IMAGE_EXTRA_INSTALL:8dev-basic:append = " base-network"

# Citron only: dmidecode for SMBIOS/DMI inspection on the UEFI/UKI boot path.
CORE_IMAGE_EXTRA_INSTALL:append:citron = " dmidecode"

# Citron only: USB (UVC) camera -> network video streaming via GStreamer.
IMAGE_FEATURES:append:citron = " video-streaming"

# Build/deploy machine artifacts with the image. esp-qcom-image is efi-gated
# (features_check); flashtools self-gates on fastboot in its own recipe.
EXTRA_IMAGEDEPENDS:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'efi', 'esp-qcom-image:do_image_complete', '', d)}"
EXTRA_IMAGEDEPENDS:append = " flashtools:do_deploy"

inherit 8dev-image
inherit core-image

# Mask getty@tty1: citron is serial-console only (serial-getty@ttyMSM0). The VT
# login is an instance of the shared getty@ template, so mask it rather than drop
# a package. Scoped to citron so tobufi is unaffected.
mask_minimal_units () {
    install -d ${IMAGE_ROOTFS}${sysconfdir}/systemd/system
    ln -sf /dev/null ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/getty@tty1.service
}
ROOTFS_POSTPROCESS_COMMAND:append:citron = " mask_minimal_units;"
