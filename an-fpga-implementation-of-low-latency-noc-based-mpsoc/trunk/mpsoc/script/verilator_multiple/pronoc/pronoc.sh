#!/bin/sh
#set -e
# Any subsequent commands which fail will cause the shell script to exit immediately

#my_dir="$(dirname "$0")"
#source "$my_dir/../parameter.sh"

cc=$(pwd)
PWDI=$cc
echo "$PWD "

script_path=$PWDI/../..
path=$script_path/..
comp_path=$path/../mpsoc_work/verilator
work_path=$comp_path/work
bin_path=$work_path/bin
multiple_path=$work_path/pronoc
data_path=$multiple_path/data
plot_path=$multiple_path/plot
src_c_path=$path/src_c
src_noc_path=$path/src_noc
src_verilator_path=$path/src_verilator
plot_c_path=$src_c_path/plot	

source "$script_path/parameter.sh"

rm -Rf $multiple_path
mkdir -p $data_path
mkdir -p $plot_path
cp $path/src_c/plot/plot $multiple_path/plot_bin


#commen parameter
    V=2   # number of VC per port
    NX=8  # number of node in x axis
    NY=8  # number of node in y axis
    CONGESTION_INDEX=3 
    B=4   # buffer space :flit per VC 
    ESCAP_VC_MASK="2'b01"  # mask scape vc
    C=0   #  number of flit class
    COMBINATION_TYPE="COMB_NONSPEC" # "BASELINE" or "COMB_SPEC1" or "COMB_SPEC2" or "COMB_NONSPEC"
    AVC_ATOMIC_EN=0   
    FIRST_ARBITER_EXT_P_EN=0  
    TOPOLOGY="MESH" #"MESH" or "TORUS"
    CLASS_SETTING="4'b1111"	#There are total of two classes. each class use half of avb VCs   
   
#simulation parameters:
    C0_p=50    #  the percentage of injected packets with class 0 
    C1_p=50
    C2_p=0
    C3_p=0
     
    
    
 # Simulation parameters:   
   
    #Hotspot Traffic setting
    HOTSPOT_PERCENTAGE=4		   	#maximum 20
    HOTSOPT_NUM=4					#maximum 5
    HOTSPOT_CORE_1=$(CORE_NUM 2 3)
    HOTSPOT_CORE_2=$(CORE_NUM 4 6)
    HOTSPOT_CORE_3=$(CORE_NUM 6 2)
    HOTSPOT_CORE_4=$(CORE_NUM 6 6)
   
    
                 
    
    
    MAX_PCK_NUM=200000
    MAX_SIM_CLKs=100000
    MAX_PCK_SIZ=10  # maximum flit number in a single packet
    TIMSTMP_FIFO_NUM=16
    
   PACKET_SIZE=4
    
	
	DEBUG_EN=0
	
	 
	
 						



# 
	
	AVC_ATOMIC_EN=0
	STND_DEV_EN=0 # 1: generate standard devision  








######################
#
#	verilator_compile_hw
#
######################

verilator_compile_hw(){


	
	work_path=$comp_path/work
	#echo "$work_path\n"
	cd $script_path			
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

#replace conventional 
	if [ "$routename" == "DUATO_ORG" ] 
	then 
		cp -f $PWDI/vc_alloc_request_gen.v rtl_work/vc_alloc_request_gen.v

		echo "$PWDI vc_alloc_request_gen.v have been replaced"
	fi


	echo "split all verilog modules in separate  files"
	./split > foo

	find  $src_verilator_path -name \*.sv -exec cp '{}' processed_rtl/ \;

 
	cd processed_rtl

	verilator  --cc router_verilator.v --profile-cfuncs --prefix "Vrouter" -O3  
	verilator  --cc noc_connection.sv --prefix "Vnoc" -O3
	verilator  --cc --profile-cfuncs traffic_gen_verilator.v --prefix "Vtraffic" -O3 


	cp $script_path/Makefile	obj_dir/
	cd obj_dir
	make  lib -j 4
	cd $script_path	


}




################
#	
#	regenerate_NoC
#
################	
			
regenerate_NoC() {
	generate_parameter_v
	mv -f parameter.v $src_verilator_path/
			
	#verilate the NoC and make the library files
#################################################################3
	verilator_compile_hw

	# compile the testbench file
	generate_parameter_h
	mv -f parameter.h $src_verilator_path/

	./verilator_compile_sw.sh
	
		
	cp $bin_path/testbench $multiple_path/$testbench_name		
}

routename="NULL"
################
#	
#	merg_files
#
################	
		
				
merg_files(){
						 
	data_file=$data_path/$plot_name"_all.txt"
	plot_file=$plot_path/$plot_name"_all.eps"
		
	printf "#name:"$CURVE_NAME"\n" >> $data_file
	cat 	$testbench_name"_all.txt" >> $data_file
	printf "\n\n" >> $data_file
	
	./plot_bin $data_file  $plot_file "Injection ratio flits/node/clk" "Average latency clk" "left"
	
	
	
	if [ $C  -gt  1 ] 
	then
	
		data_file=$data_path/$plot_name"_c0.txt"
		plot_file=$plot_path/$plot_name"_c0.eps"
	
	
		printf "#name:"$CURVE_NAME"\n" >> $data_file
		cat 	$testbench_name"_c0.txt" >> $data_file
		printf "\n\n" >> $data_file
	
		./plot_bin $data_file  $plot_file "Injection ratio flits/node/clk" "Average latency clk" "left"
	
		data_file=$data_path/$plot_name"_c1.txt"
		plot_file=$plot_path/$plot_name"_c1.eps"
	
	
		printf "#name:"$CURVE_NAME"\n" >> $data_file
		cat 	$testbench_name"_c1.txt" >> $data_file
		printf "\n\n" >> $data_file
	
		./plot_bin $data_file  $plot_file "Injection ratio flits/node/clk" "Average latency clk" "left"
	
	fi
	
	
	rm	$testbench_name* 	
			
}	




#######################
#
#	generate_plot_command_h
#######################

generate_plot_command(){

rm -f plot_command.h

cat > plot_command.h << EOF
#ifndef PLOT_COMMAND_H
	#define PLOT_COMMAND_H

char * commandsForGnuplot[] = {
	"set terminal postscript eps enhanced color font 'Helvetica,15'",
	"set output 'temp.eps' ",
	"set style line 1 lc rgb \"red\"    	lt 1 lw 2 pt 4  ps 1.5",
	"set style line 2 lc rgb \"blue\"   	lt 1 lw 2 pt 6  ps 1.5", 
	"set style line 3 lc rgb \"green\"  	lt 1 lw 2 pt 10 ps 1.5",
	"set style line 4 lc rgb '#8B008B' 	lt 1 lw 2 pt 14 ps 1.5",//darkmagenta
	"set style line 5 lc rgb '#B8860B' 	lt 1 lw 2 pt 2  ps 1.5", //darkgoldenrod
	"set style line 6 lc rgb \"gold\" 	lt 1 lw 2 pt 3  ps 1.5",
	"set style line 7 lc rgb '#FF8C00' 	lt 1 lw 2 pt 10 ps 1.5",//darkorange
	"set style line 8 lc rgb \"black\" 	lt 1 lw 2 pt 1  ps 1.5",
	"set style line 9 lc rgb \"spring-green\" 	lt 1 lw 2 pt 8  ps 1.5",
	"set style line 10 lc rgb \"yellow4\" 	lt 1 lw 2 pt 0  ps 1.5",
	"set yrange [0:80]",
	"set xrange [0:]",
	
	0
};

#endif

EOF

	mv -f plot_command.h	$plot_c_path/plot_command.h	
	cd $plot_c_path
	make
	cp $plot_c_path/plot $multiple_path/plot_bin
	cd $script_path	

}



gen_testbench_name(){
	testbench_name="B"$B"_"$routename"_"$TRAFFIC"_"$PACKET_SIZE
		
}

gen_plot_name(){
	plot_name="B"$B"_"$TRAFFIC"_"$PACKET_SIZE
	
}


route_setting(){
	case $routename in    
		
		

		'DUATO_ORG')
			ROUTE_NAME="DUATO"
			ROUTE_SUBFUNC="XY"	
			VC_REALLOCATION_TYPE="ATOMIC"
			AVC_ATOMIC_EN=1
			echo "DUATO_ORG"
		;;
		'DUATO_WPF')
			ROUTE_NAME="DUATO"
			ROUTE_SUBFUNC="XY"
			VC_REALLOCATION_TYPE="NONATOMIC"	
			AVC_ATOMIC_EN=1	
			echo "DUATO_WPF"

		;;
		'DUATO_MINE')
			ROUTE_NAME="DUATO"
			ROUTE_SUBFUNC="XY"	
			VC_REALLOCATION_TYPE="NONATOMIC"
			AVC_ATOMIC_EN=0	
			echo "DUATO_MINE"
		;;
		
		
		
		*)
			ROUTE_NAME=$routename
			VC_REALLOCATION_TYPE="NONATOMIC"
			AVC_ATOMIC_EN=0		
			echo $ROUTE_NAME
		;;
			
		
esac
}	
	
	




################
#	
#	run_sim
#
################
run_sim(){

	for  routename in   "DUATO_ORG" "DUATO_MINE" "DUATO_WPF" "XY" "WEST_FIRST" "ODD_EVEN"  "NEGETIVE_FIRST"  
	do	
		route_setting
		gen_testbench_name
		regenerate_NoC
	done
				
	



	cd $multiple_path
	
	for  routename in "XY" "WEST_FIRST" "ODD_EVEN"  "NEGETIVE_FIRST" 
	do	
		route_setting
		gen_testbench_name
		CMD="./$testbench_name $testbench_name"
        
		command $CMD &
	done
	
				
	# wait for all simulation to be done
	wait
	
	for  routename in "DUATO_ORG"  "DUATO_MINE" "DUATO_WPF"
	do	
		route_setting
		gen_testbench_name
		CMD="./$testbench_name $testbench_name"
        
		command $CMD &
	done
	
				
	# wait for all simulation to be done
	wait
	
	
	# merge the results in one file 
	VC_REALLOCATION_TYPE="NONATOMIC"
	
	for  routename in "XY" "WEST_FIRST" "ODD_EVEN"  "NEGETIVE_FIRST" "DUATO_ORG"  "DUATO_MINE"  "DUATO_WPF"
	do	
		
		route_setting
		gen_testbench_name
		gen_plot_name
		CURVE_NAME=$routename
		merg_files
	done # ROUTE_NAME
	

	cd $script_path			
																		
}		

generate_plot_command																																		

for B in    8
do					
 for PACKET_SIZE in 2   8
 do 
	for	TRAFFIC in "TRANSPOSE2" "TRANSPOSE1" "BIT_REVERSE" "RANDOM" "HOTSPOT"  
	do
		for   CONGESTION_INDEX in   12 #0 1 2 3
		do
			
			run_sim
			
		done 
	done 
 done #PACKET_SIZE

done
			
