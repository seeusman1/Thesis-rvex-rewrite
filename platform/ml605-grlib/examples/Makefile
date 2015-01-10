
# Toolchain setup.
TOOLS = ../../../tools
GEN_EXAMPLES = ../../../examples
DEBUGIFACE = $(TOOLS)/debug-interface
RVD = $(DEBUGIFACE)/bin/rvd.sh

# Platform-specific executables.
EXECUTABLES = 

# Platform-specific object files to link.
OBJECTS = rvex-grlib.o

# Platform specific targets for help.
TARGETS = \
"make upload-<program>    uploads program to platform using rvd"\
"make copy-<program>      registers program for simulation"

# Additional things to clean.
CLEAN = 

# Include generic examples makefile.
include $(GEN_EXAMPLES)/Makefile

# How to upload; (this requires make debug; source debug in debug-interface)
.PHONY: upload-%
upload-%: %.srec $(RVD)
	-cd $(DEBUGIFACE) && make server
	$(RVD) -call break
	$(RVD) -c0 upload srec $< 0
	$(RVD) -call reset

$(RVD):
	cd $(DEBUGIFACE) && make debug

# Copies the given program machine code and disassembly to init* indicating
# which program was used for simulation. Also copy it into the grlib project.
.PHONY: copy-%
copy-%: %.srec %.disas
	$(CP) $(patsubst copy-%,%,$@).srec init.srec
	$(CP) $(patsubst copy-%,%,$@).disas init.disas
	$(RM) ../work/ram.srec
	$(CP) init.srec ../work/ram.srec

