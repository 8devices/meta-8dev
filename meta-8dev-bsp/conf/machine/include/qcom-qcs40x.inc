SOC_FAMILY ?= "qcs40x"
require conf/machine/include/qcom-common.inc

DEFAULTTUNE ?= "cortexa53"
include conf/machine/include/arm/armv8a/tune-cortexa53.inc

MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS += " \
    qrtr \
"
