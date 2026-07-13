# Build and install the test-launch example - a minimal RTSP server that turns a
# GStreamer pipeline into an rtsp:// mountpoint - for development. The recipe
# disables examples and upstream marks them install:false, so enable examples and
# install just test-launch; it lands in the ${PN}-apps package (FILES = ${bindir}).
# Scoped to the 8dev-basic distro so it doesn't alter the recipe for other distros.
EXTRA_OEMESON:remove:8dev-basic = "-Dexamples=disabled"
EXTRA_OEMESON:append:8dev-basic = " -Dexamples=enabled"

do_install:append:8dev-basic() {
    install -D -m 0755 ${B}/examples/test-launch ${D}${bindir}/test-launch
}
