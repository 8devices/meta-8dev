SUMMARY = "Runtime board detection and initialization"
DESCRIPTION = "Detects board type from device tree at boot, initializes \
board-specific defaults, hostname, and USB identity."
LICENSE = "CLOSED"

inherit systemd

SRC_URI = "\
    file://board-init.sh \
    file://board-init.service \
"

S = "${WORKDIR}"

do_install() {
    install -D -m 0755 ${WORKDIR}/board-init.sh \
        ${D}/usr/share/board-init/board-init.sh
    install -D -m 0644 ${WORKDIR}/board-init.service \
        ${D}${systemd_system_unitdir}/board-init.service
}

SYSTEMD_SERVICE:${PN} = "board-init.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

FILES:${PN} += "/usr/share/board-init/"
