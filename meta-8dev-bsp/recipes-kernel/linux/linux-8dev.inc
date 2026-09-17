# Hardcode linux-yocto path to ensure correct directory is
# extended when including it from different named recipes.
FILESEXTRAPATHS:prepend:citron := "${THISDIR}/linux-yocto-6.18:"

SRC_URI:append:citron = "\
    file://meta-bsp;type=kmeta;destsuffix=meta-bsp \
    file://files \
"

do_kernel_checkout:append:citron() {
    if [ -d ${UNPACKDIR}/files ]; then
        cp -r ${UNPACKDIR}/files/* ${S}
    fi
}

# Report fragment options the merge dropped or redefined, so a fragment that
# silently stops taking effect shows up in do_kernel_configcheck.
KCONF_BSP_AUDIT_LEVEL:citron = "1"

KERNEL_FEATURES:append:citron = "\
    cfg/fs/ext4.scc \
    cfg/fs/vfat.scc \
    cfg/8dev/systemd.scc \
    cfg/8dev/squashfs.scc \
    cfg/8dev/uvc-camera.scc \
    bsp/qcs6490/camss.scc \
    bsp/qcs6490/venus.scc \
"

# Keeps linux-yocto's default features/netfilter/netfilter.scc out.
KERNEL_EXTRA_FEATURES:citron = ""

# Qualcomm UEFI resolves its platform fixups against the __symbols__ node this
# emits; without it boot fails in ufdt_overlay_do_fixups.
KERNEL_DTC_FLAGS:append:citron = " -@"

# meta-qcom wraps the dtb into dtb-${QCOM_DTB_DEFAULT}-image.vfat in a second
# sstate task, and two tasks writing one deploy dir is not stable: the
# StaleSetSceneTasks cleanup that runs with do_deploy removes the other task's
# vfat while its stamp stays valid, so it never comes back and do_swuimage
# fails. Build the vfat here, from the installed blobs do_deploy already reads.
do_deploy:append:citron() {
    for dtbf in ${KERNEL_DEVICETREE}; do
        dtb=$(normalize_dtb "$dtbf")
        stem=$(basename $dtb .dtb)
        src="${D}/${KERNEL_DTBDEST}/$(basename $dtb)"
        [ -f "$src" ] || bbfatal "dtb vfat: missing $src"

        mkfs.vfat -S ${QCOM_VFAT_SECTOR_SIZE} -C ${DEPLOYDIR}/dtb-$stem-image.vfat ${DTBBIN_SIZE}
        mcopy -i "${DEPLOYDIR}/dtb-$stem-image.vfat" -smpQ "$src" ::/combined-dtb.dtb
    done
}

# Task flags cannot take a machine override in this bitbake, hence anon python.
# OVERRIDES is matched by hand because bb.utils.contains cannot split on colons.
python () {
    if 'citron' not in (d.getVar('OVERRIDES') or '').split(':'):
        return

    d.appendVarFlag('do_deploy', 'depends',
                    ' dosfstools-native:do_populate_sysroot mtools-native:do_populate_sysroot')

    # noexec is not enough: its setscene stays live and restores stale vfats from a
    # shared SSTATE_DIR, which then collide with the ones do_deploy writes.
    bb.build.deltask('do_qcom_dtbbin_deploy', d)
    bb.build.deltask('do_qcom_dtbbin_deploy_setscene', d)
    d.setVar('SSTATETASKS', ' '.join(x for x in (d.getVar('SSTATETASKS') or '').split()
                                     if x != 'do_qcom_dtbbin_deploy'))
}
