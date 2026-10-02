FILESEXTRAPATHS:prepend:tobufi := "${THISDIR}/files:"
FILESEXTRAPATHS:prepend:citron := "${THISDIR}/files:"

PACKAGECONFIG_CONFARGS:tobufi = ""
PACKAGECONFIG_CONFARGS:citron = ""

SRC_URI:append = "\
    file://0001-add-a-property-install-if-hash-different.patch \
"

SRC_URI:append:tobufi = "\
    file://swupdate.cfg \
    file://09-swupdate-args \
    file://swinfo.sh \
    file://update.sh \
    file://swchange.sh \
    file://sgdisk.sh \
"

SRC_URI:append:citron = "\
    file://swupdate.cfg \
    file://09-swupdate-args \
    file://swinfo.sh \
    file://update.sh \
    file://swchange.sh \
"

do_install:append:tobufi() {
    install -m 0644 ${WORKDIR}/09-swupdate-args ${D}${libdir}/swupdate/conf.d/
    sed -i -e "s#@MACHINE@#${MACHINE}#g" -e "s#@LIBDIR@#${libdir}#g" ${D}${libdir}/swupdate/conf.d/09-swupdate-args
    install -D -m 755 ${WORKDIR}/sgdisk.sh ${D}${libdir}/swupdate/compat/sgdisk

    install -d ${D}${sysconfdir}
    install -m 644 ${WORKDIR}/swupdate.cfg ${D}${sysconfdir}

    install -d ${D}${bindir}
    install -m 755 ${WORKDIR}/swinfo.sh ${D}${bindir}/swinfo
    install -m 755 ${WORKDIR}/update.sh ${D}${bindir}/update
    install -m 755 ${WORKDIR}/swchange.sh ${D}${bindir}/swchange
}

do_install:append:citron() {
    install -m 0644 ${WORKDIR}/09-swupdate-args ${D}${libdir}/swupdate/conf.d/
    sed -i "s#@MACHINE@#${MACHINE}#g" ${D}${libdir}/swupdate/conf.d/09-swupdate-args

    install -d ${D}${sysconfdir}
    install -m 644 ${WORKDIR}/swupdate.cfg ${D}${sysconfdir}

    install -d ${D}${bindir}
    install -m 755 ${WORKDIR}/swinfo.sh ${D}${bindir}/swinfo
    install -m 755 ${WORKDIR}/update.sh ${D}${bindir}/update
    install -m 755 ${WORKDIR}/swchange.sh ${D}${bindir}/swchange
}

RDEPENDS:${PN}:append:tobufi = " swupdate-client swupdate-progress qbootctl"
RDEPENDS:${PN}:append:citron = " swupdate-client swupdate-progress qbootctl"
