require conf/machine/include/qcom-qcs6490.inc

# qcom-base.inc, pulled in by the require above, already sets the provider with
# ?=, so a plain ?= here is a no-op and the build picks linux-qcom. The override
# variant wins at expansion regardless of who assigned the base value first.
PREFERRED_PROVIDER_virtual/kernel:citron ?= "linux-yocto"
PREFERRED_VERSION_linux-yocto:citron ?= "6.18%"

MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS:append = " \
    qbootctl \
    tlvstore \
"

MACHINE_EXTRA_RRECOMMENDS:append = " \
    linux-firmware-qcom-qcm6490-qupv3fw \
    linux-firmware-qcom-vpu \
"

# At machine scope rather than in a video-streaming packagegroup: a USB camera is
# independent of CAMERA_STACK and the kernel carries uvc-camera.scc unconditionally.
MACHINE_EXTRA_RRECOMMENDS:append = " \
    kernel-module-uvcvideo \
"

# urm owns the runtime tuning the camera pipeline depends on (cpusets, THP, uclamp,
# IRQ affinity). -extensions owns /etc/urm/target, without which no qcm6490 policy
# runs; urm reads its target from /sys/devices/soc0/machine, hence
# patches/qcom-socinfo-add-qcs6490-soc-id.patch.
MACHINE_EXTRA_RRECOMMENDS:append = " \
    userspace-resource-manager \
    userspace-resource-manager-extensions \
"

BAD_RECOMMENDATIONS:append = " \
    kernel-module-wlan-platform \
    kernel-module-qcacld-wlan \
    kernel-module-qca6490 \
    wlan-conf \
    securedsp-example \
    modemmanager \
    networkmanager-wifi \
"

# qairt-sdk recommends every HTP skel variant; only v68 matches QCS6490.
BAD_RECOMMENDATIONS:append = " \
    qairt-sdk-hexagon-v66 \
    qairt-sdk-hexagon-v73 \
    qairt-sdk-hexagon-v75 \
"

SERIAL_CONSOLES = "115200;ttyMSM0"

# One packed dtb that UEFI matches against the CDT per blob. The FIT alternative
# ("multi-dtb") would need FIT_DTB_COMPATIBLE and qcom-dtb-metadata nodes instead.
QCOM_DTB_DEFAULT = "combined"

# Boots a UKI from the ESP. The boot.img this class builds expects an Image.gz
# we do not produce, and nothing consumes it.
KERNEL_CLASSES:remove = "linux-qcom-bootimg"

# Fallback rootfs; UEFI appends the active slot's root= later (last root= wins).
QCOM_BOOTIMG_ROOTFS = "PARTLABEL=system_a"

# DEBUG earlycon; remove once boot is clean.
KERNEL_CMDLINE_EXTRA:append = " earlycon=qcom_geni,mmio32,0x994000"

# efi gates the systemd-boot UKI path and esp-qcom-image.
# USB features are defined to be consistend with a generic
# SOM dts where only usb0 is defined.
MACHINE_FEATURES:append = " \
    usbhost \
    usbgadget \
    fastboot \
    edl \
    efi \
"

MACHINE_EXTRA_RRECOMMENDS:append = " \
    android-tools-adbd \
"
PREFERRED_PROVIDER_android-tools-conf = " \
    android-tools-conf-configfs \
"

# No DSP compute, Ethernet-only by default.
MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS:remove = "pd-mapper networkmanager-nmcli networkmanager-wifi"
# fastrpc is a hard RDEPENDS of this group, so the whole group has to go.
MACHINE_EXTRA_RRECOMMENDS:remove = "packagegroup-qcom-boot-additional"

INITRAMFS_IMAGE_BUNDLE = "1"
# Minimal ramdisk that pivots into the real A/B rootfs.
INITRAMFS_IMAGE = "initramfs-rootfs-image"

IMAGE_CLASSES += "image_types_qcom"
