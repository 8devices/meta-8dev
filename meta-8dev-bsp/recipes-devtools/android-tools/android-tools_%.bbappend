FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " \
    file://0001-adb-services-fix-android_reboot.patch;patchdir=system/core \
    file://0002-linux-arm64-undefine-HAVE_ANDROID_OS.patch;patchdir=build \
"
