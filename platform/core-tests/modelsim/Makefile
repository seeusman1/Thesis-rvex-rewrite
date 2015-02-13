
RVLIB = ../../../lib/rvex
VHDL_LIBS = common utils core work

include ../../share/modelsim.makefile

compile-work.do:
	@echo "vlib work" > $@
	@echo "vcom -quiet -93 -work work \"../design/core_tb.vhd\"" >> $@
