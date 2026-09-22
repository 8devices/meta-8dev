SUMMARY = "Board IO controls utilities and application"
SECTION = "system"
LICENSE = "CLOSED"

# Only for the btnpoll/ subdir: prepending files/ would rank it above
# files/<machine>/ and shadow the per-board overrides.
FILESEXTRAPATHS:prepend := "${THISDIR}:"
SRC_URI = " \
    file://btnpoll \
    file://buttons.sh \
    file://leds.sh \
    file://board-btn.conf \
    file://board-led.conf \
"
S = "${UNPACKDIR}/btnpoll"

inherit pkgconfig

DEPENDS = "libevdev"

RDEPENDS:${PN} = "libevdev"

FILES:${PN} += " \
    ${bindir} \
    ${datadir} \
    ${sysconfdir} \
"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/btnpoll ${D}${bindir}

    install -d ${D}${datadir}/boardio
    install -m 0644 ${UNPACKDIR}/leds.sh ${D}${datadir}/boardio
    install -m 0644 ${UNPACKDIR}/buttons.sh ${D}${datadir}/boardio

    install -d ${D}${sysconfdir}
    install -m 0644 ${UNPACKDIR}/board-led.conf ${D}${sysconfdir}
    install -m 0644 ${UNPACKDIR}/board-btn.conf ${D}${sysconfdir}
}
