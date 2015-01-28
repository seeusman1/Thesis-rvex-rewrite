# Core setup.
ISSUE_WIDTH = 8
MODEL = pipe_1_8_fw.mm

ASFLAGS = --issue $(ISSUE_WIDTH) --borrow 1.0.3,0.2,1.5,2.4,3.7,4.6,5 --config 3333337B -u

# Toolchain setup.
TOOLS = ../../../../tools
BUILD = $(TOOLS)/build/bin
AS = $(BUILD)/rvex-elf32-as
LD = $(BUILD)/rvex-elf32-ld
OBJCOPY = $(BUILD)/rvex-elf32-objcopy
CC = $(TOOLS)/vex-3.43/bin/cc
CFLAGS = -O2 -fno-xnop -fexpand-div -fmm=$(MODEL)
CP = cp

# Make magic.

SRC = src
SREC = ../srec

EXECUTABLES = div x264 factorial extReconf

.SUFFIXES:
.PRECIOUS: %.o %.s

.PHONY: all
all: $(EXECUTABLES)

# Where to get assembly files from when there's no C code;
%.s: $(SRC)/%.S
	$(CP) $< $@

# How to compile;
%.s: $(SRC)/%.c
	$(CC) $(CFLAGS) -S $<

# How to assemble;
%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

# How to link and generate srec;
$(EXECUTABLES) : % : %.o _start.o tools/sbitmod
	$(LD) $< _start.o -o $@
	tools/sbitmod $@ 8
	$(OBJCOPY) -O srec $@ $(SREC)/$@.srec

# This is temporary; the assembler should just generate the stop bits properly.
tools/sbitmod: tools/sbitmod.c
	gcc -o $@ $^

.PHONY: clean
clean:
	$(RM) $(EXECUTABLES) *.o *.s tools/sbitmod

