FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append:tobufi = "\
    file://ath10k;subdir=${BP} \
"

FILES:${PN}-ath10k:append:tobufi = " \
    ${nonarch_base_libdir}/firmware/wcnss.b00 \
    ${nonarch_base_libdir}/firmware/wcnss.b01 \
    ${nonarch_base_libdir}/firmware/wcnss.b02 \
    ${nonarch_base_libdir}/firmware/wcnss.b03 \
    ${nonarch_base_libdir}/firmware/wcnss.b04 \
    ${nonarch_base_libdir}/firmware/wcnss.b05 \
    ${nonarch_base_libdir}/firmware/wcnss.b06 \
    ${nonarch_base_libdir}/firmware/wcnss.b07 \
    ${nonarch_base_libdir}/firmware/wcnss.b08 \
    ${nonarch_base_libdir}/firmware/wcnss.b10 \
    ${nonarch_base_libdir}/firmware/wcnss.b11 \
    ${nonarch_base_libdir}/firmware/wcnss.b12 \
    ${nonarch_base_libdir}/firmware/wcnss.b14 \
    ${nonarch_base_libdir}/firmware/wcnss.b15 \
    ${nonarch_base_libdir}/firmware/wcnss.b16 \
    ${nonarch_base_libdir}/firmware/wcnss.b17 \
    ${nonarch_base_libdir}/firmware/wcnss.b18 \
    ${nonarch_base_libdir}/firmware/wcnss.b19 \
    ${nonarch_base_libdir}/firmware/wcnss.b20 \
    ${nonarch_base_libdir}/firmware/wcnss.mdt \
"

do_install:append:tobufi() {
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b00 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b00
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b00 ${D}${nonarch_base_libdir}/firmware/wcnss.b00
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b01 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b01
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b01 ${D}${nonarch_base_libdir}/firmware/wcnss.b01
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b02 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b02
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b02 ${D}${nonarch_base_libdir}/firmware/wcnss.b02
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b03 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b03
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b03 ${D}${nonarch_base_libdir}/firmware/wcnss.b03
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b04 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b04
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b04 ${D}${nonarch_base_libdir}/firmware/wcnss.b04
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b05 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b05
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b05 ${D}${nonarch_base_libdir}/firmware/wcnss.b05
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b06 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b06
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b06 ${D}${nonarch_base_libdir}/firmware/wcnss.b06
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b07 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b07
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b07 ${D}${nonarch_base_libdir}/firmware/wcnss.b07
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b08 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b08
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b08 ${D}${nonarch_base_libdir}/firmware/wcnss.b08
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b10 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b10
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b10 ${D}${nonarch_base_libdir}/firmware/wcnss.b10
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b11 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b11
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b11 ${D}${nonarch_base_libdir}/firmware/wcnss.b11
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b12 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b12
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b12 ${D}${nonarch_base_libdir}/firmware/wcnss.b12
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b14 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b14
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b14 ${D}${nonarch_base_libdir}/firmware/wcnss.b14
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b15 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b15
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b15 ${D}${nonarch_base_libdir}/firmware/wcnss.b15
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b16 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b16
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b16 ${D}${nonarch_base_libdir}/firmware/wcnss.b16
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b17 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b17
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b17 ${D}${nonarch_base_libdir}/firmware/wcnss.b17
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b18 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b18
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b18 ${D}${nonarch_base_libdir}/firmware/wcnss.b18
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b19 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b19
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b19 ${D}${nonarch_base_libdir}/firmware/wcnss.b19
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.b20 ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.b20
    ln -sf ath10k/WCN3990/hw1.0/wcnss.b20 ${D}${nonarch_base_libdir}/firmware/wcnss.b20
    install -m 0644 ${S}/ath10k/WCN3990/hw1.0/wcnss.mdt ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0/wcnss.mdt
    ln -sf ath10k/WCN3990/hw1.0/wcnss.mdt ${D}${nonarch_base_libdir}/firmware/wcnss.mdt
}
