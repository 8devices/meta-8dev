FILESEXTRAPATHS:prepend:citron := "${THISDIR}/${PN}:"

# The qcom layer's copy wins on FILESEXTRAPATHS ties, so ship ours under a unique
# name and overwrite at the end of do_install.
SRC_URI:append:citron = " \
    file://android-gadget-setup.machine \
"
