# Citron's A/B is attribute-only: it boots from the ESP with no boot_a/boot_b or
# slot_suffix, and only dtb/efi/system carry slot attributes.
SRC_URI:append:citron = "\
    file://0002-citron-support-attribute-based-ab-slot-scheme.patch \
"

FILESEXTRAPATHS:prepend:citron := "${THISDIR}/files:"
