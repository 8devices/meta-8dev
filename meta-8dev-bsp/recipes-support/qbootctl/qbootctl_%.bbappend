# Citron's A/B is attribute-only: it boots from the ESP with no boot_a/boot_b or
# slot_suffix, and only dtb/efi/system carry slot attributes. 0003 is a generic fix
# (update_slot_attribute() commits a gpt_disk it never read), gated here rather
# than carried for every machine.
SRC_URI:append:citron = "\
    file://0002-citron-support-attribute-based-ab-slot-scheme.patch \
    file://0003-fix-commit-of-an-uninitialised-gpt_disk.patch \
"

FILESEXTRAPATHS:prepend:citron := "${THISDIR}/files:"
