require conf/machine/include/qcom-qcs404.inc
include conf/machine/include/tobufi-extras.inc

# cortexa53 tune (arch-armv8a.inc already pulled in by qcom-qcs404.inc)
TUNEVALID[cortexa53] = "Enable Cortex-A53 specific processor optimizations"
TUNE_CCARGS_MARCH = " -mcpu=cortex-a53"
AVAILTUNES += "cortexa53 cortexa53-crypto"
ARMPKGARCH:tune-cortexa53             = "cortexa53"
ARMPKGARCH:tune-cortexa53-crypto      = "cortexa53-crypto"
TUNE_FEATURES:tune-cortexa53          = "aarch64 crc cortexa53"
TUNE_FEATURES:tune-cortexa53-crypto   = "${TUNE_FEATURES:tune-cortexa53} crypto"
PACKAGE_EXTRA_ARCHS:tune-cortexa53    = "${PACKAGE_EXTRA_ARCHS:tune-armv8a-crc} cortexa53"
PACKAGE_EXTRA_ARCHS:tune-cortexa53-crypto = "${PACKAGE_EXTRA_ARCHS:tune-armv8a-crc-crypto} cortexa53 cortexa53-crypto"
BASE_LIB:tune-cortexa53               = "lib64"
BASE_LIB:tune-cortexa53-crypto        = "lib64"
DEFAULTTUNE = "cortexa53"

MACHINEOVERRIDES =. "tobufi:"

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
