# Vendor drop-in rather than editing /etc/systemd/system.conf. Drop-ins from
# /etc, /run, /usr/local/lib and /usr/lib are pooled and parsed in basename
# order after the main file, last write winning -- so a field override needs a
# name sorting after "10-", or the same name to mask this file outright.
FILESEXTRAPATHS:prepend:tobufi := "${THISDIR}/systemd-conf:"

SRC_URI:append:tobufi = " file://10-watchdog.conf"

do_install:append:tobufi() {
    install -D -m0644 ${WORKDIR}/10-watchdog.conf \
        ${D}${systemd_unitdir}/system.conf.d/10-watchdog.conf
}
