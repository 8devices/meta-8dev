SUMMARY = "Firmware images flashing tools"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit deploy

S = "${UNPACKDIR}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "${@bb.utils.contains('MACHINE_FEATURES', 'fastboot', 'file://fastboot_flash.py', '', d)}"

# fastboot.json flash map: partition -> deployed image name (A/B share an image).
FLASHMAP_ROOTFS_IMAGE ?= "8dev-image-base-${MACHINE}.rootfs.ext4"
FLASHMAP_ESP_IMAGE    ?= "esp-qcom-image-${MACHINE}.rootfs.vfat"
FLASHMAP_DTB_IMAGE    ?= "dtb-${QCOM_DTB_DEFAULT}-image.vfat"

do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"

python do_deploy() {
    import json, os, shutil

    if not bb.utils.contains("MACHINE_FEATURES", "fastboot", True, False, d):
        return

    deploydir = d.getVar("DEPLOYDIR")
    shutil.copy(os.path.join(d.getVar("UNPACKDIR"), "fastboot_flash.py"), deploydir)
    os.chmod(os.path.join(deploydir, "fastboot_flash.py"), 0o755)

    images = {
        "dtb":    d.getVar("FLASHMAP_DTB_IMAGE"),
        "efi":    d.getVar("FLASHMAP_ESP_IMAGE"),
        "system": d.getVar("FLASHMAP_ROOTFS_IMAGE"),
    }
    flashmap = {}
    for part, image in images.items():
        flashmap[part + "_a"] = image
        flashmap[part + "_b"] = image

    with open(os.path.join(deploydir, "fastboot.json"), "w") as f:
        json.dump(flashmap, f, indent=4)
        f.write("\n")
}
addtask deploy after do_install
