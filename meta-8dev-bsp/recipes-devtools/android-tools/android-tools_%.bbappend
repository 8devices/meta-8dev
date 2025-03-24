FILESEXTRAPATHS:prepend:tobufi := "${THISDIR}/${PN}:"
SRC_URI:append:tobufi = "\
    file://0001-adb-services-fix-android_reboot.patch;patchdir=system/core \
    file://0002-linux-arm64-undefine-HAVE_ANDROID_OS.patch;patchdir=build \
    file://android-tools-adbd.init \
"

do_install:append:tobufi() {
    install -D -p -m 0755 ${WORKDIR}/android-tools-adbd.init ${D}${sysconfdir}/init.d/android-tools-adbd
    # Auto-enable adbd
    touch ${D}/${sysconfdir}/usb-debugging-enabled
}

FILES:${PN}-adbd:append:tobufi = "\
    ${sysconfdir}/init.d/android-tools-adbd \
    ${sysconfdir}/usb-debugging-enabled \
"

# XXX: idempotent layer compatibility requries a bit more
# mangling for class inherit and INITSCRIPT_PACKAGES param
# which is not fond of override syntax.
INHERIT_8DEV = ""
INHERIT_8DEV:tobufi = "update-rc.d"
inherit ${INHERIT_8DEV}

INITSCRIPT_PACKAGES_8DEV = ""
INITSCRIPT_PACKAGES_8DEV:tobufi = "${PN}-adbd"
INITSCRIPT_PACKAGES = "${INITSCRIPT_PACKAGES_8DEV}"
INITSCRIPT_NAME:${PN}-adbd:tobufi = "android-tools-adbd"
INITSCRIPT_PARAMS:${PN}-adbd:tobufi = "defaults"
