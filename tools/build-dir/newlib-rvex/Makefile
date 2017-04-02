.PHONY: all
all: newlib-cygwin
	cd newlib-cygwin && ./configure --target=rvex-elf32 CC_FOR_TARGET=`pwd`/../../rvex-elf32/bin/rvex-gcc --prefix=`pwd`/../build CFLAGS=-O2 CFLAGS_FOR_TARGET=-O2 --enable-newlib-io-long-long --enable-newlib-io-c99-formats
	PATH=`pwd`/../../rvex-elf32/bin:$$PATH $(MAKE) -C newlib-cygwin 
	PATH=`pwd`/../../rvex-elf32/bin:$$PATH $(MAKE) -C newlib-cygwin install
	rm -rf build/include
	rm -rf build/lib
	mkdir -p build/include/newlib
	mkdir -p build/lib/newlib
	mv build/rvex-elf32/include/* build/include/newlib
	mv build/rvex-elf32/lib/* build/lib/newlib/
	ln -s ../libgcc.a build/lib/newlib/libgcc.a

DOWNLOADS=newlib-cygwin
include ../download.makefile

.PHONY:
clean:
	rm -rf build
	rm -rf newlib-cygwin

