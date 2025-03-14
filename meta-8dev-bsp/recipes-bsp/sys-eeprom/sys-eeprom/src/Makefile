CC ?= gcc
CFLAGS += -g -Wall
INCLUDES += -I.

SRCS := $(wildcard *.c)
OBJS := $(SRCS:.c=.o)
TARGET := sys-eeprom

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

clean:
	rm -f $(OBJS) sys-eeprom
