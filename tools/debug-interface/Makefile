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

.PHONY: help server stop catlog monitor debug copyconf

help: copyconf
	@cat USAGE

server: copyconf $(BINDIR)/rvsrv
	$(BINDIR)/rvsrv -p$(SERIAL_PORT) -b$(SERIAL_BAUD) -a$(TCP_PORT_APP) -d$(TCP_PORT_DEBUG)

server-debug: copyconf $(BINDIR)/rvsrv
	$(BINDIR)/rvsrv -p$(SERIAL_PORT) -b$(SERIAL_BAUD) -a$(TCP_PORT_APP) -d$(TCP_PORT_DEBUG) --foreground

stop: copyconf $(BINDIR)/rvd
	@$(BINDIR)/rvd -p$(TCP_PORT_DEBUG) stop

catlog:
	@cat /var/tmp/rvsrv.log

monitor: copyconf
	@echo "Connecting you to the rvex now, ctrl+c to exit. If you get an error, the server is probably not running."; $(NETCAT) localhost $(TCP_PORT_APP)

debug: copyconf $(BINDIR)/rvd
	@echo "#!/bin/bash" > $(BINDIR)/rvd.sh
	@echo "$(shell pwd)/bin/rvd -p$(TCP_PORT_DEBUG) -m$(shell pwd)/memory.map \"\$$@\"" >> $(BINDIR)/rvd.sh
	@chmod +x $(BINDIR)/rvd.sh
	@echo "export PATH=\$$PATH:$(shell pwd)/$(BINDIR)" > debug
	@echo "alias rvd=\"rvd.sh\"" >> debug
	@echo "echo You should now be able to use call rvd \<command\>. Run rvd help for a command listing." >> debug
	@echo Run source debug now...

# This copies over the default configuration files to the system-specific,
# git-ignored config file.
copyconf: configuration.cfg memory.map

configuration.cfg: $(SRCDIR)/default-configuration.cfg
	cp -i $(SRCDIR)/default-configuration.cfg configuration.cfg

memory.map: $(SRCDIR)/default-memory.map
	cp -i $(SRCDIR)/default-memory.map memory.map

#------------------------------------------------------------------------------
# Tool compilation targets
#------------------------------------------------------------------------------
CC = gcc
CFLAGS = -g
TOOLS = rvsrv rvd

.PHONY: all clean

all: $(BINDIR)/rvsrv $(BINDIR)/rvd

$(BINDIR)/rvsrv: $(SRCDIR)/rvsrv/*.c
	mkdir -p $(BINDIR)
	$(CC) $(CFLAGS) -o $@ $(SRCDIR)/rvsrv/*.c

$(BINDIR)/rvd: $(SRCDIR)/rvd/*.c
	mkdir -p $(BINDIR)
	$(CC) $(CFLAGS) -o $@ $(SRCDIR)/rvd/*.c

clean:
	rm -rf $(BINDIR)
	rm -f debug
