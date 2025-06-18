SUMMARY = "A port of the Qualcomm Android bootctrl HAL for musl/glibc userspace"
HOMEPAGE = "https://gitlab.com/sdm845-mainline/qbootctl"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=7475d4a045b602c247a1b641ad13d139"

SRCREV = "39a6e6daaf029fb0a083777679a15ea2c18f72de"
SRC_URI = "git://github.com/linux-msm/qbootctl.git;protocol=https;branch=main \
           file://qbootctl-bless-boot.init \
           file://qbootctl-bless-boot.service.in \
           "

S = "${WORKDIR}/git"

PV = "0.2.2"

inherit meson update-rc.d systemd

do_install:append () {
    if ${@bb.utils.contains('DISTRO_FEATURES','sysvinit','true','false',d)}; then
        install -d ${D}${sysconfdir}/init.d
        install -m 0755 ${WORKDIR}/qbootctl-bless-boot.init ${D}${sysconfdir}/init.d/qbootctl-bless-boot
    fi

    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${systemd_system_unitdir}
        install -m 0644 ${WORKDIR}/qbootctl-bless-boot.service.in ${D}${systemd_system_unitdir}/qbootctl-bless-boot.service
        sed -i -e 's:@bindir@:${bindir}:g' ${D}${systemd_system_unitdir}/qbootctl-bless-boot.service
    fi
}

INITSCRIPT_NAME = "qbootctl-bless-boot"
INITSCRIPT_PARAMS = "start 99 S ."
SYSTEMD_SERVICE:${PN} = "qbootctl-bless-boot.service"
