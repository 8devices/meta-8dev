#!/bin/sh

get_board_id() {
	local board rev compat board_base board_id board_cdt part

	# Board ID comes from the CDT. When absent (legacy board), fall back to
	# the board-type default -- QCS6490 IOT platform (0x00000020).
	#
	# CDT platform fields are four separate bytes:
	#   [0x13] platform_type  [0x14] version_major
	#   [0x15] version_minor  [0x16] platform_subtype
	# Compose them explicitly. Reading the four bytes as one little-endian word
	# (od -H) reverses them, which swaps major and minor -- invisible on the
	# legacy CDT where both are 1, wrong on every board since. hexdump also
	# avoids od -H, which is a busybox extension GNU od does not implement.
	for part in /sys/class/block/*; do
		grep -qs '^PARTNAME=cdt$' "$part/uevent" || continue
		set -- $(dd if="/dev/${part##*/}" bs=1 skip=$((0x13)) count=4 2>/dev/null \
			| hexdump -v -e '1/1 "%02x "')
		[ -n "$4" ] && board_id="$4$2$3$1"
		break
	done
	if [ -n "$board_id" ]; then
		board_id="0x$board_id"
		board_cdt="yes"
	else
		board_id="0x00000020"
		board_cdt="no"
	fi

	if [ -f /proc/device-tree/compatible ]; then
		compat=$(tr '\0' '\n' < /proc/device-tree/compatible 2>/dev/null | head -n 1)
	fi

	case "$board_id" in
		0x02010120) board_base="citron-prototype"; rev="1.0" ;; # Early prototype boards
		0x80010020) board_base="citron-generic";   rev="1.0" ;; # Pre-flashed SoMs for clients
		0x81010020) board_base="citron-dvk";       rev="1.0" ;;
		0x81020020) board_base="citron-dvk";       rev="2.0" ;;
		0x82010020) board_base="robovision";       rev="1.0" ;;
		0x82020020) board_base="robovision";       rev="2.0" ;;
	esac

	# Use board compatible as primary board name source
	case "$compat" in
		"8devices,citron-generic")  board="citron-generic"  ;;
		"8devices,citron-dvk")      board="citron-dvk"      ;;
		"8devices,citron-dvk-rev2") board="citron-dvk-rev2" ;;
		"8devices,robovision")      board="robovision"      ;;
		"8devices,robovision-rev2") board="robovision-rev2" ;;
		*)                          board="$compat"         ;;
	esac

	if [ -n "$DUMP" ]; then
		[ -n "$board_base" -a "$board_base" != "$board" ] && echo "BOARD_BASE=$board_base"
		echo "BOARD=$board"
		echo "BOARD_REV=$rev"
		echo "BOARD_ID=$board_id"
		echo "BOARD_CDT=$board_cdt"
		return
	fi

	printf "Board name: %s\n" "${board}${rev:+ rev$rev}"
}

get_board_id
