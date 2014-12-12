
# Source compile script. This can be generated from ISE *.prj files using the
# prj2do.sh script. ISE outputs these *.prj files when (for example) you run
# "Behavioral Check Syntax" in the Simulation view with ISim set as the default
# simulator.
vlib rvex
source core_tb_compile.do

# Give simulate command.
vsim -t ps -novopt -L unisim rvex.core_tb

onerror {resume}
add wave -group "Test case info" sim:/core_tb/sim_*

#Change radix to Hexadecimal#
radix hex

# Supress spam.
set NumericStdNoWarnings 1
set StdArithNoWarnings 1

run 1000 ms
