#!/bin/sh

set -e

dual_boot_parts=$(ls -1 /dev/disk/by-partlabel | grep _a  | sed 's/_.*//')
active_slot=$(grep -o "SLOT_SUFFIX=_[ab]" /proc/cmdline  | cut -d '=' -f2)

if [ -z "$dual_boot_parts" ] || [ -z "$active_slot" ]; then
	echo "No dual boot partitions or active slot found."
	exit 1
fi

unused_slot=$( [ "$active_slot" = "_a" ] && echo "_b" || echo "_a" )

for part in $dual_boot_parts; do
	old_slot="/dev/disk/by-partlabel/${part}${active_slot}"
	new_slot="/dev/disk/by-partlabel/${part}${unused_slot}"

	if [ ! -e "$old_slot" ] || [ ! -e "$new_slot" ]; then
		echo "Partition $old_slot or $new_slot does not exist."
		continue
	fi

	disk=$(udevadm info --query=property --name="$new_slot" | grep -i '^DEVNAME=' | cut -d= -f2 | sed 's/p[0-9]*$//')

	old_type=$(udevadm info --query=property --name="$new_slot" | awk -F= '/^ID_PART_ENTRY_TYPE=/ {print $2}')
	new_type=$(udevadm info --query=property --name="$old_slot" | awk -F= '/^ID_PART_ENTRY_TYPE=/ {print $2}')

	new_slot_id=$(udevadm info --query=property --name="$new_slot" | grep -i '^PARTN=' | cut -d= -f2)
	old_slot_id=$(udevadm info --query=property --name="$old_slot" | grep -i '^PARTN=' | cut -d= -f2)

	# Boot slot selection in the current system is controlled using GPT
	# partition attributes (specific to Qualcomm Android), as well as the
	# partition TYPE GUID. In order to update current slot, the following
	# sequence of actions should be performed:
	#
	# Updates for new slot:
	#  - priority [48:49] -> 3
	#  - active bit [50] -> true
	#  - retry count [51:53] -> 7
	#  - clear success bit [54]
	#  - clear unbooted bit [55]
	#  - update type GUID
	# Updates for old slot:
	#  - priority [48:49] -> 1
	#  - update type GUID
	sgdisk \
		--attributes=$new_slot_id:set:48 \
		--attributes=$new_slot_id:set:49 \
		--attributes=$new_slot_id:set:50 \
		--attributes=$new_slot_id:set:51 \
		--attributes=$new_slot_id:set:52 \
		--attributes=$new_slot_id:set:53 \
		--attributes=$new_slot_id:clear:54 \
		--attributes=$new_slot_id:clear:55 \
		--typecode=$new_slot_id:$new_type \
		\
		--attributes=$old_slot_id:clear:48 \
		--attributes=$old_slot_id:clear:49 \
		--attributes=$old_slot_id:set:48 \
		--typecode=$old_slot_id:$old_type \
		$disk
done
