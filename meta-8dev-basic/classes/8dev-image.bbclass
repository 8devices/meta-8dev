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

CORE_IMAGE_EXTRA_INSTALL:append = " board-conf radio-conf"
