DESCRIPTION = "SWUpdate and related update tools"
LICENSE     = "MIT"

inherit packagegroup

RDEPENDS:${PN} = "\
    swupdate \
    swupdate-client \
    swupdate-progress \
"

# gptfdisk: swupdate can't switch A/B boot slots itself, so the SWU ships a
# script that does it manually via this tool.
RDEPENDS:${PN} += "gptfdisk"
