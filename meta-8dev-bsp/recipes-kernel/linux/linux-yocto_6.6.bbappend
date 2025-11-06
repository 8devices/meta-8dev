COMPATIBLE_MACHINE:tobufi = "^(tobufi|tobufi-dvk|robonode)$"
KBRANCH:tobufi ?= "v6.6/standard/base"
KMACHINE:tobufi ?= "tobufi"

require recipes-kernel/linux/linux-8dev.inc
