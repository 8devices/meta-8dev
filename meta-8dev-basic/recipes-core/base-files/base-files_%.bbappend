FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"

SRC_URI:append:8dev-basic = " \
    file://vim-alias.sh \
    file://kpanic.conf \
    file://boardinfo.sh \
"

do_install:append:8dev-basic () {
    install -m 0644 -D ${WORKDIR}/vim-alias.sh ${D}${sysconfdir}/profile.d/vim-alias.sh
    install -m 0644 -D ${WORKDIR}/kpanic.conf ${D}${sysconfdir}/sysctl.d/kpanic.conf
    install -m 0755 -D ${WORKDIR}/boardinfo.sh ${D}/${bindir}/boardinfo
}
