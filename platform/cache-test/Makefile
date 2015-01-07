
.PHONY: help compile-% vsim-% ise-% clean

help:
	@echo ""
	@echo " This simulation-only platform may be used to test the combination of the rvex"
	@echo " core and the cache. The testbench consists of the core, the cache, a bus"
	@echo " arbiter and a memory model, which is initialized with a compiled program."
	@echo " In addition, a secondary memory model tests if the memory as seen by the core"
	@echo " matches what the cache presents it with, and reports errors when there is a"
	@echo " difference."
	@echo ""
	@echo " Run \"make vsim-x264\" to run the cache test in modelsim with the x264 program."
	@echo " Make sure modelsim is correctly setup (vsim and vcom must be accessible)."
	@echo " Alternatively, run \"make ise-x264\" to launch the ISE project if you prefer"
	@echo " ISIM."
	@echo ""

compile-%:
	cd examples && $(MAKE) $(patsubst compile-%,copy-%,$@)

vsim-%: compile-%
	cd modelsim && vsim -do sim.do

ise-%: compile-%
	cd ise && ise cache-test.xise

clean:
	find modelsim/* ! -name 'sim.do' ! -name '.gitignore' -type f -exec rm -f {} +
	find modelsim/* ! -name 'sim.do' ! -name '.gitignore' -type d -exec rm -rf {} +
	cd examples && $(MAKE) clean

