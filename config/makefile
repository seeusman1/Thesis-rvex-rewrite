
# Tool configuration.
PYTHON = python
RM = rm -f
CP = cp
ENSURE_DIR = mkdir -p
RM_DIR = rm -rf

# Path configuration.
SCRIPTS = interpreter
TEMP = temp
CORE_LIB = ../lib/rvex/core
DOCS = ../doc/src/refman/generated
RVEX_H = ../examples/src/rvex.h
MEMORY_MAP = ../tools/debug-interface/core-regs.map

# Define how to generate everything.
.PHONY: all
all: $(TEMP)
	@echo ""
	@echo "Configuring core..."
	$(CP) $(TEMP)/core_opcode_pkg.vhd $(CORE_LIB)/core_opcode_pkg.vhd
	@echo ""
	@echo "Configuring C/assembly headers..."
	$(CP) $(TEMP)/rvex.h $(RVEX_H)
	@echo ""
	@echo "Configuring reference manual..."
	$(CP) $(TEMP)/opcode-stats.generated.tex $(DOCS)/opcode-stats.generated.tex
	$(CP) $(TEMP)/opcode-table.generated.tex $(DOCS)/opcode-table.generated.tex
	$(CP) $(TEMP)/opcode-docs.generated.tex $(DOCS)/opcode-docs.generated.tex
	$(CP) $(TEMP)/gbreg.generated.tex $(DOCS)/gbreg.generated.tex
	$(CP) $(TEMP)/cxreg.generated.tex $(DOCS)/cxreg.generated.tex
	$(CP) $(TEMP)/traps.generated.tex $(DOCS)/traps.generated.tex
	@echo ""
	@echo "Cleaning up..."
	@$(RM_DIR) $(TEMP)
	@$(RM) $(SCRIPTS)/*.pyc
	@echo ""
	@echo "Trying to rebuild reference manual..."
	cd $(DOCS)/../../.. && $(MAKE)

$(TEMP): opcodes.tex gbreg.tex cxreg.tex traps.tex $(SCRIPTS)
	@echo "Parsing input..."
	@$(ENSURE_DIR) $(TEMP)
	$(PYTHON) $(SCRIPTS)/opcodes-latex.py opcodes.tex \
		$(TEMP)/opcode-stats.generated.tex \
		$(TEMP)/opcode-table.generated.tex \
		$(TEMP)/opcode-docs.generated.tex
	$(PYTHON) $(SCRIPTS)/opcodes-vhdl.py opcodes.tex $(CORE_LIB)/core_opcode_pkg.vhd \
		$(TEMP)/core_opcode_pkg.vhd
	$(PYTHON) $(SCRIPTS)/registers-latex.py gbreg.tex \
		$(TEMP)/gbreg.generated.tex
	$(PYTHON) $(SCRIPTS)/registers-latex.py cxreg.tex \
		$(TEMP)/cxreg.generated.tex
	$(PYTHON) $(SCRIPTS)/traps-latex.py traps.tex \
		$(TEMP)/traps.generated.tex
	$(PYTHON) $(SCRIPTS)/rvex_h.py gbreg.tex cxreg.tex traps.tex \
		$(TEMP)/rvex.h
	
