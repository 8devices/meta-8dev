# Hardcode linux-yocto path to ensure correct directory is
# extended when including it from different named recipes.
FILESEXTRAPATHS:prepend:citron := "${THISDIR}/linux-yocto-6.18:"

SRC_URI:append:citron = "\
    file://meta-bsp;type=kmeta;destsuffix=meta-bsp \
    file://files \
"

do_kernel_checkout:append:citron() {
    if [ -d ${WORKDIR}/files ]; then
        cp -r ${WORKDIR}/files/* ${S}
    fi
}
