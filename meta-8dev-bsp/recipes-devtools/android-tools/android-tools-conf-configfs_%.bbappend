FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append:tobufi = " \
    file://android-gadget-setup.machine \
"

do_install:append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'false', 'true', d)}; then
        rm -rf ${D}${systemd_unitdir}/system/android-tools-adbd.service.d
    fi
}
