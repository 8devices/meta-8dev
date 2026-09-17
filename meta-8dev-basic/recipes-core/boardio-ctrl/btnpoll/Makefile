.PHONY: all clean

CFLAGS += $(shell pkg-config --cflags libevdev)
LDFLAGS += $(shell pkg-config --libs libevdev)

ifneq ($(CONFIG_EVENT_DEVICE),)
	CFLAGS += -DEVENT_DEVICE=\"$(CONFIG_EVENT_DEVICE)\"
endif

all: btnpoll

btnpoll: btnpoll.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

clean:
	rm -f btnpoll
