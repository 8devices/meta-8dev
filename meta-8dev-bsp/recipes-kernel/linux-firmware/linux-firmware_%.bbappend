DEPENDS:append:tobufi = "qca-swiss-army-knife-native"
DEPENDS:append:robovision = "qca-swiss-army-knife-native"

FILESEXTRAPATHS:prepend:tobufi := "${THISDIR}/${PN}:"
FILESEXTRAPATHS:prepend:robovision := "${THISDIR}/${PN}:"

SRC_URI:append:tobufi = "\
    file://WCN3990 \
    file://QCN9074 \
"
SRC_URI:append:robovision = " \
    file://QCN9274 \
"

do_compile:append:tobufi() {
     (cd ${WORKDIR}/WCN3990; ath10k-bdencoder -c board-2.json -o board-2.bin)
     (cd ${WORKDIR}/QCN9074; ath11k-bdencoder -c board-2.json -o board-2.bin)
}

do_compile:append:robovision() {
     (cd ${WORKDIR}/QCN9274; ath12k-bdencoder -c board-2.json -o board-2.bin)
}

do_install:append:tobufi() {
    install -m 0644 ${WORKDIR}/WCN3990/qdsp6sw.mbn ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0
    install -m 0644 ${WORKDIR}/WCN3990/board-2.bin ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0
    install -m 0644 ${WORKDIR}/QCN9074/board-2.bin ${D}${nonarch_base_libdir}/firmware/ath11k/QCN9074/hw1.0
}

do_install:append:robovision() {
    install -m 0644 ${WORKDIR}/QCN9274/board-2.bin \
        ${D}${nonarch_base_libdir}/firmware/ath12k/QCN9274/hw2.0

    install -m 0644 ${WORKDIR}/QCN9274/amss_dualmac.bin \
        ${D}${nonarch_base_libdir}/firmware/ath12k/QCN9274/hw2.0/amss.bin
    install -m 0644 ${WORKDIR}/QCN9274/m3.bin \
        ${D}${nonarch_base_libdir}/firmware/ath12k/QCN9274/hw2.0/m3.bin

    install -m 0644 ${WORKDIR}/QCN9274/caldata_4.bin \
        ${D}${nonarch_base_libdir}/firmware/ath12k/QCN9274/hw2.0/caldata.bin
}

# Cleanup preinstalled files.
do_install:append:robovision() {
    rm -f ${D}${nonarch_base_libdir}/firmware/ath12k/QCN9274/hw2.0/firmware-2.bin
    # Both on-board NICs are RTL8168H/8111H and load only rtl8168h-2.fw; drop the
    # other rtl8168 variant blobs.
    find ${D}${nonarch_base_libdir}/firmware/rtl_nic -name 'rtl8168*.fw' \
        ! -name 'rtl8168h-2.fw' -delete
}

# Disable the Qualcomm artifact-server fetch.
QCM6490_SRC_URI:robovision = ""

# gptauuid.xml is a GPT partition map, not loadable firmware, and no HLOSFW
# update package claims it.
do_install:append:qcom() {
    find ${D} -name gptauuid.xml -delete
}

# Override meta-qcom-hwe's hlosfw_update_packages: a sub-package whose files are
# absent from the firmware archive never gets a staging dir, and the upstream
# os.listdir() then aborts do_package. Skip packages with no staged files.
def hlosfw_update_packages(d, pkgs_list):
    import os
    import shutil

    pkgdest = d.getVar('PKGDEST')
    soc = pkgs_list.split('_')[0].lower()

    for pkg in d.getVar(pkgs_list).split():
        soc_dir = '%s/%s/%s' % (pkgdest, pkg, soc)
        parent_dir = os.path.dirname(soc_dir)

        if os.path.isdir(soc_dir):
            for item in os.listdir(soc_dir):
                shutil.move(os.path.join(soc_dir, item), os.path.join(parent_dir, item))
            os.rmdir(soc_dir)

        if pkg.endswith("qcom-tzapps-updates"):
            tza_updates_dir = '%s/%s/%s' % (pkgdest, pkg, d.getVar('FIRMWARE_UPDATES_DIR'))
            tza_parent_dir = os.path.dirname(tza_updates_dir)
            if os.path.isdir(tza_updates_dir):
                for item in os.listdir(tza_updates_dir):
                    shutil.move(os.path.join(tza_updates_dir, item), os.path.join(tza_parent_dir, item))
                os.rmdir(tza_updates_dir)
