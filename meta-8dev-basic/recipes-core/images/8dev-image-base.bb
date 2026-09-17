SUMMARY = "8devices base image for bring-up and debugging"

LICENSE = "MIT"

IMAGE_LINGUAS = ""

COPY_LIC_MANIFEST = "0"
COPY_LIC_DIRS = "0"

# Kept here, not in the distro conf, so no other image built under 8dev-basic
# inherits an open root account. (wrynose dropped the "debug-tweaks" meta feature.)
IMAGE_FEATURES += "\
    ssh-server-openssh \
    allow-empty-password \
    allow-root-login \
    empty-root-password \
    post-install-logging \
    system-debug \
    network-debug \
    update-tools \
"

IMAGE_INSTALL:append:8dev-basic = " packagegroup-basic-core"
IMAGE_INSTALL:append:8dev-basic = " base-network"

IMAGE_FSTYPES:append:citron = " ext4.gz"

EXTRA_IMAGEDEPENDS:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'efi', 'esp-qcom-image:do_image_complete', '', d)}"
EXTRA_IMAGEDEPENDS:append = " flashtools:do_deploy"

inherit 8dev-image
inherit core-image

# Serial console only.
mask_minimal_units () {
    install -d ${IMAGE_ROOTFS}${sysconfdir}/systemd/system
    ln -sf /dev/null ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/getty@tty1.service
}
ROOTFS_POSTPROCESS_COMMAND:append:citron = " mask_minimal_units;"
