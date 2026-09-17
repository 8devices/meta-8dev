# Qualcomm include files form a non-conventional MACHINEOVERRIDES
# order, which makes Qualcomm BSP overrides to take a precedence
# over our prepended SOM override. Thus, we must prepend override
# before including qcom SOM include file.
MACHINEOVERRIDES =. "citron:"

require conf/machine/include/qcom-qcs6490.inc
include conf/machine/include/citron-extras.inc

PREFERRED_PROVIDER_virtual/kernel:citron ?= "linux-yocto"
PREFERRED_VERSION_linux-yocto:citron ?= "6.18%"

# Accept the "commercial" LICENSE_FLAGS for the patent-encumbered codecs in the
# citron camera stack (openh264, ffmpeg/libav, x264/plugins-ugly); citron-only.
LICENSE_FLAGS_ACCEPTED:append = " \
    commercial_openh264 \
    commercial_ffmpeg \
    commercial_gstreamer1.0-libav \
    commercial_x264 \
    commercial_gstreamer1.0-plugins-ugly \
"

MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS:append = " \
    qbootctl \
"

# QCS6490 SoC firmware: QUP serial engines (I2C/SPI) + Venus codec.
MACHINE_EXTRA_RRECOMMENDS:append = " \
    linux-firmware-qcom-qcm6490-qupv3fw \
    linux-firmware-qcom-vpu \
"

# At machine scope rather than in a video-streaming packagegroup: a USB camera is
# independent of CAMERA_STACK and the kernel carries uvc-camera.scc unconditionally.
MACHINE_EXTRA_RRECOMMENDS:append = " \
    kernel-module-uvcvideo \
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
