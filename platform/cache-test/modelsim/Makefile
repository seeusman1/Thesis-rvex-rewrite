
RVLIB = ../../../lib/rvex
VHDL_LIBS = common utils bus core cache work

include ../../share/modelsim.makefile

compile-work.do:
	@echo "vlib work" > $@
	@echo "vcom -quiet -93 -work work \"../design/testbench.vhd\"" >> $@

