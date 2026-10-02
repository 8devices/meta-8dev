#!/bin/sh
# Switch to the other SW partition (A/B slot) and boot it; -n skips the
# reboot, -nn only prints what would change.

set -e

usage() {
	echo "usage: swchange [-n|-nn]" >&2
	exit 1
}

n=0
while getopts n opt; do
	case "$opt" in
	n) n=$((n + 1)) ;;
	*) usage ;;
	esac
done
shift $((OPTIND - 1))
[ $# -eq 0 ] || usage

case "$(qbootctl -c)" in
*_a) from=A to=B ;;
*_b) from=B to=A ;;
*) echo "swchange: cannot determine current slot" >&2; exit 1 ;;
esac

if [ "$n" -ge 2 ]; then
	echo "SW partition: $from -> $to (dry run, nothing changed)"
	exit 0
fi

qbootctl -s "$to"

if [ "$n" -eq 1 ]; then
	echo "SW partition: $from -> $to on next boot"
	exit 0
fi

echo "SW partition: $from -> $to, rebooting"
reboot
