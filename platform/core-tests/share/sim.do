
# Compile the VHDL files.
do compile.do

# Increase the iteration limit. This is needed because processing a load
# command takes two delta delays.
set IterationLimit 500000

# Give simulate command.
vsim -t ps -novopt -L unisim work.core_tb

onerror {resume}
add wave -group "Test case info" sim:/core_tb/sim_*

# Change radix to hexadecimal.
radix hex

# Supress spam.
set NumericStdNoWarnings 1
set StdArithNoWarnings 1

run -all

