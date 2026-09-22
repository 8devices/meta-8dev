FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"
SRC_URI:append:8dev-basic = "\
    file://default.conf \
    file://hostapd@.service \
    file://defconfig.8dev-extra \
"

do_configure:append:8dev-basic() {
    cat ${UNPACKDIR}/defconfig.8dev-extra >> ${B}/hostapd/.config
}

do_install:append:8dev-basic() {
    install -d ${D}/${sysconfdir}
    install -m 0644 ${UNPACKDIR}/default.conf ${D}/${sysconfdir}/hostapd.conf
    install -d ${D}/${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/hostapd@.service ${D}/${systemd_system_unitdir}
}

FILES:${PN}:append:8dev-basic = "\
    ${sysconfdir}/hostapd.conf \
    ${systemd_system_unitdir}/hostapd@.service \
"
