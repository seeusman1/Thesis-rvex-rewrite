
# Compile the VHDL files.
do compile.do

# Give simulate command.
vsim -t ps -novopt -L unisim work.core_tb

onerror {resume}
add wave -group "Test case info" sim:/core_tb/sim_*

#Change radix to Hexadecimal#
radix hex

# Supress spam.
set NumericStdNoWarnings 1
set StdArithNoWarnings 1

run 1000 ms
