#!/bin/sh

set -e
# Any subsequent commands which fail will cause the shell script to exit immediately

script_path=$(pwd)
path=$script_path/..
src_noc_path=$path/src_noc	
src_modelsim_path=$path/src_modelsim
src_verilator_path=$path/src_verilator	
comp_path=$path/../mpsoc_work/verilator
work_path=$comp_path/work
obj_dir_path=$work_path/processed_rtl/obj_dir/


cd $work_path/bin

echo "*******************START SIMULATION*************"
./testbench
