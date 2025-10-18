SUMMARY = "Radios config helper utility"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI = "\
    file://radioconf.sh \
"
SRC_URI:append:tobufi = "\
    file://radios.cfg \
"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}/${sbindir}
    install -m 0755 ${WORKDIR}/radioconf.sh ${D}/${sbindir}/radioconf

    if [ -r ${WORKDIR}/radios.cfg ]; then
        install -d ${D}/${sysconfdir}
        install -m 0644 ${WORKDIR}/radios.cfg ${D}/${sysconfdir}
    fi
}

FILES:${PN} = " \
    ${sbindir} \
    ${sysconfdir} \
"

RDEPENDS:${PN} = "hostapd wpa-supplicant iw"
