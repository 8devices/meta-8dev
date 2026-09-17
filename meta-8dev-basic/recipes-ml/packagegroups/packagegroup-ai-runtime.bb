SUMMARY = "Qualcomm AI runtime and LiteRT inference stack"
DESCRIPTION = "On-device inference from Qualcomm prebuilts: the Qualcomm AI Runtime \
(QAIRT/QNN) with the hexagon-v68 skels for the QCS6490 NSP, LiteRT (TensorFlow \
Lite) with its CPU/XNNPACK and GPU delegates, the proprietary Adreno OpenCL \
driver both use as their GPU backend, and the GStreamer inference elements from \
gst-plugins-imsdk. Selected by the qnn distro feature. QAIRT and LiteRT execute on \
the CDSP through FastRPC, so this is normally paired with the CAMX camera stack, \
which brings the DSP firmware and FastRPC in."

LICENSE = "MIT"

inherit packagegroup features_check

# The QNN GPU backend and the LiteRT GPU delegate go through the Adreno OpenCL UMD.
REQUIRED_DISTRO_FEATURES = "qnn opengl opencl"

PACKAGEGROUP_DISABLE_COMPLEMENTARY = "1"

# citron-dsp-libconf is what lets libcdsprpc resolve DSP_LIBRARY_PATH for our
# board model.
RDEPENDS:${PN} = "\
    qairt-sdk \
    qairt-sdk-hexagon-v68 \
    citron-dsp-libconf \
"

# The LiteRT runtime lib is Debian-renamed, which an allarch packagegroup cannot
# name, so depend on the fixed-name tools package instead.
RDEPENDS:${PN} += "\
    tensorflow-lite-tools \
"

RDEPENDS:${PN} += "\
    qcom-adreno-cl \
    clinfo \
"

# The preprocessing and LiteRT elements come from gst-plugins-imsdk-oss instead,
# whose ml and tflite PACKAGECONFIGs follow the qnn distro feature.
RDEPENDS:${PN} += "\
    gst-plugins-imsdk-prop \
"
