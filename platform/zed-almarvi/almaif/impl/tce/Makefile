
top:
	@echo "Please call make from the parent directory."

include ../../config.makefile
include ../../tools.makefile

IP = ip/ip.srcs/component.xml

.PHONY: clean
clean:
	$(RM) -r ip work
	$(RM) -f *.jou *.log *.dump *.img transcript *.wlf wlft* *stacktrace.vstf

.PHONY: all
all: $(IP)
$(IP): rtl
	$(VIVADO) -mode batch -source generate_ip.tcl

.PHONY: sim
sim:
	./modsim_compile.sh
	$(CP) testsw/fib/fib.img .
	$(CP) testsw/fib/fib_data.img .
	$(VSIM) -t ps -novopt -L unisim work.tta_axislave_tb

