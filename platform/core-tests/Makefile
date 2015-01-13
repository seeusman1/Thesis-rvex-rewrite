
.PHONY: help sim clean

help:
	@echo ""
	@echo " This simulation-only platform runs unit test cases on the current core design."
	@echo " It can and should be used to test if the core behaves sanely after the design"
	@echo " is modified."
	@echo ""
	@echo " The test cases are defined using the *.suite and *.test files in the tests"
	@echo " directory. *.suite files are just lists of *.test files and/or other *.suite"
	@echo " files to process; the simulation runs tests/index.suite. Refer to the"
	@echo " documentation at the top of design/core_tb.vhd for more information on the"
	@echo "*.test file structure and available commands."
	@echo ""
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
	@echo " The test case runner cannot change the generic configuration of the core, so"
	@echo " you will need to set this yourself at the top of design/core_tb.vhd. Note that"
	@echo " the test case runner generates random clkEn and memory stall signals in order"
	@echo " to test that functionality, as well."
	@echo ""
	@echo " Make targets:"
	@echo ""
	@echo "  make sim             : runs the simulation in Modelsim."
	@echo ""
	@echo "  make clean           : removes intermediate files."
	@echo ""

sim:
	cd tests/compiled && $(MAKE) all
	cd modelsim && vsim -do sim.do

clean:
	cd tests/compiled && $(MAKE) clean
	find modelsim/* ! -name 'sim.do' ! -name '.gitignore' -type f -exec rm -f {} +
	find modelsim/* ! -name 'sim.do' ! -name '.gitignore' -type d -exec rm -rf {} +
