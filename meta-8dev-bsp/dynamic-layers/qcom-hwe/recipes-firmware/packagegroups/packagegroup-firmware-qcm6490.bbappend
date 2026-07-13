# Headless networking board: drop base-packagegroup firmware for unused
# subsystems - DSP PAS images, Adreno, audio, compute, WCN6750/ath11k Wi-Fi
# (we use external QCN9274 over ath12k). KEPT: qupv3fw (GENI serial-engine
# firmware for our I2C/UARTs), verinfo, and linux-firmware-qcom-vpu (venus.mbn
# for the Venus HW video codec).
#
# The "-updates" entries (WCN6750, QPS615 PCIe bridge) are only RRECOMMENDED on
# qcom-custom-bsp (citron is base-bsp, so not pulled today), but the 8devices fw
# repo ships those blobs - drop them defensively in case BSP selection changes.
RRECOMMENDS:${PN}:remove:citron = " \
    hexagon-dsp-binaries-thundercomm-rb3gen2-adsp \
    hexagon-dsp-binaries-thundercomm-rb3gen2-cdsp \
    linux-firmware-qcom-adreno-a660 \
    linux-firmware-qcom-qcm6490-adreno \
    linux-firmware-qcom-qcm6490-audio \
    linux-firmware-qcom-qcm6490-compute \
    linux-firmware-ath11k-wcn6750 \
    linux-firmware-qca-wcn6750 \
    linux-firmware-qcom-qcm6490-wifi \
    linux-firmware-ath11k-wcn6750-updates \
    linux-firmware-qca-wcn6750-updates \
    linux-firmware-qcom-qcm6490-qps615-updates \
"
