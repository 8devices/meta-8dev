#!/bin/sh

[ -f /etc/board.conf ] && [ -s /lib/firmware/ath10k/cal-snoc-a000000.wifi.bin ] && exit 0

if ! tlvs -g /usr/share/tlvs/eeprom-store > /tmp/board.json; then
	tlvs -g /usr/share/tlvs/eeprom-legacy > /tmp/board.json && legacy=1
fi

if [ ! -s /lib/firmware/ath10k/cal-snoc-a000000.wifi.bin ]; then
	if [ -z "$legacy" ]; then
		tlvs -g RADIO_CALIBRATION_DATA=@/lib/firmware/ath10k/cal-snoc-a000000.wifi.bin
	else
		tlvs -g RADIO_CALDATA=@/lib/firmware/ath10k/cal-snoc-a000000.wifi.bin
	fi
fi

if [ ! -f /tmp/board.conf ]; then
	echo "Failed to load EEPROM data" >&2
	exit 1
fi

mv /tmp/board.conf /etc/board.conf

. /etc/board.conf

if [ ! -s /etc/modprobe.d/stmmac_mac.conf ] && [ -n "$MAC_ADDR_eth0" ]; then
	mkdir -p /etc/modprobe.d
	echo "options dwmac_qcom_ethqos mac_addr=$MAC_ADDR_eth0" > /etc/modprobe.d/stmmac_mac.conf
fi

if [ ! -s /etc/modprobe.d/ath10k_mac.conf ] && [ -n "$MAC_ADDR_wlan1" ]; then
	mkdir -p /etc/modprobe.d
	echo "options ath10k_snoc mac_addr=$MAC_ADDR_wlan1" > /etc/modprobe.d/ath10k_mac.conf
fi
