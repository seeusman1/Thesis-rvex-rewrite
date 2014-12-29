
.PHONY: help sim

help:
	@echo "Run \"make sim\" to run the unit tests in modelsim."
	@echo "Make sure modelsim is correctly setup (vsim and vcom must be accessible)."

sim:
	cd modelsim && vsim -do sim.do

clean:
	find modelsim/* ! -name 'sim.do' ! -name '.gitignore' -type f -exec rm -f {} +
	find modelsim/* ! -name 'sim.do' ! -name '.gitignore' -type d -exec rm -rf {} +
