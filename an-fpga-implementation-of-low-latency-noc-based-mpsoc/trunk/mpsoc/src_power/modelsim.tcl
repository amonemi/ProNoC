set path 			[pwd]/../..
set altera_lib		/home/alireza/altera/quartus/eda/sim_lib



transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}

vlib gate_work
vmap work gate_work

vlog -vlog01compat -work work +incdir+. {power_3_900mv_85c_slow.vo}

vlog -vlog01compat -work work +incdir+$path  $path/testbench.v

vlog power_3_900mv_85c_slow.vo -vlog01compat -work work +incdir+$altera_lib -v $altera_lib/stratixiv_atoms.v

#foreach f $stratixiv_lib_files {
       	#vhdl -work  work  +incdir+$stratixiv_lib_files  $f
	
#}

	vlib altera_ver
	vmap altera_ver altera_ver
	vlog -work altera_ver $altera_lib/altera_primitives.v	

	vlib altera_mf_ver
	vmap altera_mf_ver
	vlog -work altera_mf_ver $altera_lib/altera_mf.v	
	

	vlib sgate_ver
	vmap sgate_ver
	vlog -work sgate_ver $altera_lib/sgate.v
	
	vlib lpm_ver
	vmap lpm_ver lpm_ver
	vlog -work lpm_ver $altera_lib/220model.v
	
	vlib  stratixiv_hssi_ver
	vmap  stratixiv_hssi_ver stratixiv_hssi_ver
	vlog -work stratixiv_hssi_ver $altera_lib/stratixiv_hssi_atoms.v


	vlib stratixiv_pcie_hip_ver
	vmap stratixiv_pcie_hip_ver stratixiv_pcie_hip_ver
	vlog -work stratixiv_pcie_hip_ver $altera_lib/stratixiv_pcie_hip_atoms.v

	vlib stratixiv_ver
	vmap stratixiv_ver stratixiv_ver
	vlog -work stratixiv_ver $altera_lib/stratixiv_atoms.v




vsim -t 1ps +transport_int_delays +transport_path_delays -L altera_mf_ver -L altera_ver -L lpm_ver -L sgate_ver -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L stratixiv_ver -L gate_work -L work -voptargs="+acc"  testbench

source power_dump_all_vcd_nodes.tcl
#add wave *
#view structure
#view signals

run 200 us

quit -force 
