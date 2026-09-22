# 8dev-basic drops the udev hwdb lsusb reads names from, so silence the resulting
# cosmetic warning. Distro-gated so other distros stay stock.
FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"
SRC_URI:append:8dev-basic = " file://0001-lsusb-do-not-warn-when-udev-hwdb-is-absent.patch"
