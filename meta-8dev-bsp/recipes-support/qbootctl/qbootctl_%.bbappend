FILESEXTRAPATHS:prepend:tobufi := "${THISDIR}/files:"

SRC_URI:append:tobufi = "\
    file://0001-search-upper-case-marker.patch \
    file://0003-set-active-probe-a-partition-that-exists-when-detect.patch \
    file://0004-gpt-utils-read-and-write-the-backup-GPT-not-a-second.patch \
"
# citron uses an attribute-only A/B scheme: boots from the ESP (no
# boot_a/boot_b), no slot_suffix on cmdline, only dtb/efi/system carry slot
# attributes, eMMC is mmcblk1. This patch adapts qbootctl to it.
SRC_URI:append:citron = "\
    file://0002-citron-support-attribute-based-ab-slot-scheme.patch \
    file://0003-set-active-probe-a-partition-that-exists-when-detect.patch \
    file://0004-gpt-utils-read-and-write-the-backup-GPT-not-a-second.patch \
"

FILESEXTRAPATHS:prepend:citron := "${THISDIR}/files:"
