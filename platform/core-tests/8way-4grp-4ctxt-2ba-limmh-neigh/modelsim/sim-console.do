
onerror {exit}
onbreak {resume}

# Compile the VHDL files.
do compile.do

# Give simulate command.
vsim -c -t ps -novopt -L unisim work.core_tb

# Supress spam.
set NumericStdNoWarnings 1
set StdArithNoWarnings 1

run -all
exit
