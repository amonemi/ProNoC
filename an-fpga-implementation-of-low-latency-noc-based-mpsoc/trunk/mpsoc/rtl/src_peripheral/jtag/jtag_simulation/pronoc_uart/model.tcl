#!/usr/bin/tclsh

###################################################################
## Author      : Alireza Monemi
## Email       : 
## Description : Compile all verilog files inside the design folder 
##             : using modelsim
###################################################################
set text "###################################################################"
set text "##                Start Compilation Script "
set text "###################################################################"

###################################################################
##---- Specify variables
set text "###################################################################"
set text "##---- Specify variables"

##-- Project path variables


set path0	[pwd]
set path 	[pwd]/verilog
set uart        $path0/../../jtag_uart/pronoc_jtag_uart.v	
#set jtag       $path0/../../jtag_wb/xilinx_jtag_wb.v	

set comp_path 			$::env(PRONOC_WORK)/simulation
set work_path			$comp_path/work

puts "work path is : $work_path"


##-- change directory
file mkdir $comp_path

cd $comp_path
exec rm -Rf *
proc r  {} {uplevel #0 source compile.tcl}
proc rr {} {global last_compile_time
            set last_compile_time 0
            r                            }
proc q  {} {quit -force                  }

proc sleep {N} {
    after [expr {int($N * 1000)}]
}


#Does this installation support Tk?
set tk_ok 1
if [catch {package require Tk}] {set tk_ok 0}

###################################################################
##---- 1. Creating working library
set text "###################################################################"
set text "##---- 1. Creating working library"

##-- Create work lib
vlib $work_path

##-- Mapping work lib
vmap work $work_path



###################################################################
##---- 3. Compile the Design
set text "###################################################################"
set text "##---- 3. Compile the Design"


# Compile out of date files
set time_now [clock seconds]

if {[file isfile start_time.txt] != 0} {
 	set fp [open start_time.txt r]
	set line [gets $fp]
  	close $fp
  	regexp {\d+} $line last_compile_time
 	puts "last compiled time is  $last_compile_time"
} else {
	set last_compile_time 0
}





foreach a [list $path]  {
      puts "$a "
      set lib_file_list [glob -directory $a *.v *.sv]
	foreach f $lib_file_list {
       
		if { $last_compile_time < [file mtime $f] } {
			vlog  -work  $work_path  +acc=rn +incdir+$a+$path0  $f
			
			 set last_compile_time 0
        	} else {
			 puts "$f is uptodate"
		}    
        }
  }
vlog  -work  $work_path  +acc=rn +incdir+$a+$path0  $uart	
#vlog  -work  $work_path  +acc=rn +incdir+$a+$path0  $jtag			
		



set last_compile_time $time_now



set text "###################################################################"
set text "##                       END OF COMPILATION"
set text "###################################################################"


#vsim -t ps -L altera_mf_ver work.testbench_router
vsim   -t ps  work.testbench

#do "$comp_path/wave.do"

run 100 ms

quit


#####################################################################################

