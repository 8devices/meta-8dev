#!/bin/sh

[ -f /etc/board.conf ] && [ -s /lib/firmware/ath10k/cal-snoc-a000000.wifi.bin ] && exit 0

if ! tlvs -c -g @/usr/share/tlvs/8dev-tobufi-store > /tmp/board.conf; then
	# XXX: legacy EEPROM can have two variations for Wi-Fi MAC address
	if ! tlvs -O 0 -g @/usr/share/tlvs/8dev-tobufi-legacy > /tmp/board.conf && legacy=1; then
		tlvs -O 0 -g @/usr/share/tlvs/8dev-tobufi-initial > /tmp/board.conf && legacy=1
	fi
fi

if [ ! -s /lib/firmware/ath10k/cal-snoc-a000000.wifi.bin ]; then
	if [ -z "$legacy" ]; then
		tlvs -g RADIO_CALDATA=@/lib/firmware/ath10k/cal-snoc-a000000.wifi.bin
	else
		tlvs -O 0 -g RADIO_CALIBRATION_DATA=@/lib/firmware/ath10k/cal-snoc-a000000.wifi.bin
	fi
fi

if [ ! -s /tmp/board.conf ]; then
	echo "Failed to load EEPROM data" >&2
	exit 1
fi

. /tmp/board.conf

[ -n "$MAC_ADDR_eth0" ] || echo "Warning: EEPROM missing eth0 MAC address" >&2
[ -n "$MAC_ADDR_wlan0" ] || echo "Warning: EEPROM missing wlan0 MAC address" >&2
[ -n "$MAC_ADDR_wlan1" ] || echo "Warning: EEPROM missing wlan1 MAC address" >&2

# XXX: if MAC_ADDR_wlan0 and MAC_ADDR_wlan1 MAC are equal, increment wlan1 MAC
if [ "$MAC_ADDR_wlan0" = "$MAC_ADDR_wlan1" ] && [ -n "$MAC_ADDR_wlan1" ]; then
	echo "Info: Patching duplicate wlan1 MAC address" >&2
	OLD_ARG="$*"; OLD_IFS="$IFS"; IFS=:; set -- $MAC_ADDR_wlan1
	o4=$((0x$4)) o5=$((0x$5)) o6=$((0x$6 + 1))
	[ $o6 -gt 255 ] && { o6=0; o5=$((o5 + 1)); }
	[ $o5 -gt 255 ] && { o5=0; o4=$((o4 + 1)); }
	[ $o4 -gt 255 ] && o4=0
	MAC_ADDR_wlan1="$1:$2:$3:$(printf "%02x:%02x:%02x" $o4 $o5 $o6)"
	sed -i "s|^MAC_ADDR_wlan1=.*|MAC_ADDR_wlan1=$MAC_ADDR_wlan1|" /tmp/board.conf
	IFS="$OLD_IFS"; set -- "$OLD_ARG"
fi

mv /tmp/board.conf /etc/board.conf

if [ ! -s /etc/modprobe.d/stmmac_mac.conf ] && [ -n "$MAC_ADDR_eth0" ]; then
	mkdir -p /etc/modprobe.d
	echo "options dwmac_qcom_ethqos mac_addr=$MAC_ADDR_eth0" > /etc/modprobe.d/stmmac_mac.conf
fi

if [ ! -s /etc/modprobe.d/ath10k_mac.conf ] && [ -n "$MAC_ADDR_wlan1" ]; then
	mkdir -p /etc/modprobe.d
	echo "options ath10k_snoc mac_addr=$MAC_ADDR_wlan1" > /etc/modprobe.d/ath10k_mac.conf
fi
