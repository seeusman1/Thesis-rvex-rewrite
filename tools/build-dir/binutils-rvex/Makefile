.PHONY: all
all: binutils-gdb
	cd binutils-gdb && ./configure --target=rvex-elf32 --program-prefix=rvex-elf32- --prefix=`pwd`/../build
	$(MAKE) -j16 -C binutils-gdb && $(MAKE) -C binutils-gdb install

DOWNLOADS=binutils-gdb
include ../download.makefile

.PHONY:
clean:
	rm -rf build
	rm -rf binutils-gdb

