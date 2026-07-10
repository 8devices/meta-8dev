#!/bin/sh

get_board_id() {
	local board rev compat board_base board_id board_cdt

	# Board ID comes from the CDT. When absent (legacy board), fall back to
	# the board-type default -- QCS405 IOT board id 0x20.
	if [ -e /dev/disk/by-partlabel/cdt ]; then
		board_id=$(dd if=/dev/disk/by-partlabel/cdt bs=1 skip=$((0x17)) count=4 2>/dev/null \
			| od -H | awk 'NR==1{print $2}')
	fi
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
		0x81000320) board_base="tobufi-dvk"; rev="3.0" ;;
		0x81000420) board_base="tobufi-dvk"; rev="4.0" ;;
		0x81000520) board_base="tobufi-dvk"; rev="5.0" ;;
		0x82000220) board_base="robonode";   rev="2.0" ;;
		0x00000020)
			case "$compat" in
				"8devices,tobufi-dvk") board_base="tobufi-dvk"; rev="3.0" ;;
				"8devices,robonode")   board_base="robonode";   rev="1.0" ;;
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
		[ -n "$board_base" -a "$board_base" != "$board" ] && echo "BOARD_BASE=$board_base"
		echo "BOARD=$board"
		echo "BOARD_REV=$rev"
		echo "BOARD_ID=$board_id"
		echo "BOARD_CDT=$board_cdt"
		return
	fi

	printf "Board name: %s\n" "${board}${rev:+ rev$rev}"
}

get_radio_id() {
	local svid sdid type features

	svid=$(cat "/sys/devices/platform/soc@0/10000000.pci/pci0000:00/0000:00:00.0/0000:01:00.0/subsystem_vendor" 2>/dev/null)
	sdid=$(cat "/sys/devices/platform/soc@0/10000000.pci/pci0000:00/0000:00:00.0/0000:01:00.0/subsystem_device" 2>/dev/null)

	# XXX: mixed radio IDs handling
	if [ "$sdid" = "0x3845" ]; then
		sdid="$svid"
		svid="0x3845"
	fi

	case "$svid-$sdid" in
		0x3844-0x040a) type="Standard"; features="2-5GHz 2x4" ;;
		0x3845-0x040a) type="Premium";  features="2-5GHz 2x4" ;;
		0x3844-0x040c) type="Standard"; features="2-6GHz 2x4" ;;
		0x3845-0x040c) type="Premium";  features="2-6GHz 2x4" ;;
		*)             type="unknown";  features="unknown"    ;;
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
