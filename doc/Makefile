
TARGETS = core.pdf

all: $(TARGETS)

clean:
	rm -f $(TARGETS)

core.pdf:
	cd src/core && $(MAKE) all
	cp src/core/core.pdf core.pdf
	cd src/core && $(MAKE) clean
