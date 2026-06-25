# Strip rootfs-only and custom 8dev features from the ESP/DTB sub-images, which
# don't inherit them and would otherwise fail with "not a valid image feature".
# Keep in sync with EXTRA_IMAGE_FEATURES in 8dev-basic.conf.
FEATURES_EXCLUDE_LIST = "\
    ssh-server-openssh \
    tools-debug \
    network-debug \
    update-tools \
    system-debug \
    video-streaming \
"

EXTRA_IMAGE_FEATURES:remove:pn-esp-qcom-image = "${FEATURES_EXCLUDE_LIST}"
EXTRA_IMAGE_FEATURES:remove:pn-dtb-qcom-image = "${FEATURES_EXCLUDE_LIST}"
EXTRA_IMAGE_FEATURES:remove:pn-dtb-el2-qcom-image = "${FEATURES_EXCLUDE_LIST}"
