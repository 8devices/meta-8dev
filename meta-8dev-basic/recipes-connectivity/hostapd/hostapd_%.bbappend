FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "\
    file://default.conf \
    file://hostapd@.service \
    file://defconfig.8dev-extra \
"

PACKAGES =+ "${PN}-conf ${PN}-systemd ${PN}-sysvinit"
FILES:${PN}-conf = "${sysconfdir}/hostapd.conf"
FILES:${PN}-systemd = "${systemd_system_unitdir}/hostapd@.service"
FILES:${PN}-sysvinit = "${sysconfdir}/init.d"

RRECOMMENDS:${PN} += "${PN}-conf"

PACKAGECONFIG:append = " ${INIT_MANAGER}"
PACKAGECONFIG[systemd] = ",,,${PN}-systemd"
PACKAGECONFIG[sysvinit] = ",,,${PN}-sysvinit"

do_configure:append() {
    cat ${WORKDIR}/defconfig.8dev-extra >> ${B}/hostapd/.config
}

do_install:append() {
    install -d ${D}/${sysconfdir}
    install -m 0644 ${WORKDIR}/default.conf ${D}/${sysconfdir}/hostapd.conf
    install -d ${D}/${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/hostapd@.service ${D}/${systemd_system_unitdir}
}
