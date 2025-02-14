SUMMARY = "A set of utilities to help QCA driver development."
HOMEPAGE = "https://github.com/qca/qca-swiss-army-knife"
SECTION = "devel"

LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://LICENSE;md5=884c3f3a874b2a0cfa283c7db0e5d604"

PV = "0.0+${SRCPV}"

SRC_URI = "\
    git://github.com/qca/${BPN}.git;branch=master;protocol=https \
"
SRCREV = "583eed7e66c661fe240189dd21c8f1eeb666c576"

S = "${WORKDIR}/git"

do_install () {
    install -d ${D}/${bindir}
    install -m 0755 tools/scripts/*/* ${D}/${bindir}
}

RDEPENDS:${PN} += "python3-core"

BBCLASSEXTEND = "native nativesdk"
