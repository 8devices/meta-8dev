SUMMARY = "8devices default network policy: br0 bridge over all eth*/wlan* ports"
DESCRIPTION = "systemd-networkd bridge (br0) that enslaves every wired (eth*) \
and wireless (wlan*) interface, with the DHCP client and all services bound to \
br0. Shipped on every board built under the 8dev-basic distro; board-specific \
bring-up (e.g. citron's hostapd APs) is layered in by the matching machine \
override."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI = "\
    file://10-br0.netdev \
    file://10-br0.network \
    file://10-bridge-ports.network \
"

SRC_URI:append:robovision = "\
    file://hostapd-wlan0.conf \
    file://hostapd-wlan1.conf \
    file://10-wait-bridge.conf \
"

S = "${WORKDIR}"

do_install() {
    # systemd-networkd: br0 owns DHCP; every eth*/wlan* is a bridge port. The
    # 10- prefix sorts ahead of the stock 80-wired.network so eth* join br0
    # instead of getting their own DHCP.
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/10-br0.netdev           ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${WORKDIR}/10-br0.network          ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${WORKDIR}/10-bridge-ports.network ${D}${sysconfdir}/systemd/network/
}

do_install:append:robovision() {
    # Per-radio AP configs (hostapd@wlanN reads /etc/hostapd/wlanN.conf).
    install -d ${D}${sysconfdir}/hostapd
    install -m 0644 ${WORKDIR}/hostapd-wlan0.conf ${D}${sysconfdir}/hostapd/wlan0.conf
    install -m 0644 ${WORKDIR}/hostapd-wlan1.conf ${D}${sysconfdir}/hostapd/wlan1.conf

    # Make every hostapd@ instance wait for br0 (drop-in on the template).
    install -d ${D}${systemd_system_unitdir}/hostapd@.service.d
    install -m 0644 ${WORKDIR}/10-wait-bridge.conf ${D}${systemd_system_unitdir}/hostapd@.service.d/

    # Enable hostapd@wlan0 and hostapd@wlan1 at boot (the template's
    # [Install] WantedBy=network.target).
    install -d ${D}${systemd_system_unitdir}/network.target.wants
    ln -sf ../hostapd@.service ${D}${systemd_system_unitdir}/network.target.wants/hostapd@wlan0.service
    ln -sf ../hostapd@.service ${D}${systemd_system_unitdir}/network.target.wants/hostapd@wlan1.service
}

FILES:${PN} = "\
    ${sysconfdir}/systemd/network \
"

FILES:${PN}:append:robovision = "\
    ${sysconfdir}/hostapd \
    ${systemd_system_unitdir}/hostapd@.service.d \
    ${systemd_system_unitdir}/network.target.wants \
"

# hostapd ships the binary + the hostapd@.service template we instantiate.
RDEPENDS:${PN}:append:robovision = " hostapd"
