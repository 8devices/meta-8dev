#!/bin/sh

/usr/bin/sys-eeprom -d >/dev/null 2>&1 || {
	echo "No data present on EEPROM."
	exit 1
}

if [ ! -s /lib/firmware/ath10k/cal-snoc-a000000.wifi.bin ]; then
	/usr/bin/sys-eeprom -g RADIO_CALIBRATION_DATA | xzcat > /lib/firmware/ath10k/cal-snoc-a000000.wifi.bin
fi

if [ ! -s /etc/modprobe.d/stmmac_mac.conf -o ! -s /etc/board.conf ]; then
	MAC_ADDR_eth0=$(/usr/bin/sys-eeprom -g "GENERIC_MAC_eth0")
fi
if [ ! -s /etc/modprobe.d/ath10k_mac.conf -o ! -s /etc/board.conf ]; then
	MAC_ADDR_wlan0=$(/usr/bin/sys-eeprom -g "GENERIC_MAC_wifi0")
	# Initial TobuFi production had wifi0 and wlan0 interfaces. However
	# those interaces names are SW specific therefore they are switch to
	# more generic wlan0 and wlan1 ones in later production batches. In
	# turn this names matches open source netdevs naming conventions.
	if [ -z "$MAC_ADDR_wlan0" ]; then
		MAC_ADDR_wlan0=$(/usr/bin/sys-eeprom -g "GENERIC_MAC_wlan0")
		MAC_ADDR_wlan1=$(/usr/bin/sys-eeprom -g "GENERIC_MAC_wlan1")
	else
		MAC_ADDR_wlan1=$(/usr/bin/sys-eeprom -g "GENERIC_MAC_wlan0")
	fi
fi

if [ ! -s /etc/modprobe.d/stmmac_mac.conf -a -n "$MAC_ADDR_eth0" ]; then
	mkdir -p /etc/modprobe.d
	echo "options dwmac_qcom_ethqos mac_addr=$MAC_ADDR_eth0" > /etc/modprobe.d/stmmac_mac.conf
fi

if [ ! -s /etc/modprobe.d/ath10k_mac.conf -a -n "$MAC_ADDR_wlan1" ]; then
	mkdir -p /etc/modprobe.d
	echo "options ath10k_snoc mac_addr=$MAC_ADDR_wlan1" > /etc/modprobe.d/ath10k_mac.conf
fi

if [ ! -s /etc/board.conf ]; then
	(
		echo "PRODUCT_ID=$(/usr/bin/sys-eeprom -g "PRODUCT_ID")"
		echo "PCB_REVISION=$(/usr/bin/sys-eeprom -g "PCB_REVISION")"
		echo "PCB_NAME=$(/usr/bin/sys-eeprom -g "PCB_NAME")"
		echo "PCB_SN=$(/usr/bin/sys-eeprom -g "PCB_SN")"
		echo "PCB_PROD_DATE=$(/usr/bin/sys-eeprom -g "PCB_PROD_DATE")"
		echo "PCB_PROD_LOCATION=$(/usr/bin/sys-eeprom -g "PCB_PROD_LOCATION")"
		echo "SERIAL_NO=$(/usr/bin/sys-eeprom -g "SERIAL_NO")"
		echo "MAC_ADDR_eth0=$MAC_ADDR_eth0"
		echo "MAC_ADDR_wlan0=$MAC_ADDR_wlan0"
		echo "MAC_ADDR_wlan1=$MAC_ADDR_wlan1"
	) > /etc/board.conf
fi
