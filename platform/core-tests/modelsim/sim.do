
vlib rvex
vcom -quiet -93 -work rvex "../../../lib/rvex/common/common_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/utils/utils_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/utils/simUtils_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/utils/simUtils_mem_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/utils/simUtils_scanner_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_pipeline_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_intIface_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_opcodeDatapath_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_opcodeAlu_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_opcodeBranch_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_opcodeMemory_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_opcodeMultiplier_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_opcode_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_trap_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_asDisas_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_ctrlRegs_pkg.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_br.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_alu.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_mulu.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_memu.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_brku.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_pipelane.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_forward.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_contextPipelaneIFace.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_dmemSwitch.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_limmRouting.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_trapRouting.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_pipelanes.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_gpRegs_mem.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_gpRegs_sim.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_gpRegs.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_ctrlRegs_busSwitch.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_ctrlRegs_bank.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_ctrlRegs_readPort.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_ctrlRegs_contextLaneSwitch.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_ctrlRegs.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_contextRegLogic.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_globalRegLogic.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_cfgCtrl_decode.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_cfgCtrl.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core_trace.vhd"
vcom -quiet -93 -work rvex "../../../lib/rvex/core/core.vhd"

vlib work
vcom -quiet -93 -work work "../design/core_tb.vhd"

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
