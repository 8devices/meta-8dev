require conf/machine/include/qcom/qcs40x.inc

MACHINEOVERRIDES =. "tobufi:"

MACHINE_FEATURES += "wifi"

KERNEL_CLASSES += "kernel-android"
KERNEL_IMAGETYPE = "aImage.gz"
AIMAGE_BASEADDR = "0x80000000"
AIMAGE_PAGESIZE = "4096"
AIMAGE_CMDLINE = "noinitrd rw rootwait console=ttyMSM0,115200,n8 no_console_suspend=1 net.ifnames=0"

IMAGE_CLASSES += "image_types_android"
IMAGE_FSTYPES += "ext4-sparse"
EXTRA_IMAGECMD:ext4-sparse += "-b 4096"
EXTRA_IMAGECMD:ext4-sparse += "-l 681574400"

IMAGE_ROOTFS_ALIGNMENT ?= "4"
IMAGE_ROOTFS_MAXSIZE = "665600"

SERIAL_CONSOLES = "115200;ttyMSM0"

PREFERRED_PROVIDER_virtual/kernel ?= "linux-yocto"
PREFERRED_VERSION_linux-yocto ?= "6.6%"

MACHINE_EXTRA_RRECOMMENDS += " \
    kernel-modules \
    linux-firmware-ath10k \
    linux-firmware-ath11k \
"

# Enable custom reboot-mode for non-systemd
MACHINE_EXTRA_RRECOMMENDS += "\
    ${@bb.utils.contains('INIT_MANAGER', 'systemd', '', 'reboot-mode', d)} \
"

EXTRA_IMAGEDEPENDS += "flashtools"

# Exclude linux kernel from rootfs
RRECOMMENDS:${KERNEL_PACKAGE_NAME}-base = ""
