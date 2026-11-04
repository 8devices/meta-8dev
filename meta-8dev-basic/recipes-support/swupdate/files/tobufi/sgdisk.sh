#!/bin/sh
# Older SWUs switch slots with sgdisk, once per A/B partition: switch with
# qbootctl instead, whose -c reads the booted slot from the cmdline, so every
# call picks the same slot. Only under swupdate, which sets SWUPDATE_INFO_FD
# for its scripts; elsewhere fail like a missing sgdisk.

[ -n "$SWUPDATE_INFO_FD" ] || { echo "sgdisk: not installed" >&2; exit 127; }

case "$(qbootctl -c)" in
*_a) exec qbootctl -s b ;;
*_b) exec qbootctl -s a ;;
*) echo "sgdisk: cannot determine current slot" >&2; exit 1 ;;
esac
