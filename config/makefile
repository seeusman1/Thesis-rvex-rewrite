
# Tool configuration.
PYTHON = python
RM = rm -f
CP = cp
ENSURE_DIR = mkdir -p
RM_DIR = rm -rf

# Path configuration.
SCRIPTS = scripts
SCRIPTS_COMMON = $(SCRIPTS)/common
TEMP = temp
CORE_LIB = ../lib/rvex/core
DOCS = ../doc/src/refman/generated
RVEX_H = ../examples/src/rvex.h
MEMORY_MAP = ../tools/debug-interface/core.map
MEMORY_MAP_PY = ../tools/debug-interface/pyrvd/core_map.py
PLATFORMS = ../platform

# Set python search path.
PYTHONP = PYTHONPATH=$(SCRIPTS) $(PYTHON)

# Define how to generate everything.
.PHONY: all
all: $(TEMP)
	@echo ""
	@echo "Configuring core..."
	$(CP) $(TEMP)/core_opcode_pkg.vhd $(CORE_LIB)/core_opcode_pkg.vhd
	$(CP) $(TEMP)/core_pipeline_pkg.vhd $(CORE_LIB)/core_pipeline_pkg.vhd
	$(CP) $(TEMP)/core_trap_pkg.vhd $(CORE_LIB)/core_trap_pkg.vhd
	$(CP) $(TEMP)/core_ctrlRegs_pkg.vhd $(CORE_LIB)/core_ctrlRegs_pkg.vhd
	$(CP) $(TEMP)/core_globalRegLogic.vhd $(CORE_LIB)/core_globalRegLogic.vhd
	$(CP) $(TEMP)/core_contextRegLogic.vhd $(CORE_LIB)/core_contextRegLogic.vhd
	$(CP) $(TEMP)/core_tb.vhd $(PLATFORMS)/core-tests/share/core_tb.vhd
	@echo ""
	@echo "Configuring C/assembly and rvd headers..."
	$(CP) $(TEMP)/rvex.h $(RVEX_H)
	$(CP) $(TEMP)/core.map $(MEMORY_MAP)
	$(CP) $(TEMP)/core_map.py $(MEMORY_MAP_PY)
	@echo ""
	@echo "Configuring reference manual..."
	$(CP) $(TEMP)/opcode-stats.generated.tex $(DOCS)/opcode-stats.generated.tex
	$(CP) $(TEMP)/opcode-table.generated.tex $(DOCS)/opcode-table.generated.tex
	$(CP) $(TEMP)/opcode-docs.generated.tex $(DOCS)/opcode-docs.generated.tex
	$(CP) $(TEMP)/gbreg.generated.tex $(DOCS)/gbreg.generated.tex
	$(CP) $(TEMP)/cxreg.generated.tex $(DOCS)/cxreg.generated.tex
	$(CP) $(TEMP)/traps.generated.tex $(DOCS)/traps.generated.tex
	$(CP) $(TEMP)/vexasm.generated.tex $(DOCS)/vexasm.generated.tex
	@echo ""
	@echo "Cleaning up..."
	@$(RM_DIR) $(TEMP)
	@$(RM) $(SCRIPTS)/code/*.pyc
	@$(RM) $(SCRIPTS)/common/*.pyc
	@$(RM) $(SCRIPTS)/cregs/*.pyc
	@$(RM) $(SCRIPTS)/funcparserlib/*.pyc
	@$(RM) $(SCRIPTS)/headers/*.pyc
	@$(RM) $(SCRIPTS)/opcodes/*.pyc
	@$(RM) $(SCRIPTS)/pipeline/*.pyc
	@$(RM) $(SCRIPTS)/traps/*.pyc
	@echo ""
	@echo "Trying to rebuild reference manual..."
	cd $(DOCS)/../../.. && $(MAKE)

.PHONY: $(TEMP)
$(TEMP): cregs/*.tex opcodes/*.tex opcodes/*.ini traps/*.tex pipeline/*.ini $(SCRIPTS)
	@$(ENSURE_DIR) $(TEMP)
	$(PYTHONP) $(SCRIPTS)/generate.py opcodes cregs traps pipeline templates $(TEMP)

