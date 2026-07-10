# Build and install the test-launch example - a minimal RTSP server that turns a
# GStreamer pipeline into an rtsp:// mountpoint - for development. The recipe
# disables examples and upstream marks them install:false, so enable examples and
# install just test-launch; it lands in the ${PN}-apps package (FILES = ${bindir}).
EXTRA_OEMESON:remove = "-Dexamples=disabled"
EXTRA_OEMESON:append = " -Dexamples=enabled"

do_install:append() {
    install -D -m 0755 ${B}/examples/test-launch ${D}${bindir}/test-launch
}
