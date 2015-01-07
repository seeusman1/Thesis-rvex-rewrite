
# Toolchain setup.
TOOLS = ../../../tools
GEN_EXAMPLES = ../../../examples
DEBUGIFACE = $(TOOLS)/debug-interface
RVD = $(DEBUGIFACE)/bin/rvd.sh

# Platform-specific executables.
EXECUTABLES = timer

# Platform-specific object files to link.
OBJECTS = rvex-standalone.o

# Platform specific targets for help.
TARGETS = \
"make upload-<program>    uploads program to platform using rvd"

# Include generic examples makefile.
include $(GEN_EXAMPLES)/Makefile

# How to upload; (this requires make debug; source debug in debug-interface)
.PHONY: %-upload
upload-%: %.srec $(RVD)
	-cd $(DEBUGIFACE) && make server
	$(RVD) -call break
	$(RVD) -c0 upload srec $< _IMEM
	$(RVD) -c0 upload srec $< _DMEM
	$(RVD) -call reset

$(RVD):
	cd $(DEBUGIFACE) && make debug

