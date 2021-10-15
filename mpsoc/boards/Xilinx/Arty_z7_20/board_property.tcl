proc set_project_properties { } {
	set_property  "board_part_repo_paths" [list "$::env(PRONOC_WORK)/toolchain/board_files"] [current_project]
	set_property "part" "xc7z020clg400-1" [current_project]
	set_property "board_part" "digilentinc.com:arty-z7-20:part0:1.0" [current_project]
	set_property "default_lib" "xil_defaultlib" [current_project]
}

	
proc program_board {bit_file} {
	open_hw
	connect_hw_server
	open_hw_target
	set_property PROGRAM.FILE $bit_file [get_hw_devices xc7z020_1]
	program_hw_devices [get_hw_devices xc7z020_1]
	refresh_hw_device [get_hw_devices xc7z020_1]
}
