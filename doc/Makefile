
TARGETS = reference-manual.pdf

all: $(TARGETS)

clean:
	rm -f $(TARGETS)

.PHONY: reference-manual.pdf
reference-manual.pdf:
	cd src/refman && $(MAKE) clean all
	cp src/refman/refman.pdf reference-manual.pdf
	cd src/refman && $(MAKE) clean
