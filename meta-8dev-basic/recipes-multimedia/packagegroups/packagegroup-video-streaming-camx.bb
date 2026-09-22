SUMMARY = "Qualcomm CAMX (Spectra) camera + GStreamer streaming stack"
DESCRIPTION = "Downstream Qualcomm CAMX camera stack for streaming over the network: \
the CAMX HAL + CHI-CDK (camxlib), the QMMF camera service (cam-server), the \
GStreamer qtiqmmfsrc source (gst-plugins-imsdk), the out-of-tree camx-dlkm kernel \
driver, the Spectra ICP camera firmware, and the CDSP/ADSP FastRPC offload path. \
Selected by CAMERA_STACK = camx, which also brings in the matching kernel feature \
and device tree overlay. On-device inference is a separate opt-in, the qnn \
distro feature."

LICENSE = "MIT"

inherit packagegroup features_check

# camxlib runs its IQ nodes on the GPU; qcom-adreno only ships -egl/-gles with glvnd.
REQUIRED_DISTRO_FEATURES = "camx opengl glvnd"

# camxlib-kodiak's -dev/-dbg are dynamically renamed, which an allarch
# packagegroup's auto-generated complementary packages cannot depend on.
PACKAGEGROUP_DISABLE_COMPLEMENTARY = "1"

# iris-video-dlkm replaces mainline Venus: it blacklists venus/vidc and supports
# UBWC, giving a zero-copy CAMX-ISP -> encode path.
RDEPENDS:${PN} = "\
    packagegroup-video-streaming-common \
    camxlib-kodiak \
    camera-service \
    camera-service-server-lib-kodiak \
    camx-dlkm \
    iris-video-dlkm \
    fastrpc \
"

# PN pulls -meta, i.e. all built plugins; the vision-AI elements only exist when
# the qnn distro feature is set.
RDEPENDS:${PN} += "\
    gst-plugins-imsdk-oss \
"

# Hard depends, not recommends: the Spectra ICP and the CDSP/ADSP do not come up
# without these, so they must not be droppable via BAD_RECOMMENDATIONS.
RDEPENDS:${PN} += "\
    camxfirmware-kodiak \
    linux-firmware-qcom-qcm6490-compute \
    linux-firmware-qcom-qcm6490-audio \
    hexagon-dsp-binaries-qcom-qcm6490-idp-cdsp \
    hexagon-dsp-binaries-qcom-qcm6490-idp-adsp \
"

# camxlib runs its IQ nodes on the GPU and imsdk allocates via EGL.
RDEPENDS:${PN} += "\
    linux-firmware-qcom-qcm6490-adreno \
    linux-firmware-qcom-adreno-a660 \
    qcom-adreno-egl \
"
