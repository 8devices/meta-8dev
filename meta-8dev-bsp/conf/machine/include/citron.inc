# Qualcomm include files form a non-conventional MACHINEOVERRIDES
# order, which makes Qualcomm BSP overrides to take a precedence
# over our prepended SOM override. Thus, we must prepend override
# before including qcom SOM include file.
MACHINEOVERRIDES =. "citron:"

require conf/machine/include/qcom-qcs6490.inc
include conf/machine/include/citron-extras.inc

QCOM_SELECTED_BSP = "base"

PREFERRED_PROVIDER_virtual/kernel:citron ?= "linux-yocto"
PREFERRED_VERSION_linux-yocto:citron ?= "6.18%"
PREFERRED_VERSION_wpa-supplicant:citron = "2.10"

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
