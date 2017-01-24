
onerror {exit}
onbreak {resume}

# Compile the VHDL files.
do compile.do

# Increase the iteration limit. This is needed because processing a load
# command takes two delta delays.
set IterationLimit 500000

# Give simulate command.
vsim -c -t ps -novopt -L unisim work.core_tb

# Supress spam.
set NumericStdNoWarnings 1
set StdArithNoWarnings 1

puts "START_SIM"

run -all
exit
