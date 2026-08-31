# Qualcomm include files form a non-conventional MACHINEOVERRIDES
# order, which makes Qualcomm BSP overrides to take a precedence
# over our prepended SOM override. Thus, we must prepend override
# before including qcom SOM include file.
MACHINEOVERRIDES =. "tobufi:"

require conf/machine/include/qcom-qcs40x.inc
include conf/machine/include/tobufi-extras.inc

MACHINE_FEATURES += "wifi"

# flashtools picks the host flash tool by MACHINE_FEATURE; tobufi uses fastboot.
MACHINE_FEATURES += "fastboot"

KERNEL_CLASSES += "linux-qcom-bootimg"
QCOM_BOOTIMG_ROOTFS = "/dev/mmcblk0p24"

KERNEL_CMDLINE_EXTRA = "no_console_suspend=1 net.ifnames=0"

# systemd seds this into RebootWatchdogSec=: PID 1 arms the apss watchdog with
# it before handing over to systemd-shutdown, so a wedged reboot resets instead
# of hanging. Reboot only -- poweroff, halt and kexec leave the timer at 0,
# which disarms it. Poky defaults to 60; a measured reboot here takes ~12s.
#
# Mind what the budget covers: systemd-shutdown pings once as it arms, then not
# again until the unmount loop, so the sync and both kill waits are inside it.
# A flush slower than this is cut off by the reset, not given headroom by it.
WATCHDOG_TIMEOUT = "30"

IMAGE_CLASSES += "image_types_android"

IMAGE_FSTYPES += "ext4.gz ext4-sparse"

# Size the filesystem to the whole slot so a factory-flashed and an updated
# device end up identical, with nothing left to grow afterwards; sparse and
# gzip both carry the unused tail for next to nothing. SIZE floors the image,
# MAXSIZE only aborts the build -- equal values pin it to the slot and still
# catch a rootfs that outgrows it.
IMAGE_ROOTFS_SIZE = "665600"
IMAGE_ROOTFS_MAXSIZE = "665600"
# qcom-common.inc asks for 4096, but the unit is KB and 665600 is not a
# multiple of 4 MB, so it would round past the end of the slot. ext4 needs
# only its 4096-byte block size.
IMAGE_ROOTFS_ALIGNMENT = "4"
IMAGE_ROOTFS_EXTRA_SPACE = "0"
IMAGE_OVERHEAD_FACTOR = "1"

# Applied to the base type, so the gz and the sparse image share it:
# * 4 KB blocks (-b 4096), matching the page size and the alignment above
# * no 5% root reserve (-m 0): only root writes here, so it protected nothing
#   and merely understated free space
# * 4 MB journal rather than the 16 MB mke2fs picks (-J size=4): journal size
#   bounds in-flight metadata, not durability, and config writes never queue
#   anything close
# * inode count left at the default (no -N), already ~10x what the rootfs uses
EXTRA_IMAGECMD:ext4 += "-b 4096 -m 0 -J size=4"

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

# Exclude linux kernel from rootfs
RRECOMMENDS:${KERNEL_PACKAGE_NAME}-base = ""
