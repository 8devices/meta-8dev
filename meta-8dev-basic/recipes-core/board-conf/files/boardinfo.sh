#!/bin/sh

# Directory of drop-in definitions for custom boards and radios. Integrator
# layers can install a file here named after the key it describes; matching
# files are sourced after the built-in resolution below and expose their values
# via uppercase variables (each applied only when set, overriding the built-in
# result). Supported keys and variables:
#
#   Boards -- file named after the CDT board id or the device tree compatible:
#     # /lib/boardinfo.d/0x83000120   (or /lib/boardinfo.d/acme,myboard)
#     BOARD_NAME=myboard
#     BOARD_REV=1.0
#
#   Radios -- file named after the "svid-sdid" pair:
#     # /lib/boardinfo.d/0x3844-0x040a
#     RADIO_TYPE=Custom
#     RADIO_FEATURES='2-5GHz 2x4'
#
BOARDINFO_DIR="${BOARDINFO_DIR:-/lib/boardinfo.d}"

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

	# Initial base resolution
	case "$compat" in
		"8devices,tobufi")     board_base="tobufi-som" ;;
		"8devices,tobufi-dvk") board_base="tobufi-dvk" ;;
		"8devices,robonode")   board_base="robonode"   ;;
		"8devices,robovision") board_base="robovision" ;;
	esac

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

	board="$board_base"

	# Custom boards / overrides: source a drop-in file named after the board
	# id or the compatible string, if present. It exposes BOARD and REV, which
	# override the values above. The id-named file is applied last so it wins
	# over a more generic compatible-named one.
	for key in "$compat" "$board_id"; do
		[ -n "$key" ] && [ -f "$BOARDINFO_DIR/$key" ] || continue
		BOARD_NAME="" BOARD_REV=""
		. "$BOARDINFO_DIR/$key"
		# Board revision is irrelevant without board name
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

	# Custom radios / overrides: source a drop-in file named after the
	# svid-sdid pair, if present. It exposes RADIO_TYPE and RADIO_FEATURES,
	# which override the values above.
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
