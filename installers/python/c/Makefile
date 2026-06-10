# =============================================================================
# PolyInstall — Python Installer (C variant) — Makefile
# =============================================================================

CC      ?= gcc
CFLAGS  := -std=c11 -Wall -Wextra -Wpedantic -O2
TARGET  := polyinstall_python
SRCS    := main.c steps.c log.c
OBJS    := $(SRCS:.c=.o)

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c installer.h
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET)
