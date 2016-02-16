
TARGET=refman
ASSETS=assets/rvex-block-diagram/rvex-block-diagram-linked.tex

.PHONY: all clean

# Makes the PDF.
all: $(ASSETS) pdf

# Clean everything.
clean: pdf-distclean
	rm -f $(ASSETS)
	rm -f $(TARGET)*.py
	rm -f $(TARGET)*.py.err
	rm -f $(TARGET)*.py.out
	rm -f latex.py
	rm -f *.pyc
	rm -f $(TARGET).tdo

# Add hyperlinks to the block diagram.
assets/rvex-block-diagram/rvex-block-diagram-linked.tex: assets/rvex-block-diagram/rvex-block-diagram.tex
	@cd assets/rvex-block-diagram && ./hyperlink.sh

# Include the makefile with pdflatex magic.
ROOT=..
include ../pdflatex-makefile.include
