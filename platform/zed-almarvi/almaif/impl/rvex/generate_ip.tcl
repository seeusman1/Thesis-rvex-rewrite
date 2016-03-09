create_project -force ip ./ip -part xc7z020clg484-1
set_property board_part em.avnet.com:zed:part0:1.3 [current_project]
set_property target_language VHDL [current_project]
add_files ./rtl
import_files -force
set_property top rvex_axislave [current_fileset]
ipx::package_project -root_dir ./ip/ip.srcs -vendor user.org -library user -taxonomy /UserIP
set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property  ip_repo_paths  ./ip/ip.srcs [current_project]
update_ip_catalog
