SUMMARY = "Product metadata storage utility"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=901493caddf8a4e12c198b0a0431c2f9"

inherit update-rc.d systemd

COMPATIBLE_MACHINE = "tobufi"

DEPENDS += "xz"

TLVS_BRANCH ?= "master"
TLVS_URI ?= "git://github.com/8devices/tlvstore.git;protocol=https"
TLVS_REV ?= "7b4dc2763438c297f328a80cb9ed040f8475e9b0"

SRC_URI = "\
    ${TLVS_URI};branch=${TLVS_BRANCH} \
    file://eeprom-dump.sh \
    file://eeprom-dump.service \
    file://eeprom-dump.init \
"
SRC_URI:append:tobufi = "\
    file://8dev-tobufi-store \
    file://8dev-tobufi-legacy \
    file://8dev-tobufi-initial \
"
SRCREV = "${TLVS_REV}"

S = "${WORKDIR}/git"

STORAGE_FILE = "/etc/eeprom"
STORAGE_FILE:tobufi = "/sys/bus/i2c/devices/0-0056/eeprom"
STORAGE_SIZE = "8192"
STORAGE_SIZE:tobufi = ""
STORAGE_OFFSET = "0"
STORAGE_OFFSET:tobufi = "512"

EXTRA_OEMAKE += "\
    CONFIG_TLVS_FILE=${STORAGE_FILE} \
    CONFIG_TLVS_SIZE=${STORAGE_SIZE} \
    CONFIG_TLVS_OFFSET=${STORAGE_OFFSET} \
"

do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${B}/tlvs ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/eeprom-dump.sh ${D}/${bindir}/eeprom-dump

    install -d ${D}/${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/eeprom-dump.service ${D}/${systemd_unitdir}/system

    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/eeprom-dump.init ${D}${sysconfdir}/init.d/eeprom-dump
}

do_install:append:tobufi() {
    install -d ${D}${datadir}/tlvs
    install -m 0755 ${WORKDIR}/8dev-tobufi-store ${D}${datadir}/tlvs
    install -m 0755 ${WORKDIR}/8dev-tobufi-legacy ${D}${datadir}/tlvs
    install -m 0755 ${WORKDIR}/8dev-tobufi-initial ${D}${datadir}/tlvs
}

FILES:${PN} += "${datadir}"
RDEPENDS:${PN} = "liblzma"
INITSCRIPT_NAME = "eeprom-dump"
INITSCRIPT_PARAMS = "start 04 S ."
SYSTEMD_SERVICE:${PN} = "eeprom-dump.service"
