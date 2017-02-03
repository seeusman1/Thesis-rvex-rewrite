
TOOLS = ../tools
CONFORM = python3 $(TOOLS)/misc/conform.py

# Simulation platforms.
SUPPORTED_PLATFORMS += simrvex core-tests cache-test
UNSTABLE_PLATFORMS += 

# ML605 platforms.
SUPPORTED_PLATFORMS += ml605-standalone ml605-doom ml605-grlib
UNSTABLE_PLATFORMS += ml605-grlib-bare

# VC707 platforms.
SUPPORTED_PLATFORMS += vc707-standalone
UNSTABLE_PLATFORMS += vc707-grlib vc707-stream

# Zedboard platforms.
SUPPORTED_PLATFORMS += 
UNSTABLE_PLATFORMS += zed-almarvi


ALL_PLATFORMS = $(SUPPORTED_PLATFORMS) $(UNSTABLE_PLATFORMS)

.PHONY: all
all:
	@echo ""
	@echo " Targets:"
	@echo ""
	@echo "  make clean        : runs make clean for all platforms."
	@echo ""
	@echo "  make conformance  : runs the conformance test for all platforms."
	@echo ""

.PHONY: clean clean-%
clean: $(patsubst %,clean-%,$(ALL_PLATFORMS))
clean-%:
	cd $* && $(MAKE) clean

.PHONY: conformance conformance-%
conformance: $(patsubst %,conformance-%,$(SUPPORTED_PLATFORMS))
conformance-%:
	@$(CONFORM) $* "cd $* && $(MAKE) -ksj conformance"

