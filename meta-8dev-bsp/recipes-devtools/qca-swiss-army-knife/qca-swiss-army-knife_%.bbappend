# Distro-gated, not machine-gated: only the -native variant is ever built and
# native.bbclass empties MACHINEOVERRIDES, so a :citron gate could never fire here.
# A bbappend's own dir is not on FILESPATH, hence FILESEXTRAPATHS for the patch.
FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/${BPN}:"

SRC_URI:8dev-basic = " \
    git://github.com/qca/${BPN}.git;branch=master;protocol=https \
    file://0001-ath12k-bdencoder-increase-buffer-to-20000000.patch \
"
SRCREV:8dev-basic = "3349c9cfbd7e937578967ab0bca70b36e6534be3"

do_install:8dev-basic () {
    install -d ${D}/${bindir}
    install -m 0755 tools/scripts/*/* ${D}/${bindir}
}
