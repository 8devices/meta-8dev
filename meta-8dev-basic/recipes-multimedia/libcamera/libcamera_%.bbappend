FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Enable libcamerasrc (gst), off in the stock recipe. Needed to debayer the
# MIPI-CSI raw Bayer in libcamera's software ISP (sc7280 CAMSS has no HW ISP).
PACKAGECONFIG:append = " gst"
