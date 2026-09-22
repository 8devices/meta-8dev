FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"

# Static /etc/passwd and no DynamicUser= services. nss-systemd is kept.
PACKAGECONFIG:remove:8dev-basic = "userdb"

# None of these apply to a headless, Ethernet-only, root-only board.
PACKAGECONFIG:remove:8dev-basic = "\
    machined nss-mymachines backlight vconsole hibernate \
    quotacheck binfmt localed rfkill polkit \
"

# The leading/trailing spaces keep these separate from the qcom SRC_URI:append,
# which has none.
SRC_URI:append:8dev-basic = " \
    file://networkd-wait-online-any.conf \
    file://resolved-no-zeroconf.conf \
"

do_install:append:8dev-basic() {
    install -d ${D}${systemd_system_unitdir}/systemd-networkd-wait-online.service.d
    install -m 0644 ${UNPACKDIR}/networkd-wait-online-any.conf \
        ${D}${systemd_system_unitdir}/systemd-networkd-wait-online.service.d/10-any.conf

    install -d ${D}${systemd_unitdir}/resolved.conf.d
    install -m 0644 ${UNPACKDIR}/resolved-no-zeroconf.conf \
        ${D}${systemd_unitdir}/resolved.conf.d/10-no-zeroconf.conf
}

FILES:${PN}:append:8dev-basic = " \
    ${systemd_system_unitdir}/systemd-networkd-wait-online.service.d \
    ${systemd_unitdir}/resolved.conf.d \
"
