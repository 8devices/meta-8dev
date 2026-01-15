#!/bin/sh

# parse S/N, board ID and radio ID
boardinfo

slot_suffix=$(systemctl show-environment 2>/dev/null | grep "^SLOT_SUFFIX=" | cut -d'=' -f2)
[ -n "$DEBUG" ] && echo -n "BOOTBANK_SLOT=" || echo -n "SW partition: "
case "$slot_suffix" in
    _a) echo "A" ;;
    _b) echo "B" ;;
    *) [ -n "$DEBUG" ] echo "" || echo "Unknown" ;;
esac

if [ -f /lib/release/build ]; then
    . /lib/release/build
    [ -n "$DEBUG" ] && echo "BUILD_VERSION=${BUILD_VERSION:-N/A}" || echo "SW Version: ${BUILD_VERSION:-N/A}"
    [ -n "$DEBUG" ] && echo "BUILD_IMAGE=${BUILD_IMAGE:-N/A}" || echo "Image: ${BUILD_IMAGE:-N/A}"
    [ -n "$DEBUG" ] && echo "BUILD_DISTRO=${BUILD_DISTRO:-N/A}" || echo "Distro: ${BUILD_DISTRO:-N/A}"
    [ -n "$DEBUG" ] && echo "BUILD_MACHINE=${BUILD_MACHINE:-N/A}" || echo "Machine: ${BUILD_MACHINE:-N/A}"
elif [ -f /etc/version ]; then
    [ -n "$DEBUG" ] && echo "SW_VERSION=$(cat /etc/version)" || echo "SW Version: $(cat /etc/version)"
fi

if [ -f /lib/release/hashes ]; then
    [ -z "$DEBUG" ] && echo "Build hashes:"
    while IFS='=' read -r key value; do
        if [ -n "$key" ] && [ -n "$value" ]; then
            [ -n "$DEBUG" ] && echo "RELEASE_HASH_${key}=${value}" || echo "  $key: $value"
        fi
    done < /lib/release/hashes
fi
