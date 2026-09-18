FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"

# Drop-in fixing rpcbind's early-boot failure (see the .conf for rationale).
SRC_URI:append:8dev-basic = " file://rpcbind-runtimedir.conf"

do_install:append:8dev-basic() {
    install -d ${D}${systemd_system_unitdir}/rpcbind.service.d
    install -m 0644 ${UNPACKDIR}/rpcbind-runtimedir.conf \
        ${D}${systemd_system_unitdir}/rpcbind.service.d/10-runtimedir.conf
}

FILES:${PN}:append:8dev-basic = " ${systemd_system_unitdir}/rpcbind.service.d"
