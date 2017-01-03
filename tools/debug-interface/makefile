#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

# Include default configuration.
include src/default-configuration.cfg

# Try to include user configuration.
-include configuration.cfg

ifeq ($(PCIE_ENABLE), 1)
	PCIE_FLAG = -P$(PCIE_CDEV)
endif

ifndef RVSRV_HOST
	RVSRV_HOST = localhost
endif

#------------------------------------------------------------------------------
# Environment setup
#------------------------------------------------------------------------------

# Netcat is used for a number of commands.
NETCAT = netcat

.PHONY: help clean server stop catlog monitor debug copyconf

help: copyconf
	@cat USAGE

clean:
	rm -rf bin
	rm -f debug

server: copyconf bin/rvsrv
	bin/rvsrv -p$(SERIAL_PORT) -b$(SERIAL_BAUD) -a$(TCP_PORT_APP) -d$(TCP_PORT_DEBUG) $(PCIE_FLAG)

server-debug: copyconf bin/rvsrv
	bin/rvsrv -p$(SERIAL_PORT) -b$(SERIAL_BAUD) -a$(TCP_PORT_APP) -d$(TCP_PORT_DEBUG) $(PCIE_FLAG) --foreground

stop: copyconf bin/rvd
	@bin/rvd -p$(TCP_PORT_DEBUG) stop

catlog:
	@cat /var/tmp/rvsrv/rvsrv-p$(TCP_PORT_DEBUG).log

monitor: copyconf
	@echo "Connecting you to the rvex now, ctrl+c to exit. If you get an error, the server is probably not running."; $(NETCAT) $(RVSRV_HOST) $(TCP_PORT_APP)

monitor-nobuf: copyconf
	@echo "Connecting you to the rvex now, ctrl+c to exit. If you get an error, the server is probably not running."; stty -echo -icanon && $(NETCAT) localhost $(TCP_PORT_APP)

debug: copyconf bin/rvd bin/rvtrace
	@echo "#!/bin/bash" > bin/rvd.sh
	@echo "$(shell pwd)/bin/rvd -h$(RVSRV_HOST) -p$(TCP_PORT_DEBUG) -m$(shell pwd)/core.map -m$(shell pwd)/memory.map \$$RVD_OPT \"\$$@\"" >> bin/rvd.sh
	@chmod +x bin/rvd.sh
	@echo "export PATH=\$$PATH:$(shell pwd)/bin" > debug
	@echo "alias rvd=\"rvd.sh\"" >> debug
	@echo "export PYTHONPATH=\$$PYTHONPATH:$(shell pwd)" >> debug
	@echo "echo You should now be able to use call rvd \<command\>. Run rvd help for a command listing." >> debug
	@echo Run source debug now...

# This copies over the default configuration files to the system-specific,
# git-ignored config file.
copyconf: configuration.cfg memory.map

configuration.cfg: src/default-configuration.cfg
	cp -i src/default-configuration.cfg configuration.cfg

memory.map: src/default-memory.map
	cp -i src/default-memory.map memory.map

#------------------------------------------------------------------------------
# Tool compilation targets
#------------------------------------------------------------------------------

include tools.makefile

