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

# This board has no motion sensors, so EIS and NCS only buy gyro QMI probe
# timeouts and a per-frame AFD warning. Measured: cam-server init 20s -> 1.4s.
# Core dumps are 33 MB per recovery event with no rotation, so they fill the rootfs.
SRC_URI:append:citron = " file://camxoverridesettings.txt"
SRC_URI:append:citron = " file://var-cache-camera-coredump.mount"

do_install:append:citron() {
    install -d ${D}${systemd_system_unitdir}/cam-server.service.d
    install -m 0644 ${UNPACKDIR}/cam-server-restart.conf \
        ${D}${systemd_system_unitdir}/cam-server.service.d/restart.conf

    # CamX reads overrides from the same dir as camera_config.xml.
    install -d ${D}${localstatedir}/cache/camera
    install -m 0644 ${UNPACKDIR}/camxoverridesettings.txt \
        ${D}${localstatedir}/cache/camera/camxoverridesettings.txt

    install -m 0644 ${UNPACKDIR}/var-cache-camera-coredump.mount \
        ${D}${systemd_system_unitdir}/var-cache-camera-coredump.mount
}

FILES:${PN}:append:citron = " \
    ${systemd_system_unitdir}/cam-server.service.d/restart.conf \
    ${systemd_system_unitdir}/var-cache-camera-coredump.mount \
    ${localstatedir}/cache/camera/camxoverridesettings.txt \
"

# Hard cap on dump growth in case the override file is not picked up.
SYSTEMD_SERVICE:${PN}:append:citron = " var-cache-camera-coredump.mount"
