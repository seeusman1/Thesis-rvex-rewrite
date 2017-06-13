
TARGETS = rvex-user-manual.pdf

all: $(TARGETS)

clean:
	rm -f $(TARGETS)

.PHONY: rvex-user-manual.pdf
rvex-user-manual.pdf:
	cd src/userman && $(MAKE) clean all
	cp src/userman/userman.pdf rvex-user-manual.pdf
	cd src/userman && $(MAKE) clean
