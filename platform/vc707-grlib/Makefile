
.PHONY: help
help: work
	@echo ""
	@echo " This platform is essentially grlib's LEON3 project for the VC707 board, with"
	@echo " the rvex processor and debug support UART added to it."
	@echo ""
	@echo " Synthesis and simulation have been verified to work with modelsim 10.2a and"
	@echo " Xilinx ISE 14.7. Xilinx ISE 13.4 is known NOT to synthesize correctly. Use"
	@echo " other versions at your own risk."
	@echo " This platform also needs Vivado 2013.3 or newer for synthesis."
	@echo ""
	@echo " Make targets:"
	@echo ""
	@echo "  make sim-<prog>   : shorthand for cleaning and running all necessary targets"
	@echo "                      for modelsim simulation. Source both modelsim and xilinx"
	@echo "                      environment scripts first. <prog> may be set to one of the"
	@echo "                      known programs, listed below."
	@echo ""
	@echo "  make resim-<prog> : shorthand for recompiling and restarting simulation if"
	@echo "                      only already existing VHDL files have been changed."
	@echo ""
	@echo "  make synth        : shorthand for cleaning and running all necessary targets"
	@echo "                      for command-line based synthesis of the design using Vivado."
	@echo "                      Source the ISE 14.7 and Vivado environment scripts first."
	@echo ""
	@echo "  make ise          : launches the ISE GUI."
	@echo ""
	@echo "  make upload-<prog>: compiles the specified program, starts rvsrv if it is"
	@echo "                      not already running and uploads the program to the"
	@echo "                      core. Leaves the core reset at PC 0."
	@echo ""
	@echo "  make start-<prog> : same as upload-<prog>, but also starts the program."
	@echo ""
	@echo "  make trace-<prog> : uploads and traces a program using the hardware trace"
	@echo "                      unit."
	@echo ""
	@echo "  make gdb-<prog>   : compiles and uploads the specified program and then runs"
	@echo "                      gdb to debug it."
	@echo ""
	@echo "  make run-<prog>   : same as start-<prog>, but also waits for completion."
	@echo "                      Completion is detected when none of the context cycle"
	@echo "                      counters increment between two reads."
	@echo ""
	@echo "  make run-all      : calls run-<prog> for all executables."
	@echo ""
	@echo "  make server       : starts rvsrv."
	@echo ""
	@echo "  make stop         : stops rvsrv."
	@echo ""
	@echo "  make debug        : generates a script which can be sourced to set up the"
	@echo "                      rvd/rvsrv debugging environment; run \"source debug\""
	@echo "                      after calling this command."
	@echo ""
	@echo "  make monitor      : uses netcat to connect to the application interface of"
	@echo "                      rvsrv. Anything written by the application using puts"
	@echo "                      will be dumped to the terminal and you can send lines"
	@echo "                      to the program which can be read using getchar. Exit"
	@echo "                      using ctrl+C."
	@echo ""
	@echo "  make monitor-nobuf: same as monitor, but with line buffering and echo"
	@echo "                      disabled."
	@echo ""
	@echo "  make clean        : cleans most grlib and rvex compilation intermediate files."
	@echo ""
	@echo "  make clean-ex     : cleans only compilation intermediate files."
	@echo ""
	@echo "  make very-clean   : on top of clean, removes the ENTIRE grlib working"
	@echo "                      directory. This might contain modified source files - it"
	@echo "                      is your own responsibility to run make update-patch first"
	@echo "                      if so."
	@echo ""
	@echo "  make update-patch : cleans the working directory and generates the work.patch"
	@echo "                      file used to rebuild the working directory from the grlib"
	@echo "                      base project. This must be run if changes are made to the"
	@echo "                      files in work before committing to git."
	@cd test-progs && $(MAKE) --no-print-directory list-executables
	@echo " For convenience, you can also call the usual grlib makefile targets from this"
	@echo " file, by prefixing with gr-. The targets are listed below."
	@cd work && $(MAKE) --no-print-directory help | sed -e "s/make \([a-zA-Z0-9_-]*\)/ make gr-\1/"


#------------------------------------------------------------------------------
# GRLIB project management
#------------------------------------------------------------------------------

# Call the makefile in the grlib directory to download and patch grlib.
../../grlib/grlib-gpl-1.4.1-b4156:
	cd ../../grlib && $(MAKE) grlib-gpl-1.4.1-b4156

# Copies the base project from grlib into work and patches it.
work: ../../grlib/grlib-gpl-1.4.1-b4156
	cp -r ../../grlib/grlib-gpl-1.4.1-b4156/designs/leon3-xilinx-vc707 .
	mv ./leon3-xilinx-vc707 ./work
	cd work && patch -p1 < ../work.patch

# Updates the patchfile based upon the differences between the grlib base
# project and the current contents of work. Kind of the inverse operation of
# the "work" target.
.PHONY: update-patch
update-patch: clean
	@cd work && $(MAKE) distclean
	diff -rupN --exclude="ram.srec" ../../grlib/grlib-gpl-1.4.1-b4156/designs/leon3-xilinx-vc707/ work/ > work.patch ; true

# Cleans all grlib and rvex compilation intermediate files.
.PHONY: clean
clean: clean-ex
	-cd work && $(MAKE) distclean scripts-clean
	rm -f work/*_beh.prj

# Removes the entire working directory; use with care (because the work dir might contain
# source files as well, which may not have been put in the patch file yet).
.PHONY: very-clean
very-clean: clean
	rm -Ir work


#------------------------------------------------------------------------------
# GRLIB makefile chaining/shorthands
#------------------------------------------------------------------------------

# Chain to the grlib makefile.
gr-%: work
	@cd work && $(MAKE) $(patsubst gr-%,%,$@)

# Shorthand notations for simulating, as descibed in the grlib leon project
# readme. THIS DOES A LOT OF EXTRA WORK BECAUSE IT STARTS FROM SCRATCH. FIXME!
.PHONY: sim-%
sim-%: work compile-%
	cd work && $(MAKE) \
		distclean\
		scripts-clean\
		mig_7series\
		sgmii_7series
		soft
		compile.vsim\
		vsim\
		vsim-launch

# Like sim-%, but does a little less extra work.
.PHONY: resim-%
resim-%: work compile-%
	cd work && $(MAKE) \
		vsim\
		vsim-launch

# Shorthand notations for synthesizing, as descibed in the grlib leon project
# readme.
#This one also used to do :
#		distclean\
#		scripts-clean\
.PHONY: synth
synth: work
	cd work && $(MAKE) \
		mig_7series\
		sgmii_7series
		vivado

# Shorthand for launching Vivado.
ise: work
	cd work && $(MAKE) \
		scripts-clean\
		vivado-launch

# Shorthand for launching Vivado.
vivado: work
	cd work && $(MAKE) \
		scripts-clean\
		vivado-launch

#------------------------------------------------------------------------------
# C compilation and runtime targets
#------------------------------------------------------------------------------

# Cleans rvex compilation intermediate files.
.PHONY: clean-ex
clean-ex:
	cd test-progs && $(MAKE) clean

# Chains to the test-progs makefile to build the specified program and copy it
# to the s-record file read by the micron DDR memory model.
.PHONY: compile-%
compile-%:
	cd test-progs && $(MAKE) $(patsubst compile-%,copy-%,$@)

# Make sure the rvex debugging tools are compiled and generate source script
# for setting up the debugging environment.
.PHONY: debug
debug:
	cd test-progs && $(MAKE) $@
	cat ../../tools/debug-interface/debug > debug
	echo 'export RVD_OPT="-m$(shell pwd)/memory.map"' >> debug
	@echo ""
	@echo " Run \"source debug\" now..."
	@echo ""

# The following targets simply chain to the makefile in test-progs.
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

.PHONY: conformance
conformance:
	cd test-progs && $(MAKE) $@
