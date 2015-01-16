
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
"make copy-<program>      registers program files for simulation"\

# Additional things to clean.
CLEAN = 

# Include generic examples makefile.
include $(GEN_EXAMPLES)/Makefile

# How to upload;
.PHONY: upload-% upload-all
upload-%: %.srec debug
	-cd $(DEBUGIFACE) && make server
	$(RVD) -call -d"all:PRINT_STATE{1}" break
	$(RVD) -c0 upload srec $< 0
	$(RVD) -c0 exec RESET_ALL

upload-all: $(patsubst %,upload-%,$(EXECUTABLES))

.PHONY: debug server stop monitor
debug server stop monitor:
	cd $(DEBUGIFACE) && make $@

# Copies the given program machine code and disassembly to init* indicating
# which program was used for synthesis/simulation and creates the VHDL file
# containing memory initialization information.
.PHONY: copy-%
copy-%: %.srec %.disas tools/b2v
	$(CP) $(patsubst copy-%,%,$@).srec init.srec
	$(CP) $(patsubst copy-%,%,$@).disas init.disas
	$(RM) ../work/ram.srec
	$(CP) init.srec ../work/ram.srec

