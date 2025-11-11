#!/usr/bin/tclsh

transcript on

if {![info exists env(WORK_MMESH)]} {
    puts "Error: WORK environment variable is not set."
    exit 1
}

if {![info exists env(SOURCE_DIR)]} {
    puts "Error: SOURCE_DIR environment variable is not set."
    exit 1
}

set rtl_work $env(WORK_MMESH)/rtl_work
set src_dir  $env(SOURCE_DIR)

if {[file exists $rtl_work]} {
    vdel -lib $rtl_work -all
}
vlib $rtl_work
vmap work $rtl_work


vlog +define+SIMULATION+MULTI_MESH_ASSERTIONS +acc=rn -F $src_dir/file_list.f

vsim -t 1ps  -L $rtl_work -L work -voptargs="+acc"  testbench_noc

add wave *
view structure
view signals
run -all
quit
