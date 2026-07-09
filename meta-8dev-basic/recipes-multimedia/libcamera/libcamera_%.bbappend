FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Enable libcamerasrc (gst), off in the stock recipe. Needed to debayer the
# MIPI-CSI raw Bayer in libcamera's software ISP (sc7280 CAMSS has no HW ISP).
PACKAGECONFIG:append = " gst"

# IMX577 sensor helper (shares the IMX477 die): analogue-gain model for the soft ISP.
SRC_URI += "file://0001-libipa-Add-IMX577-sensor-support.patch"

# Fixed AWB colour gains from tuning: sc7280 CAMSS soft-ISP stats read ~zero, so
# grey-world AWB casts.
SRC_URI += "file://0002-ipa-soft-awb-fixed-colour-gains-from-tuning.patch"

# IMX577 soft-ISP tuning: fixed black level + neutral WB gains, no AGC.
SRC_URI += "file://imx577.yaml"

do_install:append() {
    install -d ${D}${datadir}/libcamera/ipa/simple
    install -m 0644 ${WORKDIR}/imx577.yaml ${D}${datadir}/libcamera/ipa/simple/imx577.yaml
}
