# Build only x264enc (+ ORC); override the default a52dec/mpeg2dec, which pull
# further commercial-flagged codecs we don't need. x264 flag accepted in
# citron.inc. Kept :citron (not :8dev-basic) so it doesn't alter tobufi/QCS40x.
PACKAGECONFIG:citron = "${GSTREAMER_ORC} x264"
