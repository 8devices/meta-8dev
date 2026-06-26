# Already citron-only (dynamic-layers/qcom-hwe, and mergedtb is only built for
# the citron UEFI/UKI path), so tasks are unconditional. The base recipe has no
# do_deploy, so a :citron override would leave it empty on the build that needs it.
python do_compile:prepend() {
    kernel_dt_var = "KERNEL_DEVICETREE:pn-" + d.getVar('PREFERRED_PROVIDER_virtual/kernel')
    kernel_dt = d.getVar(kernel_dt_var) or ""
    filtered = " ".join(e for e in kernel_dt.split() if e.endswith('.dtb'))
    d.setVar(kernel_dt_var, filtered)
}

FILES:${PN} += "*.dtbo"

inherit deploy

do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${B}/DTOverlays/combined-dtb.dtb ${DEPLOYDIR}/
}
addtask deploy after do_compile before do_build
