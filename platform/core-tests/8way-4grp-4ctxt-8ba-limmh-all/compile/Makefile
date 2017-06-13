
# Toolchain setup.
TOOLS = ../../../../tools
GEN_TEST_PROGS = ../../../../test-progs

# Platform-specific executables.
EXECUTABLES = div extReconf factorial

# Platform-specific object files to link.
OBJECTS = rvex-tests.o

# Compilation configuration.
ISSUE_WIDTH = 8
LANECONFIG = 7373737B
BUNDLE_ALIGN = 8
DYNAMIC = true-O2
LIMMH_PREV = true

# Recompiles the test case executables.
.PHONY: recompile
recompile:
	$(MAKE) clean
	$(MAKE) ucbqsort-fast.srec div.srec extReconf.srec factorial.srec

# Include generic test program makefile.
include $(GEN_TEST_PROGS)/include.makefile
