SUMMARY = "DSP library-path mapping for the 8devices Citron boards"
DESCRIPTION = "Ships a /usr/share/qcom/conf.d entry mapping each board model to the \
QCM6490 CDSP skel search path so libcdsprpc (fastrpc) can resolve DSP_LIBRARY_PATH \
for QNN/QAIRT HTP execution. Without it the board model matches no shipped conf.d \
entry, libcdsprpc warns 'DSP_LIBRARY_PATH not found for machine', and the HTP \
backend cannot locate its hexagon-v68 skels on the CDSP."

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://8devices-citron.yaml"

# No source tree; the file unpacks straight into UNPACKDIR.
S = "${UNPACKDIR}"

inherit allarch

COMPATIBLE_MACHINE = "citron"

do_install() {
    install -d ${D}${datadir}/qcom/conf.d
    install -m 0644 ${UNPACKDIR}/8devices-citron.yaml ${D}${datadir}/qcom/conf.d/
}

FILES:${PN} = "${datadir}/qcom/conf.d/8devices-citron.yaml"
