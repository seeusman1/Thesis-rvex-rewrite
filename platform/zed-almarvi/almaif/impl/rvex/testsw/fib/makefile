
# Use bash syntax.
SHELL := /bin/bash

# Stop make from being annoying.
.SUFFIXES:
.SECONDARY:
.PRECIOUS: %.s

# Objects for this program.
OBJECTS = _start fib
TARGET = fib
LINKER = linker.x

#-------------------------------------------------------------------------------
# Development machine rules.
ifeq ($(shell uname -m | grep -q arm; echo $$?),1)

# Link to the rvex-rewrite tools directory.
TOOLS = ../../../../../../../tools

# Compiler tools.
CC        = $(TOOLS)/open64/bin/st200-gcc
OBJDUMP   = $(TOOLS)/rvex-elf32-32bit/bin/rvex-elf32-objdump
OBJCOPY   = $(TOOLS)/rvex-elf32-32bit/bin/rvex-elf32-objcopy

CFLAGS += -nostartfiles -O3

# Test for compiler tool existence before doing anything.
ifeq ("$(wildcard $(CC))","")
all:
	@echo "Error: could not find r-VEX Open64 compiler toolchain."
	@echo "Looked in: $(CC)"
else

# Standard tools.
RM        = rm
GREP      = grep
SED       = sed

# S-record to binary image script that splits up the three memories.
SPLIT_MEM = python split-mem.py

# Toplevel rule.
.PHONY: all
all: | $(TARGET) clean-int

# Build rule.
.PHONY: $(TARGET)
$(TARGET): $(TARGET).img $(TARGET)_data.img $(TARGET)_param.img $(TARGET).disas $(TARGET).objects

# Cleaning rule.
.PHONY: clean
clean: clean-int
	$(RM) -f *.disas *.img *.objects loader *.dump

# Clean intermediate files only.
.PHONY: clean-int
clean-int:
	$(RM) -f *.s *.o *.d *.elf *.srec

# Assembling.
%.s: %.S
	$(CC) $(CFLAGS) -E $< -o $@
%.o: %.s
	$(CC) $(CFLAGS) -c $< -o $@

# Compiling.
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Dependency generation for make.
%.d: %.S
	$(CC) $(CFLAGS) -MM $< > $@

%.d: %.c
	$(CC) $(CFLAGS) -MM $< > $@

-include $(OBJECTS:=.d)

# Linking.
$(TARGET).elf: $(OBJECTS:=.o)
	$(CC) $(CFLAGS) -Wl,-T$(LINKER) $^ -o $@

# Disassembling.
%.disas: %.elf
	$(OBJDUMP) -d $^ > $@

# Conversion from elf to S-record file format.
%.srec: %.elf
	$(OBJCOPY) -O srec $< $@

# Conversion from single S-record to an S-record and binary image for each
# accelerator memory.
%.imem.srec %.dmem.srec %.pmem.srec %.img %_data.img %_param.img: %.srec
	$(SPLIT_MEM) $<

# Generating a text file specifying where the objects are.
%.objects: %.elf
	@echo "DMEM:" > $@
	$(OBJDUMP) -t $< | $(GREP) -E "^1.{14}O" | $(SED) -r -e 's/^1/0/g' >> $@
	@echo "" >> $@
	@echo "PMEM:" >> $@
	$(OBJDUMP) -t $< | $(GREP) -E "^8.{14}O" | $(SED) -r -e 's/^8/0/g' >> $@

endif

#-------------------------------------------------------------------------------
# Linaro/Zynq rules.
else

.PHONY: all
all: loader
ifndef ADDR
	@echo "Please specify the address of the accelerator as ADDR=0x..."
else
	sudo ./loader -m $(ADDR) -p $(TARGET).img -o $(TARGET).dump -s 0 -e 64
endif

loader: ../../drivers/loader/loader.cc
	g++ -o $@ $^

# Cleaning rule.
.PHONY: clean
clean: clean-int
	$(RM) -f loader *.dump

endif
