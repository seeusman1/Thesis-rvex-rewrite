# This Makefile can be used with parameters ISSUE WIDTH, DYNAMIC, COMPILER and
# LIMMH_PREV, documented below.

# It can also be included from different directories for different platforms.
# In this case, the following things should be defined by the calling makefile;
#   TOOLS - point to tools directory in repo w.r.t. calling makefile
#   GEN_EXAMPLES - point to the directory in which this makefile resides
#   EXECUTABLES - list of platform-specific programs to compile
#   OBJECTS - list of platform-specific object files to build and link
#   TARGETS - list of platform-specific make targets for make help
#   CLEAN - list of platform-specific file(type)s to clean

# Issue width; must be 2, 4 or 8. Default = 8.
ifndef ISSUE_WIDTH
ISSUE_WIDTH = 8
endif

# Must be one of the following;
#   false   - compile for the specified issue width only.
#   true    - use the -u assembler flag to compile generic binaries.
#   fix     - same as true, but run the vexparse script to attempt to fix
#             scheduling first.
#   resched - same as fix, with the addition of the --resched switch for
#             vexparse.
# Default = false.
ifndef DYNAMIC
DYNAMIC = false
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

# Trace settings for the simulator (seen cfgdefault.sim for more info)
ifndef SIM_TRACE
SIM_TRACE = 3
endif

ifndef SIM_TRACEREGS
SIM_TRACEREGS = 3
endif


# Define stuff for this makefile when called on its own (not included).
ifndef EXECUTABLES
EXECUTABLES = 
endif
ifndef OBJECTS
OBJECTS = rvex-xstsim.o
endif
ifndef GEN_EXAMPLES
GEN_EXAMPLES = .
endif
ifndef START
START = default_start
endif

# List of platform-agnostic (generic) programs.
EXECUTABLES += adpcm blit crc des fir pocsag \
	ucbqsort bcnt compress engine g3fax jpeg qurt v42 \
	adpcm1 dft itver2 itver2-repeat matrix memwrite soma x264 uart xstsimframebuffer#This line contains programs not from Powerstone

# Toolchain setup.
ifndef TOOLS
TOOLS = ../tools
endif
BUILD = $(TOOLS)/build/bin
AS = $(BUILD)/rvex-elf32-as
LD = $(BUILD)/rvex-elf32-ld
ifeq ($(COMPILER), HP)
CC = $(TOOLS)/vex-3.43/bin/cc
CFLAGS = -I$(GEN_EXAMPLES)/src -O2 -fno-xnop -fexpand-div -fmm=$(GEN_EXAMPLES)/pipe_1_$(ISSUE_WIDTH)_fw.mm
else ifeq ($(COMPILER), GCC)
CC = $(TOOLS)/build/bin/vex-gcc
CFLAGS = -O3 #use with GCC compiler
else
CC=st200-gcc
CFLAGS = -O3 -mcore=st220 -EB -fshort-double #use with Open64 compiler
endif
OBJCOPY = $(BUILD)/rvex-elf32-objcopy
OBJDUMP = $(BUILD)/rvex-elf32-objdump
CP = cp
MV = mv
RM = rm -f
MKDIR = mkdir
PYTHON = python3
VEXPARSE = $(PYTHON) $(TOOLS)/vexparse/main.py
SIM = $(TOOLS)/sim/xstsim-r-VEX-1.1.2
SIMFLAGS = --ips='"[r-VEX c]"' --c.core.issue_width=$(ISSUE_WIDTH) \
	-w --config-file=cfg.sim --c.trace=$(SIM_TRACE) --c.trace_regs=$(SIM_TRACEREGS)
PLATFORM_SRC = src
GENERIC_SRC = $(GEN_EXAMPLES)/src

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
.SUFFIXES:
.PRECIOUS: %.o %.s *.s %.elf %.srec %.disas

.PHONY: help list-executables
help:
	@echo ""
	@echo " Compiles programs for the rvex. The following targets are available."
	@echo ""
	@echo "  make all                 builds all programs"
	@echo "  make clean               cleans output files"
	@echo "  make <program>           buils the given program"
	@echo "  make xstsim-<program>    runs the given program using xstsim"
	@for target in $(TARGETS) ; do \
		echo "  $$target" ; \
	done
	@echo ""
	@echo " You can use the following modifies when building (be careful to spell them"
	@echo " correctly!)"
	@echo ""
	@echo "  make <target> ISSUE_WIDTH=<2|4|8>     (default = 8)"
	@echo "  make <target> DYNAMIC=<true|false>    (default = true)"
	@echo "  make <target> COMPILER=<HP|GCC|ST200> (default = HP)"
	@echo "  make <target> LIMMH_PREV=<true|false> (default = true)"
	@echo ""
	@echo " The following programs are available:"
	@echo ""
	@for exec in $(EXECUTABLES) ; do \
		echo "  $$exec" ; \
	done
	@echo ""

list-executables:
	@echo ""
	@echo " The following programs are available:"
	@echo ""
	@for exec in $(EXECUTABLES) ; do \
		echo "  $$exec" ; \
	done
	@echo ""

.PHONY: all
all: $(EXECUTABLES)

# How to compile platform-specific sources;
%.s: $(PLATFORM_SRC)/%.c
	$(CC) $(CFLAGS) $(patsubst %,-D%,$(DEFS)) -S $<

# Where to get platform-specific assembly files and how to preprocess them;
ifeq ($(COMPILER), HP)
%.s: $(PLATFORM_SRC)/%.S
	$(CC) $(CFLAGS) $(patsubst %,-D%,$(DEFS)) -E $< > $@
else
%.s: $(PLATFORM_SRC)/%.S
	$(CC) $(CFLAGS) $(patsubst %,-D%,$(DEFS)) -E $< -o $@
endif

# How to compile generic sources;
%.s: $(GENERIC_SRC)/%.c
	$(CC) $(CFLAGS) $(patsubst %,-D%,$(DEFS)) -S $<

# Where to get generic assembly files and how to preprocess them;
ifeq ($(COMPILER), HP)
%.s: $(GENERIC_SRC)/%.S
	$(CC) $(CFLAGS) $(patsubst %,-D%,$(DEFS)) -E $< > $@
else
%.s: $(GENERIC_SRC)/%.S
	$(CC) $(CFLAGS) $(patsubst %,-D%,$(DEFS)) -E $< -o $@
endif

# How to assemble;
%.o: %.s
ifeq ($(DYNAMIC), fix)
	$(CP) $< $(patsubst %.s,%.orig.s,$<)
	$(VEXPARSE) $(patsubst %.s,%.orig.s,$<) -o $<
endif
ifeq ($(DYNAMIC), resched)
	$(CP) $< $(patsubst %.s,%.orig.s,$<)
	$(VEXPARSE) $(patsubst %.s,%.orig.s,$<) --resched -o $<
endif
	$(AS) $(ASFLAGS) $< -o $@

# Special rule for _start.o, may be overwritten target-specifically;
.PHONY: _start.o-%
_start.o-%: default_start.o
	$(RM) _start.o
	$(CP) default_start.o _start.o

# How to link;
.SECONDEXPANSION:
%.elf: _start.o-% %.o $$(OBJECTS) $$(shell $$(PYTHON3) $$(GEN_EXAMPLES)/deps.py -p$$(PLATFORM_SRC) -p$$(GENERIC_SRC) $$@)
	$(LD) _start.o $(filter-out $<,$^) -o $@

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

xstsim-% : %
	$(SIM) $(SIMFLAGS) --c.target_exec='"$^.elf"'

.PHONY: clean
clean:
	$(RM) *.o *.s *.elf *.srec *.disas $(CLEAN)


