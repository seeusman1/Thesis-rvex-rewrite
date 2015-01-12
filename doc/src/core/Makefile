
TARGET=core
ASSETS=assets/rvex-block-diagram/rvex-block-diagram-linked.tex

.PHONY: all clean

# Makes the PDF.
all: $(ASSETS) pdf

# Clean everything.
clean: pdf-distclean
	rm -f $(ASSETS)

# Add hyperlinks to the block diagram.
assets/rvex-block-diagram/rvex-block-diagram-linked.tex: assets/rvex-block-diagram/rvex-block-diagram.tex
	@cd assets/rvex-block-diagram && ./hyperlink.sh

# Include the makefile with pdflatex magic.
include ../pdflatex-makefile.include
