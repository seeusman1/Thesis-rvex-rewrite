
# Toolchain setup.
TOOLS = ../../../../tools
GEN_EXAMPLES = ../../../../examples

# Platform-specific executables.
EXECUTABLES = div extReconf factorial

# Platform-specific object files to link.
OBJECTS = rvex-tests.o

# Compilation configuration.
ISSUE_WIDTH = 2
LANECONFIG = 7B
BUNDLE_ALIGN = 2
DYNAMIC = false
LIMMH_PREV = false

# Recompiles the test case executables.
.PHONY: recompile
recompile:
	$(MAKE) clean
	$(MAKE) ucbqsort-fast.srec div.srec extReconf.srec factorial.srec

# Include generic examples makefile.
include $(GEN_EXAMPLES)/Makefile
