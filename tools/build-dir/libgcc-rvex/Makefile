.PHONY: all
all: libgcc-rvex
	mkdir -p build/lib
	cd libgcc-rvex && ./config/configure --with-target-cc-path=`pwd`/../../rvex-elf32/bin --with-toolname-root=rvex-elf32- --with-target-cc-name=rvex-gcc --with-target-binutils-home=`pwd`/../../rvex-elf32/bin --enable-perf=yes --enable-debug=no --enable-endian=be --enable-core=st220 --target=st220 --with-target-os=linux --prefix=`pwd`/build
	$(MAKE) -C libgcc-rvex libflip libfp
	rvex-elf32-as --issue 8 --borrow 1.0.3.2.5.4.7.6 --config FBFBFBFB --padding 8 -u libgcc-rvex/VEXdiv.resched.S -o build/VEXdiv.o
	cp libgcc-rvex/devimage/LIBFP/lib/libcfpi-st220.cc.a build/lib/libgcc.a
	rvex-elf32-ar r build/lib/libgcc.a build/VEXdiv.o
	rm build/VEXdiv.o
	rvex-elf32-ranlib build/lib/libgcc.a
	cp -r libgcc-rvex/devimage/LIBFP/include build/
	cp -r libgcc-rvex/devimage/LIBFLIP/include build/

include ../download.makefile

.PHONY:
clean:
	rm -rf build
	rm -rf libgcc-rvex

