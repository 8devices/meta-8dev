SUMMARY = "Network debugging tools"

PACKAGE_ARCH = "${TUNE_PKGARCH}"

inherit packagegroup

RDEPENDS:${PN} = "\
    ethtool \
    tcpdump \
    iperf3 \
"
