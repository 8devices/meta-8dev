FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "\
    file://default.conf \
    file://wpa_supplicant@.service \
    file://wpa_supplicant.init \
    file://defconfig.8dev-extra \
"

inherit update-rc.d

INITSCRIPT_NAME = "wpa_supplicant"

PACKAGES =+ "${PN}-conf ${PN}-systemd ${PN}-sysvinit"
FILES:${PN}-conf = "${sysconfdir}/wpa_supplicant.conf"
FILES:${PN}-systemd = "${systemd_system_unitdir}/wpa_supplicant@.service"
FILES:${PN}-sysvinit = "${sysconfdir}/init.d"

RRECOMMENDS:${PN} += "${PN}-conf"

PACKAGECONFIG:append = " ${INIT_MANAGER}"
PACKAGECONFIG[systemd] = ",,,${PN}-systemd"
PACKAGECONFIG[sysvinit] = ",,,${PN}-sysvinit"

do_configure:append() {
    cat ${WORKDIR}/defconfig.8dev-extra >> ${B}/wpa_supplicant/.config
}

do_install:append() {
    install -d ${D}/${sysconfdir}
    install -m 0644 ${WORKDIR}/default.conf ${D}/${sysconfdir}/wpa_supplicant.conf
    install -d ${D}/${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/wpa_supplicant.init ${D}/${sysconfdir}/init.d/wpa_supplicant
    install -d ${D}/${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/wpa_supplicant@.service ${D}/${systemd_system_unitdir}
}
