# This Makefile can be used with parameters ISSUE WIDTH, DYNAMIC, DYNAMIC_CORE,
# COMPILER and LIMMH_PREV, documented below.

# It can also be included from different directories for different platforms.
# In this case, the following things should be defined by the calling makefile;
#   TOOLS - point to tools directory in repo w.r.t. calling makefile
#   GEN_TEST_PROGS - point to the directory in which this makefile resides
#   EXECUTABLES - list of platform-specific programs to compile
#   OBJECTS - list of platform-specific object files to build and link
#   TARGETS - list of platform-specific make targets for make help
#   CLEAN - list of platform-specific file(type)s to clean

# Parallel execution is not supported due to the _start.o file, which differs
# for different targets while the filename is shared.
.NOTPARALLEL:

# Issue width; must be 2, 4 or 8. Default = 8.
ifndef ISSUE_WIDTH
ISSUE_WIDTH = 8
endif
DEFS += ISSUE=$(ISSUE_WIDTH)

# Bundle alignment requirement. Must be 1, 2, 4 or 8 (and at most ISSUE_WIDTH).
# Default is $(ISSUE_WIDTH) to disable stop bits.
ifndef BUNDLE_ALIGN
BUNDLE_ALIGN = $(ISSUE_WIDTH)
# NOTE: This was changed to 2 in ancient times for some reason. Please refrain
# from changing the defaults in this file; they should always correspond to the
# default core configuration ( = what you get when you configure with core_cfg()
# without parameters). Platform specific core configurations should be changed
# in the platform specific makefiles.
endif

# Generic binary behavior. Must be one of the following;
#   false     - compile for the specified issue width only.
#   true      - alias for true-O1.
#   true-O0   - run vexparse prior to assembly with --resched --O0
#   true-O1   - run vexparse prior to assembly with --resched --O1
#   true-O2   - run vexparse prior to assembly with --resched --O2
#   true-noresched - run vexparse prior to assembly without --resched
#   true-nofix - do not run vexparse prior to assembly.
# Default = true-O1.
ifndef DYNAMIC
DYNAMIC = true-O1
endif
ifeq ($(DYNAMIC), true)
override DYNAMIC = true-O1
endif
VEXPARSE_ENABLE = false
VEXPARSE_FLAGS = 
ifeq ($(DYNAMIC), true-O0)
VEXPARSE_ENABLE = true
VEXPARSE_FLAGS = --resched $(shell if grep -q docopt $(TOOLS)/vexparse/main.py; then echo --O0; else echo -O0; fi)
else ifeq ($(DYNAMIC), true-O1)
VEXPARSE_ENABLE = true
VEXPARSE_FLAGS = --resched $(shell if grep -q docopt $(TOOLS)/vexparse/main.py; then echo --O1; else echo -O1; fi)
else ifeq ($(DYNAMIC), true-O2)
VEXPARSE_ENABLE = true
VEXPARSE_FLAGS = --resched $(shell if grep -q docopt $(TOOLS)/vexparse/main.py; then echo --O2; else echo -O2; fi)
else ifeq ($(DYNAMIC), true-noresched)
VEXPARSE_ENABLE = true
endif

ifneq ($(DYNAMIC), false)
override DYNAMIC = true
ifndef DYNAMIC_CORE
DYNAMIC_CORE=true
endif
else
ifndef DYNAMIC_CORE
DYNAMIC_CORE=false
endif
endif

# Anything other than false enables debugging symbols and disables
# optimizations.
ifndef DEBUG
DEBUG = false
endif

# Compiler to use, must be HP, GCC or ST200. Default = HP.
ifndef COMPILER
COMPILER = HP
endif

# Whether LIMMH from previous syllable pair is supported by the core
# (limmhFromPreviousPair in the rvex CFG vector). Default = false.
ifndef LIMMH_PREV
LIMMH_PREV = false
endif

# Define stuff for this makefile when called on its own (not included).
ifndef EXECUTABLES
EXECUTABLES = 
endif
ifndef GEN_TEST_PROGS
GEN_TEST_PROGS = .
endif
ifndef START
START = default_start
endif

# Determine borrow configuration.
BORROW01   = 1.0
ifeq ($(LIMMH_PREV), true)
BORROW23   = .3,0.2,1
BORROW4567 = .5,2.4,3.7,4.6,5
else
BORROW23   = .3.2
BORROW4567 = .5.4.7.6
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
ifndef LANECONFIG
ifeq ($(ISSUE_WIDTH), 2)
ifeq ($(DYNAMIC_CORE), false)
 LANECONFIG = FB
else
 LANECONFIG = FB
endif
else ifeq ($(ISSUE_WIDTH), 4)
ifeq ($(DYNAMIC_CORE), false)
 LANECONFIG = FBBB
else
 LANECONFIG = FBFB
endif
else
ifeq ($(DYNAMIC_CORE), false)
 LANECONFIG = FBBBBBBB
else
 LANECONFIG = FBFBFBFB
endif
endif
endif

# Empty program.
EXECUTABLES += nothing

# Powerstone benchmarks.
POWERSTONE = adpcm bcnt blit compress crc des engine fir g3fax jpeg pocsag qurt ucbqsort v42 
#POWERSTONE += whetstone auto
EXECUTABLES += $(POWERSTONE)

# Random other applications.
EXECUTABLES += ucbqsort-fast adpcm1 dft itver2 itver2-repeat matrix memwrite\
	soma x264 uart helloworld all-at-once mandel

# List of platform-agnostic (generic) programs which run and complete without
# interaction, and test for success/failure. On success, main() should return
# 0.
BENCH_EXECUTABLES  = adpcm bcnt blit crc engine fir g3fax itver2 jpeg matrix des compress
BENCH_EXECUTABLES += pocsag qurt soma ucbqsort v42 x264 

# Toolchain setup.
ifndef TOOLS
TOOLS = ../tools
endif
BUILD = $(TOOLS)/rvex-elf32-32bit/bin
HOSTCC = gcc
OBJCOPY = $(BUILD)/rvex-elf32-objcopy
OBJDUMP = $(BUILD)/rvex-elf32-objdump
AR = $(BUILD)/rvex-elf32-ar
SED = sed
CP = cp
MV = mv
RM = rm -f
MKDIR = mkdir
PYTHON = python3
VEXPARSE = $(PYTHON) $(TOOLS)/vexparse/main.py
GDB = $(BUILD)/rvex-elf32-gdb
PLATFORM_SRC = src
GENERIC_SRC = $(GEN_TEST_PROGS)/src

# Assembler setup.
AS = $(BUILD)/rvex-elf32-as
ASFLAGS = --issue $(ISSUE_WIDTH) --borrow $(BORROW) --config $(LANECONFIG) --padding $(BUNDLE_ALIGN)
ifneq ($(DYNAMIC), false)
ASFLAGS += -u
endif
ifneq ($(DEBUG), false)
ASFLAGS += -g
endif
ifneq ($(AUTOSPLIT), false)
ASFLAGS += --autosplit
endif

# Linker setup.
LD = $(BUILD)/rvex-elf32-ld
ifneq ($(DEBUG), false)
LDFLAGS += -g
endif

# Compiler setup.
ifeq ($(COMPILER), HP)
CC = $(TOOLS)/vex-3.43/bin/cc
CFLAGS += -I$(PLATFORM_SRC) -I$(GENERIC_SRC) -fno-xnop -c99inline -fmm=$(GEN_TEST_PROGS)/cfg/pipe_1_$(ISSUE_WIDTH)_fw.mm
DEFS += HPVEX=HPVEX
# We add the floating point and division libraries, along with common.o, as .a files.
# That way, the linker will remove the code if it is not referenced, preventing 
# unneeded code size increase.
# The Open64 Compiler uses a different naming convention for floating point and division
# operations, and has its own library (named libgcc.a) that is added with -lgcc.
FLOATLIB=floatlib.a
DIVLIB=VEXdiv.a
ifeq ($(DEBUG), false)
CFLAGS += -O2
else
CFLAGS += -g
endif

else # Open64
CFLAGS += --issue $(ISSUE_WIDTH) -I$(PLATFORM_SRC) -I$(GENERIC_SRC) -fshort-double \
-fno-exceptions -std=c99 -fno-builtin $(INCLUDES)
DEFS += O64=O64
LDFLAGS += -nostartfiles -lgcc 
CC=$(TOOLS)/open64/bin/st200-gcc
LD=$(TOOLS)/open64/bin/st200-gcc
ifeq ($(DEBUG), false)
CFLAGS += -O3
else
CFLAGS += -g
endif
endif

ifdef XCFLAGS
CFLAGS += $(XCFLAGS)
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
	@for target in $(TARGETS) ; do \
		echo "  $$target" ; \
	done
	@echo ""
	@echo " You can use the following modifies when building (be careful to spell them"
	@echo " correctly!)"
	@echo ""
	@echo "  make <target> ISSUE_WIDTH=<2|4|8>                (default = 8)"
	@echo "  make <target> DYNAMIC=<(see Makefile)>           (default = true-O1)"
	@echo "  make <target> DYNAMIC_CORE=<true|false>          (default = same as DYNAMIC)"
	@echo "  make <target> COMPILER=<HP|O64>                  (default = HP)"
	@echo "  make <target> LIMMH_PREV=<true|false>            (default = true)"
	@echo "  make <target> DEFS=<list of preprocessor defs>   (default = <none>)"
	@echo ""
	@echo " NOTE: in general, you should clean before building a program using a different"
	@echo " target or with different modifiers.
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
ifeq ($(COMPILER), HP)
	$(SED) -i -e "s/^\(\.stab[sn][^\w].*\);$$/\1/" $@
endif

# Where to get platform-specific assembly files and how to preprocess them;
ifeq ($(COMPILER), HP)
%.s: $(PLATFORM_SRC)/%.S
	$(CC) $(CFLAGS) $(patsubst %,-D%,$(DEFS)) -E $< > $@
	$(SED) -i -e "s/^\(\.stab[sn][^\w].*\);$$/\1/" $@
else
%.s: $(PLATFORM_SRC)/%.S
	$(CC) $(CFLAGS) $(patsubst %,-D%,$(DEFS)) -E $< -o $@
endif

# How to compile generic sources;
ifeq ($(COMPILER), O64)
io.s: $(GENERIC_SRC)/io.c
	$(CC) $(CFLAGS) -I$(TOOLS)/newlib/rvex-elf32/include \
	$(patsubst %,-D%,$(DEFS)) -S $<
else
io.s:
	@echo "Attempted to compile io.c using incorrect compiler."
	@echo "Please build with COMPILER=O64."
	@exit 1
endif

%.s: $(GENERIC_SRC)/%.c
	$(CC) $(CFLAGS) $(patsubst %,-D%,$(DEFS)) -S $<
ifeq ($(COMPILER), HP)
	$(SED) -i -e "s/^\(\.stab[sn][^\w].*\);$$/\1/" $@
endif

# Where to get generic assembly files and how to preprocess them;
ifeq ($(COMPILER), HP)
%.s: $(GENERIC_SRC)/%.S
	$(CC) $(CFLAGS) $(patsubst %,-D%,$(DEFS)) -E $< > $@
	$(SED) -i -e "s/^\(\.stab[sn][^\w].*\);$$/\1/" $@
else
%.s: $(GENERIC_SRC)/%.S
	$(CC) $(CFLAGS) $(patsubst %,-D%,$(DEFS)) -E $< -o $@
endif

# How to assemble;
%.o: %.s
ifeq ($(VEXPARSE_ENABLE), true)
	@# This right here is really f'ing ugly, but for some reason the labels in
	@# _start.s are treated differently from the labels in the other files, and
	@# vexparse doesn't like it.
	@if [ "$(findstring _start.s,$<)" != "_start.s" ]; then \
		echo "$(CP) $< $(patsubst %.s,%.orig.s,$<)"; \
		$(CP) $< $(patsubst %.s,%.orig.s,$<); \
		echo "$(VEXPARSE) $(patsubst %.s,%.orig.s,$<) $(VEXPARSE_FLAGS) --borrow $(BORROW) --config $(LANECONFIG) -o $<"; \
		$(VEXPARSE) $(patsubst %.s,%.orig.s,$<) $(VEXPARSE_FLAGS) --borrow $(BORROW) --config $(LANECONFIG) -o $<; \
	fi
endif
	$(AS) $(ASFLAGS) $< -o $@

# How to convert objects with a main() such that they can be used as
# subprograms in a bigger program (prefixes global symbols with the object
# name);
%-sub.o: %.o
	$(OBJDUMP) -t $< | grep -E '^[0-9a-fA-F]{8} g' | sed -r 's/^.* (\w+)$$/\1 $(patsubst %.o,%,$<)_\1/g' > $(patsubst %.o,%.syms,$<)
	$(OBJCOPY) --redefine-syms $(patsubst %.o,%.syms,$<) $< $@

# Special rule for _start.o, may be overwritten target-specifically;
.PHONY: _start.o-%
_start.o-%: default_start.o
	$(RM) _start.o
	$(CP) default_start.o _start.o

# How to link;
%.elf: _start.o-% %.o $(OBJECTS) common.a $(FLOATLIB) $(DIVLIB)
	$(LD) _start.o $(filter-out $<,$^) -o $@ $(LDFLAGS)

# How to link all BENCH_EXECUTABLES together so they all run from a single
# main():
.SECONDEXPANSION:
all-at-once.elf: _start.o-all-at-once $$(patsubst %,%-sub.o,$$(BENCH_EXECUTABLES)) $(OBJECTS) common.a $(FLOATLIB) $(DIVLIB)
	$(PYTHON3) $(GEN_TEST_PROGS)/tools/all-at-once.py $(BENCH_EXECUTABLES) > all-at-once.s
	$(AS) $(ASFLAGS) all-at-once.s -o all-at-once.o
	$(LD) _start.o all-at-once.o $(filter-out $<,$^) -o $@

# How to create an archive file from a single object file (See HP Compiler setup above);
%.a: %.o
	$(AR) r $@ $<

# How to generate an srec;
%.srec: %.elf
	$(OBJCOPY) -O srec $< $@

# How to disassemble;
%.disas: %.elf
	$(OBJDUMP) -d $< > $@

#Create binary file to upload using GRMON
%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

# Default targets for applications;
.PHONY: $(EXECUTABLES)
$(EXECUTABLES):
	$(MAKE) $@.srec $@.disas

.PHONY: clean
clean:
	$(RM) *.a *.o *.s *.elf *.srec *.disas *.syms $(CLEAN)
ifdef CLEAN_DIR
	$(RM) -r $(CLEAN_DIR)
endif

