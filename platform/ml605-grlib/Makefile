
.PHONY: help update-patch very-clean gr-%

help: work
	@echo ""
	@echo " This makefile generates the grlib design directory from the leon3-xilinx-ml605"
	@echo " design in grlib in work, keeping all the grlib specific sources away from the"
	@echo " rvex repository (where it doesn't belong, and which is differently licensed)."
	@echo " The makefile has already generated the working directory as you're reading"
	@echo " this."
	@echo ""
	@echo " Targets specific to wrapper makefile:"
	@echo ""
	@echo " make update-patch : cleans the working directory and generates the work.patch"
	@echo "                     file used to rebuild the working directory from the grlib"
	@echo "                     base project."
	@echo " make very-clean   : removes the ENTIRE grlib working directory: careful! This"
	@echo "                     might remove source files!"
	@echo ""
	@echo " The following targets are from the grlib makefile (you can also cd to work if"
	@echo " you don't want to type gr- all the time)"
	
	@# The sed magic replaces the make commands listed in grlib's help to prefix
	@# them with "gr-", which is how this makefile expects them to be called. It
	@# also removes the "entering directory" and "leaving directory" spam from
	@# the make recursion.
	@cd work && $(MAKE) help | sed -e "s/make \([a-zA-Z0-9_-]*\)/make gr-\1/;s/make\[1\]\([^\n]*\)work'//"

# Copies the base project from grlib into work and patches it.
work:
	cp -r ../../grlib/grlib-gpl-1.3.7-b4144/designs/leon3-xilinx-ml605 .
	mv ./leon3-xilinx-ml605 ./work
	cd work && patch -p1 < ../work.patch

# Updates the patchfile based upon the differences between the grlib base
# project and the current contents of work. Kind of the inverse operation of
# the "work" target.
update-patch:
	@cd work && $(MAKE) distclean
	diff -rupN ../../grlib/grlib-gpl-1.3.7-b4144/designs/leon3-xilinx-ml605/ work/ > work.patch ; true

# Removes the entire working directory; use with care (because the work dir might contain
# source files as well, which may not have been put in the patch file yet).
very-clean:
	rm -Ir work

# Recursively calls grlib's makefile.
gr-%: work
	@cd work && $(MAKE) $(patsubst gr-%,%,$@)

