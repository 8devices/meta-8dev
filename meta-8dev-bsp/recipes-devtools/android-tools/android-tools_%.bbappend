inherit update-rc.d

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " \
    file://0001-adb-services-fix-android_reboot.patch;patchdir=system/core \
    file://0002-linux-arm64-undefine-HAVE_ANDROID_OS.patch;patchdir=build \
    file://android-tools-adbd.init \
"

do_install:append() {
    install -D -p -m 0755 ${WORKDIR}/android-tools-adbd.init ${D}${sysconfdir}/init.d/android-tools-adbd
    # Auto-enable adbd
    touch ${D}/${sysconfdir}/usb-debugging-enabled
}

FILES:${PN}-adbd += "\
    ${sysconfdir}/init.d/android-tools-adbd \
    ${sysconfdir}/usb-debugging-enabled \
"

INITSCRIPT_PACKAGES = "${PN}-adbd"
INITSCRIPT_NAME:${PN}-adbd = "android-tools-adbd"
INITSCRIPT_PARAMS:${PN}-adbd = "defaults"
