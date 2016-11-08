
RVLIB = ../../../../lib/rvex
VHDL_LIBS = unisim common utils core work

include ../../../share/modelsim.makefile

compile-work.do:
	@echo "vlib work" > $@
	@echo "vcom -quiet -93 -work work \"../core_cfg.vhd\"" >> $@
	@echo "vcom -quiet -93 -work work \"../../share/core_tb.vhd\"" >> $@
