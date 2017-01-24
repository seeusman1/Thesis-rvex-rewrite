
TOOLS = ../../../tools
CONFORM = python3 $(TOOLS)/misc/conform.py

.PHONY: vsim
vsim:
	cd compile && $(MAKE)
	cd tests && $(MAKE)
	cd modelsim && $(MAKE) vsim

.PHONY: conformance
conformance:
	@$(MAKE) -s clean 2>&1 >/dev/null
	@$(CONFORM) "Generate test programs" "cd tests && $(MAKE)"
	@$(CONFORM) "Compile test programs" "cd compile && $(MAKE)"
	@cd modelsim && $(MAKE) vsim-sim-console.do VSIMFLAGS=-c 2>&1 | python3 ../../share/conformance.py

clean:
	cd compile && $(MAKE) clean
	cd tests && $(MAKE) clean
	cd modelsim && $(MAKE) clean
