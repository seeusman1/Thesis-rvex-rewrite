add wave sim:/testbench/d3/rvsys_gen(0)/rvsys_inst/rvex_block/rvex_inst/rv2sim

do bridge.do

add wave -group Memory -label "AHB to bridge" sim:/testbench/d3/ahb2mig0/ahbsi
add wave -group Memory -label "Bridge to AHB" sim:/testbench/d3/ahb2mig0/ahbso
add wave -group Memory -label "Bridge to MIG" sim:/testbench/d3/ahb2mig0/migi
add wave -group Memory -label "MIG to bridge" sim:/testbench/d3/ahb2mig0/migo
