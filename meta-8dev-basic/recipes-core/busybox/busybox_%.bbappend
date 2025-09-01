FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/${PN}:"
SRC_URI:append:8dev-basic = "\
    file://no-ip-support.cfg \
    file://legacy-networking.cfg \
    file://shell-debugging.cfg \
"
