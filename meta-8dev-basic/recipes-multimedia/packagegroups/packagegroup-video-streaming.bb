SUMMARY = "GStreamer stack for USB camera video streaming"
DESCRIPTION = "Minimal GStreamer runtime to capture from a generic USB (UVC) \
camera and stream it over the network (e.g. v4l2src ! ... ! udpsink). Kernel \
UVC support is provided separately by the cfg/8dev/uvc-camera.scc kernel feature."

LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = "\
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
"
