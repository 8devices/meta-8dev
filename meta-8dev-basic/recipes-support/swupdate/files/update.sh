#!/bin/sh
# Launch swupdate-progress together with swupdate-client

cleanup() {
	[ -n "$PROG_PID" ] || return
	kill -0 "$PROG_PID" 2>/dev/null || return
	sleep 0.5
	kill -0 "$PROG_PID" 2>/dev/null && kill -KILL "$PROG_PID" 2>/dev/null
}

trap cleanup EXIT INT TERM
 
swupdate-progress &
PROG_PID=$!

swupdate-client "$@"

