SUMMARY = "Stack-independent GStreamer streaming runtime"
DESCRIPTION = "GStreamer core with the software H.264 encode and RTSP paths. \
Enough on its own for a USB/UVC camera; the camx and camss packagegroups add \
their MIPI-CSI stack on top."
LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = "\
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-rtsp-server \
    gstreamer1.0-rtsp-server-apps \
"

# The H.264 packages exist only under this distro: the first needs the openh264
# PACKAGECONFIG the plugins-bad append adds, the rest need LICENSE_FLAGS_ACCEPTED.
# Ungated they leave bitbake world unbuildable for every other distro.
RDEPENDS:${PN}:append:8dev-basic = " \
    gstreamer1.0-plugins-bad-openh264 \
    gstreamer1.0-libav \
    ffmpeg \
    gstreamer1.0-plugins-ugly-x264 \
"
