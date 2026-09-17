# MACHINEOVERRIDES already carries citron; the include only prepends qcom/qcm6490.
require conf/machine/include/qcom-qcs6490.inc

PREFERRED_PROVIDER_virtual/kernel:citron ?= "linux-yocto"
PREFERRED_VERSION_linux-yocto:citron ?= "6.18%"

MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS:append = " \
    qbootctl \
    tlvstore \
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

# urm owns the runtime tuning the camera pipeline depends on (cpusets, THP, uclamp,
# IRQ affinity). -extensions owns /etc/urm/target, without which no qcm6490 policy
# runs; urm reads its target from /sys/devices/soc0/machine, hence
# patches/qcom-socinfo-add-qcs6490-soc-id.patch.
MACHINE_EXTRA_RRECOMMENDS:append = " \
    userspace-resource-manager \
    userspace-resource-manager-extensions \
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

# qairt-sdk recommends every HTP skel variant; only v68 matches QCS6490.
BAD_RECOMMENDATIONS:append = " \
    qairt-sdk-hexagon-v66 \
    qairt-sdk-hexagon-v73 \
    qairt-sdk-hexagon-v75 \
"

SERIAL_CONSOLES = "115200;ttyMSM0"
