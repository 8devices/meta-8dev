# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 8devices UAB
#

AIMAGE_BASEADDR ?= "0x10000000"
AIMAGE_PAGESIZE ?= "2048"
AIMAGE_CMDLINE ?= ""

python () {
    if "aImage.gz" in d.getVar("KERNEL_IMAGETYPES"):
        depends = d.getVar("DEPENDS")
        depends = "%s android-tools-native" % depends
        d.setVar("DEPENDS", depends)

        typeformake = d.getVar("KERNEL_IMAGETYPE_FOR_MAKE")
        if "aImage.gz" in typeformake.split():
            d.setVar("KERNEL_IMAGETYPE_FOR_MAKE", typeformake.replace("aImage.gz", "Image.gz"))

        bb.build.addtask("do_android_bootimg", "do_install", "do_kernel_link_images", d)
}

do_android_bootimg[dirs] += "${B}"
do_android_bootimg() {
        cat arch/${ARCH}/boot/Image.gz > linux.bin

        for dtb in ${KERNEL_DEVICETREE}; do
                cat arch/${ARCH}/boot/dts/${dtb} >> linux.bin
        done

        mkbootimg \
            --kernel linux.bin \
            --ramdisk /dev/null \
            --ramdisk_offset 0 \
            --base ${AIMAGE_BASEADDR} \
            --pagesize ${AIMAGE_PAGESIZE} \
            --cmdline "${AIMAGE_CMDLINE}" \
            --output arch/${ARCH}/boot/aImage.gz
        rm -f linux.bin
}
