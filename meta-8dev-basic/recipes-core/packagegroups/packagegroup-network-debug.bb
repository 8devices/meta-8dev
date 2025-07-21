SUMMARY = "Network debugging tools"

PACKAGE_ARCH = "${TUNE_PKGARCH}"

inherit packagegroup

RDEPENDS:${PN} = "\
    tcpdump \
    iproute2-ss \
    iproute2-genl \
    iperf3 \
"
