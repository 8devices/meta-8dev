SUMMARY = "8devices multimedia packagegroups"
DESCRIPTION = "Package groups to bring in packages required \
to enable multimedia support"

LICENSE = "BSD-3-Clause-Clear"

PACKAGE_ARCH = "${TUNE_PKGARCH}"

inherit packagegroup

PROVIDES = "${PACKAGES}"

PACKAGES = "\
    ${PN} \
    ${PN}-streaming \
"

RDEPENDS:${PN} = "\
    ${PN}-streaming \
"

RDEPENDS:${PN}-streaming = "\
    libcamera \
    libcamera-gst \
    v4l-utils \
    media-ctl \
    yavta \
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-rtsp-server \
"
