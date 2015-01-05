# Core setup.
ISSUE_WIDTH = 8
MODEL = pipe_1_8_fw.mm

ASFLAGS = --issue $(ISSUE_WIDTH) --borrow 1.0.3,0.2,1.5,2.4,3.7,4.6,5 --config 3333337B -u

# Toolchain setup.
TOOLS = ../../../tools
BUILD = $(TOOLS)/build/bin
DEBUGIFACE = $(TOOLS)/debug-interface
AS = $(BUILD)/rvex-elf32-as
LD = $(BUILD)/rvex-elf32-ld
CC = $(TOOLS)/vex-3.43/bin/cc
RVD = $(DEBUGIFACE)/bin/rvd.sh
CFLAGS = -O2 -fno-xnop -fexpand-div -fmm=$(MODEL)
OBJCOPY = $(BUILD)/rvex-elf32-objcopy
OBJDUMP = $(BUILD)/rvex-elf32-objdump
CP = cp


# Make magic.

SRC = src

EXECUTABLES = x264

.SUFFIXES:
.PRECIOUS: %.o %.s

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
%: %.o _start.o
	$(LD) $^ -o $@
	$(OBJCOPY) -O srec $@ $@.srec
	$(OBJDUMP) -DS $@ > $@.disas
	$(CP) $@.srec sim.srec
	$(CP) $@.disas sim.disas

# How to generate an srec;
%.srec: %
	$(OBJCOPY) -O srec $< $@

# How to disassemble;
%.disas: %
	$(OBJDUMP) -DS $< > $@

.PHONY: clean
clean:
	$(RM) $(EXECUTABLES) *.srec *.o *.s *.disas

