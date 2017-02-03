#!/bin/sh
set -e
# Any subsequent commands which fail will cause the shell script to exit immediately

script_path=$(pwd)
path=$script_path/..
comp_path=$path/../adaptive_work/verilator
work_path=$comp_path/work
bin_path=$work_path/bin
multiple_path=$work_path/multiple
data_path=$multiple_path/data
plot_path=$multiple_path/plot
src_c_path=$path/src_c

rm -Rf $multiple_path
mkdir -p $data_path
mkdir -p $plot_path
cp $path/src_c/plot $multiple_path/plot_bin


CORE_NUM(){
  # local variable x and y with passed args	
  local x=$1
  local y=$2

  echo $(( $x + ($y*$NX) ))
}



# NoC parameters:
	V=4   # number of VC per port
    P=5   # number of port per router 
    B=4   # buffer space :flit per VC 
    NX=8  # number of node in x axis
    NY=8  # number of node in y axis
    C=1   #  number of flit class 
    Fpay=32	#flit payload width
    MUX_TYPE="ONE_HOT"  #crossbar multiplexer type : "ONE_HOT" or "BINARY"
    VC_REALLOCATION_TYPE="NONATOMIC" # "ATOMIC" or "NONATOMIC"
    COMBINATION_TYPE="COMB_NONSPEC" # "BASELINE" or "COMB_SPEC1" or "COMB_SPEC2" or "COMB_NONSPEC"
    FIRST_ARBITER_EXT_P_EN=1  
    TOPOLOGY="MESH" #"MESH" or "TORUS"
    ROUTE_NAME="DUATO" # Routing algorithm
	#    mesh :  "XY"        , "WEST_FIRST"      , "NORTH_LAST"      , "NEGETIVE_FIRST"      , "DUATO"
    #   torus:  "TRANC_XY"  , "TRANC_WEST_FIRST", "TRANC_NORTH_LAST", "TRANC_NEGETIVE_FIRST", "TRANC_DUATO"
    CONGESTION_INDEX="VC" #"CREDIT","VC"  
    CLASS_SETTING="4'b1111"           
	#0: no class. packets can be sent to any available OVC
	#1: class field hold the binary number of VC which the packet can be sent to
	#2: class field contains one-hot code of candidate OVCs
    #3: there are two class, class 0 is permitted to be sent to all OVCs VS. class 1 can candidate only half of VCs    
   
	DEBUG_EN=0 # 1 :do error checking on router, will reduce the simulation speed 
			#0 : error checking is disabled  
    
     CLASS_3_TRAFFIC_PATTERN=1
    #0: 25 % class 0 , 75 % class 1
    #1: 50 % class 0 , 50 % class 1
    #2: 75 % class 0 , 25 % class 1    
    
 # Simulation parameters:   
    TRAFFIC="RANDOM"     # "RANDOM","TRANSPOSE1","TRANSPOSE2","HOTSPOT","BIT_REVERSE","BIT_COMPLEMENT","CUSTOM"
    #Hotspot Traffic setting
    HOTSPOT_PERCENTAGE=1		   	#maximum 20
    HOTSOPT_NUM=4					#maximum 5
    HOTSPOT_CORE_1=$(CORE_NUM 2 2)
    HOTSPOT_CORE_2=$(CORE_NUM 5 2)
    HOTSPOT_CORE_3=$(CORE_NUM 2 5)
    HOTSPOT_CORE_4=$(CORE_NUM 5 5)
    HOTSPOT_CORE_5=$(CORE_NUM 2 2)
    
                 
    
    TOTAL_PKT_PER_ROUTER=5000 #total number of packets which is sent by a router
    MAX_DELAY_BTWN_PCKTS=64	 # maximum delay between two consecutive packets
	ESCAP_VC_MASK="4'b0001"  # mask escape VC

# Simulation C file constant:  
	PACKET_SIZE=2	# packet size in flit. Minimum is 2


# 	for minimal fully adaptive on 2D mesh paper 
	ROUTING_SUBFUNCTION= "XY" # "XY" "NORTH_LAST"
	AVC_REALLOCATION= "" 	

generate_parameter_v (){
	printf " \`ifdef     INCLUDE_PARAM \n\n" >> parameter.v	    
	printf " parameter V=$V;\n" >> parameter.v	
	printf " parameter P=$P;\n" >> parameter.v
    printf " parameter B=$B;\n" >> parameter.v	
    printf " parameter NX=$NX;\n" >> parameter.v	
    printf " parameter NY=$NY;\n" >> parameter.v	
    printf " parameter C=$C;\n" >> parameter.v	
    printf " parameter Fpay=$Fpay;\n" >> parameter.v	
    printf " parameter MUX_TYPE=\"$MUX_TYPE\";\n" >> parameter.v	
    printf " parameter VC_REALLOCATION_TYPE=\"$VC_REALLOCATION_TYPE\";\n" >> parameter.v	
    printf " parameter COMBINATION_TYPE=\"$COMBINATION_TYPE\";\n" >> parameter.v	
    printf " parameter FIRST_ARBITER_EXT_P_EN=$FIRST_ARBITER_EXT_P_EN;\n" >> parameter.v	 
    printf " parameter TOPOLOGY=\"$TOPOLOGY\";\n" >> parameter.v	
    printf " parameter ROUTE_NAME=\"$ROUTE_NAME\";\n" >> parameter.v	
	printf " parameter CONGESTION_INDEX=\"$CONGESTION_INDEX\";\n" >> parameter.v	
	printf " parameter CLASS_3_TRAFFIC_PATTERN=$CLASS_3_TRAFFIC_PATTERN;\n" >> parameter.v	
    printf " parameter TRAFFIC=\"$TRAFFIC\";\n" >> parameter.v	
	printf " parameter HOTSPOT_PERCENTAGE=$HOTSPOT_PERCENTAGE;\n" >> parameter.v	
    printf " parameter HOTSOPT_NUM=$HOTSOPT_NUM;\n" >> parameter.v	
    printf " parameter HOTSPOT_CORE_1=$HOTSPOT_CORE_1;\n" >> parameter.v	
    printf " parameter HOTSPOT_CORE_2=$HOTSPOT_CORE_2;\n" >> parameter.v	
    printf " parameter HOTSPOT_CORE_3=$HOTSPOT_CORE_3;\n" >> parameter.v	
    printf " parameter HOTSPOT_CORE_4=$HOTSPOT_CORE_4;\n" >> parameter.v	
	printf " parameter HOTSPOT_CORE_5=$HOTSPOT_CORE_5;\n" >> parameter.v	
    printf " parameter TOTAL_PKT_PER_ROUTER=$TOTAL_PKT_PER_ROUTER;\n" >> parameter.v	
    printf " parameter MAX_DELAY_BTWN_PCKTS=$MAX_DELAY_BTWN_PCKTS;\n" >> parameter.v	
	printf " parameter DEBUG_EN=$DEBUG_EN;\n" >> parameter.v	
	printf " parameter ROUTE_TYPE = (ROUTE_NAME == \"XY\" || ROUTE_NAME == \"TRANC_XY\" )?    \"DETERMINISTIC\" : \n" >> parameter.v	
    printf "			            (ROUTE_NAME == \"DUATO\" || ROUTE_NAME == \"TRANC_DUATO\" )?   \"FULL_ADAPTIVE\": \"PAR_ADAPTIVE\"; \n" >> parameter.v	          
	printf " parameter ADD_PIPREG_AFTER_CROSSBAR= $ADD_PIPREG_AFTER_CROSSBAR;\n" >>  parameter.v
	printf " parameter CVw=(C==0)? V : C * V;\n" >>  parameter.v
	printf " parameter [CVw-1:   0] CLASS_SETTING = $CLASS_SETTING;\n">>  parameter.v 
	printf " parameter [V-1	:	0] ESCAP_VC_MASK=$ESCAP_VC_MASK;\n" >> parameter.v		
	
	
	printf " \n\n \`endif " >> parameter.v	    
	
	
}

generate_parameter_h (){
	printf " #ifndef     INCLUDE_PARAM\n " >> parameter.h	 
	printf " #define   INCLUDE_PARAM\n\n" >> parameter.h	
	printf "\t #define V	$V\n" >> parameter.h	
	printf "\t #define B	$B\n" >> parameter.h	
	printf "\t #define NX	$NX\n" >> parameter.h	
    printf "\t #define NY	$NY\n" >> parameter.h	
    printf "\t #define C	$C\n" >> parameter.h	
    printf "\t #define	Fpay    $Fpay\n" >> parameter.h	
	printf "\t #define	MUX_TYPE    \"$MUX_TYPE\"\n" >> parameter.h	
	printf "\t #define	VC_REALLOCATION_TYPE    \"$VC_REALLOCATION_TYPE\"\n" >> parameter.h	
	printf "\t #define	COMBINATION_TYPE    \"$COMBINATION_TYPE\"\n" >> parameter.h	
	printf "\t #define	FIRST_ARBITER_EXT_P_EN    $FIRST_ARBITER_EXT_P_EN\n" >> parameter.h	 
	printf "\t #define	TOPOLOGY    \"$TOPOLOGY\"\n" >> parameter.h	
	printf "\t #define	ROUTE_NAME    \"$ROUTE_NAME\"\n" >> parameter.h	
	printf "\t #define	CONGESTION_INDEX    \"$CONGESTION_INDEX\"\n" >> parameter.h	
	printf "\t #define	CLASS_3_TRAFFIC_PATTERN    $CLASS_3_TRAFFIC_PATTERN\n" >> parameter.h	
	printf "\t #define	TRAFFIC    \"$TRAFFIC\"\n" >> parameter.h	
	printf "\t #define	HOTSPOT_PERCENTAGE    $HOTSPOT_PERCENTAGE\n" >> parameter.h	
	printf "\t #define	HOTSOPT_NUM    $HOTSOPT_NUM\n" >> parameter.h	
	printf "\t #define	HOTSPOT_CORE_1    $HOTSPOT_CORE_1\n" >> parameter.h	
	printf "\t #define	HOTSPOT_CORE_2    $HOTSPOT_CORE_2\n" >> parameter.h	
	printf "\t #define	HOTSPOT_CORE_3    $HOTSPOT_CORE_3\n" >> parameter.h	
	printf "\t #define	HOTSPOT_CORE_4    $HOTSPOT_CORE_4\n" >> parameter.h	
	printf "\t #define	HOTSPOT_CORE_5    $HOTSPOT_CORE_5\n" >> parameter.h	
	printf "\t #define	TOTAL_PKT_PER_ROUTER    $TOTAL_PKT_PER_ROUTER\n" >> parameter.h	
	printf "\t #define	MAX_DELAY_BTWN_PCKTS    $MAX_DELAY_BTWN_PCKTS\n" >> parameter.h
    printf "\t #define  PACKET_SIZE	$PACKET_SIZE\n" >> parameter.h  
    printf "\t #define	DEBUG_EN	$DEBUG_EN	\n" >> parameter.h 
    printf "\t #define  ADD_PIPREG_AFTER_CROSSBAR  $ADD_PIPREG_AFTER_CROSSBAR\n" >>   parameter.h
	printf "\t #define  CVw	(C==0)? V : C * V\n" >>  parameter.h
	printf "\t #define  CLASS_SETTING   \"$CLASS_SETTING\"\n">>  parameter.h 
	printf "\t #define  ESCAP_VC_MASK	$ESCAP_VC_MASK\n">>  parameter.h					 
	printf " \n\n #endif " >> parameter.h	    
		
}
			
	
for PACKET_SIZE in  3 2 4 6 
	do 
	for  TRAFFIC in  "RANDOM"  "TRANSPOSE1" "TRANSPOSE2"  "HOTSPOT"
	do

		for  ROUTE_NAME in "XY" "WEST_FIRST" "NORTH_LAST"  "NEGETIVE_FIRST"  "DUATO"
		do
			# regenerate NoC
			generate_parameter_v
			mv -f parameter.v ../src_verilator/
			
			#verilate the NoC and make the library files
			./verilator_compile_hw.sh
			
			
			# compile the testbench file
			generate_parameter_h
			mv -f parameter.h ../src_verilator/
			./verilator_compile_sw.sh
			
			testnench_name=$ROUTE_NAME$TRAFFIC"_"$PACKET_SIZE	
			cp $bin_path/testbench $multiple_path/$testnench_name
			
		done
		#run multiple testbench files in the same time
		cd $multiple_path
		
		for  ROUTE_NAME in "XY" "WEST_FIRST" "NORTH_LAST"  "NEGETIVE_FIRST"  "DUATO"
		do	
			
			./$ROUTE_NAME$TRAFFIC"_"$PACKET_SIZE $ROUTE_NAME$TRAFFIC"_"$PACKET_SIZE &	
			
		done
		# wait for all simulation to be done
		wait
		
		# merge the result in one file 
		for  ROUTE_NAME in "XY" "WEST_FIRST" "NORTH_LAST"  "NEGETIVE_FIRST"  "DUATO"
		do	
		data_file=$data_path/$TRAFFIC"_"$PACKET_SIZE"_all.txt"
		plot_file=$plot_path/$TRAFFIC"_"$PACKET_SIZE".eps"
		testnench_name=$ROUTE_NAME$TRAFFIC"_"$PACKET_SIZE	
		 
			printf "#name:"$ROUTE_NAME"\n" >> $data_file
			cat 	$testnench_name"_all.txt" >> $data_file
			printf "\n\n" >> $data_file
			./plot_bin $data_file  $plot_file "Injection ratio flits/node/clk" "Average latency clk" left
			rm	$testnench_name* 
		done
		
		cd $script_path
		
			
		done # ROUTE_NAME
	done #TRAFFIC
			
