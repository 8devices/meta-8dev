# Produce a multi-DTB boot-${MACHINE}.img. linux-qcom-bootimg symlinks
# boot-${MACHINE}.img to the first KERNEL_DEVICETREE entry, which is the wrong
# DTB on boards with revision variants. Concatenate all DTBs after the kernel so
# the Qualcomm ABL selects the correct one at runtime via qcom,board-id.

python do_qcom_img_deploy:append:tobufi() {
    import shutil, subprocess

    deploy_dir = d.getVar("QIMG_DEPLOYDIR")
    B = d.getVar("B")
    D = d.getVar("D")
    kernel_output_dir = d.getVar("KERNEL_OUTPUT_DIR")
    kernel_dtbdest = d.getVar("KERNEL_DTBDEST")
    mkbootimg = os.path.join(d.getVar("STAGING_BINDIR_NATIVE"), "skales", "mkbootimg")
    machine = d.getVar("MACHINE")

    # Image.gz + all DTBs concatenated — ABL selects via qcom,board-id
    kernel_multi = os.path.join(B, "kernel-multi-dtb")
    with open(kernel_multi, 'wb') as out:
        with open(os.path.join(kernel_output_dir, "Image.gz"), 'rb') as f:
            shutil.copyfileobj(f, out)
        for dtbf in d.getVar("KERNEL_DEVICETREE").split():
            with open(os.path.join(D, kernel_dtbdest, os.path.basename(dtbf)), 'rb') as f:
                shutil.copyfileobj(f, out)

    consoles = ' '.join(
        "console=%(tty)s,%(rate)sn8" % dict(zip(("rate", "tty"), c.split(';')))
        for c in (d.getVar("SERIAL_CONSOLES") or "").split()
    )

    multi_img = os.path.join(deploy_dir, "boot-%s.img" % machine)
    if os.path.lexists(multi_img):
        os.unlink(multi_img)
    subprocess.check_call([mkbootimg,
        "--kernel", kernel_multi,
        "--ramdisk", "/dev/null",
        "--output", multi_img,
        "--pagesize", d.getVar("QCOM_BOOTIMG_PAGE_SIZE"),
        "--base", d.getVar("QCOM_BOOTIMG_KERNEL_BASE"),
        "--cmdline", "noinitrd rw rootwait %s %s" % (
            consoles, d.getVar("KERNEL_CMDLINE_EXTRA") or "")])

    boot_img = os.path.join(deploy_dir, "boot.img")
    if os.path.lexists(boot_img):
        os.unlink(boot_img)
    os.symlink("boot-%s.img" % machine, boot_img)
}

do_qcom_img_deploy[vardeps] += "SERIAL_CONSOLES KERNEL_DEVICETREE MACHINE"
