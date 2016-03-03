
# Flags for rvsrv.
TCP_PORT_APP = 21078
TCP_PORT_DEBUG = 21079
RVSRV_FLAGS  = -p/no-serial
RVSRV_FLAGS += -a$(TCP_PORT_APP) -d$(TCP_PORT_DEBUG)
RVSRV_FLAGS += -m/dev/mem:$(ADDR)

# Memory map file flags for rvd.
MEMORY_MAP_FILES  = -m$(shell pwd)/rvex-core.map
MEMORY_MAP_FILES += -m$(shell pwd)/rvex.map
MEMORY_MAP_FILES += -m$(shell pwd)/almarvi.map

.PHONY: help clean server stop catlog debug

help:
	@cat USAGE

clean:
	find . | xargs touch
	rm -rf bin
	rm -f debug

server: bin/rvsrv
ifndef ADDR
	@echo "Please specify ADDR=<address>:<size>"
else
	bin/rvsrv $(RVSRV_FLAGS)
endif

server-debug: bin/rvsrv
ifndef ADDR
	@echo "Please specify ADDR=<address>:<size>"
else
	bin/rvsrv $(RVSRV_FLAGS) --foreground
endif

stop: bin/rvd
	@bin/rvd -p$(TCP_PORT_DEBUG) stop

catlog:
	@cat /var/tmp/rvsrv/rvsrv-p$(TCP_PORT_DEBUG).log

debug: bin/rvd bin/rvtrace
	@echo "#!/bin/bash" > bin/rvd.sh
	@echo "$(shell pwd)/bin/rvd -p$(TCP_PORT_DEBUG) $(MEMORY_MAP_FILES) \$$RVD_OPT \"\$$@\"" >> bin/rvd.sh
	@chmod +x bin/rvd.sh
	@echo "export PATH=\$$PATH:$(shell pwd)/bin" > debug
	@echo "alias rvd=\"rvd.sh\"" >> debug
	@echo "echo You should now be able to use call rvd \<command\>. Run rvd help for a command listing." >> debug
	@echo Run source debug now...

# Include tool compilation targets.
include tools.makefile

