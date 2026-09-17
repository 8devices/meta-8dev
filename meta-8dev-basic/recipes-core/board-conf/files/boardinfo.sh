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
	local board_dtb rev compat board_cdt board_id board_cdt_found part

	# Read through sysfs PARTNAME rather than the udev by-partlabel symlink, so
	# this also works early in boot. Legacy boards have no CDT id and fall back.
	for part in /sys/class/block/*; do
		grep -qs '^PARTNAME=cdt$' "$part/uevent" || continue
		board_id=$(dd if="/dev/${part##*/}" bs=1 skip=$((0x13)) count=4 2>/dev/null \
			| od -H | awk 'NR==1{print $2}')
		break
	done
	if [ -n "$board_id" ]; then
		board_id="0x$board_id"
		board_cdt_found="yes"
	else
		board_cdt_found="no"
	fi

	if [ -f /proc/device-tree/compatible ]; then
		compat=$(tr '\0' '\n' < /proc/device-tree/compatible 2>/dev/null | head -n 1)
	fi

	case "$board_id" in
		0x40000120) board_cdt="citron-generic"; rev="1.0" ;;
		0x41000120) board_cdt="citron-dvk";     rev="1.0" ;;
		0x41000220) board_cdt="citron-dvk";     rev="2.0" ;;
		0x42000120) board_cdt="robovision";     rev="1.0" ;;
		0x42000220) board_cdt="robovision";     rev="2.0" ;;
	esac

	case "$compat" in
		"8devices,citron-generic")  board_dtb="citron-generic"; rev="1.0" ;;
		"8devices,citron-dvk")      board_dtb="citron-dvk";     rev="1.0" ;;
		"8devices,citron-dvk-rev2") board_dtb="citron-dvk";     rev="2.0" ;;
		"8devices,robovision")      board_dtb="robovision";     rev="1.0" ;;
		"8devices,robovision-rev2") board_dtb="robovision";     rev="2.0" ;;
	esac

	# The id-named file is applied last so it wins over a compatible-named one.
	for key in "$compat" "$board_id"; do
		[ -n "$key" ] && [ -f "$BOARDINFO_DIR/$key" ] || continue
		BOARD_NAME="" BOARD_REV=""
		. "$BOARDINFO_DIR/$key"
		# A revision without a board name means nothing.
		[ -n "$BOARD_NAME" ] || continue
		board_dtb="$BOARD_NAME" rev="$BOARD_REV"
	done

	if [ -n "$DUMP" ]; then
		[ -n "$board_cdt" -a "$board_cdt" != "$board_dtb" ] && echo "BOARD_BASE=$board_cdt"
		echo "BOARD=$board_dtb"
		echo "BOARD_REV=$rev"
		echo "BOARD_ID=$board_id"
		echo "BOARD_CDT=$board_cdt_found"
		return
	fi

	printf "Board name: %s\n" "${board_dtb}${rev:+ rev$rev}"
}

get_radio_id() {
	local svid sdid type features

	svid=$(cat "/sys/devices/platform/soc@0/1c08000.pcie/pci0001:00/0001:00:00.0/0001:01:00.0/subsystem_vendor" 2>/dev/null)
	sdid=$(cat "/sys/devices/platform/soc@0/1c08000.pcie/pci0001:00/0001:00:00.0/0001:01:00.0/subsystem_device" 2>/dev/null)

	case "$svid-$sdid" in
		0x17cb-0x1109) type="Standard"; features="2-5GHz 2x2" ;;
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

get_board_id
get_radio_id
