/*
 * Copyright (C) 2024 8devices UAB
 */

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <linux/input.h>
#include <libevdev/libevdev.h>

#define EVENT_PATH "/dev/input"
#ifndef EVENT_DEVICE
#define EVENT_DEVICE "gpio-keys"
#endif

static int verbose;

int open_input(int flags)
{
	struct dirent *entry;
	DIR *dp;
	int fd;
	char name[256];

	dp = opendir(EVENT_PATH);
	if (dp == NULL) {
		perror("Failed to open input directory");
		return -1;
	}

	while ((entry = readdir(dp))) {
		if (strncmp(entry->d_name, "event", 5))
			continue;

		fd = openat(dirfd(dp), entry->d_name, flags);
		if (fd < 0)
			continue;

		if (ioctl(fd, EVIOCGNAME(sizeof(name)), name) < 0) {
			perror("Failed to get device name");
			close(fd);
			fd = -1;
			continue;
		}

		if (!strcmp(name, EVENT_DEVICE))
			break;

		close(fd);
		fd = -1;
	}

	closedir(dp);
	return fd;
}

void execute(const char *command, const char *state)
{
	pid_t pid;

	pid = fork();
	if (pid == 0) {
		execlp(command, command, state, (char *)NULL);
		perror("exec() failed");
		exit(EXIT_FAILURE);
	} else if (pid > 0) {
		waitpid(pid, NULL, 0);
	} else {
		perror("fork() failed");
	}
}

void button_key_monitor(struct libevdev *dev, int key_code, const char *command)
{
	struct input_event ev;
	const char *state;
	int rv;

	while (1) {
		rv = libevdev_next_event(dev, LIBEVDEV_READ_FLAG_BLOCKING, &ev);
		if (rv == -EAGAIN) {
			continue;
		} else if (rv) {
			fprintf(stderr, "Error reading event: %s\n", strerror(-rv));
			break;
		}

		if (ev.type == EV_KEY && ev.code == key_code) {
			state = ev.value == 1 ? "pressed" : "released";
			if (verbose)
				printf("%s\n", state);
			execute(command, state);
		}
	}
}

int button_key_state(struct libevdev *dev, int key_code)
{
	int key_state;

	libevdev_fetch_event_value(dev, EV_KEY, key_code, &key_state);

	return key_state;
}

void help(const char *exec, int fail)
{
	fprintf(fail ? stderr : stdout, "Usage: %s [-e|-d|-m <command>] <KEY>\n", exec);
	exit(fail ? EXIT_FAILURE : EXIT_SUCCESS);
}

int main(int argc, char *argv[])
{
	struct libevdev *dev = NULL;
	const char *key_name;
	const char *mon_handler = NULL;
	int chk_active = 0;
	int key_code, key_state;
	int fd, rv, opt;

	while (1) {
		opt = getopt(argc, argv, "hvedm:");
		if (opt == -1)
			break;

		switch (opt)
		{
		case 'e':
			chk_active = 1;
			break;
		case 'd':
			chk_active = -1;
			break;
		case 'm':
			mon_handler = optarg;
			break;
		case 'v':
			verbose = 1;
			break;
		default:
			help(argv[0], opt != 'h');
		}
	}

	if (!optind || optind >= argc) {
		fprintf(stderr, "Missing KEY name\n");
		help(argv[0], 1);
	}
	key_name = argv[optind];

	fd = open_input(O_RDONLY);
	if (fd < 0) {
		fprintf(stderr, "Cannot access '%s' input event device\n", EVENT_DEVICE);
		exit(EXIT_FAILURE);
	}

	rv = libevdev_new_from_fd(fd, &dev);
	if (rv < 0) {
		fprintf(stderr, "Failed to initialize libevdev: %s\n", strerror(-rv));
		goto exit;
	}

	key_code = libevdev_event_code_from_name(EV_KEY, key_name);
	if (key_code == -1) {
		fprintf(stderr, "Unknown key name: %s\n", key_name);
		rv = -1;
		goto exit;
	}

	if (!libevdev_has_event_type(dev, EV_KEY) || !libevdev_has_event_code(dev, EV_KEY, key_code)) {
		fprintf(stderr, "Unsupported event for key: %s\n", key_name);
		rv = -1;
		goto exit;
	}

	if (mon_handler) {
		button_key_monitor(dev, key_code, mon_handler);
	} else {
		key_state = button_key_state(dev, key_code);
		if (chk_active > 0)
			rv = key_state != 1;
		else if (chk_active < 0)
			rv = key_state != 0;
		if (!chk_active || verbose)
			printf("%s\n", key_state ? "pressed" : "released");
	}
exit:
	if (dev)
		libevdev_free(dev);
	close(fd);

	return rv;
}
