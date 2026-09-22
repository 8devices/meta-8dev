# Headless video box: no text overlay, so drop the pango plugin (pulls libpango).
PACKAGECONFIG:remove:8dev-basic = " pango"
