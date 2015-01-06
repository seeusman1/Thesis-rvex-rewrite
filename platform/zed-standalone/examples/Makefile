# This Makefile can be used with parameters ISSUE WIDTH, DYNAMIC, COMPILER and
# LIMMH_PREV, documented below.

# Issue width; must be 2, 4 or 8. Default = 8.
ifndef ISSUE_WIDTH
ISSUE_WIDTH = 8
endif

# Must be true for generic binary compilation, false for regular compilation.
# Default = true.
ifndef DYNAMIC
DYNAMIC = true
endif

# Compiler to use, must be HP, GCC or ST200. Default = HP.
ifndef COMPILER
COMPILER = HP
endif

# Whether LIMMH from previous syllable pair is supported by the core
# (limmhFromPreviousPair in the rvex CFG vector). Default = true.
ifndef LIMMH_PREV
LIMMH_PREV = true
endif

# Toolchain setup.
TOOLS = ../../../tools
BUILD = $(TOOLS)/build/bin
DEBUGIFACE = $(TOOLS)/debug-interface
AS = $(BUILD)/rvex-elf32-as
LD = $(BUILD)/rvex-elf32-ld
ifeq ($(COMPILER), HP)
CC = $(TOOLS)/vex-3.43/bin/cc
CFLAGS = -O2 -fno-xnop -fexpand-div -fmm=pipe_1_$(ISSUE_WIDTH)_fw.mm
else ifeq ($(COMPILER), GCC)
CC = $(TOOLS)/build/bin/vex-gcc
CFLAGS = -O3 #use with GCC compiler
else
CC=st200-gcc
CFLAGS = -O3 -mcore=st220 -EB -fshort-double #use with Open64 compiler
endif
RVD = $(DEBUGIFACE)/bin/rvd.sh
OBJCOPY = $(BUILD)/rvex-elf32-objcopy
OBJDUMP = $(BUILD)/rvex-elf32-objdump
CP = cp
MV = mv
RM = rm -f
MKDIR = mkdir
SIM = $(TOOLS)/sim/xstsim-r-VEX-1.1.2
SIMFLAGS = --ips='"[r-VEX c]"' --c.core.issue_width=$(ISSUE_WIDTH) \
	-w --config-file=cfg.sim --c.trace=1 --c.trace_regs=1 

# Determine borrow configuration.
BORROW01   = 1.0.
ifeq ($(LIMMH_PREV), false)
BORROW23   = 3.2.
BORROW4567 = 5.4.7.6.
else
BORROW23   = 3,0.2,1.
BORROW4567 = 5,2.4,3.7,4.6,5.
endif
ifeq ($(ISSUE_WIDTH), 2)
BORROW = $(BORROW01)
else ifeq ($(ISSUE_WIDTH), 4)
BORROW = $(BORROW01)$(BORROW23)
else
BORROW = $(BORROW01)$(BORROW23)$(BORROW4567)
endif

# Determine lane resource configuration.
#   Bit 0 = ALU
#   Bit 1 = MUL
#   Bit 2 = MEM
#   Bit 3 = BR
ifeq ($(ISSUE_WIDTH), 2)
LANECONFIG = 7B
else ifeq ($(ISSUE_WIDTH), 4)
LANECONFIG = 337B
else
LANECONFIG = 3333337B
endif

# Determine assembler flags.
ifeq ($(DYNAMIC), false)
ASFLAGS = --issue $(ISSUE_WIDTH) --borrow $(BORROW) --config $(LANECONFIG)
else
ASFLAGS = --issue $(ISSUE_WIDTH) --borrow $(BORROW) --config $(LANECONFIG) -u
endif



# Make magic.

SRC = src

EXECUTABLES = adpcm blit crc des fir pocsag \
	ucbqsort bcnt compress engine g3fax jpeg qurt v42 \
	adpcm1 dft itver2 matrix memwrite soma x264 uart #This line contains programs not from Powerstone

.SUFFIXES:
.PRECIOUS: %.o %.s %.elf %.srec %.disas

.PHONY: all
all: $(EXECUTABLES)

# How to compile;
%.s: $(SRC)/%.c
	$(CC) $(CFLAGS) -S $<

# Where to get assembly files;
%.s: $(SRC)/%.S
	$(CP) $< $@

# How to assemble;
%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

# How to link;
%.elf: %.o _start.o _basic_io.o floatlib.o #technically, not every program really needs the FP lib. But there is FP code in common.h so they all need it to link succesfully
	$(LD) $^ -o $@

# How to generate an srec;
%.srec: %.elf
	$(OBJCOPY) -O srec $< $@

# How to disassemble;
%.disas: %.elf
	$(OBJDUMP) -D $< > $@

# Default targets for applications;
.PHONY: $(EXECUTABLES)
$(EXECUTABLES):
	$(MAKE) $@.srec $@.disas

# How to upload; (this requires make debug; source debug in debug-interface)
.PHONY: %-upload
%-upload: %.srec $(RVD)
	-cd $(DEBUGIFACE) && make server
	$(RVD) -call break
	$(RVD) -c0 upload srec $< _IMEM
	$(RVD) -c0 upload srec $< _DMEM
	$(RVD) -call reset

$(RVD):
	cd $(DEBUGIFACE) && make debug

xstsim-% : %
	$(SIM) $(SIMFLAGS) --c.target_exec='"$^"'

.PHONY: clean
clean:
	$(RM) *.o *.s *.elf *.srec *.disas


