# Teach the bundled kconfiglib about the 'transitional' Kconfig keyword (Linux
# 6.16+, e.g. config CFI_CLANG); without it do_kernel_configcheck aborts with
# "couldn't parse 'transitional': syntax error". Drop once kern-tools-native
# ships support.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-kconfiglib-accept-transitional-Kconfig-keyword.patch"
