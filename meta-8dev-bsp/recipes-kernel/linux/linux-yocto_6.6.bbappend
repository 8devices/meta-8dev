# :qcs40x outranks meta-qcom's COMPATIBLE_MACHINE:qcom
COMPATIBLE_MACHINE:qcs40x = "^(tobufi|tobufi-dvk|robonode)$"
KBRANCH:tobufi ?= "v6.6/standard/base"
KMACHINE:tobufi ?= "tobufi"

# Prevent upstream features/netfilter/netfilter.scc from being included
KERNEL_EXTRA_FEATURES:tobufi = ""

require recipes-kernel/linux/linux-8dev.inc
