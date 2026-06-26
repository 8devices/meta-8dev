# systemd trimming below is 8dev-basic policy for headless/Ethernet-only boards.
# Scoped to :8dev-basic so other distros are untouched.
FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"

# meta-qcom-hwe adds "gnu-efi" to PACKAGECONFIG, but that key no longer exists in
# systemd 255 and trips a QA warning. Drop it; "efi" alone keeps systemd-boot/UKI.
PACKAGECONFIG:remove:8dev-basic = "gnu-efi"

# Drop userdbd: static /etc/passwd, no DynamicUser= services. nss-systemd kept.
PACKAGECONFIG:remove:8dev-basic = "userdb"

# Trim unused systemd components from this headless board (drops binaries+units):
#   machined/nss-mymachines (containers), backlight, vconsole (no VT), hibernate,
#   quotacheck, binfmt, localed, rfkill (Ethernet-only), polkit (root-only),
#   (debug; drop for production).
PACKAGECONFIG:remove:8dev-basic = "\
    machined nss-mymachines backlight vconsole hibernate \
    quotacheck binfmt localed rfkill polkit \
"

# networkd-wait-online --any drop-in and a resolved drop-in disabling LLMNR/mDNS
# (see the .conf files for rationale).
#
# Leading + trailing spaces keep these URIs separate from meta-qcom-hwe's
# `SRC_URI:append:qcom` (no leading space), which is concatenated at finalization.
SRC_URI:append:8dev-basic = " \
    file://networkd-wait-online-any.conf \
    file://resolved-no-zeroconf.conf \
"

do_install:append:8dev-basic() {
    install -d ${D}${systemd_system_unitdir}/systemd-networkd-wait-online.service.d
    install -m 0644 ${WORKDIR}/networkd-wait-online-any.conf \
        ${D}${systemd_system_unitdir}/systemd-networkd-wait-online.service.d/10-any.conf

    install -d ${D}${systemd_unitdir}/resolved.conf.d
    install -m 0644 ${WORKDIR}/resolved-no-zeroconf.conf \
        ${D}${systemd_unitdir}/resolved.conf.d/10-no-zeroconf.conf
}

FILES:${PN}:append:8dev-basic = " \
    ${systemd_system_unitdir}/systemd-networkd-wait-online.service.d \
    ${systemd_unitdir}/resolved.conf.d \
"
