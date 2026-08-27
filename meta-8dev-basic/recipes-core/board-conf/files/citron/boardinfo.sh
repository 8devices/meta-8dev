#!/bin/sh

get_board_id() {
	local board rev compat

	if [ -f /proc/device-tree/compatible ]; then
		compat=$(tr '\0' '\n' < /proc/device-tree/compatible 2>/dev/null | head -n 1)
	fi
	case "$compat" in
		"8devices,citron-generic")  board="citron-generic"; rev="1.0" ;;
		"8devices,citron-dvk")      board="citron-dvk";     rev="1.0" ;;
		"8devices,citron-dvk-rev2") board="citron-dvk";     rev="2.0" ;;
		"8devices,robovision")      board="robovision";     rev="1.0" ;;
		"8devices,robovision-rev2") board="robovision";     rev="2.0" ;;
	esac

	if [ -n "$DUMP" ]; then
		echo "BOARD=$board"
		echo "BOARD_REV=$rev"
		return
	fi

	printf "Board name: %s\n" "${board}${rev:+ rev$rev}"
}

get_board_id
