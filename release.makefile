
VERSION = rvex-release-4.0

OUTPUT = rvex-release
TREE = $(OUTPUT)/$(VERSION)
STATUS = $(OUTPUT)/$(VERSION)-status

# Git repository configuration.
RVEX_GIT = git@bitbucket.org:jvanstraten/rvex-rewrite.git
RVEX_COMMIT = master
BINUTILS_GIT = git@bitbucket.org:anarcobra/binutils-gdb.git
BINUTILS_COMMIT = master
GCC_GIT = git@bitbucket.org:anarcobra/gcc.git
GCC_COMMIT = master
VEXPARSE_GIT = git@bitbucket.org:anarcobra/vexparse.git
VEXPARSE_COMMIT = master

# Configuration for other downloads.
HP_VEX = http://www.hpl.hp.com/downloads/vex/vex-3.43.i586.tgz

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
	@echo "  - $(HP_VEX)"
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
	cd $(OUTPUT) && tar -czvf $(VERSION).tar.gz $(VERSION)

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

$(STATUS)/initialized: clean
	mkdir -p $(TREE)
	mkdir -p $(STATUS)
	touch $(STATUS)/initialized

# MUCH TODO

$(STATUS)/completed: $(STATUS)/initialized
	touch $(STATUS)/completed

