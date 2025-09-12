FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"

SRC_URI:append:8dev-basic = " file://android-tools-adbd.service.d/env-home.conf"

do_install:append:8dev-basic() {
    install -m 0644 -D ${WORKDIR}/android-tools-adbd.service.d/env-home.conf \
        ${D}${sysconfdir}/systemd/system/android-tools-adbd.service.d/env-home.conf
}

FILES:${PN}-adbd:append:8dev-basic = "${sysconfdir}/systemd/system/android-tools-adbd.service.d/env-home.conf"
