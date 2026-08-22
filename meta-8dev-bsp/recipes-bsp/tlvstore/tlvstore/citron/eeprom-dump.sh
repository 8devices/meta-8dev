#!/bin/sh

[ -f /etc/board.conf ] && exit 0

if ! tlvs -g @/usr/share/tlvs/8dev-citron-store > /tmp/board.conf; then
	echo "Failed to read primary EEPROM, using backup" >&2
	tlvs -F /dev/disk/by-partlabel/tlvstore_bakcup \
		-g @/usr/share/tlvs/8dev-tobufi-initial > /tmp/board.conf
fi

if [ ! -s /tmp/board.conf ]; then
	echo "Failed to load EEPROM data" >&2
	exit 1
fi

. /tmp/board.conf

[ -n "$MAC_ADDR_eth0" ] || echo "Warning: EEPROM missing eth0 MAC address" >&2
[ -n "$MAC_ADDR_eth1" ] || echo "Warning: EEPROM missing eth1 MAC address" >&2
[ -n "$MAC_ADDR_wlan0" ] || echo "Warning: EEPROM missing wlan0 MAC address" >&2
[ -n "$MAC_ADDR_wlan1" ] || echo "Warning: EEPROM missing wlan1 MAC address" >&2

mv /tmp/board.conf /etc/board.conf
