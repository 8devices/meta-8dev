require conf/machine/include/qcom-qcs6490.inc
include conf/machine/include/citron-extras.inc

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
