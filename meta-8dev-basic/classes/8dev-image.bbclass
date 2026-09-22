# Common 8devices class for generating reference images
#
# Copyright (C) 2025 8devices, UAB
#
# SPDX-License-Identifier: Apache-2.0

# List of 8devices advertised/supported IMAGE_FEATURES
#
# - system-debug        - lightweight system debugging tools (strace, no gdb)
#
FEATURE_PACKAGES_system-debug = "packagegroup-system-debug"
#
# - network-debug       - network debugging tools
#
FEATURE_PACKAGES_network-debug = "packagegroup-network-debug"
#
# - update-tools        - update & related tools
#
FEATURE_PACKAGES_update-tools = "packagegroup-update-tools"
#
# - qnn                 - Qualcomm ML compute stack
#
FEATURE_PACKAGES_qnn = "packagegroup-ai-runtime"

IMAGE_FEATURES:append = " ${@bb.utils.contains_any('DISTRO_FEATURES', 'camx camss', 'camera', '', d)}"
IMAGE_FEATURES:append = " ${@bb.utils.contains('DISTRO_FEATURES', 'qnn', 'qnn', '', d)}"

IMAGE_INSTALL:append = " board-conf radio-conf"

# citron boots the UKI from the ESP, so the /boot copy packagegroup-core-boot
# drags in is dead weight. Leaves /boot as an empty mount point.
empty_boot () {
    find ${IMAGE_ROOTFS}/boot -mindepth 1 -delete
}
ROOTFS_POSTPROCESS_COMMAND:append:citron = " empty_boot;"
