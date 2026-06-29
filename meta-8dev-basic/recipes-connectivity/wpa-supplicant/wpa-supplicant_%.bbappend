# wpa_supplicant's install target runs per-binary `install -D` rules in parallel;
# under high -j they race creating the shared $(BINDIR), failing with "cannot
# create directory". Serialize the install step to avoid it (install is cheap).
PARALLEL_MAKEINST = ""

FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"
SRC_URI:append:8dev-basic = "\
    file://default.conf \
    file://wpa_supplicant@.service \
    file://defconfig.8dev-extra \
"

do_configure:append:8dev-basic() {
    cat ${WORKDIR}/defconfig.8dev-extra >> ${B}/wpa_supplicant/.config
}

do_install:append:8dev-basic() {
    install -d ${D}/${sysconfdir}
    install -m 0644 ${WORKDIR}/default.conf ${D}/${sysconfdir}/wpa_supplicant.conf
    install -d ${D}/${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/wpa_supplicant@.service ${D}/${systemd_system_unitdir}
}

FILES:${PN}:append:8dev-basic = "\
    ${sysconfdir}/wpa_supplicant.conf \
    ${systemd_system_unitdir}/wpa_supplicant@.service \
"
