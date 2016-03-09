#!/bin/bash
# This script was automatically generated.

function usage() {
    echo "Usage: $0 [options]"
    echo "Prepares processor design for RTL simulation."
    echo "Options:"
    echo "  -c     Enables code coverage."
    echo "  -h     This helpful help text."
}

# Function to do clean up when this script exits.
function cleanup() {
    true # Dummy command. Can not have empty function.
}
trap cleanup EXIT

OPTIND=1
while getopts "ch" OPTION
do
    case $OPTION in
        c)
            enable_coverage=yes
            ;;
        h)
            usage
            exit 0
            ;;
        ?)  
            echo "Unknown option -$OPTARG"
            usage
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))"

rm -rf work
vlib work
vmap
if [ "$enable_coverage" = "yes" ]; then
    coverage_opt="+cover=sbcet"
fi

rtl_dir="rtl"
proge_out_dir="${rtl_dir}/proge_output"
debugger_dir="${rtl_dir}/debugger"
amba_dir="${rtl_dir}/amba"
mem_dir="${rtl_dir}/mem"
tb_dir="tb"

set -e

vcom ${rtl_dir}/misc-pkg.vhdl
vcom ${proge_out_dir}/vhdl/tce_util_pkg.vhdl || exit 1
vcom ${proge_out_dir}/vhdl/tta0_imem_mau_pkg.vhdl || exit 1
vcom ${proge_out_dir}/vhdl/tta0_globals_pkg.vhdl || exit 1
vcom ${proge_out_dir}/vhdl/tta0_params_pkg.vhdl || exit 1

vcom $coverage_opt ${debugger_dir}/debugger_if-pkg.vhdl  
vcom $coverage_opt ${debugger_dir}/registers-pkg.vhdl
vcom $coverage_opt ${debugger_dir}/debugger_components-pkg.vhdl  
vcom $coverage_opt ${debugger_dir}/breakpoint0-entity.vhdl         
vcom $coverage_opt ${debugger_dir}/debugger-entity.vhdl  
vcom $coverage_opt ${debugger_dir}/dbsm-entity.vhdl      
vcom $coverage_opt ${debugger_dir}/dbregbank-entity.vhdl     
vcom $coverage_opt ${debugger_dir}/cdc-entity.vhdl      
vcom $coverage_opt ${debugger_dir}/cdc-rtl.vhdl           
vcom $coverage_opt ${debugger_dir}/breakpoint0-rtl.vhdl     
vcom $coverage_opt ${debugger_dir}/dbsm-rtl.vhdl           
vcom $coverage_opt ${debugger_dir}/dbregbank-rtl.vhdl     
vcom $coverage_opt ${debugger_dir}/debugger-struct.vhdl

vcom $coverage_opt ${proge_out_dir}/vhdl/mul.vhdl || exit 1
vcom ${proge_out_dir}/vhdl/util_pkg.vhdl || exit 1
vcom $coverage_opt ${proge_out_dir}/vhdl/ldh_ldhu_ldq_ldqu_ldw_sth_stq_stw.vhdl || exit 1
vcom $coverage_opt ${proge_out_dir}/vhdl/monolithic_alu_shladd_large.vhdl || exit 1
vcom $coverage_opt ${proge_out_dir}/vhdl/stdout_db.vhdl || exit 1
vcom $coverage_opt ${proge_out_dir}/vhdl/rf_1wr_1rd_always_1_guarded_0.vhd || exit 1
vcom $coverage_opt ${proge_out_dir}/vhdl/tta0.vhdl || exit 1

vcom ${proge_out_dir}/gcu_ic/gcu_opcodes_pkg.vhdl || exit 1
vcom $coverage_opt ${proge_out_dir}/gcu_ic/datapath_gate.vhdl || exit 1
vcom $coverage_opt ${proge_out_dir}/gcu_ic/decoder.vhdl || exit 1
vcom $coverage_opt ${proge_out_dir}/gcu_ic/output_socket_3_1.vhdl || exit 1
vcom $coverage_opt ${proge_out_dir}/gcu_ic/idecompressor.vhdl || exit 1
vcom $coverage_opt ${proge_out_dir}/gcu_ic/ifetch.vhdl || exit 1
vcom $coverage_opt ${proge_out_dir}/gcu_ic/input_socket_1.vhdl || exit 1
vcom $coverage_opt ${proge_out_dir}/gcu_ic/input_socket_2.vhdl || exit 1
vcom $coverage_opt ${proge_out_dir}/gcu_ic/output_socket_1_1.vhdl || exit 1
vcom $coverage_opt ${proge_out_dir}/gcu_ic/ic.vhdl || exit 1
       
vcom $coverage_opt ${mem_dir}/simple_dual_one_clock.vhdl
vcom $coverage_opt ${mem_dir}/blockram_be.vhdl

vcom $coverage_opt ${rtl_dir}/tta-accel-entity.vhdl
vcom $coverage_opt ${rtl_dir}/tta-accel-rtl.vhdl
vcom $coverage_opt ${rtl_dir}/tta-axislave-entity.vhdl
vcom $coverage_opt ${rtl_dir}/tta-axislave-rtl.vhdl

vcom ${tb_dir}/tta-axislave-tb.vhdl || exit 1

exit 0
