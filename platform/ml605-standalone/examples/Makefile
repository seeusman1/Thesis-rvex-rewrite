
# Toolchain setup.
TOOLS = ../../../tools
GEN_EXAMPLES = ../../../examples
DEBUGIFACE = $(TOOLS)/debug-interface
RVD = $(DEBUGIFACE)/bin/rvd.sh
RVTRACE = $(DEBUGIFACE)/bin/rvtrace
HOSTCC = gcc

# Platform-specific executables.
EXECUTABLES = timer reconf cache

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
"make trace-<program>     upload + trace program (requires hardware trace unit)"\
"make gdb-<program>       upload + gdb"\
"make run-<program>       start + wait for completion"\
"make run-all             run-<program> for all executables"\
"make copy-<program>      registers program files for simulation"\
"make copy-none           unregisters files for simulation"

# Additional things to clean.
CLEAN = *.bin tools/b2v ../design/mem_init_pkg.vhd *.rawtrace *.trace

# Include generic examples makefile.
include $(GEN_EXAMPLES)/Makefile

# How to upload;
.PHONY: upload-%
upload-%: %.srec %.disas %.elf debug
	-cd $(DEBUGIFACE) && make server
	$(RVD) -call -d"all:PRINT_STATE{1}" break
	$(RVD) -c0 upload srec $< IDMEM
	$(RVD) -call -d"all:PRINT_STATE{1}" reset
	$(RVD) -c0 exec FLUSH_CACHE
	$(RVD) -c0 write CACHE_BUS_LATENCY $(BUSLAT)hh

.PHONY: start-%
start-%: upload-%
ifdef RECONF
	$(RVD) w BCRR $(RECONF)
	$(RVD) -c0 c
else
	$(RVD) -c0 write CREG 0x80000000
endif

.PHONY: run-%
run-%: start-%
	$(RVD) -c0 exec WAIT_COMPLETE

.PHONY: trace-%
trace-%: upload-% %.disas
	$(RVD) -call -d"all:PRINT_STATE{1}" trace $(patsubst trace-%,%,$@).rawtrace
	$(RVTRACE) -c0 $(patsubst trace-%,%,$@).rawtrace $(patsubst trace-%,%,$@).disas | cat > $(patsubst trace-%,%,$@).0.trace
	$(RVTRACE) -c1 $(patsubst trace-%,%,$@).rawtrace $(patsubst trace-%,%,$@).disas | cat > $(patsubst trace-%,%,$@).1.trace
	$(RVTRACE) -c2 $(patsubst trace-%,%,$@).rawtrace $(patsubst trace-%,%,$@).disas | cat > $(patsubst trace-%,%,$@).2.trace
	$(RVTRACE) -c3 $(patsubst trace-%,%,$@).rawtrace $(patsubst trace-%,%,$@).disas | cat > $(patsubst trace-%,%,$@).3.trace

.PHONY: gdb-%
gdb-%: %.elf upload-%
	$(RVD) -c0 gdb -- $(GDB) $<

.PHONY: run-all
run-all: $(patsubst %,run-%,$(BENCH_EXECUTABLES))

.PHONY: run-pwr
run-pwr: $(patsubst %,run-%,$(POWERSTONE))

# From 100us to 100ms, 6 per decade
CACHE_TIMER_VALUES +=    100    150   220   330   470   680
CACHE_TIMER_VALUES +=   1000   1500  2200  3300  4700  6800
CACHE_TIMER_VALUES +=  10000  15000 22000 33000 47000 68000
CACHE_TIMER_VALUES += 100000

.PHONY: run-cache-test
run-cache-test:
	rm -f cache-runs
	$(MAKE) upload-cache
	$(MAKE) $(patsubst %,cache-wd-%,$(CACHE_TIMER_VALUES))

.PHONY: cache-nd-%
cache-nd-%:
	echo "---------- ND $*us"         >> cache-runs
	$(RVD) -c0 w IDMEM+0x3FFF0 0x8808
	$(RVD) -c0 w IDMEM+0x3FFF4 0x0088
	$(RVD) -c0 w IDMEM+0x3FFF8 0
	$(RVD) -c0 w 0xF1000004 '(10*$*)-1'
	$(RVD) -c0 w 0xF1000000 0
	$(RVD) -c0 exec FLUSH_CACHE
	$(RVD) -c0 write CREG 0x80000000
	$(RVD) -c0 exec WAIT_COMPLETE     >> cache-runs
	echo "Return value:"              >> cache-runs
	$(RVD) -c0 r RET                  >> cache-runs
	echo "Number of interrupts:"      >> cache-runs
	$(RVD) -c0 r SCRP1                >> cache-runs
	echo "Number of engine runs:"     >> cache-runs
	$(RVD) -c0 r SCRP2                >> cache-runs
	echo "Number of jpeg runs:"       >> cache-runs
	$(RVD) -c0 r SCRP3                >> cache-runs
	echo "Total cycles:"              >> cache-runs
	$(RVD) -c0 r SCRP4                >> cache-runs

.PHONY: cache-wd-%
cache-wd-%:
	echo "---------- WD $*us"         >> cache-runs
	$(RVD) -c0 w IDMEM+0x3FFF0 0x8818
	$(RVD) -c0 w IDMEM+0x3FFF4 0x1188
	$(RVD) -c0 w IDMEM+0x3FFF8 1
	$(RVD) -c0 w IDMEM+0x3FFFC 0x8880
	$(RVD) -c0 w 0xF1000004 '(10*$*)-1'
	$(RVD) -c0 w 0xF1000000 0
	$(RVD) -c0 exec FLUSH_CACHE
	$(RVD) -c0 write CREG 0x80000000
	$(RVD) -c1 exec WAIT_COMPLETE     >> cache-runs
	echo "Return value:"              >> cache-runs
	$(RVD) -c0 r RET                  >> cache-runs
	echo "Number of interrupts:"      >> cache-runs
	$(RVD) -c0 r SCRP1                >> cache-runs
	echo "Number of engine runs:"     >> cache-runs
	$(RVD) -c1 r SCRP2                >> cache-runs
	echo "Number of jpeg runs:"       >> cache-runs
	$(RVD) -c1 r SCRP3                >> cache-runs
	echo "Total cycles:"              >> cache-runs
	$(RVD) -c1 r SCRP4                >> cache-runs


.PHONY: debug server stop monitor monitor-nobuf
debug server stop monitor monitor-nobuf:
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
