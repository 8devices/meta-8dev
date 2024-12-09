SOC_FAMILY ?= "qcs40x"
include conf/machine/include/soc-family.inc

DEFAULTTUNE ?= "cortexa53"
include conf/machine/include/arm/armv8a/tune-cortexa53.inc
