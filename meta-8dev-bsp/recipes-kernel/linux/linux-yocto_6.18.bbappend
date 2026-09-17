# 'qcom' outranks 'citron'/'robovision' in OVERRIDES, so a :citron value
# would be overwritten by meta-qcom's COMPATIBLE_MACHINE:qcom. We parse after it
# (priority 6 vs 5), so re-set the :qcom value itself.
COMPATIBLE_MACHINE:qcom = "^(citron|robovision)$"
KBRANCH:citron ?= "v6.18/standard/base"
KMACHINE:citron ?= "citron"

require recipes-kernel/linux/linux-8dev.inc
