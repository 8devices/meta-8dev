COMPATIBLE_MACHINE:tobufi = "^(tobufi|tobufi-dvk|robonode)$"
KBRANCH:tobufi ?= "v6.6/standard/base"
KMACHINE:tobufi ?= "tobufi"

# Tobufi default features
KERNEL_FEATURES:append:tobufi = "\
    cfg/fs/ext4.scc \
    cfg/fs/vfat.scc \
    cfg/8dev/systemd.scc \
    cfg/8dev/squashfs.scc \
"

require recipes-kernel/linux/linux-8dev.inc
