FILESEXTRAPATHS:prepend:tobufi := "${THISDIR}/files:"

SRC_URI:append:tobufi = " file://0001-search-upper-case-marker.patch"
# robovision uses an attribute-only A/B scheme: boots from the ESP (no
# boot_a/boot_b), no slot_suffix on cmdline, only dtb/efi/system carry slot
# attributes, eMMC is mmcblk1. This patch adapts qbootctl to it.
SRC_URI:append:robovision = "\
    file://0002-citron-support-attribute-based-ab-slot-scheme.patch \
"

FILESEXTRAPATHS:prepend:robovision := "${THISDIR}/files:"
