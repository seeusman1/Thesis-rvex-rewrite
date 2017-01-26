
TOOLS = ../../tools
CONFORM = python3 $(TOOLS)/misc/conform.py

.PHONY: help
help:
	@echo ""
	@echo " This simulation-only platform runs unit test cases on the current core design."
	@echo " It can and should be used to test if the core behaves sanely after the design"
	@echo " is modified."
	@echo ""
	@echo " The test cases are defined using the *.suite and *.test files in the tests"
	@echo " directory. *.suite files are just lists of *.test files and/or other *.suite"
	@echo " files to process; the simulation runs tests/index.suite. Refer to the"
	@echo " documentation at the top of share/core_tb.vhd for more information on the"
	@echo "*.test file structure and available commands."
	@echo ""
	@echo " Simulation can be run in the Modelsim GUI, or in command-line only mode for"
	@echo " conformance testing."
	@echo ""
	@echo " To run GUI mode, run make vsim in the desired core configuration subdirectory."
	@echo " The primary output of the test runner is the output log. Whenever a test is"
	@echo " performed, either \"SUCCESS\", \"FAILURE\", or \"Aborting.\" will be logged."
	@echo " Success and failure are self-explanatory. An abort is listed when the test file"
	@echo " requires a different core configuration to run successfully or if a test runner"
	@echo " error occurs; in general, when it cannot be determined whether the core is"
	@echo " behaving correctly or not."
	@echo ""
	@echo " Simulation will stop automatically, at which point the total number of test"
	@echo " cases run, failed and aborted is logged. If there is a problem with the core,"
	@echo " the current test case name and status and core simulation status output is"
	@echo " traced in the waveform by default, giving a starting point of figuring out what"
	@echo " went wrong."
	@echo ""
	@echo " To run in conformance testing/command line mode, run make conformance in this"
	@echo " directory. All core configurations will be tested. Core configurations can"
	@echo " also be tested in parallel using up to N threads using make's -j <N> option."
	@echo " If any test fails, make will return exit code 1. The logs for each"
	@echo " configuration are written to <configuration>.log."
	@echo ""
	@echo " Make targets:"
	@echo ""
	@echo "  make conformance     : conformance-tests all core configurations."
	@echo ""
	@echo "  make clean           : removes intermediate files."
	@echo ""

.PHONY: sim vsim
sim vsim:
	@echo "Please re-run 'make vsim' from the subdirectory corresponding to the desired"
	@echo "core configuration."
	@false


CONFIGURATIONS := $(patsubst %/core_cfg.vhd,%,$(shell ls -d */core_cfg.vhd))

.PHONY: conformance
conformance: $(patsubst %,conformance-%,$(CONFIGURATIONS))

.PHONY: conformance-%
conformance-%: %
	@$(CONFORM) $* "cd $< && make conformance"

.PHONY: clean
clean: $(patsubst %,clean-%,$(CONFIGURATIONS))

.PHONY: clean-%
clean-%: %
	cd $< && make clean
	rm -f $<.log

