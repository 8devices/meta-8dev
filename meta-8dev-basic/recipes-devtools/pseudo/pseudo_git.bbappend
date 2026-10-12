# Patched host tar opens through openat2(), which pseudo before 1.9.11 cannot
# track: do_package fails with "got *at() syscall for unknown directory".
# From scarthgap (YOCTO #16316); drop once poky carries it.
FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"
SRC_URI:remove:8dev-basic = "file://0001-configure-Prune-PIE-flags.patch file://glibc238.patch"
SRCREV:8dev-basic = "ba8887e5f1e922f866681ec7dec1a00b602a9328"
PV:8dev-basic = "1.9.11"
