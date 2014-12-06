
vlib work


# Compile packages in the right order.
vcom -quiet  -93  -work work   ../vhdl/rvex_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_pipeline_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_intIface_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_simUtils_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_opcodeMultiplier_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_opcodeMemory_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_opcodeDatapath_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_opcodeBranch_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_opcodeAlu_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_utils_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_trap_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_simUtils_scan_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_opcode_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_simUtils_asDisas_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_simUtils_mem_pkg.vhd
vcom -quiet  -93  -work work   ../vhdl/rvex_ctrlRegs_pkg.vhd

# Compile entities of RTL sources.
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_alu.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_br.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_brku.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_cfgCtrl_decode.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_cfgCtrl.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_contextPipelaneIFace.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_contextRegLogic.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_ctrlRegs_bank.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_ctrlRegs_busSwitch.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_ctrlRegs_contextLaneSwitch.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_ctrlRegs_readPort.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_ctrlRegs.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_dmemSwitch.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_forward.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_globalRegLogic.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_gpRegs_mem.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_gpRegs_sim.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_gpRegs.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_limmRouting.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_memu.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_mulu.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_pipelane.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_pipelanes.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex_trapRouting.vhd
vcom -just e -quiet  -93  -work work   ../vhdl/rvex.vhd

# Compile entities of RTL sources.
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_alu.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_br.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_brku.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_cfgCtrl_decode.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_cfgCtrl.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_contextPipelaneIFace.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_contextRegLogic.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_ctrlRegs_bank.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_ctrlRegs_busSwitch.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_ctrlRegs_contextLaneSwitch.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_ctrlRegs_readPort.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_ctrlRegs.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_dmemSwitch.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_forward.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_globalRegLogic.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_gpRegs_mem.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_gpRegs_sim.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_gpRegs.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_limmRouting.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_memu.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_mulu.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_pipelane.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_pipelanes.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex_trapRouting.vhd
vcom -just pbac -quiet  -93  -work work   ../vhdl/rvex.vhd

# Compile testbench.
vcom -quiet  -93  -work work   ../vhdl/rvex_tb.vhd

# Give simulate command.
vsim -t ps -novopt -L unisim work.rvex_tb

onerror {resume}
add wave -group "Test case info" sim:/rvex_tb/sim_*

#Change radix to Hexadecimal#
radix hex

# Supress spam.
set NumericStdNoWarnings 1
set StdArithNoWarnings 1

run 1000 ms
