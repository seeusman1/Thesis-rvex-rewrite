
.PHONY: help

LOCAL_TEST=TRUE
LOCAL_TEST_LOC=/data/workspaces/release/tools

CURRENT_VERSION =4.1

# Tools that are built normally, using the host machine
BUILD_LOCAL_TOOLS=binutils-rvex sim-rvex newlib-rvex libgcc-rvex

# Tools that are built in a special build environment
BUILD_ENV_TOOLS=open64-rvex

ALLTOOLS = $(BUILD_ENV_TOOLS) $(BUILD_LOCAL_TOOLS)

help:
	@echo ""
	@echo " This makefile will assist building the rVEX tools."
	@echo " Targets:"
	@echo ""
	@echo " make build-env-<version> : Downloads and extracts the build environment."
	@echo " make all                 : Builds all tools"
	@echo " make issue2             : Builds 2-issue version of the tools"
	@echo " make issue4             : Builds 4-issue version of the tools"
	@echo " make issue8             : Builds 8-issue version of the tools"
	@echo " The following tools are available:"
	@echo ""
	@for tool in $(ALLTOOLS) ; do \
		echo "  $$tool" ; \
	done
	@echo ""

.PHONY: all
all: rvex-elf32 issue2 issue4 issue8

# In order to build the 2 and 4-issue versions of the toolchain,
# The default 8-issue toolchain must be built already
# because we will use the same binutils and libraries (they are compiled with
# generic binaries so they will run on other issue widths)
issue%: build-env-$(CURRENT_VERSION) rvex-elf32
	cp config/rvex_$*_si.cxx $</open64-rvex/open64-rvex/osprey/targinfo/st200/proc/rvex_si.cxx
	make -C $< open64-rvex
	cp -r rvex-elf32 $@
	cp -r $</open64-rvex/build/* $@/
	

# phony because even if the directory is created, it may not have been fully built
.PHONY: rvex-elf32 skeleton
rvex-elf32: skeleton $(ALLTOOLS)
	rvex-elf32/bin/rvex-gcc -c ../../test-progs/src/default_start.S -o rvex-elf32/lib/crt0.o

skeleton:
	cp -r rvex-elf32-skeleton rvex-elf32
	

.PHONY: $(BUILD_LOCAL_TOOLS)
binutils-rvex: skeleton
	$(MAKE) -C $@
	mkdir -p rvex-elf32
	cp -r $@/build/* rvex-elf32/
	ln -sf rvex-elf32-as rvex-elf32/bin/rvex-as
	ln -sf rvex-elf32-ld rvex-elf32/bin/rvex-ld
	ln -sf rvex-elf32-ar rvex-elf32/bin/rvex-ar
	ln -sf rvex-elf32-nm rvex-elf32/bin/rvex-nm
	ln -sf rvex-elf32-objcopy rvex-elf32/bin/rvex-objcopy
	ln -sf rvex-elf32-objdump rvex-elf32/bin/rvex-objdump
	ln -sf rvex-elf32-ranlib rvex-elf32/bin/rvex-ranlib
	ln -sf rvex-elf32-size rvex-elf32/bin/rvex-size
	ln -sf rvex-elf32-string rvex-elf32/bin/rvex-strings
	ln -sf rvex-elf32-strip rvex-elf32/bin/rvex-strip

newlib-rvex: skeleton libgcc-rvex 
	$(MAKE) -C $@
	mkdir -p rvex-elf32
	cp -r $@/build/* rvex-elf32/

libgcc-rvex: skeleton 
	$(MAKE) -C $@
	mkdir -p rvex-elf32
	cp -r $@/build/* rvex-elf32/

sim-rvex:
	$(MAKE) -C $@	
		


# Attempts to download the build environment if it doesn't exist.
build-env-%:
ifeq ($(LOCAL_TEST), TRUE)
	cp $(LOCAL_TEST_LOC)/$@.tar.bz2 ./
else
	wget http://ftp.tudelft.nl/TUDelft/rvex/$@.tar.bz2
endif
	tar -xjf $@.tar.bz2
	rm $@.tar.bz2



open64-rvex: build-env-$(CURRENT_VERSION)
	make -C $< $@
	mkdir -p rvex-elf32
	cp -r $</$@/build/* rvex-elf32/
	mkdir -p rvex-elf32/bin
	ln -sf ../lib/cmplrs/driver rvex-elf32/bin/rvex-gcc
	ln -sf ../lib/cmplrs/driver rvex-elf32/bin/rvex-c++
	ln -sf ../lib/cmplrs/driver rvex-elf32/bin/rvexcc
	ln -sf ../lib/cmplrs/driver rvex-elf32/bin/rvexc++
	ln -sf ../lib/cmplrs/driver rvex-elf32/bin/rvex-elf32-gcc
	ln -sf ../lib/cmplrs/driver rvex-elf32/bin/rvex-elf32-c++

	
.PHONY: clean
clean: $(patsubst %,clean-%,$(BUILD_LOCAL_TOOLS)) $(patsubst %,clean-env-%,$(BUILD_ENV_TOOLS))
	rm -rf rvex-elf32

.PHONY: clean-%
clean-%:
	$(MAKE) -C $(patsubst clean-%,%,$@) clean

.PHONY: clean-env-%
clean-env-%:
	$(MAKE) -C build-env-$(CURRENT_VERSION)/ clean-$(patsubst clean-env-%,%,$@)

