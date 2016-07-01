
# Compile the VHDL files.
do compile.do

# Give simulate command.
vsim -t ps -novopt -L unisim work.vc707_tb

onerror {resume}

# Change default radix to hexadecimal.
radix hex

# Add core status strings to simulation.
add wave                     -label rv2sim           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/rv2sim
add wave                     -label rv2sim           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/rv2sim

add wave -divider RIT        -label rit_timer        sim:/vc707_tb/uut/rvex_standalone/rit_block/rit_timer
add wave                     -label rit_max          sim:/vc707_tb/uut/rvex_standalone/rit_block/rit_max 
add wave                     -label rit_pend         sim:/vc707_tb/uut/rvex_standalone/rit_block/rit_pend 
add wave                     -label rit_ack          sim:/vc707_tb/uut/rvex_standalone/rit_block/rit_ack 

add wave -divider Context_0  -label PC               sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cxreg_gen(0)/cxreg_inst/cxreg2cxplif_currentPC
add wave                     -label active           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cfg_inst/cfg2cxplif_active(0)
add wave                     -label int_en           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cxreg_gen(0)/cxreg_inst/cxreg2cxplif_interruptEnable
add wave                     -label reconf           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cfg_inst/cfg2cxplif_requestReconfig(0)
add wave                     -label blockReconf      sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cfg_inst/cxplif2cfg_blockReconfig(0)

add wave                     -label PC               sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cxreg_gen(0)/cxreg_inst/cxreg2cxplif_currentPC
add wave                     -label active           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cfg_inst/cfg2cxplif_active(0)
add wave                     -label int_en           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cxreg_gen(0)/cxreg_inst/cxreg2cxplif_interruptEnable
add wave                     -label reconf           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cfg_inst/cfg2cxplif_requestReconfig(0)
add wave                     -label blockReconf      sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cfg_inst/cxplif2cfg_blockReconfig(0)

add wave -divider Context_1  -label PC               sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cxreg_gen(1)/cxreg_inst/cxreg2cxplif_currentPC
add wave                     -label active           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cfg_inst/cfg2cxplif_active(1)
add wave                     -label int_en           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cxreg_gen(1)/cxreg_inst/cxreg2cxplif_interruptEnable
add wave                     -label reconf           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cfg_inst/cfg2cxplif_requestReconfig(1)
add wave                     -label blockReconf      sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cfg_inst/cxplif2cfg_blockReconfig(1)

add wave                     -label PC               sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cxreg_gen(1)/cxreg_inst/cxreg2cxplif_currentPC
add wave                     -label active           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cfg_inst/cfg2cxplif_active(1)
add wave                     -label int_en           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cxreg_gen(1)/cxreg_inst/cxreg2cxplif_interruptEnable
add wave                     -label reconf           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cfg_inst/cfg2cxplif_requestReconfig(1)
add wave                     -label blockReconf      sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cfg_inst/cxplif2cfg_blockReconfig(1)

add wave -divider Context_2  -label PC               sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cxreg_gen(2)/cxreg_inst/cxreg2cxplif_currentPC
add wave                     -label active           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cfg_inst/cfg2cxplif_active(2)
add wave                     -label int_en           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cxreg_gen(2)/cxreg_inst/cxreg2cxplif_interruptEnable
add wave                     -label reconf           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cfg_inst/cfg2cxplif_requestReconfig(2)
add wave                     -label blockReconf      sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cfg_inst/cxplif2cfg_blockReconfig(2)

add wave                     -label PC               sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cxreg_gen(2)/cxreg_inst/cxreg2cxplif_currentPC
add wave                     -label active           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cfg_inst/cfg2cxplif_active(2)
add wave                     -label int_en           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cxreg_gen(2)/cxreg_inst/cxreg2cxplif_interruptEnable
add wave                     -label reconf           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cfg_inst/cfg2cxplif_requestReconfig(2)
add wave                     -label blockReconf      sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cfg_inst/cxplif2cfg_blockReconfig(2)

add wave -divider Context_3  -label PC               sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cxreg_gen(3)/cxreg_inst/cxreg2cxplif_currentPC
add wave                     -label active           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cfg_inst/cfg2cxplif_active(3)
add wave                     -label int_en           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cxreg_gen(3)/cxreg_inst/cxreg2cxplif_interruptEnable
add wave                     -label reconf           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cfg_inst/cfg2cxplif_requestReconfig(3)
add wave                     -label blockReconf      sim:/vc707_tb/uut/rvex_standalone/rvex_inst/core_gen/core/core/cfg_inst/cxplif2cfg_blockReconfig(3)

add wave                     -label PC               sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cxreg_gen(3)/cxreg_inst/cxreg2cxplif_currentPC
add wave                     -label active           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cfg_inst/cfg2cxplif_active(3)
add wave                     -label int_en           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cxreg_gen(3)/cxreg_inst/cxreg2cxplif_interruptEnable
add wave                     -label reconf           sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cfg_inst/cfg2cxplif_requestReconfig(3)
add wave                     -label blockReconf      sim:/vc707_tb/uut/rvex_standalone/rvex_inst/cached_core_gen/cached_core/core/cfg_inst/cxplif2cfg_blockReconfig(3)

# Supress spam.
set NumericStdNoWarnings 1
set StdArithNoWarnings 1
