FILESEXTRAPATHS:prepend:citron := "${THISDIR}/${PN}:"

SRC_URI:append:citron = "\
    file://0001-adb-services-fix-android_reboot.patch;patchdir=system/core \
    file://0002-linux-arm64-undefine-HAVE_ANDROID_OS.patch;patchdir=build \
"

do_install:append:citron() {
    install -d ${D}${sysconfdir}
    touch ${D}${sysconfdir}/usb-debugging-enabled
}

FILES:${PN}-adbd:append:citron = " \
    ${sysconfdir}/usb-debugging-enabled \
"
