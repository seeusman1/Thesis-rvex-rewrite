
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:


top:
	@echo "Please call make from the parent directory."

include ../../config.makefile
include ../../tools.makefile

IP = ip/ip.srcs/component.xml

BRIDGE  = rtl/almarvi_iface.vhd
BRIDGE += rtl/axi_bridge.vhd
BRIDGE += rtl/rvex_axislave.vhd

.PHONY: clean
clean:
	$(RM) -r ip work
	$(RM) -rf rtl/rvex
	$(RM) -f *.jou *.log *.dump *.img transcript *.wlf wlft* *stacktrace.vstf

.PHONY: all
all: $(IP)
$(IP): rtl/rvex $(BRIDGE)
	$(VIVADO) -mode batch -source generate_ip.tcl

.PHONY: sim
sim:
	@echo "TODO"
	@false

# Fetch the required r-VEX sources and change their library names to work.
LIB_ROOT = ../../../../../lib/rvex
RVEX_SRC  = rtl/rvex/common/common_pkg.vhd
RVEX_SRC += $(shell cat $(LIB_ROOT)/utils/vhdlsyn.txt | awk '$$0="rtl/rvex/utils/"$$0')
RVEX_SRC += $(shell cat $(LIB_ROOT)/bus/vhdlsyn.txt   | awk '$$0="rtl/rvex/bus/"$$0')
RVEX_SRC += $(shell cat $(LIB_ROOT)/core/vhdlsyn.txt  | awk '$$0="rtl/rvex/core/"$$0')
RVEX_SRC += $(shell cat $(LIB_ROOT)/cache/vhdlsyn.txt | awk '$$0="rtl/rvex/cache/"$$0')
RVEX_SRC += rtl/rvex/system/rvsys_standalone_pkg.vhd
RVEX_SRC += rtl/rvex/system/rvsys_standalone_core.vhd
RVEX_SRC += rtl/rvex/system/rvsys_standalone_cachedCore.vhd
RVEX_SRC += rtl/rvex/system/rvsys_standalone.vhd
RVEX_SRC += rtl/rvex/periph/periph_trace.vhd

rtl/rvex: $(RVEX_SRC)

rtl/rvex/common/%.vhd: $(LIB_ROOT)/common/%.vhd
	mkdir -p $(patsubst %/,%,$(dir $@))
	cat $(LIB_ROOT)/$(notdir $(patsubst %/,%,$(dir $@)))/$(notdir $@) |\
		sed -re 's/library\s+rvex;/library work;/' |\
		sed -re 's/use\s+rvex\s*\./use work\./' |\
		sed -re 's/entity\s+rvex\s*\./entity work\./' > $@

rtl/rvex/utils/%.vhd: $(LIB_ROOT)/utils/%.vhd
	mkdir -p $(patsubst %/,%,$(dir $@))
	cat $(LIB_ROOT)/$(notdir $(patsubst %/,%,$(dir $@)))/$(notdir $@) |\
		sed -re 's/library\s+rvex;/library work;/' |\
		sed -re 's/use\s+rvex\s*\./use work\./' |\
		sed -re 's/entity\s+rvex\s*\./entity work\./' > $@

rtl/rvex/bus/%.vhd: $(LIB_ROOT)/bus/%.vhd
	mkdir -p $(patsubst %/,%,$(dir $@))
	cat $(LIB_ROOT)/$(notdir $(patsubst %/,%,$(dir $@)))/$(notdir $@) |\
		sed -re 's/library\s+rvex;/library work;/' |\
		sed -re 's/use\s+rvex\s*\./use work\./' |\
		sed -re 's/entity\s+rvex\s*\./entity work\./' > $@

rtl/rvex/core/%.vhd: $(LIB_ROOT)/core/%.vhd
	mkdir -p $(patsubst %/,%,$(dir $@))
	cat $(LIB_ROOT)/$(notdir $(patsubst %/,%,$(dir $@)))/$(notdir $@) |\
		sed -re 's/library\s+rvex;/library work;/' |\
		sed -re 's/use\s+rvex\s*\./use work\./' |\
		sed -re 's/entity\s+rvex\s*\./entity work\./' > $@

rtl/rvex/cache/%.vhd: $(LIB_ROOT)/cache/%.vhd
	mkdir -p $(patsubst %/,%,$(dir $@))
	cat $(LIB_ROOT)/$(notdir $(patsubst %/,%,$(dir $@)))/$(notdir $@) |\
		sed -re 's/library\s+rvex;/library work;/' |\
		sed -re 's/use\s+rvex\s*\./use work\./' |\
		sed -re 's/entity\s+rvex\s*\./entity work\./' > $@

rtl/rvex/system/%.vhd: $(LIB_ROOT)/system/%.vhd
	mkdir -p $(patsubst %/,%,$(dir $@))
	cat $(LIB_ROOT)/$(notdir $(patsubst %/,%,$(dir $@)))/$(notdir $@) |\
		sed -re 's/library\s+rvex;/library work;/' |\
		sed -re 's/use\s+rvex\s*\./use work\./' |\
		sed -re 's/entity\s+rvex\s*\./entity work\./' > $@

rtl/rvex/periph/%.vhd: $(LIB_ROOT)/periph/%.vhd
	mkdir -p $(patsubst %/,%,$(dir $@))
	cat $(LIB_ROOT)/$(notdir $(patsubst %/,%,$(dir $@)))/$(notdir $@) |\
		sed -re 's/library\s+rvex;/library work;/' |\
		sed -re 's/use\s+rvex\s*\./use work\./' |\
		sed -re 's/entity\s+rvex\s*\./entity work\./' > $@

