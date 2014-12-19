#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

# Serial port configuration.
SERIAL_PORT = /dev/ttyS0
SERIAL_BAUD = 115200

# TCP port configuration. rvdbg uses these TCP ports to allow multiple
# applications to access the rvex platform at the same time.
TCP_PORT_APP = 21078
TCP_PORT_DEBUG = 21079

# No need to change anything below here unless you're working on the tools.

#------------------------------------------------------------------------------
# Environment setup
#------------------------------------------------------------------------------

# Directory containins the rvdbg binary and compilation outputs (ignored by
# git).
BINDIR = bin

.PHONY: help server stop catlog monitor debug

help:
	cat USAGE

server: $(BINDIR)/rvsrv
	$(BINDIR)/rvsrv -p$(SERIAL_PORT) -b$(SERIAL_BAUD) -a$(TCP_PORT_APP) -d$(TCP_PORT_DEBUG)

stop:
	echo "Stop;" | nc localhost $(TCP_PORT_DEBUG)

catlog:
	cat /var/tmp/rvsrv.log

monitor: $(BINDIR)/rvmon
	$(BINDIR)/rvmon -a$(TCP_PORT_APP)

debug: $(BINDIR)/rvdbg
	echo "alias rvd=\"$(shell pwd)/$(BINDIR)/rvdbg -d$(TCP_PORT_DEBUG)\"" > debug 

#------------------------------------------------------------------------------
# Tool compilation targets
#------------------------------------------------------------------------------
CC = gcc
CFLAGS = -g
SRCDIR = src
TOOLS = rvsrv

.PHONY: all clean

all: $(BINDIR)/rvsrv $(BINDIR)/rvdbg $(BINDIR)/rvmon

$(BINDIR)/rvsrv: $(BINDIR) $(SRCDIR)/rvsrv/*.c
	$(CC) $(CFLAGS) -o $@ $(SRCDIR)/rvsrv/*.c

$(BINDIR)/rvdbg: $(BINDIR) $(SRCDIR)/rvdbg/*.c
	$(CC) $(CFLAGS) -o $@ $(SRCDIR)/rvdbg/*.c

$(BINDIR)/rvmon: $(BINDIR) $(SRCDIR)/rvmon/*.c
	$(CC) $(CFLAGS) -o $@ $(SRCDIR)/rvmon/*.c

clean:
	rm -rf $(BINDIR)
	rm -f debug

bin:
	mkdir bin
