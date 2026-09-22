SUMMARY = "Generic core tools"

inherit packagegroup

PACKAGES = "\
    packagegroup-basic-core \
    packagegroup-network-tools \
"

RDEPENDS:packagegroup-basic-core = "\
    packagegroup-network-tools \
"

RDEPENDS:packagegroup-network-tools = "\
    iproute2 \
    iproute2-bridge \
    ethtool \
"
