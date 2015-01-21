
# Toolchain setup.
TOOLS = ../../../tools
GEN_EXAMPLES = ../../../examples
DEBUGIFACE = $(TOOLS)/debug-interface
RVD = $(DEBUGIFACE)/bin/rvd.sh
HOSTCC = gcc

# Platform-specific executables.
EXECUTABLES = timer reconf

# Platform-specific object files to link.
OBJECTS = rvex-standalone.o

# Set default simulated bus latency to use when configuring the cache after
# uploading. This can be overwritten to any value between 1 and 254 for an
# additional latency of 2 to 255 cycles.
ifndef BUSLAT
BUSLAT = 0x40
endif

# Platform specific targets for help.
TARGETS = \
"make upload-<program>    uploads program to platform using rvd"\
"make start-<program>     upload + start program"\
"make run-<program>       start + wait for completion"\
"make run-all             run-<program> for all executables"\
"make copy-<program>      registers program files for simulation"\
"make copy-none           unregisters files for simulation"

# Additional things to clean.
CLEAN = *.bin tools/b2v ../design/mem_init_pkg.vhd

# Include generic examples makefile.
include $(GEN_EXAMPLES)/Makefile

# How to upload;
.PHONY: upload-% upload-all
upload-%: %.srec debug
	-cd $(DEBUGIFACE) && make server
	$(RVD) -call -d"all:PRINT_STATE{1}" break
	$(RVD) -c0 upload srec $< IDMEM
	$(RVD) -call -d"all:PRINT_STATE{1}" reset
	$(RVD) -c0 exec FLUSH_CACHE
	$(RVD) -c0 write CACHE_BUS_LATENCY $(BUSLAT)hh

start-%: upload-%
	$(RVD) -c0 write CREG 0x80000000

run-%: start-%
	$(RVD) -c0 exec WAIT_COMPLETE

run-all: $(patsubst %,run-%,$(EXECUTABLES))

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
