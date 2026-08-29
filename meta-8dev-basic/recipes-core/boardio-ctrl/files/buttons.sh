
BUTTONS_CONF=/etc/board-btn.conf

btn_get() {
	[ -z "$1" ] && return
	grep -m1 "^[^#]*=$1\$" $BUTTONS_CONF 2>/dev/null | cut -d '=' -f 1
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
	[ -n "$btn_name" ] || return 0
	shift
	[ -z "$1" ] && return 1
	# One machine can ship several board revisions, so the map names the role
	# and the running board decides whether the key exists. Ask for its state
	# first: that fails when the key is not wired here, which is nothing to
	# track. Failures after that are real and must reach the service manager.
	btnpoll $btn_name >/dev/null 2>&1 || return 0
	btnpoll -m "$*" $btn_name 2>/dev/null
}
