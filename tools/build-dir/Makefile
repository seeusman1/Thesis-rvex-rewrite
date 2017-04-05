
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
	@echo " make install             : Copies the compiled tools to the release/tools"
	@echo "                            directory. REMOVES ALL EXISTING TOOLS."
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
	ln -sf rvex-elf32-strings rvex-elf32/bin/rvex-strings
	ln -sf rvex-elf32-strip rvex-elf32/bin/rvex-strip
	rm -rf rvex-elf32/rvex-elf32/bin
	mkdir -p rvex-elf32/rvex-elf32/bin
	ln -sf ../../bin/rvex-elf32-ar rvex-elf32/rvex-elf32/bin/ar
	ln -sf ../../bin/rvex-elf32-as rvex-elf32/rvex-elf32/bin/as
	ln -sf ../../bin/rvex-elf32-ld rvex-elf32/rvex-elf32/bin/ld
	ln -sf ../../bin/rvex-elf32-ld.bfd rvex-elf32/rvex-elf32/bin/ld.bfd
	ln -sf ../../bin/rvex-elf32-nm rvex-elf32/rvex-elf32/bin/nm
	ln -sf ../../bin/rvex-elf32-objcopy rvex-elf32/rvex-elf32/bin/objcopy
	ln -sf ../../bin/rvex-elf32-objdump rvex-elf32/rvex-elf32/bin/objdump
	ln -sf ../../bin/rvex-elf32-ranlib rvex-elf32/rvex-elf32/bin/ranlib
	ln -sf ../../bin/rvex-elf32-readelf rvex-elf32/rvex-elf32/bin/readelf
	ln -sf ../../bin/rvex-elf32-strip rvex-elf32/rvex-elf32/bin/strip
	ln -sf ../../vexparse rvex-elf32/bin/vexparse

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

.PHONY: install
install:
	
	# Replace rvex-elf32.
	rm -rf ../rvex-elf32
	cp -r rvex-elf32 ../rvex-elf32
	
	# Replace newlib.
	rm -rf ../newlib
	mkdir -p ../newlib/lib
	cp -r rvex-elf32/lib/newlib ../newlib/lib
	cp rvex-elf32/lib/crt0.o ../newlib/lib
	cp rvex-elf32/lib/libgcc.a ../newlib/lib
	cp -r rvex-elf32/include ../newlib
	
	# Replace open64.
	$(MAKE) install-issue8 install-issue4 install-issue2
	
	# Remove the compiler from rvex-elf32, point to rvex-gcc script in open64 instead.
	rm -rf ../rvex-elf32/lib/cmplrs
	rm -rf ../rvex-elf32/sbin
	ln -sf ../../open64/bin/rvex-gcc ../rvex-elf32/bin/rvex-gcc
	ln -sf ../../open64/bin/rvex-gcc ../rvex-elf32/bin/rvex-c++
	ln -sf ../../open64/bin/rvex-gcc ../rvex-elf32/bin/rvexcc
	ln -sf ../../open64/bin/rvex-gcc ../rvex-elf32/bin/rvexc++
	ln -sf ../../open64/bin/rvex-gcc ../rvex-elf32/bin/rvex-elf32-gcc
	ln -sf ../../open64/bin/rvex-gcc ../rvex-elf32/bin/rvex-elf32-c++
	
	# Remove duplicate files between rvex-elf32 and the open64 directories.
	fdupes -R ../rvex-elf32 -R ../open64/issue8 -R ../open64/issue4 -R ../open64/issue2 > dupes
	python3 dupes.py
	chmod +x dupes-fix
	./dupes-fix
	rm -f dupes dupes-fix
	
	# Replace the simulator.
	rm -rf ../simrvex
	cp -r sim-rvex/build ../simrvex
	mv ../simrvex/bin/simrvex ../simrvex/bin/real-simrvex
	cp sim-rvex/simrvex-preload ../simrvex/bin/simrvex
	

.PHONY: install-issue%
install-issue%:
	rm -rf ../open64/issue$*
	cp -r issue$* ../open64/issue$*
	
	# Remove random broken symlinks that open64 puts in its sbin...
	rm -rf ../open64/issue$*/sbin
	
	# Replace newlib directories with symlinks (directories won't be caught nicely by fdupes)
	rm -rf ../open64/issue$*/lib/newlib
	ln -s ../../../newlib/lib/newlib ../open64/issue$*/lib/newlib
	rm -rf ../open64/issue$*/include/newlib
	ln -s ../../../newlib/include/newlib ../open64/issue$*/include/newlib
	
	# Fix the vexparse symlink.
	ln -sf ../../../vexparse ../open64/issue$*/bin/vexparse
