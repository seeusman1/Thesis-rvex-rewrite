
UNISIM = $(XILINX_VIVADO)/ids_lite/ISE/vhdl/src/unisims
SYNTH_MAKEFILE= ../share/synthesis.makefile
SYNTH_INIT = ../share/synthesis-init.py
IMPACT_MAKEFILE = ../share/impact.makefile

.PHONY: help
help:
	@echo ""
	@echo " This platform consists of an rvex processor, on-chip memories and basic clock"
	@echo " and reset signal generation, intended to be run on the Xilinx VC707 Virtex 7"
	@echo " development board. It can also be simulated using modelsim for very basic"
	@echo " program verification. The testbench includes a UART simulating the computer"
	@echo " connected to the FPGA and allows manually written debug commands to be sent."
	@echo " Anything sent by the FPGA over the UART is echo'd to the simulation output, but"
	@echo " be aware that escape sequences are not unescaped."
	@echo ""
	@echo " Synthesis and simulation have been verified to work with modelsim 10.2a and"
	@echo " Vivado 2015.4. Use other versions at your own risk."
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
	@echo "  make vivado-<prog>   : compiles the specified program and runs Vivado for"
	@echo "                         simulation using ISIM or synthesis."
	@echo ""
	@echo "  make upload-<prog>   : compiles the specified program, starts rvsrv if it is"
	@echo "                         not already running and uploads the program to the"
	@echo "                         core. Leaves the core reset at PC 0."
	@echo ""
	@echo "  make start-<prog>    : same as upload-<prog>, but also starts the program."
	@echo ""
	@echo "  make trace-<prog>    : uploads and traces a program using the hardware trace"
	@echo "                         unit."
	@echo ""
	@echo "  make gdb-<prog>      : compiles and uploads the specified program and then"
	@echo "                         runs gdb to debug it."
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
	@echo "  make monitor-nobuf   : same as monitor, but with line buffering and echo"
	@echo "                         disabled."
	@echo ""
	@echo "  make clean           : cleans C, modelsim and Vivado output files."
	@echo ""
	@echo "  make clean-synth     : removes synthesis temporary and output files generated"
	@echo "                         by make synth-<prog>."
	@echo ""
	@cd test-progs && $(MAKE) --no-print-directory list-executables
	@echo " In addition, you can use \"none\" to initialize the memories with zeros for all"
	@echo " targets but upload-<prog> and run-<prog>."
	@echo ""
	@echo " NOTE: be aware that static elaboration can take several minutes when simulating"
	@echo " or synthesizing with the memories initialized to a large program."
	@echo ""

.PHONY: compile-%
compile-%:
	cd test-progs && $(MAKE) $(patsubst compile-%,copy-%,$@)

.PHONY: vsim-%
vsim-%: compile-%
	cd modelsim && $(MAKE) vsim

.PHONY: vivado vivado-%
vivado: vivado-none
vivado-%: compile-%
	cd vivado && vivado standalone.xpr

.PHONY: upload-%
upload-%:
	cd test-progs && $(MAKE) $@

.PHONY: start-%
start-%:
	cd test-progs && $(MAKE) $@

.PHONY: run-%
run-%:
	cd test-progs && $(MAKE) $@

.PHONY: trace-%
trace-%:
	cd test-progs && $(MAKE) $@

.PHONY: gdb-%
gdb-%:
	cd test-progs && $(MAKE) $@

.PHONY: server stop monitor monitor-nobuf
server stop monitor monitor-nobuf:
	cd test-progs && $(MAKE) $@

.PHONY: debug
debug:
	cd test-progs && $(MAKE) $@
	cat ../../tools/debug-interface/debug > debug
	echo 'export RVD_OPT="-m$(shell pwd)/design/memory.map"' >> debug
	@echo ""
	@echo " Run \"source debug\" now..."
	@echo ""

.PHONY: clean
clean:
	cd test-progs && $(MAKE) clean
	cd modelsim && $(MAKE) clean
	cd vivado && ls -a | grep -Ev "^\.\.?$$" | grep -v ".gitignore" | grep -v "standalone.xpr" | xargs rm -rf
	rm -f design/mem_init_pkg.vhd

# Cleans rvex compilation intermediate files.
.PHONY: clean-ex
clean-ex:
	cd test-progs && $(MAKE) clean

.PHONY: clean-synth
clean-synth:
	rm -rf synth-*

.PHONY: conformance
conformance:
	cd test-progs && $(MAKE) $@
