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

mkdir -p $work_path/bin
rm -rf $work_path/bin/testbench
 
cp Makefile $obj_dir_path
cp $src_verilator_path/simulator2.cpp  $obj_dir_path/testbench.cpp
cp $src_verilator_path/parameter.h  $obj_dir_path
cd $obj_dir_path
make sim
cp testbench $work_path/bin
echo done!


