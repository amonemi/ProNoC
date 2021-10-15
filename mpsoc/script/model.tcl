#!/usr/bin/tclsh

#Get tcl shell path relative to current script
set tcl_path	[file dirname [info script]] 
if { [info exists $::env(LM_WORK_PLACE)] } { 
  puts "You need to define the work dir as LM_WORK_PLACE linux envirement variable \n"
  exit(1)
}

if { [info exists $::env(LM_FILE_LIST)] } { 
  puts "You need to define the file list path as LM_FILE_LIST linux envirement variable \n"
  exit(1)
}




set rtl_work $::env(LM_WORK_PLACE)/rtl_work


transcript on
if {[file exists $rtl_work]} {
	vdel -lib $rtl_work -all
}
vlib $rtl_work
vmap work $rtl_work


vlog  +acc=rn  -F $::env(LM_FILE_LIST)

vsim -t 1ps  -L $rtl_work -L work -voptargs="+acc"  pck_injector_test

add wave *
view structure
view signals
run -all
