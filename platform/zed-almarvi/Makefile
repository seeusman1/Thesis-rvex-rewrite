
# This makefile contains extensions of the targets in the almaif/ directory
# that only work as a platform within the rvex-rewrite repository. All targets
# within the almaif/ directory operate independently.

top: help

# Include tool configuration from the almaif repo.
include almaif/tools.makefile


#-------------------------------------------------------------------------------
# r-VEX library management
#-------------------------------------------------------------------------------

RVLIB_SOURCE   = ../../lib/rvex

RVLIB_SOURCES  = $(addprefix $(realpath $(RVLIB_SOURCE)/common)/,$(shell cat $(RVLIB_SOURCE)/common/vhdlsyn.txt))
RVLIB_SOURCES += $(addprefix $(realpath $(RVLIB_SOURCE)/utils)/, $(shell cat $(RVLIB_SOURCE)/utils/vhdlsyn.txt))
RVLIB_SOURCES += $(addprefix $(realpath $(RVLIB_SOURCE)/bus)/,   $(shell cat $(RVLIB_SOURCE)/bus/vhdlsyn.txt))
RVLIB_SOURCES += $(addprefix $(realpath $(RVLIB_SOURCE)/core)/,  $(shell cat $(RVLIB_SOURCE)/core/vhdlsyn.txt))
RVLIB_SOURCES += $(addprefix $(realpath $(RVLIB_SOURCE)/cache)/, $(shell cat $(RVLIB_SOURCE)/cache/vhdlsyn.txt))
RVLIB_SOURCES += $(realpath $(RVLIB_SOURCE)/system/rvsys_standalone_pkg.vhd)
RVLIB_SOURCES += $(realpath $(RVLIB_SOURCE)/system/rvsys_standalone_core.vhd)
RVLIB_SOURCES += $(realpath $(RVLIB_SOURCE)/system/rvsys_standalone_cachedCore.vhd)
RVLIB_SOURCES += $(realpath $(RVLIB_SOURCE)/system/rvsys_standalone.vhd)
RVLIB_SOURCES += $(realpath $(RVLIB_SOURCE)/periph/periph_trace.vhd)

RVLIB_DEPS     = $(filter-out %rvex-version-pkg.vhd,$(RVLIB_SOURCES))

RVLIB          = almaif/impl/rvex/rtl/rvex

.PHONY: rvlib
rvlib: $(RVLIB)
$(RVLIB): $(RVLIB_DEPS)
	
	# Generate core version tag and archive the core files.
	$(PYTHON) ../../versions/tools/archive_core.py
	
	# Copy the core files into the almaif repo.
	$(RM) -r $(RVLIB)
	$(MKDIR) -p $(RVLIB)
	$(CP) $(RVLIB_SOURCES) $(RVLIB)
	
	# Change the rvex library name to work to make the IP inclusion easier.
	$(SED) -e 's/^library rvex;/library work;/' -i'' $(RVLIB)/*.vhd
	$(SED) -e 's/^use rvex\./use work./' -i'' $(RVLIB)/*.vhd
	$(SED) -e 's/: entity rvex\./: entity work./' -i'' $(RVLIB)/*.vhd
	
	# Output compile order.
	-$(RM) $(RVLIB)/compile-order
	for i in $(notdir $(RVLIB_SOURCES)); do echo $$i >> $(RVLIB)/compile-order; done


#-------------------------------------------------------------------------------
# rvsrv/rvd tools
#-------------------------------------------------------------------------------

RVD_SOURCE     = ../../tools/debug-interface
RVD_INC        = rvd-inc
RVD            = almaif/utils/rvd

.PHONY: rvd
rvd: $(RVD)
$(RVD): $(RVD_SOURCE) $(RVD_INC)
	$(RM) -r $(RVD)
	$(MKDIR) -p $(RVD)
	$(CP) -r $(RVD_SOURCE)/* $(RVD)
	$(RM) $(RVD)/configuration.cfg
	cd $(RVD) && $(MAKE) clean
	$(RM) $(RVD)/configuration.cfg $(RVD)/memory.map $(RVD)/core.template.map
	$(MV) $(RVD)/core.map $(RVD)/rvex-core.map
	$(MV) $(RVD)/src/default-memory.map $(RVD)/rvex.map
	$(RM) $(RVD)/src/default-configuration.cfg
	$(RM) $(RVD)/makefile $(RVD)/USAGE
	$(CP) -r $(RVD_INC)/* $(RVD)


#-------------------------------------------------------------------------------
# Chain to the makefile in test-progs/ for testing the r-VEX on the board with
# the usual programs and benchmarks
#-------------------------------------------------------------------------------

.PHONY: upload-%
upload-%:
	cd test-progs && $(MAKE) $@

.PHONY: start-%
start-%:
	cd test-progs && $(MAKE) $@

.PHONY: run-%
run-%:
	cd test-progs && $(MAKE) $@

.PHONY: trace-%
trace-%:
	cd test-progs && $(MAKE) $@

.PHONY: gdb-%
gdb-%:
	cd test-progs && $(MAKE) $@

.PHONY: server stop monitor monitor-nobuf
server stop monitor monitor-nobuf:
	cd test-progs && $(MAKE) $@

.PHONY: debug
debug:
	cd test-progs && $(MAKE) $@
	cat ../../tools/debug-interface/debug > debug
	echo 'export RVD_OPT="-m$(shell pwd)/rvd-inc/almarvi.map"' >> debug
	@echo ""
	@echo " Run \"source debug\" now..."
	@echo ""

.PHONY: clean-ex
clean-ex:
	cd test-progs && $(MAKE) clean


#-------------------------------------------------------------------------------
# Chain to the makefile in almaif/
#-------------------------------------------------------------------------------

.DEFAULT:
	$(MAKE) rvlib rvd
	@cd almaif && $(MAKE) --no-print-directory $@

.PHONY: clean-almarvi
clean-almarvi:
	cd almaif && $(MAKE) clean


#-------------------------------------------------------------------------------
# Distribution
#-------------------------------------------------------------------------------

.PHONY: dist
dist: rvlib
	cd almaif/impl/rvex/testsw/fib && $(MAKE) clean && $(MAKE) all
	$(GIT) ls-files -io --exclude-standard almaif > ignored
	$(PYTHON) dist.py
	$(RM) ignored

.PHONY: dist-push
dist-push:
	rsync -avu --exclude boards/zed/dl almaif/* pocl-almarvi-ipif/almaif

.PHONY: dist-pull
dist-pull:
	rsync -avu --exclude boards/zed/dl pocl-almarvi-ipif/almaif/* almaif

.PHONY: dist-sync
dist-sync: dist-push dist-pull


#-------------------------------------------------------------------------------
# Cleaning
#-------------------------------------------------------------------------------

.PHONY: clean
clean: clean-ex clean-almarvi
	$(RM) -r $(RVD)
	$(RM) -r $(RVLIB)

#-------------------------------------------------------------------------------
# Conformance test stuff
#-------------------------------------------------------------------------------

.PHONY: conformance
	cd test-progs && $(MAKE) $@
