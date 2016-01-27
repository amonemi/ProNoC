#!/bin/sh
set -e
# Any subsequent commands which fail will cause the shell script to exit immediately

my_dir="$(dirname "$0")"
source "$my_dir/../parameter.sh"


cd ..
script_path=$(pwd)
path=$script_path/..
comp_path=$path/../mpsoc_work/verilator
work_path=$comp_path/work
bin_path=$work_path/bin
multiple_path=$work_path/congestion_index
data_path=$multiple_path/data
plot_path=$multiple_path/plot
src_c_path=$path/src_c

rm -Rf $multiple_path
mkdir -p $data_path
mkdir -p $plot_path
cp $path/src_c/plot/plot $multiple_path/plot_bin



    V=4   # number of VC per port
    B=4   # buffer space :flit per VC 
    NX=8  # number of node in x axis
    NY=8  # number of node in y axis
    C=2   #  number of flit class 
    COMBINATION_TYPE="COMB_NONSPEC" # "BASELINE" or "COMB_SPEC1" or "COMB_SPEC2" or "COMB_NONSPEC"
    FIRST_ARBITER_EXT_P_EN=1  
    TOPOLOGY="MESH" #"MESH" or "TORUS"
    CLASS_SETTING="8'b11000011" # There are total of two classes. each class use half of avb VCs   
   
#simulation parameters:
    C0_p=50    #  the percentage of injected packets with class 0 
    C1_p=50
    C2_p=0
    C3_p=0
     
    
    
 # Simulation parameters:   
   
    #Hotspot Traffic setting
    HOTSPOT_PERCENTAGE=3		   	#maximum 20
    HOTSOPT_NUM=4					#maximum 5
    HOTSPOT_CORE_1=$(CORE_NUM 2 2)
    HOTSPOT_CORE_2=$(CORE_NUM 2 6)
    HOTSPOT_CORE_3=$(CORE_NUM 6 2)
    HOTSPOT_CORE_4=$(CORE_NUM 6 6)
   
    
                 
    
    
	MAX_PCK_NUM=128000
    MAX_SIM_CLKs=100000
	MAX_PCK_SIZ=10  # maximum flit number in a single packet
    TIMSTMP_FIFO_NUM=64
    
   
    
	ESCAP_VC_MASK="4'b0101"  # mask scape vc
	DEBUG_EN=1
	
	CONGESTION_INDEX=3	# 0: packets are routed to the ports with more available VCs
						# 1: packets are routed to the ports with more available credits  
 	 				  	# 2: packets are routed to the ports connected to the routers with less active ivc requests
						# 3: packets are routed to the ports connected to the routers with less active ivc requests that are not granted 

	
 						



# 
	
	AVC_ATOMIC_EN=0
	STND_DEV_EN=0 # 1: generate standard devision  






################
#	
#	regenerate_NoC
#
################	
			
regenerate_NoC() {
	generate_parameter_v
	mv -f parameter.v ../src_verilator/
			
	#verilate the NoC and make the library files
#################################################################3
			./verilator_compile_hw.sh

	# compile the testbench file
	generate_parameter_h
	mv -f parameter.h ../src_verilator/

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
	
	./plot_bin $data_file  $plot_file "Injection ratio flits/node/clk" "Average latency clk" "outside left"
	
	
	
	if [ $C  -gt  1 ] 
	then
	
		data_file=$data_path/$plot_name"_c0.txt"
		plot_file=$plot_path/$plot_name"_c0.eps"
	
	
		printf "#name:"$CURVE_NAME"\n" >> $data_file
		cat 	$testbench_name"_c0.txt" >> $data_file
		printf "\n\n" >> $data_file
	
		./plot_bin $data_file  $plot_file "Injection ratio flits/node/clk" "Average latency clk" "outside left"
	
		data_file=$data_path/$plot_name"_c1.txt"
		plot_file=$plot_path/$plot_name"_c1.eps"
	
	
		printf "#name:"$CURVE_NAME"\n" >> $data_file
		cat 	$testbench_name"_c1.txt" >> $data_file
		printf "\n\n" >> $data_file
	
		./plot_bin $data_file  $plot_file "Injection ratio flits/node/clk" "Average latency clk" "outside left"
	
	fi
	
	
	rm	$testbench_name* 	
			
}	

gen_testbench_name(){
	testbench_name=$routename"_"$TRAFFIC"_"$PACKET_SIZE
		
}

gen_plot_name(){
	plot_name="CONG"$CONGESTION_INDEX$"_"$TRAFFIC"_"$PACKET_SIZE
	
}


route_setting(){
	case $routename in    
		'DUATO_XY_A')
			ROUTE_NAME="DUATO"
			ROUTE_SUBFUNC="XY"	
			VC_REALLOCATION_TYPE="ATOMIC"
			AVC_ATOMIC_EN=1	
			echo "DUATO_XY_A"
		;;
		'DUATO_XY_H')
			ROUTE_NAME="DUATO"
			ROUTE_SUBFUNC="XY"
			VC_REALLOCATION_TYPE="NONATOMIC"	
			AVC_ATOMIC_EN=1	
			echo "DUATO_XY_H"

		;;
		'DUATO_XY_F')
			ROUTE_NAME="DUATO"
			ROUTE_SUBFUNC="XY"	
			VC_REALLOCATION_TYPE="NONATOMIC"
			AVC_ATOMIC_EN=0	
			echo "DUATO_XY_F"
		;;
		'DUATO_NL_A')
			ROUTE_NAME="DUATO"
			ROUTE_SUBFUNC="NORTH_LAST"
			VC_REALLOCATION_TYPE="ATOMIC"	
			AVC_ATOMIC_EN=1		
			echo "DUATO_NL_A"
		;;
		'DUATO_NL_H')
			ROUTE_NAME="DUATO"
			ROUTE_SUBFUNC="NORTH_LAST"
			VC_REALLOCATION_TYPE="NONATOMIC"	
			AVC_ATOMIC_EN=1
			echo "DUATO_NL_H"

		;;
		'DUATO_NL_F')
			ROUTE_NAME="DUATO"
			ROUTE_SUBFUNC="NORTH_LAST"	
			VC_REALLOCATION_TYPE="NONATOMIC"
			AVC_ATOMIC_EN=0		
		echo "DUATO_NL_F"
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

	for  routename in "XY" "WEST_FIRST" "ODD_EVEN"  "NEGETIVE_FIRST" "DUATO_XY_A" "DUATO_XY_H" "DUATO_XY_F"  "DUATO_NL_A" "DUATO_NL_H" "DUATO_NL_F"
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
	
	for  routename in "DUATO_XY_A" "DUATO_XY_H" "DUATO_XY_F"  "DUATO_NL_A" "DUATO_NL_H" "DUATO_NL_F"
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
	
	for  routename in "XY" "WEST_FIRST" "ODD_EVEN"  "NEGETIVE_FIRST" "DUATO_XY_A" "DUATO_XY_H" "DUATO_XY_F"  "DUATO_NL_A" "DUATO_NL_H" "DUATO_NL_F"
	do	
		
		route_setting
		gen_testbench_name
		gen_plot_name
		CURVE_NAME=$routename
		merg_files
	done # ROUTE_NAME
	

	cd $script_path			
																		
}		

																																		
					
 for PACKET_SIZE in 2 3 4 6
 do 
	for	TRAFFIC in "TRANSPOSE2" 
	do
		for   CONGESTION_INDEX in   10 9 8 7 6 5 4 3 2 1
		do
			
			run_sim
			
		done 
	done 
done #PACKET_SIZE
			
