# libiwarp needs libOpenCL, but the stock recipe only removes it when opengl is
# off. We enable opengl for gst-plugins-imsdk while leaving opencl off, so it
# survives with no provider and fails do_package_qa file-rdeps.
do_install:append:8dev-basic() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'opencl', 'false', 'true', d)}; then
        rm -f ${D}${libdir}/camx/kodiak/camera/components/libiwarp*
    fi
}
