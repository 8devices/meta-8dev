PACKAGECONFIG:remove = " rsvg"

# openh264 software H.264 encoder; commercial-flagged (accepted in citron.inc).
# Kept :citron (not :8dev-basic) so the codec build stays off tobufi/QCS40x.
PACKAGECONFIG:append:citron = " openh264"
