FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append:tobufi = " \
    file://android-gadget-setup.machine \
"

do_install:append() {
    # enable adbd immediately
    touch ${D}/${sysconfdir}/usb-debugging-enabled
}
