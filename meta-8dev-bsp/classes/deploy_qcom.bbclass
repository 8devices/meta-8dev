IMAGE_GEN_DEBUGFS = "0"
IMAGE_FSTYPES_DEBUGFS = ""

# Don't install locales into rootfs
IMAGE_LINGUAS = ""

# Default Image names
SYSTEMIMAGE_TARGET ?= "system.img"

SYSTEMIMAGE_TYPE = "ext4"

do_deploy_qcom[dirs] = "${DEPLOY_DIR_IMAGE}"
do_deploy_qcom[depends] += "esp-qcom-image:do_image_complete"
do_deploy_qcom[depends] += "dtb-qcom-image:do_image_complete"
do_deploy_qcom[deptask] = "do_image_complete"

DEPLOYDEPENDS = " \
    flashtools:do_deploy \
"
do_deploy_qcom[depends] += "${DEPLOYDEPENDS}"

do_deploy_qcom[nostamp] = "1"
do_deploy_qcom () {
    SRC="${DEPLOY_DIR_IMAGE}"

    install -m 0644 "${SRC}/${IMAGE_LINK_NAME}.${SYSTEMIMAGE_TYPE}" "${SYSTEMIMAGE_TARGET}"
    install -m 0644 "${SRC}/esp-qcom-image-${MACHINE}${IMAGE_NAME_SUFFIX}.vfat" efi.bin
    install -m 0644 "${SRC}/dtb-qcom-image-${MACHINE}${IMAGE_NAME_SUFFIX}.vfat" dtb.bin

    # gzip the filesystem images for swupdate OTA (~6x smaller, slack is
    # zero-filled). Raw copies stay for EDL/fastboot, which flash uncompressed.
    # gzip -n keeps output reproducible (no embedded mtime/name).
    for img in "${SYSTEMIMAGE_TARGET}" efi.bin dtb.bin; do
        gzip -n -9 -c "${img}" > "${img}.gz"
    done
}
addtask do_deploy_qcom after do_image_complete before do_build
