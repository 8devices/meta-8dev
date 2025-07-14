DESCRIPTION = "SWUpdate and related update tools"
LICENSE     = "MIT"

inherit packagegroup

RDEPENDS:${PN} = "\
    swupdate \
    swupdate-client \
"

# Swupdate (in our system) currently does not support A/B boot slot switching.
# To work around this limitation, the boot slot switch is performed manually
# using a script file included in the final SWU image. However, this
# functionality depends on an external tool to switch the boot slot. Moreover,
# we must enable it here, because building the SWU image depends on the board
# firmware build.
RDEPENDS:${PN} += "gptfdisk"
