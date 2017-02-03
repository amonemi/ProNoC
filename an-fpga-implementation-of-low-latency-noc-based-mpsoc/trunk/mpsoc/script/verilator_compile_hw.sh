#!/bin/sh
script_path=$(pwd)
path=$script_path/..
src_noc_path=$path/src_noc	
src_modelsim_path=$path/src_modelsim
src_verilator_path=$path/src_verilator	
comp_path=$path/../mpsoc_work/verilator
work_path=$comp_path/work
mkdir -p $work_path/rtl_work

cp split $work_path/split

 
cd $work_path

# remove old files
rm -rf rtl_work/* 
rm -rf processed_rtl/* 
rm -rf processed_rtl/obj_dir/*



echo "copy all verilog files in rtl_work folder" 
find  $src_noc_path -name \*.v -exec cp '{}' rtl_work/ \;
find  $src_verilator_path -name \*.v -exec cp '{}' rtl_work/ \;


echo "split all verilog modules in separate  files"
./split > foo

find  $src_verilator_path -name \*.sv -exec cp '{}' processed_rtl/ \;

 
cd processed_rtl

verilator  --cc router_verilator.v --profile-cfuncs --prefix "Vrouter" -O3  -CFLAGS -O3
verilator  --cc noc_connection.sv --prefix "Vnoc" -O3 -CFLAGS -O3
verilator  --cc --profile-cfuncs traffic_gen_verilator.v --prefix "Vtraffic" -O3 -CFLAGS -O3


cp $script_path/Makefile	obj_dir/
cd obj_dir
make lib

