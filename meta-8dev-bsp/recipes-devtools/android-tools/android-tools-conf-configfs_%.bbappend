FILESEXTRAPATHS:prepend:citron := "${THISDIR}/${PN}:"

# FIXME: meta-qcom-hwe ships android-gadget-setup.machine for all QCS6490
# machines (via SRC_URI:append:qcom). At equal layer priority its
# FILESEXTRAPATHS wins on collection-name ordering, so the shared filename
# resolves to Qualcomm's copy. Work around by shipping ours under a unique
# name and overwriting the installed file at end of do_install.
SRC_URI:append:citron = " \
    file://android-gadget-setup.machine \
"
