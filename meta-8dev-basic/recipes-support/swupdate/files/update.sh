#!/bin/sh
# Launch swupdate-progress together with swupdate-client

# SWUs from before the qbootctl slot switch call sgdisk, which this image
# lacks; its stand-in on the swupdate PATH marks their switch here instead.
SLOT_REQUEST=/run/update-slot-request

cleanup() {
	rm -f "$SLOT_REQUEST"
	[ -n "$PROG_PID" ] || return
	kill -0 "$PROG_PID" 2>/dev/null || return
	sleep 0.5
	kill -0 "$PROG_PID" 2>/dev/null && kill -KILL "$PROG_PID" 2>/dev/null
}

trap cleanup EXIT INT TERM

: > "$SLOT_REQUEST"

swupdate-progress &
PROG_PID=$!

swupdate-client "$@" || exit
[ -s "$SLOT_REQUEST" ] || exit 0

case "$(qbootctl -c)" in
*_a) qbootctl -s b ;;
*_b) qbootctl -s a ;;
*) echo "update: cannot determine current slot; not switching" >&2; exit 1 ;;
esac
