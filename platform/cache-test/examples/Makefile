
# Toolchain setup.
TOOLS = ../../../tools
GEN_EXAMPLES = ../../../examples

# Platform-specific executables.
EXECUTABLES = 

# Platform-specific object files to link.
OBJECTS = rvex-sim.o

# Platform specific targets for help.
TARGETS = \
"make copy-<program>      selects the given program for simulation"

# Include generic examples makefile.
include $(GEN_EXAMPLES)/Makefile

# Copies the given program machine code and disassembly to the filename which
# is used by the simulation code.
.PHONY: copy-%
copy-%: %.srec %.disas
	$(CP) $(patsubst copy-%,%,$@).srec sim.srec
	$(CP) $(patsubst copy-%,%,$@).disas sim.disas

