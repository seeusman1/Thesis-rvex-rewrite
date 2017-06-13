
# Toolchain setup.
TOOLS = ../../../tools
GEN_TEST_PROGS = ../../../test-progs
DEBUGIFACE = $(TOOLS)/debug-interface
RVD = $(DEBUGIFACE)/bin/rvd.sh
RVTRACE = $(DEBUGIFACE)/bin/rvtrace

# Platform-specific executables.
ifeq ($(COMPILER), O64)
EXECUTABLES = median
endif
EXECUTABLES = time convolution_3x3 convolution_5x5 convolution_7x7 greyscale mandel mandel_multi

# Platform-specific code to link.
OBJECTS = platform.a

# Platform specific targets for help.
TARGETS = \
"make upload-<program>    uploads program to platform using rvd"\
"make start-<program>     upload + start program"\
"make trace-<program>     upload + trace program (requires hardware trace unit)"\
"make gdb-<program>       upload + gdb"\
"make run-<program>       start + wait for completion"\
"make run-all             run-<program> for all executables"\
"make copy-<program>      registers program files for simulation"\

# Additional things to clean.
CLEAN = 

# Core configuration.
BUNDLE_ALIGN = 2

# Include generic test program makefile.
include $(GEN_TEST_PROGS)/include.makefile

# How to upload;
.PHONY: upload-%
upload-%: %.srec debug
	-cd $(DEBUGIFACE) && make server
	$(RVD) -call -d"all:PRINT_STATE{1}" break
	$(RVD) -c0 upload srec $< 0
	$(RVD) -call -d"all:PRINT_STATE{1}" reset

.PHONY: start-%
start-%: upload-%
ifdef RECONF
	$(RVD) w BCRR $(RECONF)
	$(RVD) -c0 c
else
	$(RVD) -c0 write CREG 0x80000000
endif

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

.PHONY: run-%
run-%: start-%
	$(RVD) -c0 exec WAIT_COMPLETE

.PHONY: run-all
run-all: $(patsubst %,run-%,$(BENCH_EXECUTABLES))

.PHONY: run-pwr
run-pwr: $(patsubst %,run-%,$(POWERSTONE))

.PHONY: debug server stop monitor monitor-nobuf
debug server stop monitor monitor-nobuf:
	cd $(DEBUGIFACE) && make $@

# Copies the given program machine code and disassembly to init* indicating
# which program was used for synthesis/simulation. Subsequently copies the
# srec to the file read by the ddr3 simulation model in the grlib project.
.PHONY: copy-%
copy-%: %.srec %.disas
	$(CP) $(patsubst copy-%,%,$@).srec init.srec
	$(CP) $(patsubst copy-%,%,$@).disas init.disas
	$(RM) ../work/ram.srec
	$(CP) init.srec ../work/ram.srec

