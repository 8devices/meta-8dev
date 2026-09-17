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
    bsp/qcs6490/venus.scc \
"

# Set by the selected conf/distro/include/camera-stack-*.inc.
CAMERA_KERNEL_FEATURE ??= ""
KERNEL_FEATURES:append:citron = " ${CAMERA_KERNEL_FEATURE}"

# Keeps linux-yocto's default features/netfilter/netfilter.scc out.
KERNEL_EXTRA_FEATURES:citron = ""

# Qualcomm UEFI resolves its platform fixups against the __symbols__ node this
# emits; without it boot fails in ufdt_overlay_do_fixups. fdtoverlay needs it too.
KERNEL_DTC_FLAGS:append:citron = " -@"

# Both kernels need this: the board dts describes the panel unconditionally, so a
# DSI-less kernel leaves the DPU master unbound and loses /dev/dri/card0 entirely.
KERNEL_FEATURES:append:citron = " bsp/qcs6490/display.scc"

# Merged into the dtb so every blob in combined-dtb.dtb is self-contained. Works on
# the installed blobs, which is what the deploy tasks read.
merge_camera_dtbo() {
    for pair in ${CAMERA_DTB_OVERLAYS}; do
        dtb="${D}/${KERNEL_DTBDEST}/${pair%%:*}.dtb"
        dtbo="${D}/${KERNEL_DTBDEST}/${pair#*:}.dtbo"
        if [ ! -f "$dtb" ] || [ ! -f "$dtbo" ]; then
            bbfatal "merge_camera_dtbo: missing $dtb or $dtbo, check KERNEL_DEVICETREE"
        fi
        fdtoverlay -i "$dtb" -o "$dtb.merged" "$dtbo"
        mv "$dtb.merged" "$dtb"
    done
}

# One flashed dtb partition has to serve every Citron board, which neither of
# meta-qcom's outputs (one vfat per board, or the FIT image) can do.
#
# It lives in do_deploy, with meta-qcom's do_qcom_dtbbin_deploy deleted below,
# because two sstate tasks writing one deploy dir is not stable: the
# StaleSetSceneTasks cleanup removes the other task's vfats while its stamp stays
# valid, so they never come back and do_swuimage fails.
#
# The -S padding is for UEFI, which walks the pack by each header's totalsize and
# needs the next header 8-byte aligned. expr, not $(( )): bitbake's shell parser
# raises NotImplementedError on arithmetic expansion.
#
# A task-body append rather than a postfunc: sstate.bbclass puts
# sstate_task_postfunc last, so a later postfunc would run after the sstate capture.
do_deploy:append:citron() {
    combined="${WORKDIR}/combined-dtb.dtb"
    rm -f "$combined"

    for dtbf in ${KERNEL_DEVICETREE}; do
        dtb=$(normalize_dtb "$dtbf")
        case "$dtb" in
            *.dtbo) continue ;;
        esac
        stem=$(basename $dtb .dtb)
        src="${D}/${KERNEL_DTBDEST}/$(basename $dtb)"
        [ -f "$src" ] || bbfatal "combined-dtb: missing $src"

        mkfs.vfat -S ${QCOM_VFAT_SECTOR_SIZE} -C ${DEPLOYDIR}/dtb-$stem-image.vfat ${DTBBIN_SIZE}
        mcopy -i "${DEPLOYDIR}/dtb-$stem-image.vfat" -smpQ "$src" ::/combined-dtb.dtb

        size=$(stat -c%s "$src")
        dtc -q -I dtb -O dtb -S $(expr \( $size + 7 \) / 8 \* 8) "$src" >> "$combined"
    done

    mkfs.vfat -S ${QCOM_VFAT_SECTOR_SIZE} -C ${DEPLOYDIR}/dtb-combined-image.vfat ${DTBBIN_SIZE}
    mcopy -i "${DEPLOYDIR}/dtb-combined-image.vfat" -smpQ "$combined" ::/combined-dtb.dtb
    rm -f "$combined"
}

# Task flags cannot take a machine override in this bitbake, hence anon python.
# OVERRIDES is matched by hand because bb.utils.contains cannot split on colons.
python () {
    if 'citron' not in (d.getVar('OVERRIDES') or '').split(':'):
        return

    d.appendVar('DEPENDS', ' dtc-native')
    d.appendVarFlag('do_install', 'postfuncs', ' merge_camera_dtbo')
    d.appendVarFlag('do_deploy', 'depends',
                    ' dosfstools-native:do_populate_sysroot mtools-native:do_populate_sysroot')

    # noexec is not enough: its setscene stays live and restores stale vfats from a
    # shared SSTATE_DIR, which then collide with the ones do_deploy writes.
    bb.build.deltask('do_qcom_dtbbin_deploy', d)
    bb.build.deltask('do_qcom_dtbbin_deploy_setscene', d)
    d.setVar('SSTATETASKS', ' '.join(x for x in (d.getVar('SSTATETASKS') or '').split()
                                     if x != 'do_qcom_dtbbin_deploy'))
}
