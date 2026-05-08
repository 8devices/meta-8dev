# Hardcode linux-yocto path to ensure correct directory is
# extended when including it from different named recipes.
FILESEXTRAPATHS:prepend:tobufi := "${THISDIR}/linux-yocto:"
SRC_URI:append:tobufi = "\
    file://meta-bsp;type=kmeta;destsuffix=meta-bsp \
    file://files \
"

do_kernel_checkout:append:tobufi() {
    if [ -d ${WORKDIR}/files ]; then
        cp -r ${WORKDIR}/files/* ${S}
    fi
}

require ${THISDIR}/kernel-android.inc
