SUMMARY = "Open-source (CAMSS/libcamera) video streaming stack for USB and MIPI-CSI cameras"
DESCRIPTION = "Open-source video-streaming stack: runtime to capture from a camera and stream it over the network. \
Covers: a generic USB/UVC camera (v4l2src ! ... ! udpsink, ready to use); the \
on-SoC MIPI-CSI camera via Qualcomm CAMSS, using media-ctl/v4l2-ctl for the \
media pipeline; and libcamera, whose software ISP debayers the sensor's raw \
Bayer to YUV/RGB (libcamerasrc / cam) since mainline sc7280 CAMSS has no \
hardware ISP. Selected by CAMERA_STACK = camss, which also brings in the matching \
kernel feature and device tree overlay."

LICENSE = "MIT"

inherit packagegroup features_check

REQUIRED_DISTRO_FEATURES = "camss"

RDEPENDS:${PN} = "\
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-bad-openh264 \
    gstreamer1.0-libav \
    ffmpeg \
    gstreamer1.0-rtsp-server \
    gstreamer1.0-rtsp-server-apps \
    gstreamer1.0-plugins-ugly-x264 \
    v4l-utils \
    media-ctl \
    libcamera \
    libcamera-gst \
"
