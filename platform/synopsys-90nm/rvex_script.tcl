#From Digital VLSI chip design with cadence and Synopsis CAD tools page 255

set plot_command {lpr -Pcsps}
set text_print_command {lpr -Pcsps}
set text_editor_command {emacs %s &}
set command_log_file "./synopsys-dc_shell.log"
set find_converts_name_lists "false"

set SynopsysInstall [getenv "SYNOPSYS"]

set search_path [list . \
[format "%s%s" $SynopsysInstall /libraries/syn] \
[format "%s%s" $SynopsysInstall /dw/sim_ver] \
../../lib/rvex ]

define_design_lib rvex -path ./rvex

set hdlin_check_no_latch true
set compile_fix_multiple_port_nets true
set hdlin_translate_off_skip_text true
set hdlin_vhdl_std 2008

set verilogout_write_components true
set verilogout_architecture_name "structural"
set verilogout_no_tri true

set hdlin_translate_off_skip_text true
set bus_naming_style {%s[%d]}

set target_library [list /opt/applics/synopsys-90nm-libs/SAED_EDK90nm/Digital_Standard_cell_Library/synopsys/models/saed90nm_min.db]
set synthetic_library [list /opt/applics/synthesis-J-2014.09-SP2/libraries/syn/standard.sldb]
set link_library [list /opt/applics/synopsys-90nm-libs/SAED_EDK90nm/Digital_Standard_cell_Library/synopsys/models/saed90nm_min.db]
set symbol_library [list /opt/applics/synthesis-J-2014.09-SP2/libraries/syn/generic.sdb]

analyze -autoread -library rvex -format vhdl { \
core/core_alu.vhd \
core/core_asDisas_pkg.vhd \
core/core_br.vhd \
core/core_brku.vhd \
core/core_cfgCtrl_decode.vhd \
core/core_cfgCtrl_tb.vhd \
core/core_cfgCtrl.vhd \
core/core_contextPipelaneIFace.vhd \
core/core_contextRegLogic.vhd \
core/core_ctrlRegs_busSwitch.vhd \
core/core_ctrlRegs_contextLaneSwitch.vhd \
core/core_ctrlRegs_pkg.vhd \
core/core_ctrlRegs.vhd \
core/core_dmemSwitch.vhd \
core/core_forward.vhd \
core/core_globalRegLogic.vhd \
core/core_gpRegs_mem.vhd \
core/core_gpRegs_sim.vhd \
core/core_gpRegs.vhd \
core/core_intIface_pkg.vhd \
core/core_limmRouting.vhd \
core/core_listOpcodes_tb.vhd \
core/core_memu.vhd \
core/core_mulu.vhd \
core/core_opcode_pkg.vhd \
core/core_opcodeAlu_pkg.vhd \
core/core_opcodeBranch_pkg.vhd \
core/core_opcodeDatapath_pkg.vhd \
core/core_opcodeMemory_pkg.vhd \
core/core_opcodeMultiplier_pkg.vhd \
core/core_pipelane.vhd \
core/core_pipelanes.vhd \
core/core_pipeline_pkg.vhd \
core/core_pkg.vhd \
core/core_trap_pkg.vhd \
core/core_trapRouting.vhd \
core/core.vhd \
utils/simUtils_pkg.vhd \
utils/simUtils_scanner_pkg.vhd \
utils/utils_pkg.vhd \
common/common_pkg.vhd \
bus/bus_arbiter.vhd \
bus/bus_pkg.vhd \
bus/bus_demux.vhd \
system/rvsys_standalone_core.vhd \
system/rvsys_standalone_pkg.vhd \
system/rvsys_synopsis.vhd \
system/rvsys_synopsis_pkg.vhd \
bus/bus_addrConv_pkg.vhd \
utils/utils_uart.vhd \
utils/utils_fracDiv.vhd \
utils/utils_uart_rxBit.vhd \
utils/utils_uart_rxByte.vhd \
utils/utils_uart_tx.vhd \
utils/utils_uart_tb.vhd \
utils/utils_crc.vhd \
periph/periph_uart_switch.vhd \
periph/periph_uart_busIface.vhd \
periph/periph_uart_fifo.vhd \
periph/periph_uart_packetBuffer.vhd \
periph/periph_uart_packetControl.vhd \
periph/periph_uart_packetHandler.vhd \
periph/periph_uart.vhd \
cache/cache.vhd \
cache/cache_data_block.vhd \
cache/cache_data_blockData.vhd \
cache/cache_data_blockTag.vhd \
cache/cache_data_blockValid.vhd \
cache/cache_data_mainCtrl.vhd \
cache/cache_data.vhd \
cache/cache_instr_block.vhd \
cache/cache_instr_blockData.vhd \
cache/cache_instr_blockTag.vhd \
cache/cache_instr_blockValid.vhd \
cache/cache_instr_missCtrl.vhd \
cache/cache_instr.vhd \
cache/cache_pkg.vhd \
core/core_trace.vhd \
core/core_stopBitRouting.vhd \
core/core_instructionBuffer.vhd \
core/core_version_pkg.vhd}

elaborate RVSYS_SYNOPSIS -library RVEX
#create_clock -name "clk" -period 10 -waveform { 0 5  }  { core/clk  }

#check_design?

#compile -exact_map

#report_design -nosplit -hierarchy
#report_area -hierarchy

exit


    #common/common_pkg.vhd \
    #utils/utils_pkg.vhd \
    #utils/utils_sync.vhd \
    #utils/utils_fracDiv.vhd \
    #utils/utils_crc.vhd \
    #utils/simUtils_pkg.vhd \
    #utils/simUtils_mem_pkg.vhd \
    #utils/simUtils_scanner_pkg.vhd \
    #utils/utils_uart_rxBit.vhd \
    #utils/utils_uart_rxByte.vhd \
    #utils/utils_uart_tx.vhd \
    #utils/utils_uart.vhd \
    #bus/bus_pkg.vhd \
    #bus/bus_addrConv_pkg.vhd \
    #bus/bus_ramBlock_singlePort.vhd \
    #bus/bus_ramBlock.vhd \
    #bus/bus_arbiter.vhd \
    #bus/bus_demux.vhd \
    #bus/bus_crossClock.vhd \
    #core/core_pkg.vhd \
    #core/core_pipeline_pkg.vhd \
    #core/core_ctrlRegs_pkg.vhd \
    #core/core_intIface_pkg.vhd \
    #core/core_opcodeDatapath_pkg.vhd \
    #core/core_opcodeAlu_pkg.vhd \
    #core/core_opcodeBranch_pkg.vhd \
    #core/core_opcodeMemory_pkg.vhd \
    #core/core_opcodeMultiplier_pkg.vhd \
    #core/core_opcode_pkg.vhd \
    #core/core_trap_pkg.vhd \
    #core/core_asDisas_pkg.vhd \
    #core/core_alu.vhd \
    #core/core_brku.vhd \
    #core/core_br.vhd \
    #core/core_cfgCtrl_decode.vhd \
    #core/core_cfgCtrl.vhd \
    #core/core_forward.vhd \
    #core/core_contextPipelaneIFace.vhd \
    #core/core_contextRegLogic.vhd \
    #core/core_ctrlRegs_bank.vhd \
    #core/core_ctrlRegs_busSwitch.vhd \
    #core/core_ctrlRegs_contextLaneSwitch.vhd \
    #core/core_ctrlRegs_readPort.vhd \
    #core/core_ctrlRegs.vhd \
    #core/core_dmemSwitch.vhd \
    #core/core_globalRegLogic.vhd \
    #core/core_gpRegs_mem.vhd \
    #core/core_gpRegs.vhd \
    #core/core_limmRouting.vhd \
    #core/core_memu.vhd \
    #core/core_mulu.vhd \
    #core/core_pipelane.vhd \
    #core/core_stopBitRouting.vhd \
    #core/core_trapRouting.vhd \
    #core/core_pipelanes.vhd \
    #core/core_instructionBuffer.vhd \
    #core/core_trace.vhd \
    #core/core.vhd \
    #cache/cache_pkg.vhd \
    #cache/cache_data_blockData.vhd \
    #cache/cache_data_blockTag.vhd \
    #cache/cache_data_blockValid.vhd \
    #cache/cache_data_mainCtrl.vhd \
    #cache/cache_data_block.vhd \
    #cache/cache_data.vhd \
    #cache/cache_instr_blockData.vhd \
    #cache/cache_instr_blockTag.vhd \
    #cache/cache_instr_blockValid.vhd \
    #cache/cache_instr_missCtrl.vhd \
    #cache/cache_instr_block.vhd \
    #cache/cache_instr.vhd \
    #cache/cache.vhd \
    #periph/periph_uart_packetHandler.vhd \
    #periph/periph_uart_packetBuffer.vhd \
    #periph/periph_uart_packetControl.vhd \
    #periph/periph_uart_fifo.vhd \
    #periph/periph_uart_busIface.vhd \
    #periph/periph_uart_switch.vhd \
    #periph/periph_uart.vhd \
    #periph/periph_trace.vhd \
    #system/rvsys_standalone_pkg.vhd \
    #system/rvsys_standalone_core.vhd }
