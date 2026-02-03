SUMMARY = "System debugging tools (lightweight)"
DESCRIPTION = "Minimal system debugging tools without gdb"

PACKAGE_ARCH = "${TUNE_PKGARCH}"

inherit packagegroup

RDEPENDS:${PN} = "\
    strace \
"
