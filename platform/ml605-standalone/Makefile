
.PHONY: help compile-% vsim-% ise-% upload-% server stop debug monitor clean

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
	@echo " Make targets:"
	@echo ""
	@echo "  make compile-<prog>  : just compiles the specified program. Note that this is"
	@echo "                         not enough to update the modelsim simulation, you'll"
	@echo "                         need to run vsim-<prog> again for that."
	@echo ""
	@echo "  make vsim-<prog>     : compiles the specified program and runs the simulation"
	@echo "                         in modelsim. You need to have sourced the environment"
	@echo "                         script for ISE 14.7 as well for this, to let make"
	@echo "                         generate the VHDL files needed to simulate FPGA"
	@echo "                         primitives (Xilinx unisim library)."
	@echo ""
	@echo "  make ise-<prog>      : compiles the specified program and runs ISE for"
	@echo "                         simulation using ISIM or synthesis."
	@echo ""
	@echo "  make upload-<prog>   : compiles the specified program, starts rvsrv if it is"
	@echo "                         not already running and uploads the program to the"
	@echo "                         core. Leaves the core reset at PC 0."
	@echo ""
	@echo "  make start-<prog>    : same as upload-<prog>, but also starts the program."
	@echo ""
	@echo "  make run-<prog>      : same as start-<prog>, but also waits for completion."
	@echo "                         Completion is detected when none of the context cycle"
	@echo "                         counters increment between two reads."
	@echo ""
	@echo "  make run-all         : calls run-<prog> for all executables."
	@echo ""
	@echo "  make server          : starts rvsrv."
	@echo ""
	@echo "  make stop            : stops rvsrv."
	@echo ""
	@echo "  make debug           : generates a script which can be sourced to set up the"
	@echo "                         rvd/rvsrv debugging environment; run \"source debug\""
	@echo "                         after calling this command."
	@echo ""
	@echo "  make monitor         : uses netcat to connect to the application interface of"
	@echo "                         rvsrv. Anything written by the application using puts"
	@echo "                         will be dumped to the terminal and you can send lines"
	@echo "                         to the program which can be read using getchar. Exit"
	@echo "                         using ctrl+C."
	@echo ""
	@cd examples && $(MAKE) --no-print-directory list-executables
	@echo " In addition, you can use \"none\" to initialize the memories with zeros for all"
	@echo " targets but upload-<prog> and run-<prog>."
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

upload-%:
	cd examples && $(MAKE) $@

start-%:
	cd examples && $(MAKE) $@

run-%:
	cd examples && $(MAKE) $@

server stop monitor:
	cd examples && $(MAKE) $@

debug:
	cd examples && $(MAKE) $@
	cat ../../tools/debug-interface/debug > debug
	echo 'export RVD_OPT="-m$(shell pwd)/design/memory.map"' >> debug
	@echo ""
	@echo " Run \"source debug\" now..."
	@echo ""

clean:
	find modelsim/* ! -name 'sim.do' ! -name '.gitignore' -type f -exec rm -f {} +
	find modelsim/* ! -name 'sim.do' ! -name '.gitignore' -type d -exec rm -rf {} +
	cd examples && $(MAKE) clean

