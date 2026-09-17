SUMMARY = "Product metadata storage utility"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=901493caddf8a4e12c198b0a0431c2f9"

inherit update-rc.d systemd

COMPATIBLE_MACHINE = "citron"

DEPENDS += "xz"

TLVS_BRANCH ?= "master"
TLVS_URI ?= "git://github.com/8devices/tlvstore.git;protocol=https"
TLVS_REV ?= "ad919ee81ad2aa0d09f623ae72687fdbe8ce1422"

SRC_URI = "\
    ${TLVS_URI};branch=${TLVS_BRANCH} \
    file://eeprom-dump.sh \
    file://eeprom-dump.service \
    file://eeprom-dump.init \
"
SRC_URI:append:citron = "\
    file://8dev-citron-store \
"
SRCREV = "${TLVS_REV}"

STORAGE_FILE = "/etc/eeprom"
STORAGE_FILE:citron = "/dev/disk/by-partlabel/tlvstore"
STORAGE_SIZE = "8192"
STORAGE_SIZE:citron = ""
STORAGE_OFFSET = "0"

EXTRA_OEMAKE += "\
    CONFIG_TLVS_FILE=${STORAGE_FILE} \
    CONFIG_TLVS_SIZE=${STORAGE_SIZE} \
    CONFIG_TLVS_OFFSET=${STORAGE_OFFSET} \
"

do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${B}/tlvs ${D}/${bindir}/
    install -m 0755 ${UNPACKDIR}/eeprom-dump.sh ${D}/${bindir}/eeprom-dump

    install -d ${D}/${systemd_unitdir}/system
    install -m 0644 ${UNPACKDIR}/eeprom-dump.service ${D}/${systemd_unitdir}/system

    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${UNPACKDIR}/eeprom-dump.init ${D}${sysconfdir}/init.d/eeprom-dump
}

do_install:append:citron() {
    install -d ${D}${datadir}/tlvs
    install -m 0644 ${UNPACKDIR}/8dev-citron-store ${D}${datadir}/tlvs
}

FILES:${PN} += "${datadir}"
RDEPENDS:${PN} = "liblzma"
INITSCRIPT_NAME = "eeprom-dump"
INITSCRIPT_PARAMS = "start 04 S ."
SYSTEMD_SERVICE:${PN} = "eeprom-dump.service"
