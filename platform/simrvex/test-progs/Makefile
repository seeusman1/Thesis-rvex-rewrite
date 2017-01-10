
# Toolchain setup.
TOOLS = ../../../tools
GEN_TEST_PROGS = ../../../test-progs

# Platform-specific executables.
EXECUTABLES = convolution convolution_5x5 convolution_7x7 greyscale median framebuffertest

# Platform-specific code to link.
OBJECTS = platform.a

# Include generic test program makefile.
include $(GEN_TEST_PROGS)/Makefile

# Simulator command line.
SIM = ADAPTOR_CONFIG=cfg/plugin.conf LD_LIBRARY_PATH=$(TOOLS)/simrvex/lib64/sim200 $(TOOLS)/simrvex/bin/simrvex

# How to create the platform.a library
platform.a: platform.o simrvex_stubs.o
	$(AR) r $@ $^

.PHONY: help
help:
	@echo ""
	@echo " This platform allows you to easily run test programs on the simrvex simulator."
	@echo ""
	@echo ""
	@echo " Make targets:"
	@echo ""
	@echo "  make <prog>          : just compiles the specified program."
	@echo ""
	@echo "  make sim-<prog>      : runs prog on the simulator"
	@echo ""
	@echo "  make simtest-<prog>  : runs prog on the simulator and checks return code."
	@echo ""
	@echo "  make simtestall      : calls simtest-<prog> for all executables."
	@echo "  will output a list of success/failures to file \'simtestall\'"
	@echo ""
	@echo "  make clean           : cleans intermediate files."
	@echo ""
	$(MAKE) --no-print-directory list-executables
	@echo ""

# How to run simrvex
sim-%: %.elf
	${SIM} $< $(SIMFLAGS)

.PHONY: simtestall
simtestall: simtestall-clean $(POWERSTONE:%=simtest-%)

.PHONY: simtestall-clean
simtestall-clean:
	echo -n "" > simtestall

#The Powerstone programs all return 0xdeadbeef. 
#We take the last register contents using tail and grep for that value in r3 (return value register).
simtest-% : %.elf
	@${SIM} -t1,0 --batch $^|tail -n 40 | grep "RET: 0";\
	if [ $$? != 0 ] ; then \
	echo "Program returned unexpected exit code" ; echo $* >> simtestall; echo -e "\t\tError!" >> simtestall; \
	else \
	echo "Program Finished Successfully" ; echo $* >> simtestall; echo -e "\t\tOK" >> simtestall;  \
	fi

simtrace-% : %.elf
	${SIM} -t1,0 $< > $@


