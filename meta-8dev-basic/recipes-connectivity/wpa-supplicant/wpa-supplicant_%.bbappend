FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"
SRC_URI:append:8dev-basic = "\
    file://default.conf \
    file://wpa_supplicant@.service \
    file://wpa_supplicant.init \
    file://defconfig.8dev-extra \
"

INHERIT_8DEV = ""
INHERIT_8DEV:8dev-basic = "update-rc.d"
inherit ${INHERIT_8DEV}

INITSCRIPT_NAME:8dev-basic = "wpa_supplicant"

PACKAGES:prepend:8dev-basic = "${PN}-conf ${PN}-systemd ${PN}-sysvinit "
FILES:${PN}-conf:8dev-basic = "${sysconfdir}/wpa_supplicant.conf"
FILES:${PN}-systemd:8dev-basic = "${systemd_system_unitdir}/wpa_supplicant@.service"
FILES:${PN}-sysvinit:8dev-basic = "${sysconfdir}/init.d"

RRECOMMENDS:${PN}:append:8dev-basic = " ${PN}-conf"

PACKAGECONFIG:append = " ${INIT_MANAGER}"
PACKAGECONFIG[systemd] = ",,,${PN}-systemd"
PACKAGECONFIG[sysvinit] = ",,,${PN}-sysvinit"

do_configure:append:8dev-basic() {
    cat ${WORKDIR}/defconfig.8dev-extra >> ${B}/wpa_supplicant/.config
}

do_install:append:8dev-basic() {
    install -d ${D}/${sysconfdir}
    install -m 0644 ${WORKDIR}/default.conf ${D}/${sysconfdir}/wpa_supplicant.conf
    install -d ${D}/${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/wpa_supplicant.init ${D}/${sysconfdir}/init.d/wpa_supplicant
    install -d ${D}/${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/wpa_supplicant@.service ${D}/${systemd_system_unitdir}
}
