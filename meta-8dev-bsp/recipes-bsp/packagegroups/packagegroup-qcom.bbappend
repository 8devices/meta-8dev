# No modem or DSP here, so the file-serving daemons have nothing to serve. qrtr
# stays: ath12k QMI rides that bus.
RDEPENDS:${PN}-boot-essential:remove:citron = "rmtfs tqftpserv"
