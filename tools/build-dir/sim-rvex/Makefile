.PHONY: all
all: sim200-1.1-rVEX
	cd sim200-1.1-rVEX && ./configure --prefix=`pwd`/../build
	$(MAKE) -C sim200-1.1-rVEX && $(MAKE) -C sim200-1.1-rVEX install

DOWNLOADS=sim200-1.1-rVEX
include ../download.makefile

.PHONY:
clean:
	rm -rf build
	rm -rf sim200-1.1-rVEX

