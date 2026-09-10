SUMMARY = "Runtime board detection and configuration"
DESCRIPTION = "Detects board type at boot, sets hostname, and exposes \
board identity to dependent services."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

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

FILES:${PN} += "\
    ${base_libdir}/boardinfo.d \
"
