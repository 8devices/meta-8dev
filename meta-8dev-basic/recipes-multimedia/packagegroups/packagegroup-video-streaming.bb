SUMMARY = "GStreamer + V4L2 + libcamera tooling for USB and MIPI-CSI cameras"
DESCRIPTION = "Runtime to capture from a camera and stream it over the network. \
Covers: a generic USB/UVC camera (v4l2src ! ... ! udpsink, ready to use); the \
on-SoC MIPI-CSI camera via Qualcomm CAMSS, using media-ctl/v4l2-ctl for the \
media pipeline; and libcamera, whose software ISP debayers the sensor's raw \
Bayer to YUV/RGB (libcamerasrc / cam) since mainline sc7280 CAMSS has no \
hardware ISP. Kernel support is provided separately by the cfg/8dev/ \
uvc-camera.scc and cfg/8dev/qcs6490-camera.scc kernel features."

LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = "\
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    v4l-utils \
    media-ctl \
    libcamera \
    libcamera-gst \
"

# Software H.264 encoder, enabled in the plugins-bad bbappend.
RDEPENDS:${PN}:append:citron = " gstreamer1.0-plugins-bad-openh264"

# Development CPU-pipeline tooling: libav (avdec_*), ffmpeg/ffprobe CLI,
# rtsp-server, x264enc. libav/ffmpeg and x264 are commercial-flagged (citron.inc).
RDEPENDS:${PN}:append:citron = " \
    gstreamer1.0-libav \
    ffmpeg \
    gstreamer1.0-rtsp-server \
    gstreamer1.0-plugins-ugly-x264 \
"
