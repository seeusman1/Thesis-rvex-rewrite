
# Generate the previous block diagram.
generate_target all [get_files pl.srcs/sources_1/bd/system/system.bd]

# Upgrade IP blocks.
upgrade_ip [get_ips]

# Start the GUI and open the block diagram.
start_gui
open_bd_design {pl.srcs/sources_1/bd/system/system.bd}
