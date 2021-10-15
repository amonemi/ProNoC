#!/bin/bash

#remove address from make_project.tcl & program_board.tcl  
#fix jtag_intfc.sh ~/mpsoc/jtag_xilinx_xsct/jtag_xilinx_xsct

source "my_password.sh"

remote_folder="kc07_mesh6"
source_path="$PRONOC_WORK/MPSOC/kc07_mesh6"
ProNoC_HOME="../../.."

echo "$PRONOC_WORK"


function check_fpga_exist_on_server {
   xsct
   connect 
   jtag targets
}



my_array=("$source_path/src_verilog "
	"$source_path/sw "
	"$source_path/xilinx_compile "
	"$source_path/xilinx_mem "
	"$source_path/*.tcl "
	"$source_path/*.xdc ")





function copy_sources_all {
	sshpass -p $my_passwd ssh $my_server mkdir -p  "~/mpsoc/$remote_folder"
	echo "copy $source_all on server"  
	#sshpass -p $my_passwd scp -r $source_all   "$my_server:mpsoc/"
	for i in "${my_array[@]}"; do
 		echo "copy $i on server"
		sshpass -p $my_passwd scp -r $i  "$my_server:mpsoc/$remote_folder/"		
 	done
	copy_uart_terminal
}


function copy_sources_sw {
	echo "copy $source_path/sw on server"  
	sshpass -p $my_passwd scp -r "$source_path/sw"   "$my_server:mpsoc/$remote_folder/"
}

function copy_uart_terminal {
	echo "copy uart_terminal on server"
	sshpass -p $my_passwd scp -r "${ProNoC_HOME}/src_c/jtag/uart_xsct_terminal" "$my_server:mpsoc/"
	sshpass -p $my_passwd scp -r "${ProNoC_HOME}/src_c/jtag/jtag_xilinx_xsct" "$my_server:mpsoc/"

}


function copy_board_files {
	echo "copy board files"
	sshpass -p $my_passwd scp -r "$PRONOC_WORK/toolchain/board_files" "$my_server:mpsoc/"
	# update  board_part_repo_paths manulay in $my_server:mpsoc/$remote_folder/board_property.tcl file with new addr:    " /mnt/SSD-2TB/alireza/mpsoc/board_files "
}


function update_jtag_xilinx_xsct {
	# should be run inside the server
	cd ~/mpsoc/jtag_xilinx_xsct/; make
	cp ~/mpsoc/jtag_xilinx_xsct/jtag_xilinx_xsct ~/toolchain/bin/
	cd ~/mpsoc/uart_xsct_terminal/; make
    cp ~/mpsoc/uart_xsct_terminal/uart ~/toolchain/bin/
}

#should be run in server folder
function compile_vivado {       
	vivado -mode tcl -source make_project.tcl
}

function program_fpga {
    cd ~/mpsoc/kc07_mesh6/
	vivado  -mode tcl -source program_board.tcl
}


function run_uart {
	cd ~/toolchain/bin
	./uart -a 2 -b 36 -t 3 -n 126,125,124,123,122,121,120,119,118,117,116,115

}

function program_cpus {
	 cd ~/mpsoc/kc07_mesh12/sw

}


function copy_back_from_server {
	echo "copy back xilinx_compile to $source_path"
	sshpass -p $my_passwd scp -r  "$my_server:mpsoc/$remote_folder/xilinx_compile/*"  "$source_path/xilinx_compile/"
}

copy_sources_all


# copy_board_files

#copy_back_from_server

#copy_uart_terminal

#copy_sources_sw

