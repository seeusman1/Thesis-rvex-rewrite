
RVLIB = ../../../lib/rvex
VHDL_LIBS = unisim common utils bus core cache periph system-sa work

include ../../share/modelsim.makefile

# We need to do this directory manually, because we don't want to and can't
# compile the grlib system, which is in the same directory.
compile-system-sa.do:
	@echo "vlib rvex" > $@
	@echo "vcom -quiet -93 -work rvex \"$(RVLIB)/system/rvsys_standalone_pkg.vhd\"" >> $@
	@echo "vcom -quiet -93 -work rvex \"$(RVLIB)/system/rvsys_standalone_core.vhd\"" >> $@
	@echo "vcom -quiet -93 -work rvex \"$(RVLIB)/system/rvsys_standalone_cachedCore.vhd\"" >> $@
	@echo "vcom -quiet -93 -work rvex \"$(RVLIB)/system/rvsys_standalone.vhd\"" >> $@

compile-work.do:
	@echo "vlib work" > $@
	@echo "vcom -quiet -93 -work work \"../design/mem_init_pkg.vhd\"" >> $@
	@echo "vcom -quiet -93 -work work \"../design/vc707.vhd\"" >> $@
	@echo "vcom -quiet -93 -work work \"../design/vc707_tb.vhd\"" >> $@

