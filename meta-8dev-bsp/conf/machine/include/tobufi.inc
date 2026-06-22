require conf/machine/include/qcom-qcs40x.inc
include conf/machine/include/tobufi-extras.inc

# Add "tobufi" as a sub-family level so it lands between SOC_FAMILY (qcom/qcs40x)
# and ${MACHINE} in OVERRIDES: :tobufi outranks the SOC overrides but the
# machine's own override still wins.
SOC_FAMILY .= ":tobufi"

MACHINE_FEATURES += "wifi"

KERNEL_CLASSES += "linux-qcom-bootimg"
QCOM_BOOTIMG_ROOTFS = "/dev/mmcblk0p24"

KERNEL_CMDLINE_EXTRA = "no_console_suspend=1 net.ifnames=0"

IMAGE_CLASSES += "image_types_android"
IMAGE_FSTYPES += "ext4-sparse"
EXTRA_IMAGECMD:ext4-sparse += "-b 4096"
EXTRA_IMAGECMD:ext4-sparse += "-l 681574400"

IMAGE_FSTYPES += "ext4"
EXTRA_IMAGECMD:ext4 += "-b 4096"

IMAGE_ROOTFS_ALIGNMENT = "4"
IMAGE_ROOTFS_MAXSIZE = "665600"

PREFERRED_PROVIDER_virtual/kernel ?= "linux-yocto"
PREFERRED_VERSION_linux-yocto ?= "6.6%"

MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS += "\
    qbootctl \
"

MACHINE_EXTRA_RRECOMMENDS += " \
    kernel-modules \
    linux-firmware-ath10k \
    linux-firmware-ath11k \
    android-tools-adbd \
    tlvstore \
"

# Enable custom reboot-mode for non-systemd
MACHINE_EXTRA_RRECOMMENDS += "\
    ${@bb.utils.contains('INIT_MANAGER', 'systemd', '', 'reboot-mode', d)} \
"

EXTRA_IMAGEDEPENDS += "flashtools"

KERNEL_IMAGETYPES:remove = "Image"
KERNEL_IMAGETYPE = "Image.gz"
