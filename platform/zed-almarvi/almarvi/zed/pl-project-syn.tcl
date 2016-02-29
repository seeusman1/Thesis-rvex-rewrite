
# Clean before building.
reset_project

# Upgrade IP blocks.
upgrade_ip [get_ips]

# Generate the block diagram.
generate_target all [get_files pl.srcs/sources_1/bd/system/system.bd]

# Make a VHD wrapper for the block diagram and set it as the toplevel entity.
make_wrapper -files [get_files pl.srcs/sources_1/bd/system/system.bd] -top
add_files -norecurse "[file normalize "pl.srcs/sources_1/bd/system/hdl/system_wrapper.vhd"]"
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Run synthesis.
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Run implementation.
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

