CC = gcc
CFLAGS = -Wall -Wextra -O2
TARGET = go_installer
OBJS = main.o steps.o log.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

%.o: %.c installer.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o $(TARGET) *.exe