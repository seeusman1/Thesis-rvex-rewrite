
.SUFFIXES:
.SECONDARY:

# Toolchain setup.
TOOLS = ../../../tools
DEBUGIFACE = $(TOOLS)/debug-interface
RVD = $(DEBUGIFACE)/bin/rvd.sh
RVTRACE = $(DEBUGIFACE)/bin/rvtrace

POWERSTONE = qurt crc bcnt blit compress des engine fir g3fax jpeg pocsag ucbqsort v42 

.PHONY: all
all: $(patsubst %,run-%,$(POWERSTONE))

.PHONY: clean
clean:
	rm -rf $(POWERSTONE)

.PHONY: run-%
run-%: %.srec
	mkdir -p $*
	-cd $* && ln -s ../$*.srec prog.srec
	cd $* && $(MAKE) -f ../Makefile baseline   TOOLS=../$(TOOLS)
	cd $* && $(MAKE) -f ../Makefile trace-0x01 TOOLS=../$(TOOLS)
	cd $* && $(MAKE) -f ../Makefile trace-0x11 TOOLS=../$(TOOLS)
	cd $* && $(MAKE) -f ../Makefile trace-0x51 TOOLS=../$(TOOLS)
	cd $* && $(MAKE) -f ../Makefile trace-0x59 TOOLS=../$(TOOLS)
	cd $* && $(MAKE) -f ../Makefile trace-0x79 TOOLS=../$(TOOLS)

.PHONY: upload
upload:
	$(RVD) -call -d"all:PRINT_STATE{1}" break
	$(RVD) -c0 upload srec prog.srec 0
	$(RVD) -call -d"all:PRINT_STATE{1}" reset

baseline:
	$(MAKE) -f ../Makefile upload TOOLS=$(TOOLS)
	$(RVD) -c0 write CREG 0x80000000
	$(RVD) -c0 exec WAIT_COMPLETE > $@

trace-%:
	$(MAKE) -f ../Makefile upload TOOLS=$(TOOLS)
	$(RVD) -c0 trace ../temp/$@.rawtrace $*
	wc -c ../temp/$@.rawtrace > $@.size
	tar -zcf $@.rawtrace.tgz ../temp/$@.rawtrace
	rm -f ../temp/$@.rawtrace
	$(RVD) -c0 exec WAIT_COMPLETE > $@



.PHONY: start-%
start-%: upload-%
ifdef RECONF
	$(RVD) w BCRR $(RECONF)
	$(RVD) -c0 c
else
	$(RVD) -c0 write CREG 0x80000000
endif

