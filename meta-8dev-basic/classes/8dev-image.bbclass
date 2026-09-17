# Common 8devices class for generating reference images
#
# Copyright (C) 2025 8devices, UAB
#
# SPDX-License-Identifier: Apache-2.0

# FEATURE_PACKAGES_camera comes from the selected camera-stack-*.inc.
FEATURE_PACKAGES_system-debug = "packagegroup-system-debug"
FEATURE_PACKAGES_network-debug = "packagegroup-network-debug"
FEATURE_PACKAGES_update-tools = "packagegroup-update-tools"
FEATURE_PACKAGES_qnn = "packagegroup-ai-runtime"

IMAGE_FEATURES:append = " ${@bb.utils.contains_any('DISTRO_FEATURES', 'camx camss', 'camera', '', d)}"
IMAGE_FEATURES:append = " ${@bb.utils.contains('DISTRO_FEATURES', 'qnn', 'qnn', '', d)}"

CORE_IMAGE_EXTRA_INSTALL:append = " board-conf radio-conf"

# citron boots the UKI from the ESP, so the /boot copy packagegroup-core-boot
# drags in is dead weight. Leaves /boot as an empty mount point.
empty_boot () {
    find ${IMAGE_ROOTFS}/boot -mindepth 1 -delete
}
ROOTFS_POSTPROCESS_COMMAND:append:citron = " empty_boot;"
