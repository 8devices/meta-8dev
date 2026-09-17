# 'qcom' outranks 'citron'/'robovision' in OVERRIDES, so a :citron value
# would be overwritten by meta-qcom's COMPATIBLE_MACHINE:qcom. We parse after it
# (priority 6 vs 5), so re-set the :qcom value itself.
COMPATIBLE_MACHINE:qcom = "^(citron|robovision)$"
KBRANCH:citron ?= "v6.18/standard/base"
KMACHINE:citron ?= "citron"

# This board boots the systemd-boot UKI from the ESP, not an Android boot.img.
# meta-qcom force-inherits linux-qcom-bootimg (can't be un-inherited here), whose
# do_qcom_img_deploy builds an unused boot.img and expects Image.gz, but we build
# uncompressed Image for the UKI. Nothing consumes boot.img, so disable the task.
do_qcom_img_deploy[noexec] = "1"

require recipes-kernel/linux/linux-8dev.inc
