# A bbappend's own dir is not on FILESPATH by default, so the local patch below
# would be "could not be found" at parse (incl. native/nativesdk variants).
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
