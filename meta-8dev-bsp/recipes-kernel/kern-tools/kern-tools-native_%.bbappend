# Teach the bundled kconfiglib about the 'transitional' Kconfig keyword (Linux
# 6.16+, e.g. config CFI_CLANG); without it do_kernel_configcheck aborts with
# "couldn't parse 'transitional': syntax error". Drop once kern-tools-native
# ships support. Scoped to citron: kern-tools is shared (incl. tobufi 6.6) and
# only the citron 6.18 Kconfig tree needs it.
FILESEXTRAPATHS:prepend:citron := "${THISDIR}/files:"

SRC_URI:append:citron = " file://0001-kconfiglib-accept-transitional-Kconfig-keyword.patch"
