
VERSION = rvex-release-4.0

OUTPUT = rvex-release
STATIC = $(OUTPUT)/static
TREE = $(OUTPUT)/$(VERSION)
STATUS = $(OUTPUT)/$(VERSION)-status

# Git repository configuration.
RVEX_DIR = .
RVEX_GIT = git@bitbucket.org:jvanstraten/rvex-rewrite.git
RVEX_COMMIT = master
BINUTILS_DIR = tools/binutils-gdb
BINUTILS_GIT = git@bitbucket.org:anarcobra/binutils-gdb.git
BINUTILS_COMMIT = master
GCC_DIR = tools/gcc
GCC_GIT = git@bitbucket.org:anarcobra/gcc.git
GCC_COMMIT = master
VEXPARSE_DIR = tools/vexparse
VEXPARSE_GIT = git@bitbucket.org:anarcobra/vexparse.git
VEXPARSE_COMMIT = master

# Configuration for other downloads.
HP_VEX_DIR = tools/vex-3.43
HP_VEX_XDIR = tools
HP_VEX_URL = http://www.hpl.hp.com/downloads/vex/vex-3.43.i586.tgz
HP_VEX_FNAME = vex-3.43.i586.tgz

GRLIB_VERSION = grlib-gpl-1.3.7-b4144
GRLIB_DIR = grlib
GRLIB_URL = http://www.gaisler.com/products/grlib/$(GRLIB_VERSION).tar.gz
GRLIB_FNAME = $(GRLIB_VERSION).tar.gz

# List of things which have no online source which need to be copied from the
# working tree:
COPY += tools/sim

# Files to remove from the release:
TRIM_GLOBAL += .git
TRIM_GLOBAL += .gitignore
TRIM_GLOBAL += temp
TRIM += platform/zed-standalone
TRIM += release.makefile

.PHONY: help
help:
	@echo ""
	@echo ""
	@echo ""
	@echo " This makefile is supposed to generate a release tar.gz of the rvex core and"
	@echo " related (redistributable) utilities. This is done using the following command:"
	@echo ""
	@echo "   make release"
	@echo ""
	@echo " The release is generated in '$(OUTPUT)'. The following steps are taken to"
	@echo " generate the release."
	@echo ""
	@echo " First, the following git repositories will be cloned:"
	@echo ""
	@echo "  - $(RVEX_GIT)"
	@echo "     '-> branch/commit: $(RVEX_COMMIT)"
	@echo ""
	@echo "  - $(BINUTILS_GIT)"
	@echo "     '-> branch/commit: $(BINUTILS_COMMIT)"
	@echo ""
	@echo "  - $(GCC_GIT)"
	@echo "     '-> branch/commit: $(GCC_COMMIT)"
	@echo ""
	@echo "  - $(VEXPARSE_GIT)"
	@echo "     '-> branch/commit: $(VEXPARSE_COMMIT)"
	@echo ""
	@echo " The following archive will be downloaded for the HP compiler:"
	@echo ""
	@echo "  - $(HP_VEX_URL)"
	@echo ""
	@echo " The following files/directories will be copied from the working"
	@echo " directory with no modifications:"
	@echo ""
	@for i in $(COPY); do echo "  - $$i"; done
	@echo ""
	@echo " The following files/directories are removed from the release"
	@echo " globally:"
	@echo ""
	@for i in $(TRIM_GLOBAL); do echo "  - $$i"; done
	@echo ""
	@echo " The following files/directories are removed from the release"
	@echo " relative to the root:"
	@echo ""
	@for i in $(TRIM); do echo "  - $$i"; done
	@echo ""
	

.PHONY: release
release: $(OUTPUT)/$(VERSION).tar.gz
$(OUTPUT)/$(VERSION).tar.gz: $(STATUS)/completed
	# <DISABLED> cd $(OUTPUT) && tar -czf $(VERSION).tar.gz $(VERSION)

.PHONY: clean
clean:
	@if [ -d "$(TREE)" ]; then \
		echo ""; \
		printf "\033[1;31m YOU ARE ABOUT TO DELETE ALL INTERMEDIATE FILES/BUILD STATUS FOR \033[0m\n"; \
		printf "\033[1;31m VERSION '$(VERSION)'. ARE YOU SURE? \033[0m\n"; \
		echo ""; \
		rm -rI $(TREE); \
		if [ ! -d "$(TREE)" ]; then \
			rm -rf $(STATUS); \
		else \
			exit 1; \
		fi \
	fi

$(STATUS)/initialized:
	$(MAKE) clean
	mkdir -p $(TREE)
	mkdir -p $(STATUS)
	touch $@

$(STATUS)/pull-rvex: $(STATUS)/initialized
	rm -rf $(TREE)/$(RVEX_DIR)
	mkdir -p $(TREE)/$(RVEX_DIR)
	cd $(TREE)/$(RVEX_DIR) && git init
	cd $(TREE)/$(RVEX_DIR) && git remote add origin $(RVEX_GIT)
	cd $(TREE)/$(RVEX_DIR) && git fetch origin $(RVEX_COMMIT)
	cd $(TREE)/$(RVEX_DIR) && git reset --hard FETCH_HEAD
	touch $@

$(STATUS)/pull-binutils: $(STATUS)/pull-rvex
	rm -rf $(TREE)/$(BINUTILS_DIR)
	mkdir -p $(TREE)/$(BINUTILS_DIR)
	cd $(TREE)/$(BINUTILS_DIR) && git init
	cd $(TREE)/$(BINUTILS_DIR) && git remote add origin $(BINUTILS_GIT)
	cd $(TREE)/$(BINUTILS_DIR) && git fetch origin $(BINUTILS_COMMIT)
	cd $(TREE)/$(BINUTILS_DIR) && git reset --hard FETCH_HEAD
	touch $@

$(STATUS)/pull-gcc: $(STATUS)/pull-binutils
	rm -rf $(TREE)/$(GCC_DIR)
	mkdir -p $(TREE)/$(GCC_DIR)
	cd $(TREE)/$(GCC_DIR) && git init
	cd $(TREE)/$(GCC_DIR) && git remote add origin $(GCC_GIT)
	cd $(TREE)/$(GCC_DIR) && git fetch origin $(GCC_COMMIT)
	cd $(TREE)/$(GCC_DIR) && git reset --hard FETCH_HEAD
	touch $@

$(STATUS)/pull-vexparse: $(STATUS)/pull-gcc
	rm -rf $(TREE)/$(VEXPARSE_DIR)
	mkdir -p $(TREE)/$(VEXPARSE_DIR)
	cd $(TREE)/$(VEXPARSE_DIR) && git init
	cd $(TREE)/$(VEXPARSE_DIR) && git remote add origin $(VEXPARSE_GIT)
	cd $(TREE)/$(VEXPARSE_DIR) && git fetch origin $(VEXPARSE_COMMIT)
	cd $(TREE)/$(VEXPARSE_DIR) && git reset --hard FETCH_HEAD
	touch $@

$(STATIC)/$(HP_VEX_FNAME):
	mkdir -p $(STATIC)
	cd $(STATIC) && wget $(HP_VEX_URL)

$(STATUS)/extract-vex: $(STATIC)/$(HP_VEX_FNAME) $(STATUS)/pull-rvex
	rm -rf $(TREE)/$(HP_VEX_DIR)
	mkdir -p $(TREE)/$(HP_VEX_XDIR)
	cp $(STATIC)/$(HP_VEX_FNAME) $(TREE)/$(HP_VEX_XDIR)
	cd $(TREE)/$(HP_VEX_XDIR) && tar -xzf $(HP_VEX_FNAME)
	rm -f $(TREE)/$(HP_VEX_XDIR)/$(HP_VEX_FNAME)
	touch $@

$(STATIC)/$(GRLIB_FNAME):
	mkdir -p $(STATIC)
	cd $(STATIC) && wget $(GRLIB_URL)

$(STATUS)/cache-grlib: $(STATIC)/$(GRLIB_FNAME) $(STATUS)/pull-rvex
	mkdir -p $(TREE)/$(GRLIB_DIR)
	cp $(STATIC)/$(GRLIB_FNAME) $(TREE)/$(GRLIB_DIR)
	touch $@

$(TREE)/%: % $(STATUS)/pull-rvex
	cp -RL $< $(dir $@)

$(STATUS)/copy: $(patsubst %,$(TREE)/%,$(COPY)) $(STATUS)/pull-rvex
	touch $@

$(STATUS)/download: $(STATUS)/pull-rvex $(STATUS)/pull-binutils $(STATUS)/pull-gcc $(STATUS)/pull-vexparse $(STATUS)/extract-vex $(STATUS)/cache-grlib $(STATUS)/copy
	touch $(STATUS)/download

# MUCH TODO

$(STATUS)/completed: $(STATUS)/download
	touch $(STATUS)/completed

