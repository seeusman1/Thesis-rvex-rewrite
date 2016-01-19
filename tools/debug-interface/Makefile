#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
SRCDIR = src

# Include default configuration.
include $(SRCDIR)/default-configuration.cfg

# Try to include user configuration.
-include configuration.cfg

ifeq ($(PCIE_ENABLE), 1)
	PCIE_FLAG = -P$(PCIE_CDEV)
endif

#------------------------------------------------------------------------------
# Environment setup
#------------------------------------------------------------------------------

# Netcat is used for a number of commands.
NETCAT = netcat

# Directory containins the rvdbg binary and compilation outputs (ignored by
# git).
BINDIR = bin

.PHONY: help server stop catlog monitor debug copyconf

help: copyconf
	@cat USAGE

server: copyconf $(BINDIR)/rvsrv
	$(BINDIR)/rvsrv -p$(SERIAL_PORT) -b$(SERIAL_BAUD) -a$(TCP_PORT_APP) -d$(TCP_PORT_DEBUG) $(PCIE_FLAG)

server-debug: copyconf $(BINDIR)/rvsrv
	$(BINDIR)/rvsrv -p$(SERIAL_PORT) -b$(SERIAL_BAUD) -a$(TCP_PORT_APP) -d$(TCP_PORT_DEBUG) $(PCIE_FLAG) --foreground

stop: copyconf $(BINDIR)/rvd
	@$(BINDIR)/rvd -p$(TCP_PORT_DEBUG) stop

catlog:
	@cat /var/tmp/rvsrv.log

monitor: copyconf
	@echo "Connecting you to the rvex now, ctrl+c to exit. If you get an error, the server is probably not running."; $(NETCAT) localhost $(TCP_PORT_APP)

monitor-nobuf: copyconf
	@echo "Connecting you to the rvex now, ctrl+c to exit. If you get an error, the server is probably not running."; stty -echo -icanon && $(NETCAT) localhost $(TCP_PORT_APP)

debug: copyconf $(BINDIR)/rvd $(BINDIR)/rvtrace
	@echo "#!/bin/bash" > $(BINDIR)/rvd.sh
	@echo "$(shell pwd)/bin/rvd -p$(TCP_PORT_DEBUG) -m$(shell pwd)/core.map -m$(shell pwd)/memory.map \$$RVD_OPT \"\$$@\"" >> $(BINDIR)/rvd.sh
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

all: $(BINDIR)/rvsrv $(BINDIR)/rvd $(BINDIR)/rvtrace

$(BINDIR)/rvsrv: $(SRCDIR)/rvsrv/*.c $(SRCDIR)/rvsrv/pcie/*.c $(SRCDIR)/rvsrv/uart/*.c $(SRCDIR)/common/*.c
	mkdir -p $(BINDIR)
	$(CC) $(CFLAGS) -Wall -I $(SRCDIR)/common -o $@ $^

$(BINDIR)/rvd: $(SRCDIR)/rvd/*.c $(SRCDIR)/rvd/gdb/*.c $(SRCDIR)/rvd/commands/*.c $(SRCDIR)/common/*.c
	mkdir -p $(BINDIR)
	$(CC) $(CFLAGS) -Wall -I $(SRCDIR)/rvd -I $(SRCDIR)/common -o $@ $^

$(BINDIR)/rvtrace: $(SRCDIR)/rvtrace/*.c $(SRCDIR)/common/*.c
	mkdir -p $(BINDIR)
	$(CC) $(CFLAGS) -Wall -I $(SRCDIR)/common -o $@ $^

clean:
	rm -rf $(BINDIR)
	rm -f debug
