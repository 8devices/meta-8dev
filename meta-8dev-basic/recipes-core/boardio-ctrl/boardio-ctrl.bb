SUMMARY = "Board IO controls utilities and application"
SECTION = "system"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}:${THISDIR}/files:"
SRC_URI = " \
    file://btnpoll \
    file://buttons.sh \
    file://leds.sh \
    file://board-btn.conf \
    file://board-led.conf \
"
S = "${WORKDIR}/btnpoll"

inherit pkgconfig

# board-led.conf/board-btn.conf are per-board maps, and the A53 boards would
# otherwise share one package.
PACKAGE_ARCH = "${MACHINE_ARCH}"

DEPENDS = "libevdev"

RDEPENDS:${PN} = "libevdev"

FILES:${PN} += " \
    ${bindir} \
    ${datadir} \
    ${sysconfdir} \
"

#EXTRA_OEMAKE += "\
#    CONFIG_EVENT_DEVICE=soc:gpio-keys \
#"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/btnpoll ${D}${bindir}

    install -d ${D}${datadir}/boardio
    install -m 0644 ${WORKDIR}/leds.sh ${D}${datadir}/boardio
    install -m 0644 ${WORKDIR}/buttons.sh ${D}${datadir}/boardio

    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/board-led.conf ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/board-btn.conf ${D}${sysconfdir}
}
