FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/${PN}:"
SRC_URI:append:8dev-basic = "\
    file://sys-fs-pstore.mount \
"

do_install:append:8dev-basic() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/sys-fs-pstore.mount ${D}${systemd_system_unitdir}/sys-fs-pstore.mount
}

SYSTEMD_SERVICE:${PN}:append:8dev-basic = "\
    sys-fs-pstore.mount \
"
