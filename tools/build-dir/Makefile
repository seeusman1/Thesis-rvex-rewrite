
.PHONY: all
all: rvex-elf32 issue2 issue4 issue8

CURRENT_VERSION=$(patsubst release-%,%,$(shell cat ../../version))
DOWNLOADS=build-env-$(CURRENT_VERSION)
include download.makefile


# Tools that are built normally, using the host machine
BUILD_LOCAL_TOOLS=binutils-rvex sim-rvex newlib-rvex libgcc-rvex

# Tools that are built in a special build environment
BUILD_ENV_TOOLS=open64-rvex

ALLTOOLS = $(BUILD_ENV_TOOLS) $(BUILD_LOCAL_TOOLS)

.PHONY: help $(ALLTOOLS)
help:
	@echo ""
	@echo " This makefile will assist building the rVEX tools."
	@echo " Targets:"
	@echo ""
	@echo " make build-env-<version> : Downloads and extracts the build environment."
	@echo " make all                 : Builds all tools"
	@echo " The following tools are available:"
	@echo ""
	@for tool in $(ALLTOOLS) ; do \
		echo "  $$tool" ; \
	done
	@echo ""

# In order to build the 2 and 4-issue versions of the toolchain,
# The default 8-issue toolchain must be built already
# because we will use the same binutils and libraries (they are compiled with
# generic binaries so they will run on other issue widths)
issue%: build-env-$(CURRENT_VERSION)
	if ! [ -d rvex-elf32 ]; then $(MAKE) rvex-elf32; fi
	cp config/rvex_$*_si.cxx $</open64-rvex/Open64-rVEX/osprey/targinfo/st200/proc/rvex_si.cxx
	make -C $< open64-rvex
	cp -r rvex-elf32 $@
	cp -r $</open64-rvex/build/* $@/
	

.PHONY: skeleton
rvex-elf32: skeleton $(ALLTOOLS)
	rvex-elf32/bin/rvex-gcc -c ../../test-progs/src/default_start.S -o rvex-elf32/lib/crt0.o

skeleton:
	mkdir -p rvex-elf32
	cp -r rvex-elf32-skeleton/* rvex-elf32/
	

binutils-rvex: skeleton
	$(MAKE) -C $@
	mkdir -p rvex-elf32
	cp -r $@/build/* rvex-elf32/
	ln -sf rvex-elf32-as rvex-elf32/bin/rvex-ras
	ln -sf rvex-elf32-ld rvex-elf32/bin/rvex-ld
	ln -sf rvex-elf32-ar rvex-elf32/bin/rvex-ar
	ln -sf rvex-elf32-nm rvex-elf32/bin/rvex-nm
	ln -sf rvex-elf32-objcopy rvex-elf32/bin/rvex-objcopy
	ln -sf rvex-elf32-objdump rvex-elf32/bin/rvex-objdump
	ln -sf rvex-elf32-ranlib rvex-elf32/bin/rvex-ranlib
	ln -sf rvex-elf32-size rvex-elf32/bin/rvex-size
	ln -sf rvex-elf32-string rvex-elf32/bin/rvex-strings
	ln -sf rvex-elf32-strip rvex-elf32/bin/rvex-strip
	cp -r ../vexparse rvex-elf32/bin

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
clean: $(patsubst %,clean-%,$(BUILD_LOCAL_TOOLS))
	rm -rf rvex-elf32 build-env-$(CURRENT_VERSION) issue2 issue4 issue8

.PHONY: clean-%
clean-%:
	$(MAKE) -C $(patsubst clean-%,%,$@) clean

.PHONY: clean-env-%
clean-env-%:
	$(MAKE) -C build-env-$(CURRENT_VERSION)/ clean-$(patsubst clean-env-%,%,$@)

