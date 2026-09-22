FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"

SRC_URI:append:8dev-basic = " \
    file://vim-alias.sh \
    file://kpanic.conf \
"

# The rootfs image is sized to its contents, so a freshly written slot is far
# smaller than the partition. Growing on every boot needs no first-boot flag and
# is a no-op once the filesystem fills the slot.
do_install:append:8dev-basic () {
    install -m 0644 -D ${UNPACKDIR}/vim-alias.sh ${D}${sysconfdir}/profile.d/vim-alias.sh
    install -m 0644 -D ${UNPACKDIR}/kpanic.conf ${D}${sysconfdir}/sysctl.d/kpanic.conf

    sed -i '/^\/dev\/root[[:space:]]/ s/[[:space:]]defaults[[:space:]]/ defaults,x-systemd.growfs /' ${D}${sysconfdir}/fstab
    grep -q '^/dev/root.*x-systemd.growfs' ${D}${sysconfdir}/fstab || bbfatal "fstab root entry not found, x-systemd.growfs not applied"
}

# Hard depend, not a recommend: recommends are droppable, and growfs-root would
# then fail on every boot.
RDEPENDS:${PN}:append:8dev-basic = " e2fsprogs-resize2fs"
