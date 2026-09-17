# The ESP only carries the UKI + systemd-boot + a DTB (~42 MB); the stock recipe
# pads the vfat to ~500 MB. Cap it at 128 MiB (131072 KiB) - ~3x headroom, far
# less wasted eMMC. Must stay <= the efi_a/efi_b partition size (synced at 131072 KiB).
ROOTFS_SIZE:citron = "131072"
IMAGE_ROOTFS_SIZE:citron = "131072"
IMAGE_ROOTFS_EXTRA_SPACE:citron = "0"
IMAGE_OVERHEAD_FACTOR:citron = "1"

