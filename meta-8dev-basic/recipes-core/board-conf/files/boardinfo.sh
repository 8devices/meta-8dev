#!/bin/sh

get_board_id() {
	local board rev board_id compat

	# Board ID comes from the CDT. When absent (legacy board), fall back to
	# the board-type default -- QCS405 IOT board id 0x20.
	if [ -e /dev/disk/by-partlabel/cdt ]; then
		board_id=$(dd if=/dev/disk/by-partlabel/cdt bs=1 skip=$((0x17)) count=4 2>/dev/null \
			| od -H | awk 'NR==1{print $2}')
	fi
	if [ -z "$board_id" ]; then
		board_id="00000020"
	fi

	if [ -f /proc/device-tree/compatible ]; then
		compat=$(tr '\0' '\n' < /proc/device-tree/compatible 2>/dev/null | head -n 1)
	fi

	case "$board_id" in
		81000320) board="tobufi-dvk"; rev="rev3.0" ;;
		81000420) board="tobufi-dvk"; rev="rev4.0" ;;
		81000520) board="tobufi-dvk"; rev="rev5.0" ;;
		82000220) board="robonode";   rev="rev2.0" ;;
		00000020)
			case "$compat" in
				"8devices,tobufi-dvk") board="tobufi-dvk"; rev="rev3.0" ;;
				"8devices,robonode")   board="robonode";   rev="rev1.0" ;;
			esac
			;;
	esac

	# Use board compatible as primary board name source
	case "$compat" in
		"8devices,tobufi-dvk") board="tobufi-dvk" ;;
		"8devices,robonode")   board="robonode" ;;
		"8devices,robovision") board="robovision" ;;
		*)                     board="$compat" ;;
	esac

	if [ -n "$DUMP" ]; then
		echo "BOARD=$board"
		echo "BOARD_REV=$rev"
		echo "BOARD_ID=$board_id"
		return
	fi

	printf "Board name: %s\n" "${board}${rev:+ $rev}"
}

get_radio_id() {
	local svid sdid type features

	svid=$(cat "/sys/devices/platform/soc@0/10000000.pci/pci0000:00/0000:00:00.0/0000:01:00.0/subsystem_device" 2>/dev/null)
	sdid=$(cat "/sys/devices/platform/soc@0/10000000.pci/pci0000:00/0000:00:00.0/0000:01:00.0/subsystem_vendor" 2>/dev/null)

	# XXX: mixed radio IDs handling
	if [ "$sdid" = "0x3845" ]; then
		sdid="$svid"
		svid="0x3845"
	fi

	case $svid in
		0x3844) type="Standard" ;;
		0x3845) type="Premium" ;;
		*)      type="unknown" ;;
	esac

	case $sdid in
		0x040a) features="2-5GHz 2x4" ;;
		0x040c) features="2-6GHz 2x4" ;;
		*)      features="unknown" ;;
	esac

	if [ -n "$DUMP" ]; then
		echo "RADIO_SVID=$svid"
		echo "RADIO_SDID=$sdid"
		echo "RADIO_TYPE=$type"
		echo "RADIO_FEATURES='$features'"
		return
	fi

	echo "Radio ID: $type"
	echo "Radio features: $features"
}

get_sn() {
	local serial_no

	serial_no=$(grep -o 'androidboot.serialno=[^ ]*' /proc/cmdline 2>/dev/null | cut -d'=' -f2)
	if [ -n "$serial_no" ]; then
		[ -n "$DUMP" ] && echo "SERIAL_NO=$serial_no"
		[ -n "$DUMP" ] || echo "Serial Number: $serial_no"
	fi
}

get_board_id
get_radio_id
get_sn
