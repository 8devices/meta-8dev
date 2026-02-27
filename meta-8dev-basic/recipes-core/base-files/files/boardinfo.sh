#!/bin/sh

get_board_id() {
	CDT_PATH=/dev/disk/by-partlabel/cdt
	BOARD_ID="00000020"

	if [ -e "$CDT_PATH" ]; then
		BOARD_ID="$(dd if="$CDT_PATH" bs=1 skip=$((0x17)) count=4 2>/dev/null | od -H | awk 'NR==1{ print $2 }')"
	fi

	if [ -n "$DEBUG" ]; then
		echo "BOARD_ID=0x$BOARD_ID"
		return
	fi

	echo -n "Board name: "
	case $BOARD_ID in
		81030020) echo "TobuFi-DVK rev3.0" ;;
		81040020) echo "TobuFi-DVK rev4.0" ;;
		81050020) echo "TobuFi-DVK rev5.0" ;;
		82020020) echo "Robonode rev2.0" ;;
		*) echo "TobuFi generic" ;;
	esac
}

get_radio_id() {
	svid=$(cat "/sys/devices/platform/soc@0/10000000.pci/pci0000:00/0000:00:00.0/0000:01:00.0/subsystem_vendor")
	sdid=$(cat "/sys/devices/platform/soc@0/10000000.pci/pci0000:00/0000:00:00.0/0000:01:00.0/subsystem_device")

	if [ -n "$DEBUG" ]; then
		echo "RADIO_SVID=$svid"
		echo "RADIO_SDID=$sdid"
		return
	fi

	echo -n "Radio ID: "
	case $svid in
		0x3844) echo "Standard" ;;
		0x3845) echo "Premium" ;;
		*) echo "unknown" ;;
	esac

	echo -n "Radio features: "
	case $sdid in
		0x040a) echo "2-5GHz 2x4" ;;
		0x040c) echo "2-6GHz 2x4" ;;
		*) echo "unknown" ;;
	esac
}

get_sn() {
	SERIAL_NO=$(grep -o 'androidboot.serialno=[^ ]*' /proc/cmdline 2>/dev/null | cut -d'=' -f2)
	if [ -n "$SERIAL_NO" ]; then
		[ -n "$DEBUG" ] && echo "SERIAL_NO=$SERIAL_NO"
		[ -n "$DEBUG" ] || echo "Serial Number: $SERIAL_NO"
	fi
}

get_board_id
get_radio_id
get_sn
