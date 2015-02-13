
# Compile the VHDL files.
do compile.do

# Give simulate command.
vsim -t ps -novopt -L unisim work.testbench

onerror {resume}

#Change radix to Hexadecimal#
radix hex

# Supress spam.
set NumericStdNoWarnings 1
set StdArithNoWarnings 1
