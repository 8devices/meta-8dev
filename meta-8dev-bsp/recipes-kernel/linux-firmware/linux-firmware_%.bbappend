FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append:tobufi = "\
    file://WCN3990 \
"

do_install:append:tobufi() {
    install -m 0644 ${WORKDIR}/WCN3990/qdsp6sw.mbn ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0
}
