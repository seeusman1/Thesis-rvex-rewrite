# Core setup.
ISSUE_WIDTH = 8
MODEL = pipe_1_8_fw.mm

ASFLAGS = --issue $(ISSUE_WIDTH) --borrow 1.0.3,0.2,1.5,2.4,3.7,4.6,5 --config 3333337B -u

# Toolchain setup.
TOOLS = ../tools
BUILD = $(TOOLS)/build/bin
AS = $(BUILD)/rvex-elf32-as
LD = $(BUILD)/rvex-elf32-ld
CC = $(TOOLS)/vex-3.43/bin/cc
CFLAGS = -O2 -fno-xnop -fexpand-div -fmm=$(MODEL)
OBJCOPY = objcopy
CP = cp


# Make magic.

SRC = src

EXECUTABLES = uart banana

.SUFFIXES:
.PRECIOUS: %.o %.s

.PHONY: all
all: $(EXECUTABLES)

# Where to get assembly files from when there's no C code;
%.s: $(SRC)/%.s
	$(CP) $< .

# How to compile;
%.s: $(SRC)/%.c
	$(CC) $(CFLAGS) -S $<

# How to assemble;
%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

# How to link;
%: %.o _start.o _basic_io.o
	$(LD) $^ -o $@

# How to generate an srec;
%.srec: %
	$(OBJCOPY) -O srec $< $@

# How to upload; (this requires make debug; source debug in debug-interface)
.PHONY: %-upload
%-upload: %.srec
	rvd.sh -call break
	rvd.sh -c0 upload srec $< _IMEM
	rvd.sh -c0 upload srec $< _DMEM
	rvd.sh -call reset

.PHONY: clean
clean:
	$(RM) $(EXECUTABLES) *.srec *.o *.s

