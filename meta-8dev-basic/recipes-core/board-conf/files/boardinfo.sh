#!/bin/sh

# Drop-in overrides for integrator layers. A file named after the key it
# describes is sourced after the built-in resolution, and each variable it sets
# overrides the built-in result:
#
#   /lib/boardinfo.d/<cdt board id | dt compatible>  -> BOARD_NAME, BOARD_REV
#   /lib/boardinfo.d/<svid>-<sdid>                   -> RADIO_TYPE, RADIO_FEATURES
#
BOARDINFO_DIR="${BOARDINFO_DIR:-/lib/boardinfo.d}"

get_board_id() {
	local board rev compat board_base board_id board_cdt part

	# Read through sysfs PARTNAME rather than the udev by-partlabel symlink, so
	# this also works early in boot. Legacy boards have no CDT id and fall back.
	for part in /sys/class/block/*; do
		grep -qs '^PARTNAME=cdt$' "$part/uevent" || continue
		board_id=$(dd if="/dev/${part##*/}" bs=1 skip=$((0x17)) count=4 2>/dev/null \
			| od -H | awk 'NR==1{print $2}')
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
		0x80000520) board_base="tobufi-som"; rev="5.0" ;;
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
		0x00010120)
			case "$compat" in
				"8devices,robovision") board_base="robovision"; rev="1.0" ;;
			esac
			;;
	esac

	case "$compat" in
		"8devices,tobufi")     board="tobufi"     ;;
		"8devices,tobufi-dvk") board="tobufi-dvk" ;;
		"8devices,robonode")   board="robonode"   ;;
		"8devices,robovision") board="robovision" ;;
		*)                     board="$compat"    ;;
	esac

	# The id-named file is applied last so it wins over a compatible-named one.
	for key in "$compat" "$board_id"; do
		[ -n "$key" ] && [ -f "$BOARDINFO_DIR/$key" ] || continue
		BOARD_NAME="" BOARD_REV=""
		. "$BOARDINFO_DIR/$key"
		# A revision without a board name means nothing.
		[ -n "$BOARD_NAME" ] || continue
		board="$BOARD_NAME" rev="$BOARD_REV"
	done

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
	if [ "$sdid" = "0x3845" ] || [ "$sdid" = "0x3841" ]; then
		stmp="$sdid"
		sdid="$svid"
		svid="$stmp"
	fi

	case "$svid-$sdid" in
		0x3844-0x040a) type="Standard"; features="2-5GHz 2x4" ;;
		0x3845-0x040a) type="Premium";  features="2-5GHz 2x4" ;;
		0x3844-0x040c) type="Standard"; features="2-6GHz 2x4" ;;
		0x3845-0x040c) type="Premium";  features="2-6GHz 2x4" ;;
		*)             type="unknown";  features="unknown"    ;;
	esac

	key="$svid-$sdid"
	if [ -n "$svid" ] && [ -n "$sdid" ] && [ -f "$BOARDINFO_DIR/$key" ]; then
		RADIO_TYPE="" RADIO_FEATURES=""
		. "$BOARDINFO_DIR/$key"
		[ -n "$RADIO_TYPE" ] && type="$RADIO_TYPE"
		[ -n "$RADIO_FEATURES" ] && features="$RADIO_FEATURES"
	fi

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
