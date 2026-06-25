#!/bin/sh

set -e

QBOOTCTL=/usr/bin/qbootctl

if [ ! -x "$QBOOTCTL" ]; then
	echo "change_boot_slot: $QBOOTCTL not found or not executable" >&2
	exit 1
fi

current=$("$QBOOTCTL" -c | awk '{print $NF}' | tr -d '_')

case "$current" in
a) target=b ;;
b) target=a ;;
*)
	echo "change_boot_slot: cannot determine current slot (got '$current'); aborting" >&2
	exit 1
	;;
esac

echo "change_boot_slot: current slot '$current' -> activating slot '$target'"
"$QBOOTCTL" -s "$target"
echo "change_boot_slot: slot '$target' is now the active boot slot"
