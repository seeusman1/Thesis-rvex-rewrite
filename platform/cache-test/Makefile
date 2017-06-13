
.PHONY: help compile-% vsim-% ise-% clean

help:
	@echo ""
	@echo " This simulation-only platform may be used to test the combination of the rvex"
	@echo " core and the cache and/or to test rvex applications. The testbench consists of"
	@echo " the core, the cache, a bus arbiter and a memory model, which is initialized"
	@echo " with a compiled program. In addition, a secondary memory model tests if the"
	@echo " memory as seen by the core matches what the cache presents it with, and reports"
	@echo " errors when there is a difference."
	@echo ""
	@echo " Make targets:"
	@echo ""
	@echo "  make compile-<prog>  : compiles the specified program only."
	@echo ""
	@echo "  make vsim-<prog>     : compiles the specified program and runs the simulation"
	@echo "                         in Modelsim."
	@echo ""
	@echo "  make ise-<prog>      : compiles the specified program and launches ISE, in"
	@echo "                         case you prefer that UI or want to use ISIM."
	@echo ""
	@echo "  make clean           : removes intermediate files."
	@cd test-progs && $(MAKE) --no-print-directory list-executables

compile-%:
	cd test-progs && $(MAKE) $(patsubst compile-%,copy-%,$@)

vsim-%: compile-%
	cd modelsim && $(MAKE) vsim

ise-%: compile-%
	cd ise && ise cache-test.xise

clean:
	cd test-progs && $(MAKE) clean
	cd modelsim && $(MAKE) clean

.PHONY: conformance
conformance:
	cd test-progs && $(MAKE) $@
