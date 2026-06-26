# The ESP only carries the UKI + systemd-boot + a DTB (~42 MB); the stock recipe
# pads the vfat to ~500 MB. Cap it at 128 MiB (131072 KiB) - ~3x headroom, far
# less wasted eMMC. Must stay <= the efi_a/efi_b partition size (synced at 131072 KiB).
ROOTFS_SIZE:citron = "131072"
IMAGE_ROOTFS_SIZE:citron = "131072"
IMAGE_ROOTFS_EXTRA_SPACE:citron = "0"
IMAGE_OVERHEAD_FACTOR:citron = "1"

# "inherit image" builds a full base-files rootfs, leaving the vfat with an FHS
# skeleton, image metadata, and a stale Type#1 boot entry that nothing reads (the
# board boots the UKI systemd-boot auto-discovers in EFI/Linux). Strip everything
# but EFI/. Mirrors upstream meta-qcom-sdk esp-qcom-image's setup_efi_folder.
setup_efi_folder() {
    if [ -d ${IMAGE_ROOTFS}/boot/EFI ]; then
        mv ${IMAGE_ROOTFS}/boot/EFI/* ${IMAGE_ROOTFS}/EFI
    fi
    find ${IMAGE_ROOTFS} -mindepth 1 ! -path "${IMAGE_ROOTFS}/EFI*" -exec rm -rf {} +
}
IMAGE_PREPROCESS_COMMAND:append:citron = " setup_efi_folder"
