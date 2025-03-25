FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"
SRC_URI:append:8dev-basic = "\
    file://default.conf \
    file://hostapd@.service \
    file://defconfig.8dev-extra \
"

PACKAGES:prepend:8dev-basic = "${PN}-conf ${PN}-systemd ${PN}-sysvinit "
FILES:${PN}-conf:8dev-basic = "${sysconfdir}/hostapd.conf"
FILES:${PN}-systemd:8dev-basic = "${systemd_system_unitdir}/hostapd@.service"
FILES:${PN}-sysvinit:8dev-basic = "${sysconfdir}/init.d"

RRECOMMENDS:${PN}:append:8dev-basic = " ${PN}-conf"

PACKAGECONFIG:append = " ${INIT_MANAGER}"
PACKAGECONFIG[systemd] = ",,,${PN}-systemd"
PACKAGECONFIG[sysvinit] = ",,,${PN}-sysvinit"

do_configure:append:8dev-basic() {
    cat ${WORKDIR}/defconfig.8dev-extra >> ${B}/hostapd/.config
}

do_install:append:8dev-basic() {
    install -d ${D}/${sysconfdir}
    install -m 0644 ${WORKDIR}/default.conf ${D}/${sysconfdir}/hostapd.conf
    install -d ${D}/${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/hostapd@.service ${D}/${systemd_system_unitdir}
}
