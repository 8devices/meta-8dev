SUMMARY = "Product metadata storage utility"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=901493caddf8a4e12c198b0a0431c2f9"

inherit update-rc.d systemd

COMPATIBLE_MACHINE = "tobufi"

DEPENDS += "xz"

TLVS_BRANCH ?= "master"
TLVS_URI ?= "https://github.com/8devices/tlvstore.git"
TLVS_REV ?= "${AUTOREV}"

SRC_URI = "\
    ${TLVS_URI};branch=${TLVS_BRANCH} \
    file://eeprom-dump.sh \
    file://eeprom-dump.service \
    file://eeprom-dump.init \
"
SRC_URI:append:tobufi = "\
    file://eeprom-store \
    file://eeprom-legacy \
"
SRCREV = "${TLVS_REV}"

S = "${WORKDIR}/git"

STORAGE_FILE = "/etc/eeprom"
STORAGE_FILE:tobufi = "/sys/bus/i2c/devices/0-0056/eeprom"
STORAGE_SIZE = "8192"
STORAGE_SIZE:tobufi = ""

EXTRA_OEMAKE += "\
    CONFIG_TLVS_FILE=${STORAGE_FILE} \
    CONFIG_TLVS_SIZE=${STORAGE_SIZE} \
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
    install -m 0755 ${WORKDIR}/eeprom-store ${D}${datadir}/tlvs
    install -m 0755 ${WORKDIR}/eeprom-legacy ${D}${datadir}/tlvs
}

FILES:${PN} += "${datadir}"
RDEPENDS:${PN} = "liblzma"
INITSCRIPT_NAME = "eeprom-dump"
INITSCRIPT_PARAMS = "start 04 S ."
SYSTEMD_SERVICE:${PN} = "eeprom-dump.service"
