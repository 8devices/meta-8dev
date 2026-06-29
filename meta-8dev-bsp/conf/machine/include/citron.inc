require conf/machine/include/qcom-qcs6490.inc

MACHINEOVERRIDES:prepend = "citron:"

QCOM_SELECTED_BSP = "base"

PREFERRED_PROVIDER_virtual/kernel:qcom-base-bsp = "linux-yocto"
PREFERRED_VERSION_linux-yocto:qcom-base-bsp = "6.18%"
PREFERRED_VERSION_wpa-supplicant:qcom-base-bsp = "2.10"

MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS:append = " \
    qbootctl \
"

BAD_RECOMMENDATIONS:append = " \
    kernel-module-wlan-platform \
    kernel-module-qcacld-wlan \
    kernel-module-qca6490 \
    wlan-conf \
    securedsp-example \
    modemmanager \
    networkmanager-wifi \
"

SERIAL_CONSOLES = "115200;ttyMSM0"

# Premium overrides last: meta-8dev-extras (when present) re-selects the private
# linux-8dev kernel on the qcom-base-bsp override. Included after this file's
# base-bsp defaults so the premium values win; silently skipped on basic builds
# where the layer is absent (8dev-basic keeps linux-yocto).
include conf/machine/include/citron-extras.inc
