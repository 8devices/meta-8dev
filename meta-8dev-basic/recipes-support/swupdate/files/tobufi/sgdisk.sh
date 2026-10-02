#!/bin/sh
# SWUs from before the qbootctl slot switch flip slots with sgdisk: mark the
# request for update to finish with qbootctl. Outside update nobody would
# finish it, so fail like a missing sgdisk.

[ -f /run/update-slot-request ] || { echo "sgdisk: not installed" >&2; exit 127; }
echo 1 > /run/update-slot-request
