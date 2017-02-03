
UNISIM = $(XILINX)/vhdl/src/unisims
SYNTH_MAKEFILE= ../share/synthesis.makefile
SYNTH_INIT = ../share/synthesis-init.py
IMPACT_MAKEFILE = ../share/impact.makefile

.PHONY: help
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
	@echo "  make synth-<prog>    : synthesizes the project using ISE in command line mode."
	@echo "                         Will make a new fresh directory with copies of all"
	@echo "                         sources, so multiple synthesis attempts can be run at"
	@echo "                         once. This directory can be specified manually with"
	@echo "                         NAME=<name>, in which case the directory used will be"
	@echo "                         synth-<name>, or it will be generated based on the"
	@echo "                         current timestamp."
	@echo ""
	@echo "  make prog-<name>     : programs the ML605 board using synth-<name>/routed.bit"
	@echo "                         (as generated with 'make synth-<prog> NAME=<name>')"
	@echo "                         with impact."
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
	@echo "  make clean           : cleans C and modelsim output files."
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

.PHONY: ise ise-%
ise: ise-none
ise-%: compile-%
	cd ise && ise standalone.xise

.PHONY: synth synth-%
ifndef NAME
NAME := $(shell date +%Y-%m-%d-%H-%M-%S-%N)
endif
SYNTH := synth-$(NAME)
synth: synth-none
synth-%: compile-%
	
	# Make unique synthesis directory.
	if [ -d $(SYNTH) ]; then rm -rI $(SYNTH); fi
	if [ -d $(SYNTH) ]; then exit 1; fi
	mkdir -p $(SYNTH)
	
	# Generate archive-manifest from xise file.
	cd $(SYNTH) && ../synth-init.py ../ise/standalone.xise
	
	# Prepare the platform archive.
	cd $(SYNTH) && ../../../versions/tools/archive_platform_prepare.py arch
	
	# Remove the files generated by synth-init.py except for the manifest, as
	# they should have been archived now. We'll copy them back from the archive
	# along with all the other files needed to synthesize all at once.
	rm -f $(SYNTH)/constraints.ucf
	rm -f $(SYNTH)/project.prj
	rm -f $(SYNTH)/ptag.vhd
	
	# Copy all the archived sources to the root of the synthesis directory.
	cp -rf $(SYNTH)/arch/sources/* $(SYNTH)
	
	# Run the synthesis script.
	cd $(SYNTH) && ../synth-run.sh

.PHONY: prog-%
prog-%: synth-%/routed.bit
	cd $(dir $<) && $(MAKE) -f ../$(IMPACT_MAKEFILE) prog-ml605-routed.bit

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

.PHONY: clean-synth
clean-synth:
	find -name "synth-*" -type d | xargs rm -rf

.PHONY: conformance
conformance:
	cd test-progs && $(MAKE) $@
