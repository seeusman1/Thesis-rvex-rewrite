
# This makefile contains targets for modelsim simulation. It should be included
# from a makefile in the platform/<platform name>/modelsim directory. This
# makefile should contain the (sub-)library names which should be compiled as
# a variable named VHDL_LIBS and a relative path to lib/rvex in RVLIB.

UNISIM = $(XILINX)/vhdl/src/unisims

ifndef VSIM
VSIM = vsim
endif

ifndef VSIMFLAGS
VSIMFLAGS =
endif

RVSIM = $(RVLIB)/../../tools/rvsim

.PHONY: vsim
vsim: compile.do
	(cd $(RVSIM) && $(MAKE) bin/core.so)
	-ln -s $(RVSIM)/bin/core.so core_c.so
	$(VSIM) $(VSIMFLAGS) -do sim.do

.PHONY: vsim-%
vsim-%: compile.do
	$(VSIM) $(VSIMFLAGS) -do $(patsubst vsim-%,%,$@)

.PHONY: clean
clean:
	rm -rf *.wlf wlft* transcript work rvex unisim
	rm -rf compile*.do unisim_*.vhd
	rm -rf core_c.so

unisim_VCOMP.vhd unisim_VPKG.vhd:
	@cp $(UNISIM)/$@ $@

unisim_VITAL.vhd:
	@echo "" >  $@
	@for j in `cat $(UNISIM)/primitive/vhdl_analyze_order`; do \
		cat $(UNISIM)/primitive/$$j >> $@; \
	done ;

$(patsubst %,compile-%.do,$(shell cat $(RVLIB)/dirs.txt)): compile-%.do: $(RVLIB)/%/vhdlsyn.txt $(RVLIB)/%/vhdlsim.txt
	@echo "vlib rvex" > $@
	@cat $^ | sed -r 's/(.*)/vcom -quiet -93 -work rvex "$(subst /,\/,$(dir $<))\1"/' >> $@

compile-unisim.do: unisim_VPKG.vhd unisim_VCOMP.vhd unisim_VITAL.vhd
	@echo "vlib unisim" > $@
	@echo "vcom -quiet -93 -work unisim unisim_VPKG.vhd" >> $@
	@echo "vcom -quiet -93 -work unisim unisim_VCOMP.vhd" >> $@
	@echo "vcom -quiet -93 -work unisim unisim_VITAL.vhd" >> $@

compile.do: $(patsubst %,compile-%.do,$(VHDL_LIBS))
	@echo "" >  $@
	@for j in $^; do \
		echo "do $$j" >> $@; \
	done ;

