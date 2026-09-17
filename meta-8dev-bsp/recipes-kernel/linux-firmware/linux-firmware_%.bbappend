DEPENDS:append:citron = " qca-swiss-army-knife-native"

FILESEXTRAPATHS:prepend:citron := "${THISDIR}/${PN}:"

SRC_URI:append:citron = " \
    file://QCN9274 \
"

do_compile:append:citron() {
     (cd ${UNPACKDIR}/QCN9274; ath12k-bdencoder -c board-2.json -o board-2.bin)
}

do_install:append:citron() {
    install -m 0644 ${UNPACKDIR}/QCN9274/board-2.bin \
        ${D}${nonarch_base_libdir}/firmware/ath12k/QCN9274/hw2.0

    install -m 0644 ${UNPACKDIR}/QCN9274/amss_dualmac.bin \
        ${D}${nonarch_base_libdir}/firmware/ath12k/QCN9274/hw2.0/amss.bin
    install -m 0644 ${UNPACKDIR}/QCN9274/m3.bin \
        ${D}${nonarch_base_libdir}/firmware/ath12k/QCN9274/hw2.0/m3.bin

    # An uncalibrated radio makes the driver error out without this.
    install -m 0644 ${UNPACKDIR}/QCN9274/caldata_4.bin \
        ${D}${nonarch_base_libdir}/firmware/ath12k/QCN9274/hw2.0/caldata.bin
}

do_install:append:citron() {
    rm -f ${D}${nonarch_base_libdir}/firmware/ath12k/QCN9274/hw2.0/firmware-2.bin
    # Both on-carrier NICs load only rtl8168h-2.fw.
    find ${D}${nonarch_base_libdir}/firmware/rtl_nic -name 'rtl8168*.fw' \
        ! -name 'rtl8168h-2.fw' -delete

    # ~24M of VPU variants for other SoCs. Venus loads vpu20_p1.mbn and Iris loads
    # vpu20_p1_gen2.mbn, which is a symlink, so both it and its blob must stay.
    find ${D}${nonarch_base_libdir}/firmware/qcom/vpu -type f \
        ! -name 'vpu20_p1.mbn' ! -name 'vpu20_p1_gen2_s6.mbn' -delete
    find ${D}${nonarch_base_libdir}/firmware/qcom/vpu -type l \
        ! -name 'vpu20_p1_gen2.mbn' -delete
    rm -rf ${D}${nonarch_base_libdir}/firmware/qcom/vpu-1.0
}

# A GPT partition map, not loadable firmware, and no HLOSFW package claims it.
do_install:append:citron() {
    find ${D} -name gptauuid.xml -delete
}
