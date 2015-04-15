
.PHONY: vsim
vsim:
	cd compile && $(MAKE)
	cd modelsim && $(MAKE) vsim

.PHONY: conformance
conformance: clean
	cd compile && $(MAKE)
	cd modelsim && $(MAKE) vsim-sim-console.do VSIMFLAGS=-c 2>&1 | python3 ../../share/conformance.py

clean:
	cd compile && $(MAKE) clean
	cd modelsim && $(MAKE) clean
