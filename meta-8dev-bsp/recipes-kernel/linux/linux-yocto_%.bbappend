FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://meta;type=kmeta;destsuffix=meta \
    file://files \
"

do_kernel_checkout:append() {
        if [ -d ${WORKDIR}/files ]; then
                cp -r ${WORKDIR}/files/* ${S}
        fi
}
