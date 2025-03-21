SUMMARY = "8devices base image for bring-up and debugging"

LICENSE = "MIT"

IMAGE_LINGUAS = ""

COPY_LIC_MANIFEST = "0"
COPY_LIC_DIRS = "0"

CORE_IMAGE_EXTRA_INSTALL = "\
    radio-conf \
"

inherit 8dev-image
inherit core-image
