FILESEXTRAPATHS:prepend:tobufi := "${THISDIR}/${PN}:"

SRC_URI:append:tobufi = "\
    file://meta;type=kmeta;destsuffix=meta \
    file://files \
"

do_kernel_checkout:append:tobufi() {
    if [ -d ${WORKDIR}/files ]; then
        cp -r ${WORKDIR}/files/* ${S}
    fi
}
