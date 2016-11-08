
TARGETS = regs/gp-regs-gen.test

.PHONY: all
all: $(TARGETS)

.PHONY: clean
clean:
	rm -f $(TARGETS)

regs/gp-regs-gen.test: ../../share/gpregs.py Makefile
	python3 $< -l 2 -s 0 -o $@
