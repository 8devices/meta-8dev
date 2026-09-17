FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# An exported dma_buf outlives the msm_vidc_buffer it came from, so the release
# path reads a stale pointer and panics on gst-launch exit. Fixed upstream in
# v1.0.22; drop this when the recipe is bumped.
SRC_URI:append:citron = " file://0001-video-driver-avoid-exported-dmabuf-release-use-after.patch"
