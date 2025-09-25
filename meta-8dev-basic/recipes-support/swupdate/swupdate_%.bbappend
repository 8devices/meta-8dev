FILESEXTRAPATHS:prepend:tobufi := "${THISDIR}/files:"

PACKAGECONFIG_CONFARGS:tobufi = ""

SRC_URI:append:tobufi = "\
    file://swupdate.cfg \
    file://09-swupdate-args \
    file://swinfo.sh \
"

do_install:append:tobufi() {
    install -m 0644 ${WORKDIR}/09-swupdate-args ${D}${libdir}/swupdate/conf.d/
    sed -i "s#@MACHINE@#${MACHINE}#g" ${D}${libdir}/swupdate/conf.d/09-swupdate-args

    install -d ${D}${sysconfdir}
    install -m 644 ${WORKDIR}/swupdate.cfg ${D}${sysconfdir}

    install -d ${D}${bindir}
    install -m 755 ${WORKDIR}/swinfo.sh ${D}${bindir}/swinfo
}
