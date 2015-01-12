
.PHONY: help update-patch clean very-clean compile-& sim-% resim-% synth upload-% gr-%

help: work
	@echo ""
	@echo " This platform is essentially grlib's LEON3 project for the ML605 board, with"
	@echo " the rvex processor and debug support UART added to it."
	@echo ""
	@echo " Synthesis and simulation have been verified to work with modelsim 10.2a and"
	@echo " Xilinx ISE 14.7. Xilinx ISE 13.4 is known NOT to synthesize correctly. Use"
	@echo " other versions at your own risk."
	@echo ""
	@echo " Make targets:"
	@echo ""
	@echo " make sim-<prog>   : shorthand for cleaning and running all necessary targets"
	@echo "                     for modelsim simulation. Source both modelsim and xilinx"
	@echo "                     environment scripts first. <prog> may be set to one of the"
	@echo "                     known programs, listed below."
	@echo ""
	@echo " make resim-<prog> : shorthand for recompiling and restarting simulation if"
	@echo "                     only already existing VHDL files have been changed."
	@echo ""
	@echo " make synth        : shorthand for cleaning and running all necessary targets"
	@echo "                     for command-line based synthesis of the design using ISE."
	@echo "                     Source the ISE 14.7 environment script first."
	@echo ""
	@echo " make ise          : launches the ISE GUI."
	@echo ""
	@echo " make upload-<prog>: compiles the specified program and uploads it to the FPGA"
	@echo "                     using the rvex debugging UART."
	@echo ""
	@echo " make clean        : cleans most grlib and rvex compilation intermediate files."
	@echo ""
	@echo " make very-clean   : on top of clean, removes the ENTIRE grlib working"
	@echo "                     directory. This might contain modified source files - it"
	@echo "                     is your own responsibility to run make update-patch first"
	@echo "                     if so."
	@echo ""
	@echo " make update-patch : cleans the working directory and generates the work.patch"
	@echo "                     file used to rebuild the working directory from the grlib"
	@echo "                     base project. This must be run if changes are made to the"
	@echo "                     files in work before committing to git."
	@cd examples && $(MAKE) --no-print-directory list-executables
	@echo " For convenience, you can also call the usual grlib makefile targets from this"
	@echo " file, by prefixing with gr-. The targets are listed below."
	@cd work && $(MAKE) --no-print-directory help | sed -e "s/make \([a-zA-Z0-9_-]*\)/make gr-\1/"

# Call the makefile in the grlib directory.
../../grlib/grlib-gpl-1.3.7-b4144:
	cd ../../grlib && $(MAKE) grlib-gpl-1.3.7-b4144

# Copies the base project from grlib into work and patches it.
work: ../../grlib/grlib-gpl-1.3.7-b4144
	cp -r ../../grlib/grlib-gpl-1.3.7-b4144/designs/leon3-xilinx-ml605 .
	mv ./leon3-xilinx-ml605 ./work
	cd work && patch -p1 < ../work.patch

# Updates the patchfile based upon the differences between the grlib base
# project and the current contents of work. Kind of the inverse operation of
# the "work" target.
update-patch: clean
	@cd work && $(MAKE) distclean
	diff -rupN --exclude="ram.srec" ../../grlib/grlib-gpl-1.3.7-b4144/designs/leon3-xilinx-ml605/ work/ > work.patch ; true

# Cleans all grlib and rvex compilation intermediate files.
clean:
	cd examples && $(MAKE) clean
	-cd work && $(MAKE) distclean scripts-clean migclean
	rm -f work/*_beh.prj

# Removes the entire working directory; use with care (because the work dir might contain
# source files as well, which may not have been put in the patch file yet).
very-clean: clean
	rm -Ir work

# Chains to the examples makefile to build the specified program and copy it to
# the s-record file read by the micron DDR memory model.
compile-%:
	cd examples && $(MAKE) $(patsubst compile-%,copy-%,$@)

# Shorthand notations for simulating, as descibed in the grlib leon project
# readme.
sim-%: work compile-%
	cd work && $(MAKE) \
		distclean\
		scripts-clean\
		migclean\
		mig39\
		install-secureip\
		compile_xilinx_verilog_lib\
		vsim\
		map_xilinx_verilog_lib\
		vsim-launch

resim-%: work compile-%
	cd work && $(MAKE) \
		vsim\
		map_xilinx_verilog_lib\
		vsim-launch

# Shorthand notations for synthesizing, as descibed in the grlib leon project
# readme.
synth: work
	cd work && $(MAKE) \
		distclean\
		scripts-clean\
		migclean\
		mig39\
		planahead

# Shorthand for launching ISE.
ise: work
	cd work && $(MAKE) \
		scripts-clean\
		migclean\
		mig39\
		ise-launch

# Chains to the examples makefile to upload the specified program to the FPGA.
upload-%:
	cd examples && $(MAKE) $@

# Recursively calls grlib's makefile.
gr-%: work
	@cd work && $(MAKE) $(patsubst gr-%,%,$@)

