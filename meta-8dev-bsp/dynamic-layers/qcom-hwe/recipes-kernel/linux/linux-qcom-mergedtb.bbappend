# citron-only (dynamic-layers/qcom-hwe; mergedtb is built only for the citron
# UEFI/UKI path). We don't use tech DTBOs yet and only need the single combined
# DTB, so replace the base recipe's DTBO-merging do_compile with a plain
# concatenation of the machine's device trees.
python do_compile() {
    import os, shutil

    dtoverlaydir = os.path.join(d.getVar('B'), 'DTOverlays')
    os.makedirs(dtoverlaydir, exist_ok=True)

    deploy = d.getVar('DEPLOY_DIR_IMAGE')
    dtbs = [dt for dt in (d.getVar('KERNEL_DEVICETREE') or "").split()
            if dt.endswith('.dtb')]
    if not dtbs:
        bb.fatal("linux-qcom-mergedtb: KERNEL_DEVICETREE lists no .dtb files")

    # Concatenate the base DTB(s) into the single combined image the UEFI/UKI
    # path consumes. No overlays are applied.
    combined = os.path.join(dtoverlaydir, "combined-dtb.dtb")
    with open(combined, "wb") as fout:
        for dt in dtbs:
            src = os.path.join(deploy, os.path.basename(dt))
            with open(src, "rb") as fin:
                shutil.copyfileobj(fin, fout)
}

inherit deploy

do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${B}/DTOverlays/combined-dtb.dtb ${DEPLOYDIR}/
}
addtask deploy after do_compile before do_build
