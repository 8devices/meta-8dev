FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Enable libcamerasrc (gst), off in the stock recipe. Needed to debayer the
# MIPI-CSI raw Bayer in libcamera's software ISP (sc7280 CAMSS has no HW ISP).
# Scoped to the 8dev-basic distro so it doesn't alter libcamera for other distros.
PACKAGECONFIG:append:8dev-basic = " gst"
