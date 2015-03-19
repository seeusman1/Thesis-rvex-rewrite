
POWERSTONE = adpcm blit crc des fir pocsag ucbqsort bcnt compress engine g3fax jpeg qurt v42
EXAMPLES = cd ../examples && $(MAKE)

BASE_DEFS = BUNDLE_ALIGN=4
SBIT_DEFS = BUNDLE_ALIGN=1

TOOLS = ../../../tools
DEBUGIFACE = $(TOOLS)/debug-interface
RVD = $(DEBUGIFACE)/bin/rvd.sh
RVTRACE = $(DEBUGIFACE)/bin/rvtrace

.PHONY: help
help:
	@echo "Run 'make init' to compile sources. Run 'make run DIR=<dirname>' to run on FPGA."

# -----------------------------------------------------------------------------
# init
# -----------------------------------------------------------------------------
.PHONY: init
init:
	rm -rf prog
	mkdir -p prog
	$(EXAMPLES) clean
	$(MAKE) compile-base
	$(EXAMPLES) clean
	$(MAKE) compile-sbit

.PHONY: compile-base compile-sbit
compile-base: $(patsubst %,compile-base-%,$(POWERSTONE))
compile-sbit: $(patsubst %,compile-sbit-%,$(POWERSTONE))

.PHONY: compile-base-% 
compile-base-%:
	$(EXAMPLES) $(patsubst compile-base-%,%,$@).elf $(patsubst compile-base-%,%,$@).srec $(patsubst compile-base-%,%,$@).disas $(BASE_DEFS)
	mv ../examples/$(patsubst compile-base-%,%,$@).elf prog/base-$(patsubst compile-base-%,%,$@).elf
	mv ../examples/$(patsubst compile-base-%,%,$@).srec prog/base-$(patsubst compile-base-%,%,$@).srec
	mv ../examples/$(patsubst compile-base-%,%,$@).disas prog/base-$(patsubst compile-base-%,%,$@).disas

.PHONY: compile-sbit-% 
compile-sbit-%:
	$(EXAMPLES) $(patsubst compile-sbit-%,%,$@).elf $(patsubst compile-sbit-%,%,$@).srec $(patsubst compile-sbit-%,%,$@).disas $(SBIT_DEFS)
	mv ../examples/$(patsubst compile-sbit-%,%,$@).elf prog/sbit-$(patsubst compile-sbit-%,%,$@).elf
	mv ../examples/$(patsubst compile-sbit-%,%,$@).srec prog/sbit-$(patsubst compile-sbit-%,%,$@).srec
	mv ../examples/$(patsubst compile-sbit-%,%,$@).disas prog/sbit-$(patsubst compile-sbit-%,%,$@).disas

# -----------------------------------------------------------------------------
# run
# -----------------------------------------------------------------------------
ifndef DIR
DIR = .
endif

.PHONY: run
run:
	@if [ -d $(DIR) ]; then echo "Please specify an empty directory for the results using DIR=<dirname>."; exit 1; fi;
	$(MAKE) internal-run

.PHONY: internal-run
internal-run: $(patsubst %,run-base-%,$(POWERSTONE)) $(patsubst %,run-sbit-%,$(POWERSTONE))

.PHONY: run-%
run-%:
	mkdir -p $(DIR)
	
	# Acquire performance counters.
	$(RVD) -call -d"all:PRINT_STATE{1}" break
	$(RVD) -c0 upload srec $(patsubst run-%,prog/%.srec,$@) IDMEM
	$(RVD) -call -d"all:PRINT_STATE{1}" reset
	$(RVD) -c0 exec FLUSH_CACHE
	$(RVD) -c0 write CACHE_BUS_LATENCY 0x10hh
	$(RVD) -c0 write CREG 0x80000000
	$(RVD) -c0 exec WAIT_COMPLETE
	
	# Write performance counters to output file.
	echo "Data for $(patsubst run-%,%,$@) ***" > $(DIR)/$(patsubst run-%,%.log,$@)
	echo "" >> $(DIR)/$(patsubst run-%,%.log,$@)
	echo "*** Performance counters ***" > $(DIR)/$(patsubst run-%,%.log,$@)
	echo "" >> $(DIR)/$(patsubst run-%,%.log,$@)
	$(RVD) -c0 exec 'printf("Total cycles = %u\n", readWord(C_CYC));' >> $(DIR)/$(patsubst run-%,%.log,$@)
	$(RVD) -c0 exec 'printf("Stalled cycles (due to memory, 16 cycles per 32-bit bus access) = %u\n", readWord(C_STALL));' >> $(DIR)/$(patsubst run-%,%.log,$@)
	$(RVD) -c0 exec 'printf("Committed bundle count = %u\n", readWord(C_BUN));' >> $(DIR)/$(patsubst run-%,%.log,$@)
	$(RVD) -c0 exec 'printf("Committed syllable count = %u\n", readWord(C_SYL));' >> $(DIR)/$(patsubst run-%,%.log,$@)
	$(RVD) -c0 exec 'printf("Committed NOP count = %u\n", readWord(C_NOP));' >> $(DIR)/$(patsubst run-%,%.log,$@)
	
	# Acquire trace.
	$(RVD) -call -d"all:PRINT_STATE{1}" break
	$(RVD) -c0 upload srec $(patsubst run-%,prog/%.srec,$@) IDMEM
	$(RVD) -call -d"all:PRINT_STATE{1}" reset
	$(RVD) -c0 exec FLUSH_CACHE
	$(RVD) -c0 write CACHE_BUS_LATENCY 0x10hh
	$(RVD) -c0 trace $(DIR)/$(patsubst run-%,%.rawtrace,$@) 0b01010001
	
	# Write trace to output file.
	echo "" >> $(DIR)/$(patsubst run-%,%.log,$@)
	echo "*** Trace data ***" >> $(DIR)/$(patsubst run-%,%.log,$@)
	echo "" >> $(DIR)/$(patsubst run-%,%.log,$@)
	$(RVTRACE) -l4 -g2 $(DIR)/$(patsubst run-%,%.rawtrace,$@)\
		| cat\
		| grep -P 'mem\(0x(?!FFFFF[CDEF])|[id]cache'\
		| sed -r -e "s/^# fetch.*(hit|miss)/instruction fetch \1/g" -e "s/^# / '- /g"\
		| sed -r -e "s/[ \\t]+#[ \\t]+/data /g"\
		>> $(DIR)/$(patsubst run-%,%.log,$@)

