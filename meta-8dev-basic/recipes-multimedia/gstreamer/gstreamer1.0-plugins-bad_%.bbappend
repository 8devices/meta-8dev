# librsvg's Rust build fails on our vendor triple and nothing uses SVG overlay.
# Distro-gated so other distros stay stock.
PACKAGECONFIG:remove:8dev-basic = " rsvg"

PACKAGECONFIG:append:8dev-basic = " openh264"
