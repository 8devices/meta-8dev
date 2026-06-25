FILESEXTRAPATHS:prepend:tobufi := "${THISDIR}/${PN}:"
FILESEXTRAPATHS:prepend:citron := "${THISDIR}/${PN}:"

SRC_URI:append:tobufi = " \
    file://android-gadget-setup.machine \
"

# FIXME: meta-qcom-hwe ships android-gadget-setup.machine for all QCS6490
# machines (via SRC_URI:append:qcom). At equal layer priority its
# FILESEXTRAPATHS wins on collection-name ordering, so the shared filename
# resolves to Qualcomm's copy. Work around by shipping ours under a unique
# name and overwriting the installed file at end of do_install.
SRC_URI:append:citron = " \
    file://android-gadget-setup.machine \
"

do_install:append:tobufi() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'false', 'true', d)}; then
        rm -rf ${D}${systemd_unitdir}/system/android-tools-adbd.service.d
    fi
}
