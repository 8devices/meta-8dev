SUMMARY = "Runtime board detection and configuration"
DESCRIPTION = "Detects board type at boot, sets hostname, and exposes \
board identity to dependent services."
LICENSE = "CLOSED"

inherit systemd

SRC_URI = "\
    file://board-init.sh \
    file://board-init.service \
    file://boardinfo.sh \
"

S = "${WORKDIR}"

do_install() {
    install -D -m 0755 ${WORKDIR}/board-init.sh \
        ${D}${sbindir}/board-init
    install -D -m 0644 ${WORKDIR}/board-init.service \
        ${D}${systemd_system_unitdir}/board-init.service
    install -D -m 0755 ${WORKDIR}/boardinfo.sh \
        ${D}${bindir}/boardinfo
}

SYSTEMD_SERVICE:${PN} = "board-init.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

