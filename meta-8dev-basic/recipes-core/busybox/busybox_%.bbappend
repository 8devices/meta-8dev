FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/${PN}:"
SRC_URI:append:8dev-basic = "\
    file://brctl.cfg \
"
