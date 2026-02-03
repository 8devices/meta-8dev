#!/usr/bin/python
# pylint: disable=missing-module-docstring, missing-function-docstring, line-too-long, invalid-name, too-many-branches

import sys
import os
import time
import re
import argparse
import subprocess

board_partitions = {}

# Default filenames (relative to script directory)
DEFAULT_BOOT_FILE = 'kernel.img'
DEFAULT_SYSTEM_FILE = 'rootfs.img'


def print_head(msg):
    print("")
    print("=" * 64)
    print(msg)
    print("=" * 64)


def print_debug(msg):
    print(msg)


def print_info(msg):
    print(msg)


def print_warn(msg):
    print(msg)


def print_error(msg):
    sys.stderr.write("\033[31m{}\033[0m\n".format(msg))


def fail(msg):
    print_error("")
    print_error("=" * 64)
    print_error(msg)
    print_error("=" * 64)
    sys.exit(1)


def die(msg):
    sys.stderr.write("{}\n".format(msg))
    sys.exit(1)


def adb_reboot(serial=None):
    command = ['adb']
    if serial:
        command.extend(['-s', serial])
    command.extend(['reboot', 'bootloader'])
    subprocess.Popen(command, stdout=subprocess.PIPE)


def device_parse(output):
    result = {}
    for line in output.strip().split('\n'):
        item = re.match(r'([0-9A-Fa-f]+)\s*(\w+)', line)
        if item:
            result[item.group(1)] = item.group(2)
    return result


def device_verify(devices, serial, state):
    lstate = 'adb' if state == 'device' else state
    if not devices:
        return False
    elif serial and serial not in devices:
        return False
    elif not serial and len(devices) > 1:
        print_warn("Ambiguous state, multiple {} devices: {}".format(lstate, ','.join(devices.keys())))
        return False

    if not serial:
        serial = list(devices.keys())[0]

    if devices[serial] != state:
        print_info("Unknown state '{}' for device: {}".format(devices[serial], serial))
        return False
    return True


def adb_device(serial=None):
    try:
        result = subprocess.Popen(['adb', 'devices'], stdout=subprocess.PIPE).stdout.read().decode()
    except:
        die("ADB is not installed. Please install adb utilities and add to system path.")

    return device_verify(device_parse(result), serial, 'device')


def fastboot_device(serial=None):
    try:
        result = subprocess.Popen(['fastboot', 'devices'], stdout=subprocess.PIPE).stdout.read().decode()
    except:
        die("Fastboot is not installed. Please install fastboot utilities and add to system path.")

    return device_verify(device_parse(result), serial, 'fastboot')


def fastboot_reboot(serial=None):
    command = ['fastboot']
    if serial:
        command.extend(['-s', serial])
    command.extend(['reboot'])
    subprocess.Popen(command, stdout=subprocess.PIPE)


def fastboot_enter(serial=None):
    print_debug("Checking device state...")
    retry_count = 0
    start_time = time.time()
    while True:
        if fastboot_device(serial):
            print_info("FASTBOOT device found.")
            return

        cur_time = time.time()
        if adb_device(serial):
            print_info("ADB device found, rebooting to FASTBOOT mode.")
            adb_reboot(serial)
            retry_count = 0
            start_time = cur_time

        if cur_time - start_time > 120:
            die("Device not found. Ensure USB is connected and device ADB services are running.")
        if cur_time - start_time > 10:
            print_info("Device wait, retry attempt {}".format(retry_count))
            time.sleep(9)
        time.sleep(1)
        retry_count += 1


def fastboot_run(arguments, serial=None):
    command = ['fastboot']
    if serial:
        command.extend(['-s', serial])
    command.extend(arguments)
    print_debug("< {}".format(" ".join(command)))
    result = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT).stdout.read().decode()
    for line in result.split('\n'):
        print_debug("> {}".format(line))
    return result


def fastboot_action(arguments, ok_count=2, serial=None):
    result = fastboot_run(arguments, serial)
    if result.count("OKAY") < ok_count:
        fail("FLASHING FAILED!")
    if result.count("FAILED") > 0:
        fail("FLASHING FAILED!")


def fastboot_erase(partition, serial=None):
    print_info("Erasing {}".format(partition))
    fastboot_action(['erase', partition], ok_count=1, serial=serial)
    print_info("Complete")


def fastboot_flash(partition, file_path, serial=None):
    print_info("Flashing {}".format(partition))
    fastboot_action(['flash', partition, file_path], serial=serial)
    print_info("Complete")


def fastboot_fetch(serial=None):
    if not board_partitions:
        output = fastboot_run(['getvar', 'all'], serial=serial)
        parts = re.findall(r'partition-type:(\w+):(\w+)', output or '')
        for part_name, part_type in parts:
            part_match = re.match(r'(\w+)(_a|_b)', part_name)
            part_real = part_match.group(1) if part_match else part_name
            board_partitions[part_real] = {
                'type': part_type,
                'dual': True if part_match else False,
            }
    return board_partitions


def check_partitions(partitions, artifacts):
    for part_name in sorted(artifacts.keys()):
        file_name = artifacts[part_name]
        print(" {} | {:<10} | {} ".format('Y' if part_name in partitions else 'N', part_name, file_name))


def flash_parts(artifacts, serial=None):
    parts = fastboot_fetch(serial)
    print_head("Flashing partitions")
    check_partitions(parts, artifacts)
    for part_name, part_file in artifacts.items():
        if part_name not in parts:
            continue

        fastboot_flash(part_name, part_file, serial)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('serial', nargs='?', type=str,
                        help="device serial number")
    parser.add_argument('-s', '--stay', dest='stay', action='store_true',
                        help="stay / do not reboot after operation")
    group_parts = parser.add_argument_group('flash partitions')
    group_parts.add_argument('--boot', '--linux', dest='boot',
                        help="linux boot image file")
    group_parts.add_argument('--system', '--rootfs', dest='system',
                        help="system rootfs image file ")
    args = parser.parse_args()

    this_dir = os.path.dirname(os.path.realpath(__file__))

    artifacts = {}

    if args.boot:
        if not os.path.exists(args.boot):
            die(f"Cannot find boot image file: {args.boot}")
        artifacts['boot'] = args.boot
    else:
        default_boot = os.path.join(this_dir, DEFAULT_BOOT_FILE)
        if os.path.exists(default_boot):
            artifacts['boot'] = default_boot

    if args.system:
        if not os.path.exists(args.system):
            die(f"Cannot find system image file: {args.system}")
        artifacts['system'] = args.system
    else:
        default_system = os.path.join(this_dir, DEFAULT_SYSTEM_FILE)
        if os.path.exists(default_system):
            artifacts['system'] = default_system

    if not artifacts:
        die(f"Nothing to do")

    fastboot_enter(args.serial)

    flash_parts(artifacts, args.serial)

    if not args.stay:
        fastboot_reboot(args.serial)
