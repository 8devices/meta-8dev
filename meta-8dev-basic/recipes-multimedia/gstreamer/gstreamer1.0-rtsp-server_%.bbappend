# test-launch turns a GStreamer pipeline into an rtsp:// mountpoint, which is how
# streaming is exercised during development. Upstream marks examples
# install:false, hence the manual install. Distro-gated so others stay stock.
EXTRA_OEMESON:remove:8dev-basic = "-Dexamples=disabled"
EXTRA_OEMESON:append:8dev-basic = " -Dexamples=enabled"

do_install:append:8dev-basic() {
    install -D -m 0755 ${B}/examples/test-launch ${D}${bindir}/test-launch
}
