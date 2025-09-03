#!/bin/sh

[ "$DEBUG" = "trace" ]  && set -x

RADIOS_CONFIG="/etc/radios.cfg"

info() {
	echo $*
}

debug() {
	[ -z "$DEBUG" ] || echo $*
}

modprobe() {
	[ -z "$DEBUG" ] || echo modprobe $*
	`which modprobe` $*
}

rmmod() {
	[ -z "$DEBUG" ] || echo rmmod $*
	`which rmmod` $*
}

iw() {
	[ -z "$DEBUG" ] || echo iw $*
	`which iw` $*
}

ip() {
	[ -z "$DEBUG" ] || echo ip $*
	`which ip` $*
}

macid() {
	read -r mac < /sys/class/net/eth0/address
	old_ifs=$IFS
	IFS=':'
	set -- $mac
	IFS=$old_ifs
	echo $4$5$6
}

vapid() {
	i=0
	for f in /sys/class/net/*; do
		[ -d "$f/wireless" ] && i=$((i+1))
	done
	echo $i
}

hostap_get() {
	var=$1
	cfg=/etc/hostapd/"$VAP_NAME".conf
	if [ ! -f "$cfg" ]; then
		return 1
	fi
	sed -n "s/.*\b$var=\(.*\)/\1/p" "$cfg"
}

hostap_set() {
	var=$1
	val=$2
	cfg=/etc/hostapd/"$VAP_NAME".conf
	if [ ! -f "$cfg" ]; then
		return 1
	fi

	debug "hostapd[$VAP_NAME] $var=$val"
	if [ -z "$val" ]; then
		sed -i "/\b$var=.*/d" "$cfg"
	elif grep -qe "\b$var=" "$cfg"; then
		sed -i "s/\b$var=.*/$var=$val/" "$cfg"
	else
		echo $var=$val >> "$cfg"
	fi
}

supplicant_get() {
	var=$1
	cfg=/etc/wpa_supplicant/"$VAP_NAME".conf
	if [ ! -f "$cfg" ]; then
		return 1
	fi
	sed -n "s/.*\b$var=\(.*\)/\1/p" "$cfg"
}

supplicant_set() {
	var=$1
	val=$2
	global=$3
	cfg=/etc/wpa_supplicant/"$VAP_NAME".conf
	if [ ! -f "$cfg" ]; then
		return 1
	fi

	debug "wpa_supplicant[$VAP_NAME] $var=$val"
	if [ -z "$val" ]; then
		sed -i "/\b$var=.*/d" "$cfg"
	elif grep -qe "\b$var=" "$cfg"; then
		sed -i "s/\b$var=.*/$var=$val/" "$cfg"
	else
		[ -n "$global" ] && chr="{" || chr="}"
		sed -i "/$chr/i $var=$val" "$cfg"
	fi
}

init_hostap() {
	mkdir -p /etc/hostapd
	cp /etc/hostapd.conf /etc/hostapd/"$VAP_NAME".conf
	info "Initialized AP config at /etc/hostapd/"$VAP_NAME".conf"
}

init_supplicant() {
	mkdir -p /etc/wpa_supplicant
	cp /etc/wpa_supplicant.conf /etc/wpa_supplicant/"$VAP_NAME".conf
	info "Initialized STA config at /etc/wpa_supplicant/"$VAP_NAME".conf"
}

init_vap_defaults() {
	[ -n "$BAND" ] || {
		first_freq=$(iw phy "$PHY_NAME"	info | \
			grep -oE "[0-9]+\.0 MHz" | \
			awk -F'.' '{print $1; exit}')
		[ "$first_freq" -lt "4000" ] && BAND=2 || BAND=5
	}
	[ -n "$COUNTRY" ] || COUNTRY=US
	[ -n "$CHWIDTH" ] || CHWIDTH=20
	[ -n "$CHANNEL" ] || CHANNEL=0
}

find_channel_number() {
	local chval=$1

	[ "$chval" -lt 1000 ] && chan_number=$chval && return

	if [ $chval -ge 2412 -a $chval -le 2472 ]; then
		chan_number=$(((chval - 2412) / 5 + 1))
	elif [ $chval -eq 2484 ]; then
		chan_number=14
	elif [ $chval -ge 5180 -a $chval -le 5885 ]; then
		chan_number=$(((chval - 5000) / 5))
	fi
}

find_channel_center() {
	local chval=$1

	[ "$chval" -ge 36 -a "$chval" -le 177 ] || [ "$chval" -gt 5000 ] || return

	find_channel_number $chval

	case "$CHWIDTH" in
		160)
			[ "$chan_number" -ge 36 -a "$chan_number" -le 64 ] && chan_center=50
			[ "$chan_number" -ge 100 -a "$chan_number" -le 128 ] && chan_center=114
			[ "$chan_number" -ge 149 -a "$chan_number" -le 177 ] && chan_center=163
			;;
		80)
			[ "$chan_number" -ge 36 -a "$chan_number" -le 48 ] && chan_center=42
			[ "$chan_number" -ge 52 -a "$chan_number" -le 64 ] && chan_center=58
			[ "$chan_number" -ge 100 -a "$chan_number" -le 112 ] && chan_center=106
			[ "$chan_number" -ge 116 -a "$chan_number" -le 128 ] && chan_center=122
			[ "$chan_number" -ge 132 -a "$chan_number" -le 144 ] && chan_center=138
			[ "$chan_number" -ge 149 -a "$chan_number" -le 161 ] && chan_center=155
			[ "$chan_number" -ge 165 -a "$chan_number" -le 177 ] && chan_center=171
			;;
		*)
			;;
	esac
}

find_channel_frequency() {
	local chval=$1
	# XXX: edge-case for chan_num 14 in 2.4 GHz band
	[ "$chval" -eq 14 -a "$BAND" = "2" ] && chan_freq=2484 && return

	[ "$BAND" = "2" ] && freq_base=2412 || freq_base=5000
	chan_freq=$((freq_base + (5 * chval)))
}

apply_hostap() {
	hostap_set interface "$VAP_NAME"

	if [ -n "$COUNTRY" ]; then
		hostap_set country_code "$COUNTRY"
	fi

	if [ -n "$WDS_BRIDGE" -a "$WDS_BRIDGE" != "-" ]; then
		hostap_set bridge "$WDS_BRIDGE"
		hostap_set wds_sta 1
	elif [ "$WDS_BRIDGE" = "-" ]; then
		hostap_set bridge
		hostap_set wds_sta
	fi

	if [ "$BAND" = "2" ]; then
		hostap_set hw_mode g
		hostap_set ieee80211ac
		[ "$PHY_DRIVER" = "ath11k" ] && hostap_set ieee80211ax 1
		hostap_set vht_capab
		hostap_set he_oper_chwidth
		hostap_set he_oper_centr_freq_seg0_idx
		hostap_set vht_oper_chwidth
		hostap_set vht_oper_centr_freq_seg0_idx
	elif [ "$BAND" = "5" ]; then
		hostap_set hw_mode a
		hostap_set ieee80211ac 1
		[ "$PHY_DRIVER" = "ath11k" ] && hostap_set ieee80211ax 1
	fi

	if [ -n "$FREQLIST" ] && [ "$FREQLIST" != "-" ]; then
		hostap_set channel 0
		hostap_set freqlist "$FREQLIST"
	elif [ -n "$CHANNEL" ] && [ "$CHANNEL" -gt "1000" ]; then
		find_channel_number "$CHANNEL"
		hostap_set channel $chan_number
		hostap_set freqlist
	elif [ -n "$CHANNEL" ] && [ "$CHANNEL" -lt "1000" ]; then
		hostap_set channel "$CHANNEL"
		hostap_set freqlist
	fi

	if [ -n "$CHWIDTH" ]; then
		htcap="[SHORT-GI-20]"
		vhtcap=

		[ -n "$CHANNEL" ] || CHANNEL=$(hostap_get channel)
		# XXX: center frequency is auto detected via ACS if channel is not set
		[ "$CHANNEL" -ne "0" ] && find_channel_center "$CHANNEL"

		[ "$CHWIDTH" -ge "40" ] && htcap="$htcap[SHORT-GI-40][HT40-][HT40+]"

		hw_mode=$(hostap_get hw_mode)
		[ "$hw_mode" = "a" ] && vhtcap="[RXLDPC][MAX-MPDU-11454]"
		if [ "$hw_mode" = "a" ] && [ "$CHWIDTH" -ge "80" ]; then
			vhtcap="$vhtcap[SHORT-GI-80][VHT80]"
			[ "$CHWIDTH" = "160" ] && vhtcap="$vhtcap[VHT160][SHORT-GI-160]"
			[ "$CHWIDTH" = "160" ] && vht80=2 || vht80=1
		fi
		hostap_set ht_capab "$htcap"
		hostap_set vht_capab "$vhtcap"
		hostap_set vht_oper_chwidth "$vht80"
		hostap_set vht_oper_centr_freq_seg0_idx "$chan_center"
		if [ "$PHY_DRIVER" = "ath11k" ]; then
			hostap_set he_oper_chwidth "$vht80"
			hostap_set he_oper_centr_freq_seg0_idx "$chan_center"
		fi
	fi

	if [ "$SSID" = "-" ] || [ -z "$SSID" -a -z "`hostap_get ssid`" ]; then
		# When SSID is not specified and is
		# absent in config generate and
		# backfill it to ensure VAP startup.
		SSID=8dev-`macid`
		idx=`vapid`
		[ "$idx" -le "1" ] || SSID=$SSID"#$idx"
	fi
	if [ -n "$SSID" ]; then
		hostap_set ssid "$SSID"
		# When SSID is specified so should
		# hide SSID and WPA PSK passphrase,
		# otherwise reset them.
		[ -n "$HIDE" ] || HIDE=-
		[ -n "$WPAPSK" ] || WPAPSK=-
	fi
	if [ -n "$HIDE" ]; then
		if [ "$HIDE" = "-" ]; then
			hostap_set ignore_broadcast_ssid
		else
			hostap_set ignore_broadcast_ssid 1
		fi
	fi
	if [ -n "$WPAPSK" ]; then
		if [ "$WPAPSK" = "-" ]; then
			hostap_set wpa_key_mgmt
			hostap_set wpa_pairwise
			hostap_set wpa
			hostap_set wpa_passphrase
			hostap_set wpa_group_rekey
		else
			hostap_set wpa_key_mgmt WPA-PSK
			hostap_set wpa_pairwise CCMP
			hostap_set wpa 2
			hostap_set wpa_passphrase $WPAPSK
			hostap_set wpa_group_rekey 0
		fi
	fi

	info "Applied AP config settings to /etc/hostapd/$VAP_NAME.conf"
}

apply_supplicant() {
	if [ -n "$FREQLIST" -a "$FREQLIST" != "-" ]; then
		freqs=`echo $FREQLIST | sed 's/,/ /g'`
		# XXX: scan_freq is not supported by our wpa_supplicant
		#supplicant scan_freq "$freqs" global
		supplicant_set freq_list "$freqs" global
	elif [ -n "$CHANNEL" -a "$CHANNEL" -ne 0 ] && [ "$CHANNEL" -gt "1000" ]; then
		supplicant_set freq_list "$CHANNEL" global
	elif [ -n "$CHANNEL" -a "$CHANNEL" -ne 0 ] && [ "$CHANNEL" -lt "1000" ]; then
		# XXX: supplicant works with channel frequencies
		# convert channel number to channel frequency
		find_channel_frequency "$CHANNEL"	
		supplicant_set freq_list "$chan_freq" global
	fi
	if [ "$SSID" = "-" ] || [ -z "$SSID" -a -z "`supplicant_get ssid`" ]; then
		# When SSID is not specified and is
		# abscent in config generate and
		# backfill it to ensure VAP startup.
		SSID=8dev-`macid`
		idx=`vapid`
		[ "$idx" -le "1" ] || SSID=$SSID"#$idx"
	fi
	if [ -n "$SSID" ]; then
		supplicant_set ssid \"$SSID\"
		# When SSID is specified so should be
		# WPA PSK passphrase, otherwise reset it.
		[ -n "$WPAPSK" ] || WPAPSK=-
	fi
	if [ -n "$WPAPSK" ]; then
		if [ "$WPAPSK" = "-" ]; then
			supplicant_set key_mgmt NONE
			supplicant_set psk
			supplicant_set proto
			supplicant_set pairwise
			supplicant_set group
		else
			supplicant_set key_mgmt WPA-PSK
			supplicant_set psk \"$WPAPSK\"
			supplicant_set proto RSN
			supplicant_set pairwise CCMP
			supplicant_set group CCMP
		fi
	fi
	info "Applied STA config settings to /etc/wpa_supplicant/$VAP_NAME.conf"
}

update_vap() {
	[ -z "$VAP_NAME" ] && return
	debug "Updating VAP $VAP_NAME configuration"
	if [ -z "$VAP_TYPE" ]; then
		vap_mode=$(iw dev "$VAP_NAME" info | awk '/type (managed|AP)/ {print $2}')
		[ "$vap_mode" = "AP" ] && VAP_TYPE="ap"
		[ "$vap_mode" = "managed" ] && VAP_TYPE="sta"
	fi

	if [ "$VAP_TYPE" = "ap" ]; then
		apply_hostap
	elif [ "$VAP_TYPE" = "sta" ]; then 
		if [ "$WDS_BRIDGE" = "-" ]; then
			ip link set dev "$VAP_NAME" nomaster
			iw dev "$VAP_NAME" set 4addr off
		elif [ -n "$WDS_BRIDGE" ]; then
			iw dev "$VAP_NAME" set 4addr on
			if [ -d /sys/class/net/"$WDS_BRIDGE"/bridge ]; then
				ip link set dev "$VAP_NAME" master "$WDS_BRIDGE"
			fi
		fi
		apply_supplicant
	fi

	info "Updated $VAP_NAME VAP configuration"
}

teardown_vap() {
	ip link set dev "$VAP_NAME" down
	iw dev "$VAP_NAME" del
	info "Removed $VAP_NAME VAP"
	unset VAP_NAME
}

purge_radio() {
	[ -d /sys/class/ieee80211/"$PHY_NAME"/device/net/ ] || return
	for iface in /sys/class/ieee80211/"$PHY_NAME"/device/net/*; do
		VAP_NAME="$(basename $iface)"
		teardown_vap
	done
	info "Purged $RADIO VAPs"
}

setup_vap() {
	debug "Setting up $VAP_TYPE mode VAP $VAP_NAME"
	[ "$VAP_TYPE" = "ap" ] && iw_vap_type="__ap"
	[ "$VAP_TYPE" = "sta" ] && iw_vap_type="station"

	if [ -d /sys/class/net/"$VAP_NAME"/wireless ]; then
		iw dev "$VAP_NAME" set type "$iw_vap_type"
	else
		iw phy "$PHY_NAME" interface add "$VAP_NAME" type "$iw_vap_type"
	fi

	[ "$VAP_TYPE" = "ap" ] && init_hostap
	[ "$VAP_TYPE" = "sta" ] && init_supplicant
	info "Set up $VAP_TYPE mode VAP $VAP_NAME"
}

setup_txpower() {
	iw phy "$PHY_NAME" set txpower limit $((TXPOWER*100))
}

setup_band() {
	[ "$PHY_DRIVER" = "ath11k" ] || return
	read -r BDF_VARIANT < /sys/module/ath11k/parameters/bdf_variant
	[ "$BAND" = "$BDF_VARIANT" ] && return
	echo "options ath11k bdf_variant=$BAND" > /etc/modprobe.d/ath11k-bdf.conf
	echo "$BAND" > /sys/module/ath11k/parameters/bdf_variant
	rmmod ath11k_pci
	modprobe ath11k_pci
	info "Changed radio to $BAND GHz band"
}

parse_radio() {
	radio_dev=$(grep "$RADIO" "$RADIOS_CONFIG" | cut -d '=' -f2)
	[ -z "$radio_dev" ] && help "no such radio found: $RADIO"
	for phy in /sys/class/ieee80211/*; do
		phy_dev=$(readlink -nf "$phy/device")
		if [ "$phy_dev" = "$radio_dev" ]; then
			PHY_NAME=$(basename "$phy")
			PHY_DRIVER=$(readlink -f "$phy/device/driver" | grep -o "ath[0-9]\+k")
			return
		fi
	done
	help "Error: cannot find phy based on radio definition"
}

parse_vap() {
	[ -f /sys/class/net/"$VAP_NAME"/phy80211/name ] || help "Error: iface not part of VAP"
	PHY_NAME=$(cat /sys/class/net/"$VAP_NAME"/phy80211/name)
	PHY_DRIVER=$(readlink -f /sys/class/net/"$VAP_NAME"/phy80211/device/driver | grep -o "ath[0-9]\+k")
}

parse_args() {
	set -- $ARGS
	if [ "$1" = "help" ] || [ "$1" = "-h" ]; then
		HELP=1
	elif expr "$1" : 'radio[0-9]\+' >/dev/null; then
		RADIO="$1"
		parse_radio
		shift
	elif [ -d "/sys/class/net/$1/wireless" ]; then
		VAP_NAME="$1"
		parse_vap
		shift
	else
		help "Unknown argument: '$1'"
	fi
	while [ -n "$1" ]; do
		case "$1" in
			del)
				VAP_DEL=1
				;;
			purge)
				RADIO_PURGE=1
				;;
			init-ap)
				VAP_NAME="$2"
				VAP_TYPE=ap
				VAP_ADD=1
				shift
				;;
			init-sta)
				VAP_NAME="$2"
				VAP_TYPE=sta
				VAP_ADD=1
				shift
				;;
			ssid)
				SSID="$2"
				shift
				;;
			pass)
				WPAPSK="$2"
				shift
				;;
			wds-bridge)
				[ "$2" = "no" ] && WDS_BRIDGE=- || WDS_BRIDGE=$2
				shift
				;;
			txpower)
				TXPOWER=$2
				shift
				;;
			channel)
				[ "$2" -eq "$2" ] 2>/dev/null || help "Invalid channel/frequency: $2"
				CHANNEL=$2
				shift
				;;
			country)
				[ "${#2}" -ne 2 ] && help "Invalid country code: $2"
				COUNTRY=$2
				shift
				;;
			freq)
				if [ "$2" != "no" ] && ! echo "$2" | grep -qe "^[0-9]"; then
					help "Invalid frequency list: $2"
				fi
				[ "$2" = "no" ] && FREQLIST=- || FREQLIST=$2
				shift
				;;
			chwidth)
				[ "$2" -eq 160 ] ||
				[ "$2" -eq 80 ] ||
				[ "$2" -eq 40 ] ||
				[ "$2" -eq 20 ] ||
					help "Invalid channel width: $2"
				CHWIDTH=$2
				shift
				;;
			band)
				[ "$2" -ne "2" ] && [ "$2" -ne "5" ] && help "Invalid band: $2"
				BAND=$2
				shift
				;;
			hidden)
				HIDE=1
				;;
			*)
				help "Unknown option: '$1'"
				;;
		esac
		shift
	done
}

help() {
	[ -n "$*" ] && {
		echo $* >&2
		echo
	}
	echo "Usage: $0 <radio*|vap name> <command> ..."
	echo
	echo "Radio-only commands:"
	echo -e "\t<radio*> init-ap <vap name>"
	echo -e "\t<radio*> init-sta <vap name>"
	echo -e "\t<radio*> purge"
	echo "VAP-specific commands:"
	echo -e "\t<vap name> del"
	echo "Generic commands:"
	echo -e "\tssid <ssid>"
	echo -e "\tpass <passphrase>"
	echo -e "\ttxpower <dbm>"
	echo -e "\tchannel <channel|frequency>"
	echo -e "\twds-bridge <no|bridge iface>"
	echo -e "\tfreq <no|frequency-list>"
	echo -e "\tchwidth <20|40|80|160>"
	echo -e "\tband <2|5>"
	echo -e "\thidden"
	[ -n "$*" ] && exit 1 || exit 0
}

ARGS="$*"
parse_args

[ -n "$HELP" ] && help
[ -n "$RADIO_PURGE" ] && purge_radio
[ -n "$BAND" ] && setup_band
[ -n "$TXPOWER" ] && setup_txpower
[ -n "$VAP_DEL" ] && teardown_vap
[ -n "$VAP_ADD" ] && setup_vap && init_vap_defaults
update_vap
