SUMMARY = "Firmware images flashing tools"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit deploy

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "\
    ${@bb.utils.contains('MACHINE_FEATURES', 'fastboot', 'file://fastboot_flash.py', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'fastboot', 'file://fastboot.json', '', d)} \
"

do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"

do_deploy () {
    if ${@bb.utils.contains('MACHINE_FEATURES', 'fastboot', 'true', 'false', d)}; then
        install -m 0755 ${WORKDIR}/fastboot_flash.py ${DEPLOYDIR}
        install -m 0755 ${WORKDIR}/fastboot.json ${DEPLOYDIR}
    fi
}
addtask deploy after do_install
