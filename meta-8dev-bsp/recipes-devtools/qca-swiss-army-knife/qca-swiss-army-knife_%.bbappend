
SRC_URI = " \
    git://github.com/qca/${BPN}.git;branch=master;protocol=https \
"
SRCREV = "3349c9cfbd7e937578967ab0bca70b36e6534be3"

do_install () {
    install -d ${D}/${bindir}
    install -m 0755 tools/scripts/*/* ${D}/${bindir}
}
