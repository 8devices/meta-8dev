# Qualcomm include files form a non-conventional MACHINEOVERRIDES
# order, which makes Qualcomm BSP overrides to take a precedence
# over our prepended SOM override. Thus, we must prepend override
# before including qcom SOM include file.
MACHINEOVERRIDES =. "citron:"

require conf/machine/include/qcom-qcs6490.inc
include conf/machine/include/citron-extras.inc

MACHINEOVERRIDES .= ":emmc-storage"

QCOM_SELECTED_BSP = "base"

EFI_UKI_ADD_CMDLINE = "True"

PREFERRED_PROVIDER_virtual/kernel:citron ?= "linux-yocto"
PREFERRED_VERSION_linux-yocto:citron ?= "6.18%"
PREFERRED_VERSION_wpa-supplicant:citron = "2.10"
PREFERRED_VERSION_hostapd:citron = "2.10"

# Use libcamera 0.7.1 (meta-8dev-basic) over the meta-multimedia 0.4.0 default,
# for its colour-temperature AWB + CCM soft ISP. The recipe sets
# DEFAULT_PREFERENCE="-1", so this override selects it. Kept :citron (not the
# 8dev-basic distro) so tobufi/QCS40x stays on the meta-multimedia 0.4.0.
PREFERRED_VERSION_libcamera:citron = "0.7.1"

# Accept the "commercial" LICENSE_FLAGS for the patent-encumbered codecs in the
# citron camera stack (openh264, ffmpeg/libav, x264/plugins-ugly); citron-only.
LICENSE_FLAGS_ACCEPTED:append = " commercial_openh264 commercial_ffmpeg commercial_gstreamer1.0-libav commercial_x264 commercial_gstreamer1.0-plugins-ugly"

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
