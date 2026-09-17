LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit swupdate

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI = "\
    file://sw-description \
    file://change_boot_slot.sh \
"

# sw-description bundles the kernel-deployed dtb-${QCOM_DTB_DEFAULT}-image.vfat.
do_swuimage[depends] += "virtual/kernel:do_deploy"
