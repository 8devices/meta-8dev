# camera-service's generic dlopen backend is really the lemans (QCS9100) variant:
# ~575 MB of Spectra libraries for the wrong SoC; qcm6490 is kodiak. Dropping it
# from the server-lib RDEPENDS too removes the sole build-graph reference, so
# camxlib-lemans is never built, not merely never installed.
RDEPENDS:${PN}:remove:citron = "camera-service-server-lib"
RDEPENDS:${PN}-server-lib:remove:citron = "camxlib-lemans"

# An abruptly disconnecting client can crash cam-server; restart so the camera
# recovers without manual intervention.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:citron = " file://cam-server-restart.conf"

do_install:append:citron() {
    install -d ${D}${systemd_system_unitdir}/cam-server.service.d
    install -m 0644 ${UNPACKDIR}/cam-server-restart.conf \
        ${D}${systemd_system_unitdir}/cam-server.service.d/restart.conf
}

FILES:${PN}:append:citron = " \
    ${systemd_system_unitdir}/cam-server.service.d/restart.conf \
"
