
# This makefile contains extensions of the targets in the almarvi/ directory
# that only work as a platform within the rvex-rewrite repository. All targets
# within the almarvi/ directory operate independently.

# Include tool configuration from the almarvi repo.
include almarvi/tools.makefile

# r-VEX library sources.
RVLIB_SOURCE   = ../../lib/rvex
RVLIB          = almarvi/rvex/rtl/rvex

#-------------------------------------------------------------------------------
# r-VEX library management
#-------------------------------------------------------------------------------

RVLIB_SOURCES  = $(addprefix $(realpath $(RVLIB_SOURCE)/common)/,$(shell cat $(RVLIB_SOURCE)/common/vhdlsyn.txt))
RVLIB_SOURCES += $(addprefix $(realpath $(RVLIB_SOURCE)/utils)/, $(shell cat $(RVLIB_SOURCE)/utils/vhdlsyn.txt))
RVLIB_SOURCES += $(addprefix $(realpath $(RVLIB_SOURCE)/bus)/,   $(shell cat $(RVLIB_SOURCE)/bus/vhdlsyn.txt))
RVLIB_SOURCES += $(addprefix $(realpath $(RVLIB_SOURCE)/core)/,  $(shell cat $(RVLIB_SOURCE)/core/vhdlsyn.txt))
RVLIB_SOURCES += $(realpath $(RVLIB_SOURCE)/cache/cache_pkg.vhd)
RVLIB_SOURCES += $(realpath $(RVLIB_SOURCE)/system/rvsys_standalone_pkg.vhd)
RVLIB_SOURCES += $(realpath $(RVLIB_SOURCE)/system/rvsys_standalone_core.vhd)

.PHONY: rvlib
rvlib:
	# Generate core version tag and archive the core files.
	$(PYTHON) ../../versions/tools/archive_core.py
	
	# Copy the core files into the almarvi repo.
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

.PHONY: ip
ip: rvlib
	cd almarvi && $(MAKE) ip
