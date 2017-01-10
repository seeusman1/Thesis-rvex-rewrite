
# Don't remove random files.
.SECONDARY:

# Toolchain setup.
TOOLS = ../../../tools
GEN_TEST_PROGS = ../../../test-progs
DEBUGIFACE = $(TOOLS)/debug-interface
RVD = $(DEBUGIFACE)/bin/rvd.sh
RVTRACE = $(DEBUGIFACE)/bin/rvtrace
HOSTCC = gcc

# Platform-specific executables.
EXECUTABLES = test

# Platform-specific object files to link.
OBJECTS = pmem_puts.o

# Use a special linker script to separate IMEM and DMEM.
LDFLAGS = -Tsrc/almarvi.x

# Use stop bits.
BUNDLE_ALIGN = 2

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

# Additional things to clean.
CLEAN = *.bin *.rawtrace *.trace

# Include generic test program makefile.
include $(GEN_TEST_PROGS)/Makefile

# How to split up srec files into the three memories.
%.imem.srec %.dmem.srec %.pmem.srec %.bin %_data.bin %_param.bin: %.srec
	python src/split-mem.py $<

# How to upload;
.PHONY: upload-%
upload-%: %.imem.srec %.dmem.srec %.pmem.srec debug
	-cd $(DEBUGIFACE) && make server
	$(RVD) -c0 write A_CMD A_CMD_RUN
	$(RVD) -call -d"all:PRINT_STATE{1}" break
	$(RVD) -c0 upload srec $(patsubst upload-%,%.imem.srec,$@) IMEM
	$(RVD) -c0 upload srec $(patsubst upload-%,%.dmem.srec,$@) DMEM
	$(RVD) -c0 fill PMEM 1024 0
	$(RVD) -c0 upload srec $(patsubst upload-%,%.pmem.srec,$@) PMEM
	$(RVD) -call -d"all:PRINT_STATE{1}" reset

.PHONY: start-%
start-%: upload-%
	$(RVD) -c0 write CREG 0x80000000

.PHONY: run-%
run-%: start-%
	$(RVD) -c0 exec WAIT_COMPLETE
	$(RVD) -c0 read byte PMEM 1024

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

.PHONY: debug server stop monitor monitor-nobuf
debug server stop monitor monitor-nobuf:
	cd $(DEBUGIFACE) && make $@
