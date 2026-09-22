LED_CONF="/etc/board-led.conf"
led_root="/sys/class/leds"

LED_STATE_ROOT="/run/leds"
CURR_STATE_FILE="$LED_STATE_ROOT/current_leds_state"
PREV_STATE_FILE="$LED_STATE_ROOT/previous_leds_state"

led_get() {
	[ -z "$1" ] && return 1
	led_name=$(grep "$1" "$LED_CONF" | cut -d '=' -f1)
	[ -z "$led_name" ] && return 1
	led_path="$led_root/$led_name"
	[ -d "$led_path" ] || return 1
	echo "$led_path"
}

led_blink() {
	led=$(led_get "$1")
	[ -n "$led" ] || return

        [ -w "$led/trigger" ] && echo "timer" > "$led/trigger"
        echo 1 > "$led/brightness" 2>/dev/null
        echo "$2" > "$led/delay_on" 2>/dev/null
        echo "$2" > "$led/delay_off" 2>/dev/null
}

led_on() {
	led=$(led_get "$1")
	[ -n "$led" ] || return

	[ -w "$led/trigger" ] && echo "none" > "$led/trigger"
	echo 1 > "$led/brightness" 2>/dev/null
}

led_off() {
	led=$(led_get "$1")
	[ -n "$led" ] || return
	
	[ -w "$led/trigger" ] && echo "none" > "$led/trigger"
	echo 0 > "$led/brightness" 2>/dev/null
}

save_led_state() {
	mkdir -p "$LED_STATE_ROOT"
	mv "$CURR_STATE_FILE" "$PREV_STATE_FILE" 2>/dev/null
	tmp_state_file=$(mktemp)
	echo "$1" > "$tmp_state_file"
	mv "$tmp_state_file" "$CURR_STATE_FILE"
}

leds() {
	if [ -z "$1" ]; then
		return 1
	fi
	if [ "$1" != "restore" ]; then
		save_led_state "$1"
	fi

	# One RGB indicator, no blinking: every state maps onto a solid colour, so
	# the timer trigger is never used.
	case "$1" in
		config-activity|config|upgrade-activity)
			led_off ready
			led_off fault
			led_on config
			;;
		factory-reset)
			led_off config
			led_off ready
			led_on fault
			;;
		normal)
			led_off config
			led_off fault
			led_on ready
			;;
		restore)
			prev_state=$(cat "$PREV_STATE_FILE")
			[ -z "$prev_state" ] || leds "$prev_state"
			;;
	esac
}
