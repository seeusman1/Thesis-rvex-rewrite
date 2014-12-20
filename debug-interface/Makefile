#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
SRCDIR = src

# Include default configuration.
include $(SRCDIR)/default-configuration.cfg

# Try to include user configuration.
-include configuration.cfg

#------------------------------------------------------------------------------
# Environment setup
#------------------------------------------------------------------------------

# Netcat is used for a number of commands.
NETCAT = nc

# Directory containins the rvdbg binary and compilation outputs (ignored by
# git).
BINDIR = bin

.PHONY: help server stop catlog monitor debug

help: configuration.cfg
	@cat USAGE

server: configuration.cfg $(BINDIR)/rvsrv
	$(BINDIR)/rvsrv -p$(SERIAL_PORT) -b$(SERIAL_BAUD) -a$(TCP_PORT_APP) -d$(TCP_PORT_DEBUG)

stop:
	echo "Stop;" | $(NETCAT) localhost $(TCP_PORT_DEBUG)

catlog:
	@cat /var/tmp/rvsrv.log

monitor: configuration.cfg
	@echo "Connecting you to the rvex now, ctrl+c to exit. If you get an error, the server is probably not running."; $(NETCAT) localhost $(TCP_PORT_APP)

debug: configuration.cfg
	@echo "alias rvd=\"$(shell pwd)/$(BINDIR)/rvdbg -d$(TCP_PORT_DEBUG)\"" > debug 
	@echo "echo You should now be able to use call rvd \<command\>. Run rvd help for a command listing." > debug 
	@echo Run source debug now...

# This copies over the default configuration file to the system-specific,
# git-ignored config file.
configuration.cfg:
	cp -i $(SRCDIR)/default-configuration.cfg configuration.cfg

#------------------------------------------------------------------------------
# Tool compilation targets
#------------------------------------------------------------------------------
CC = gcc
CFLAGS = -g
TOOLS = rvsrv

.PHONY: all clean

all: $(BINDIR)/rvsrv $(BINDIR)/rvdbg

$(BINDIR)/rvsrv: $(BINDIR) $(SRCDIR)/rvsrv/*.c
	$(CC) $(CFLAGS) -o $@ $(SRCDIR)/rvsrv/*.c

$(BINDIR)/rvdbg: $(BINDIR) $(SRCDIR)/rvdbg/*.c
	$(CC) $(CFLAGS) -o $@ $(SRCDIR)/rvdbg/*.c

clean:
	rm -rf $(BINDIR)
	rm -f debug

bin:
	mkdir bin
