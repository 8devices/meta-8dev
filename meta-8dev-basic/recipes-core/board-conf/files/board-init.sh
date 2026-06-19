#!/bin/sh
EXE_TAG="$(basename "$0")[$$]"

[ -s /etc/board ] && exit 0

eval $(DUMP=1 boardinfo 2>/dev/null)

if [ -z "$BOARD" ]; then
	logger -s -t "$EXE_TAG" -p local1.warning "unsupported board, skipping board init"
	exit 0
fi

echo "$BOARD" > /etc/board

hostname "$BOARD"
echo "$BOARD" > /etc/hostname
logger -s -t "$EXE_TAG" -p local1.info "hostname set to: $BOARD"
