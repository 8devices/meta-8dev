# The Kbuild gates the whole Spectra object set behind CAMERA_ARCH and builds
# nothing without it. citron is qcm6490 silicon.
#
# SUPPORTED_ARCH is narrowed too: the Makefile's glob target loops over every arch
# regardless, and the others use cam_sync_dma_fence and fail modpost.
EXTRA_OEMAKE:append:citron = " CAMERA_ARCH=qcm6490 SUPPORTED_ARCH=qcm6490"

# Mainline-kernel fixes for the camera_kt SMMU code: an iommu_set_fault_handler
# WARN storm on managed domains, and a boot-time "no coherency" mem-mgr init race.
FILESEXTRAPATHS:prepend:8dev-basic := "${THISDIR}/files:"
SRC_URI:append:8dev-basic = " file://0001-cam_smmu-fix-mainline-iommu-warn-and-coherency-probe-race.patch"
# The sec-heap dma_buf is put twice for one reference, which mainline's file_ref
# WARNs about at every ICP close. Take a ref for the attachment.
SRC_URI:append:8dev-basic = " file://0002-cam_smmu-fix-secheap-dma_buf-double-put.patch"
# On abnormal cam-server exit cam_mem_mgr_close() double-puts a kref already at 0,
# which is a refcount underflow/UAF on mainline. cleanup_table still frees it.
SRC_URI:append:8dev-basic = " file://0003-cam_mem_mgr-guard-krefcount-underflow-on-close.patch"
