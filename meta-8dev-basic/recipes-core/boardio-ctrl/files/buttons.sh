
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
		echo "Unknown button '$1'" >&2
		return 1
	}
	shift
	[ -z "$1" ] && return 1
	btnpoll -m "$*" $btn_name 2>/dev/null
}
