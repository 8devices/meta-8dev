DEPENDS += "qca-swiss-army-knife-native"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append:tobufi = "\
    file://WCN3990 \
"

do_compile:append:tobufi() {
     (cd ${WORKDIR}/WCN3990; ath10k-bdencoder -c board-2.json -o board-2.bin)
}

do_install:append:tobufi() {
    install -m 0644 ${WORKDIR}/WCN3990/qdsp6sw.mbn ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0
    install -m 0644 ${WORKDIR}/WCN3990/board-2.bin ${D}${nonarch_base_libdir}/firmware/ath10k/WCN3990/hw1.0
}
