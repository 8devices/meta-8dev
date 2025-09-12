FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"

SRC_URI:append:8dev-basic = " file://vim-alias.sh"

do_install:append:8dev-basic () {
    install -m 0644 -D ${WORKDIR}/vim-alias.sh ${D}${sysconfdir}/profile.d/vim-alias.sh
}
