proc set_project_properties { } {
	set_property "board_part_repo_paths" [list "$::env(PRONOC_WORK)/toolchain/board_files"] [current_project]
	set_property "part" "xc7k325tffg900-2" [current_project]
	set_property "board_part" "xilinx.com:kc705:part0:1.1" [current_project]
	set_property "default_lib" "xil_defaultlib" [current_project]
}

	
proc program_board {bit_file} {
	open_hw
	connect_hw_server
	open_hw_target
	set_property PROGRAM.FILE $bit_file [get_hw_devices xc7k325t_0]
	program_hw_devices [get_hw_devices xc7k325t_0]
	refresh_hw_device [get_hw_devices xc7k325t_0]
}
