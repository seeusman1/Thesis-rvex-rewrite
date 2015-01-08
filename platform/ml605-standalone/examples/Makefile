
# Toolchain setup.
TOOLS = ../../../tools
GEN_EXAMPLES = ../../../examples
DEBUGIFACE = $(TOOLS)/debug-interface
RVD = $(DEBUGIFACE)/bin/rvd.sh
HOSTCC = gcc

# Platform-specific executables.
EXECUTABLES = timer

# Platform-specific object files to link.
OBJECTS = rvex-standalone.o

# Platform specific targets for help.
TARGETS = \
"make upload-<program>    uploads program to platform using rvd"

# Additional things to clean.
CLEAN = *.bin tools/b2v ../design/mem_init_pkg.vhd

# Include generic examples makefile.
include $(GEN_EXAMPLES)/Makefile

# How to upload; (this requires make debug; source debug in debug-interface)
.PHONY: upload-%
upload-%: %.srec $(RVD)
	-cd $(DEBUGIFACE) && make server
	$(RVD) -call break
	$(RVD) -c0 upload srec $< _IMEM
	$(RVD) -c0 upload srec $< _DMEM
	$(RVD) -call reset

$(RVD):
	cd $(DEBUGIFACE) && make debug

# Copies the given program machine code and disassembly to init* indicating
# which program was used for synthesis/simulation and creates the VHDL file
# containing memory initialization information.
.PHONY: copy-%
copy-%: %.srec %.disas tools/b2v
	$(CP) $(patsubst copy-%,%,$@).srec init.srec
	$(CP) $(patsubst copy-%,%,$@).disas init.disas
	$(OBJCOPY) -I srec -O binary init.srec init.bin
	tools/b2v init.bin mem_init_pkg MEM_INIT > ../design/mem_init_pkg.vhd

# Instead of synthesizing/simulating with a program in the memory, initialize
# the memory with all zeros. Decreases static elaboration time by a great deal.
.PHONY: copy-none
copy-none: tools/b2v
	$(RM) init.srec
	touch init.srec
	echo "# FPGA is initialized with all zeros, no disassembly here." > init.disas
	$(RM) init.bin
	touch init.bin
	tools/b2v init.bin mem_init_pkg MEM_INIT > ../design/mem_init_pkg.vhd

# Make the bin2vhd tool.
tools/b2v: tools/bin2vhd.c
	cd tools && $(HOSTCC) -o b2v bin2vhd.c
