#!/bin/sh
set -e
# Any subsequent commands which fail will cause the shell script to exit immediately

my_dir="$(dirname "$0")"
source "$my_dir/../parameter.sh"

# change default parameters
	V=4  #if change u need to change CLASS_SETTING as well
	FIRST_ARBITER_EXT_P_EN=0 
    ROUTE_NAME="XY" 
   	TRAFFIC="TRANSPOSE1" 
	DEBUG_EN=1
	STND_DEV_EN=0
   	B=4
	VC_REALLOCATION_TYPE="NONATOMIC" 
	MAX_PCK_NUM=128000
	 NX=4  # number of node in x axis
    NY=4  # number of node in y axis



cd ..
script_path=$(pwd)
path=$script_path/..
comp_path=$path/../mpsoc_work/verilator
work_path=$comp_path/work
bin_path=$work_path/bin
multiple_path=$work_path/sw_vc_comb
data_path=$multiple_path/data
plot_path=$multiple_path/plot
src_c_path=$path/src_c
src_verilator_path=$path/src_verilator
plot_c_path=$src_c_path/plot
rm -Rf $multiple_path
mkdir -p $data_path
mkdir -p $plot_path






CLASS_CONFIG=0





################
#	
#	regenerate_NoC
#
################	
			
regenerate_NoC() {
	rm -f parameter.v
	generate_parameter_v
	mv -f parameter.v $src_verilator_path/
	cd $script_path		
	#verilate the NoC and make the library files

			./verilator_compile_hw.sh

	# compile the testbench file
	generate_parameter_h
	mv -f parameter.h $src_verilator_path/

			./verilator_compile_sw.sh
	
		
	cp $bin_path/testbench $multiple_path/$testbench_name		
}

###############
# set packet classes
# 
###############


class_setting(){
	if [ $CLASS_CONFIG  -eq  0 ]
	then
		C=1
		C0_p=100
		CLASS_SETTING="4'b1111"
	elif [ $CLASS_CONFIG  -eq  1 ]
	then
		C=$V
		C0_p=$(expr 100 / $V ) 
		C1_p=$(expr 100 / $V )   
		C2_p=$(expr 100 / $V )  
		C3_p=$(expr 100 / $V ) 
		CLASS_SETTING="16'b1000010000100001"
		
		 
	elif [ $CLASS_CONFIG  -eq  3 ]
	then
		C=2
		C0_p=50  
		C1_p=50  
		CLASS_SETTING="8'b11001111"	
		
	elif [ $CLASS_CONFIG  -eq  4 ]
	then
		C=2
		C0_p=50  
		C1_p=50  	
		CLASS_SETTING="8'b11000011"
	else 
		C=2
		C0_p=50  
		C1_p=50  	
	
	fi	
	
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
	"set terminal postscript eps enhanced color font 'Helvetica,24'",
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
	"set yrange [0:60]",
	"set xrange [0:]",
	0
};

#endif

EOF

	mv -f plot_command.h	$plot_c_path/plot_command.h	
	cd $plot_c_path
	make
	cp $plot_c_path/plot $multiple_path/plot_bin
	cd $path
}



#############
#   plot_file
#
############

plot_file (){
	data_file=$data_path/$plot_name$ext".txt"
	plot_file=$plot_path/$plot_name$ext".eps"
	printf "#name:"$CURVE_NAME"\n" >> $data_file
	cat 	$testbench_name$ext".txt" >> $data_file
	printf "\n\n" >> $data_file
	./plot_bin $data_file  $plot_file "Injection ratio flits/node/clk" "Average latency clk" "left"
}


################
#	
#	merg_files
#
################	
		
				
merg_files(){
	
	ext="_all"	
	plot_file			
	
	
	if [ $STND_DEV_EN -eq 1 ]
	then
			ext="_std"	
			plot_file		
	fi
	
	if [ $CLASS_CONFIG  -eq  3 ] 
	then
		ext="_c0"	
		plot_file	
		
		ext="_c1"	
		plot_file	
		
		if [ $STND_DEV_EN -eq 1 ]
		then
			ext="_std0"	
			plot_file	
			
			ext="_std1"	
			plot_file			
		fi
		
		
	fi
	
	
	rm	$testbench_name* 	
			
}	

gen_testbench_name(){
	testbench_name=$VC_REALLOCATION_TYPE"_"$COMBINATION_TYPE"_Config"$CLASS_CONFIG"_P"$PACKET_SIZE
		
}

gen_plot_name(){
	plot_name=$VC_REALLOCATION_TYPE"_Config"$CLASS_CONFIG"_P"$PACKET_SIZE	
	
}

################
#	
#	run_sim
#
################
run_sim(){

	for	COMBINATION_TYPE in "BASELINE"  "COMB_SPEC1"  "COMB_SPEC2"  "COMB_NONSPEC"
	do
		gen_testbench_name
		regenerate_NoC
	done
					
	cd $multiple_path
	
	for	COMBINATION_TYPE in "BASELINE"  "COMB_SPEC1"  "COMB_SPEC2"  "COMB_NONSPEC"
	do	
		gen_testbench_name
		CMD="./$testbench_name $testbench_name"
        
		command $CMD &
	done
		
	# wait for all simulation to be done
	wait
	
	# merge the results in one file 
	for	COMBINATION_TYPE in "BASELINE"  "COMB_SPEC1"  "COMB_SPEC2"  "COMB_NONSPEC"
	do	 
		gen_testbench_name
		gen_plot_name
		CURVE_NAME=$COMBINATION_TYPE
		merg_files
	done #COMBINATION_TYPE
					
	

	cd $script_path			
																		
}	

###############
#	main
##############																																			


generate_plot_command																																																																								
					
 for PACKET_SIZE in 2  4 
	do 
	for	CLASS_CONFIG in 4 
	do
			class_setting
			run_sim
			#teset





		done # CLASS_CONFIG
done #PACKET_SIZE
			
