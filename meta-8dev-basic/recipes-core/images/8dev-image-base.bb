SUMMARY = "8devices base image for bring-up and debugging"

LICENSE = "MIT"

IMAGE_LINGUAS = ""

COPY_LIC_MANIFEST = "0"
COPY_LIC_DIRS = "0"

CORE_IMAGE_EXTRA_INSTALL:8dev-basic:append = " base-network"

# Citron only: dmidecode for SMBIOS/DMI inspection on the UEFI/UKI boot path.
CORE_IMAGE_EXTRA_INSTALL:append:citron = " dmidecode"

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
