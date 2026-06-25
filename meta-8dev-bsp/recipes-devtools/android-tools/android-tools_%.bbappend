FILESEXTRAPATHS:prepend:tobufi := "${THISDIR}/${PN}:"
FILESEXTRAPATHS:prepend:citron := "${THISDIR}/${PN}:"

SRC_URI:append:tobufi = "\
    file://0001-adb-services-fix-android_reboot.patch;patchdir=system/core \
    file://0002-linux-arm64-undefine-HAVE_ANDROID_OS.patch;patchdir=build \
    file://android-tools-adbd.init \
"

SRC_URI:append:citron = "\
    file://0001-adb-services-fix-android_reboot.patch;patchdir=system/core \
    file://0002-linux-arm64-undefine-HAVE_ANDROID_OS.patch;patchdir=build \
"

do_install:append:tobufi() {
    install -D -p -m 0755 ${WORKDIR}/android-tools-adbd.init ${D}${sysconfdir}/init.d/android-tools-adbd
    # Auto-enable adbd
    touch ${D}/${sysconfdir}/usb-debugging-enabled
}

do_install:append:citron() {
    install -d ${D}${sysconfdir}
    touch ${D}${sysconfdir}/usb-debugging-enabled
}

FILES:${PN}-adbd:append:tobufi = "\
    ${sysconfdir}/init.d/android-tools-adbd \
    ${sysconfdir}/usb-debugging-enabled \
"

FILES:${PN}-adbd:append:citron = " \
    ${sysconfdir}/usb-debugging-enabled \
"

# XXX: class inherit and INITSCRIPT_PACKAGES don't take override syntax,
# so route them through intermediate :tobufi vars.
INHERIT_8DEV = ""
INHERIT_8DEV:tobufi = "update-rc.d"
inherit ${INHERIT_8DEV}

INITSCRIPT_PACKAGES_8DEV = ""
INITSCRIPT_PACKAGES_8DEV:tobufi = "${PN}-adbd"
INITSCRIPT_PACKAGES = "${INITSCRIPT_PACKAGES_8DEV}"
INITSCRIPT_NAME:${PN}-adbd:tobufi = "android-tools-adbd"
INITSCRIPT_PARAMS:${PN}-adbd:tobufi = "defaults"
