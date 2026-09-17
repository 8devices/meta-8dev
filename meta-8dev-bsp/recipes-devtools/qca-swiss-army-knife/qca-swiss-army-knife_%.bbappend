# A bbappend's own dir is not on FILESPATH, so the patch below would not be found
# at parse time (native/nativesdk variants included).
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI = " \
    git://github.com/qca/${BPN}.git;branch=master;protocol=https \
    file://0001-ath12k-bdencoder-increase-buffer-to-20000000.patch \
"
SRCREV = "3349c9cfbd7e937578967ab0bca70b36e6534be3"

do_install () {
    install -d ${D}/${bindir}
    install -m 0755 tools/scripts/*/* ${D}/${bindir}
}
