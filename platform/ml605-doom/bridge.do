radix -hexadecimal
for {set i 0} {$i < 4} {incr i} {
	foreach {name} [list reset clk bus2bridge bridge2bus bridge2ahb ahb2bridge ahbReq_enable ahbReq_address ahbReq_size ahbReq_hprot ahbReq_writeEnable ahbReq_writeData ahbReq_error ahb_forceIdle ahb_forceWait ahb_sequential busRes_ack busRes_readData busRes_error hconfig] {
		add wave -group "Bus to AHB $i" -label $name sim:/testbench/d3/rvsys_gen(0)/rvsys_inst/ahb_bus_bridge_gen($i)/ahb_bus_bridge_inst/$name
	}
	add wave -group "Bus to AHB $i" -label {Cycle Counter} /testbench/d3/rvsys_gen(0)/rvsys_inst/rvex_block/rvex_inst/creg_inst/context_reg_bank_gen($i)/context_reg_bank/r(143)
	add wave -group "Bus to AHB $i" -label {Stall Counter} /testbench/d3/rvsys_gen(0)/rvsys_inst/rvex_block/rvex_inst/creg_inst/context_reg_bank_gen($i)/context_reg_bank/r(144)
	add wave -group "Bus to AHB $i" -label {Committed Bundle count} /testbench/d3/rvsys_gen(0)/rvsys_inst/rvex_block/rvex_inst/creg_inst/context_reg_bank_gen($i)/context_reg_bank/r(145)
	add wave -group "Bus to AHB $i" -label {Committed Syllable count} /testbench/d3/rvsys_gen(0)/rvsys_inst/rvex_block/rvex_inst/creg_inst/context_reg_bank_gen($i)/context_reg_bank/r(146)
	add wave -group "Bus to AHB $i" -label {Committed NOP count} /testbench/d3/rvsys_gen(0)/rvsys_inst/rvex_block/rvex_inst/creg_inst/context_reg_bank_gen($i)/context_reg_bank/r(147)
}

