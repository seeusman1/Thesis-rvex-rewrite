
.PHONY: help compile-% vsim-% ise-% clean list-executables

UNISIM = $(XILINX)/vhdl/src/unisims

help:
	@echo ""
	@echo " This platform consists of an rvex processor, on-chip memories and basic clock"
	@echo " and reset signal generation, intended to be run on the Xilinx ML605 Virtex 6"
	@echo " development board. It can also be simulated using modelsim for very basic"
	@echo " program verification. The testbench includes a UART simulating the computer"
	@echo " connected to the FPGA and allows manually written debug commands to be sent."
	@echo " Anything sent by the FPGA over the UART is echo'd to the simulation output, but"
	@echo " be aware that escape sequences are not unescaped."
	@echo ""
	@echo " Synthesis and simulation have been verified to work with modelsim 10.2a and"
	@echo " Xilinx ISE 14.7. Xilinx ISE 13.4 is known NOT to synthesize correctly. Use"
	@echo " other versions at your own risk."
	@echo ""
	@echo " To simulate using modelsim, run \"make vsim-<program>\" (valid programs are"
	@echo " listed below). You need to have sourced both the modelsim and Xilinx ISE"
	@echo " startup scripts; the latter is necessary to locate the Xilinx UNISIM library"
	@echo " files, needed to simulate the clock generation primitives in ml605.vhd."
	@echo ""
	@echo " To run ISE for synthesis or simulation using ISIM, run \"make ise-<program>\"."
	@cd examples && $(MAKE) --no-print-directory list-executables
	@echo " In addition, you can use \"none\" to initialize the memories with 0."
	@echo ""
	@echo " NOTE: be aware that static elaboration can take several minutes when simulating"
	@echo " or synthesizing with the memories initialized to a large program."
	@echo ""

compile-%:
	cd examples && $(MAKE) $(patsubst compile-%,copy-%,$@)

# This was partially taken from the grlib makefile.
modelsim/unisim_VITAL.vhd:
	@echo "" >  modelsim/unisim_VITAL.vhd; \
	for j in `cat $(UNISIM)/primitive/vhdl_analyze_order`; do \
		cat $(UNISIM)/primitive/$$j >> modelsim/unisim_VITAL.vhd; \
	done ;

vsim-%: compile-% modelsim/unisim_VITAL.vhd
	cd modelsim && vlib unisim
	cd modelsim && vcom -quiet -93 -work unisim $(UNISIM)/unisim_VPKG.vhd
	cd modelsim && vcom -quiet -93 -work unisim $(UNISIM)/unisim_VCOMP.vhd
	cd modelsim && vcom -quiet -93 -work unisim unisim_VITAL.vhd
	cd modelsim && vsim -do sim.do

ise-%: compile-%
	cd ise && ise standalone.xise

clean:
	find modelsim/* ! -name 'sim.do' ! -name '.gitignore' -type f -exec rm -f {} +
	find modelsim/* ! -name 'sim.do' ! -name '.gitignore' -type d -exec rm -rf {} +
	cd examples && $(MAKE) clean

