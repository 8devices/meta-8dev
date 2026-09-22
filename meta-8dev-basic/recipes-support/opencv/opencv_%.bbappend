# Headless, and imsdk only uses opencv core/imgproc. gtk also pulls in librsvg,
# whose Rust build fails on the "aarch64-8dev-linux-gnu" vendor triple.
PACKAGECONFIG:remove:8dev-basic = "gtk"
