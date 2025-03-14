SUMMARY = "Temporary product EEPROM utility"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit update-rc.d systemd

COMPATIBLE_MACHINE = "tobufi"

SRC_URI = " \
    file://src \
    file://sys-eeprom-dump.sh \
    file://sys-eeprom.service \
    file://sys-eeprom.init \
"

S = "${WORKDIR}/src"

do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${B}/sys-eeprom ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/sys-eeprom-dump.sh ${D}/${bindir}/sys-eeprom-dump

    install -d ${D}/${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/sys-eeprom.service ${D}/${systemd_unitdir}/system

    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/sys-eeprom.init ${D}${sysconfdir}/init.d/sys-eeprom
}

RDEPENDS:${PN} = "xz"
INITSCRIPT_NAME = "sys-eeprom"
INITSCRIPT_PARAMS = "start 04 S ."
SYSTEMD_SERVICE:${PN} = "sys-eeprom.service"
