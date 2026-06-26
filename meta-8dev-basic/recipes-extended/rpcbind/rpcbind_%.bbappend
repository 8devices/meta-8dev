FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Drop-in fixing rpcbind's early-boot failure (see the .conf for rationale).
SRC_URI += "file://rpcbind-runtimedir.conf"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}/rpcbind.service.d
    install -m 0644 ${WORKDIR}/rpcbind-runtimedir.conf \
        ${D}${systemd_system_unitdir}/rpcbind.service.d/10-runtimedir.conf
}

FILES:${PN} += "${systemd_system_unitdir}/rpcbind.service.d"
