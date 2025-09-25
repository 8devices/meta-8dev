#!/bin/sh

serial_no=$(grep -o 'androidboot.serialno=[^ ]*' /proc/cmdline 2>/dev/null | cut -d'=' -f2)
if [ -n "$serial_no" ]; then
    echo "Serial Number: $serial_no"
fi

slot_suffix=$(systemctl show-environment 2>/dev/null | grep "^SLOT_SUFFIX=" | cut -d'=' -f2)
case "$slot_suffix" in
    _a) echo "SW partition: A" ;;
    _b) echo "SW partition: B" ;;
    *) echo "SW partition: Unknown" ;;
esac

if [ -f /lib/release/build ]; then
    . /lib/release/build
    echo "SW Version: ${BUILD_VERSION:-N/A}"
    echo "Image: ${BUILD_IMAGE:-N/A}"
    echo "Distro: ${BUILD_DISTRO:-N/A}"
    echo "Machine: ${BUILD_MACHINE:-N/A}"
elif [ -f /etc/version ]; then
    echo "SW Version: $(cat /etc/version)"
fi

if [ -f /lib/release/hashes ]; then
    echo "Build hashes:"
    while IFS='=' read -r key value; do
        if [ -n "$key" ] && [ -n "$value" ]; then
            echo "  $key: $value"
        fi
    done < /lib/release/hashes
fi
