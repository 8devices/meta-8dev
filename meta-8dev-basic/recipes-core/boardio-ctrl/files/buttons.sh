
BUTTONS_CONF=/etc/board-btn.conf

btn_get() {
	[ -z "$1" ] && return
	grep "$1" $BUTTONS_CONF | cut -d '=' -f 1
}

btn_state() {
	[ -z "$1" ] && return 1
	btn_name=`btn_get $1`
	[ -n "$btn_name" ] || {
		echo "Unknown button '$1'" >&2
		return 1
	}
	[ "$2" = "off" ] && opt=-d || opt=-e
	btnpoll $opt $btn_name 2>/dev/null
}

btn_pressed() {
	btn_state $1 on
}

btn_released() {
	btn_state $1 off
}

btn_track() {
	btn_name=`btn_get $1`
	[ -n "$btn_name" ] || {
		# Unlisted means the board has no such button. Failing here would spin
		# the Restart=on-failure tracker on every buttonless board.
		echo "No '$1' button on this board, not tracking" >&2
		return 0
	}
	shift
	[ -z "$1" ] && return 1
	btnpoll -m "$*" $btn_name 2>/dev/null
}
