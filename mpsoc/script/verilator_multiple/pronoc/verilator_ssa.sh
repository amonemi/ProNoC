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
multiple_path=$work_path/ssa4
data_path=$multiple_path/data
plot_path=$multiple_path/plot
src_c_path=$path/src_c
plot_c_path=$src_c_path/plot    

rm -Rf $multiple_path
mkdir -p $data_path
mkdir -p $plot_path

#cp $path/src_c/plot/plot $multiple_path/plot_bin



    V=4   # number of VC per port
    B=5   # buffer space :flit per VC 
    NX=8  # number of node in x axis
    NY=8  # number of node in y axis
    C=4   #  number of flit class 
    COMBINATION_TYPE="COMB_NONSPEC" # "BASELINE" or "COMB_SPEC1" or "COMB_SPEC2" or "COMB_NONSPEC"
    FIRST_ARBITER_EXT_P_EN=0 
    ROUTE_NAME="XY"
    CLASS_SETTING="16'b111111111111111" 
   
#simulation parameters:
    C0_p=25    #  the percentage of injected packets with class 0 
    C1_p=25
    C2_p=25
    C3_p=25
     
    
    
 # Simulation parameters:   
   
    #Hotspot Traffic setting
    HOTSPOT_PERCENTAGE=3               #maximum 20
    HOTSOPT_NUM=4                    #maximum 5
    HOTSPOT_CORE_1=$(CORE_NUM 2 2)
    HOTSPOT_CORE_2=$(CORE_NUM 2 6)
    HOTSPOT_CORE_3=$(CORE_NUM 6 2)
    HOTSPOT_CORE_4=$(CORE_NUM 6 6)
   
    
                 
    
    
    MAX_PCK_NUM=256000
    MAX_SIM_CLKs=100000
    MAX_PCK_SIZ=10  # maximum flit number in a single packet
    
    
   
    
    ESCAP_VC_MASK="4'b0001"  # mask scape vc
    DEBUG_EN=1
    
    CONGESTION_INDEX=3    # 0: packets are routed to the ports with more available VCs
                        # 1: packets are routed to the ports with more available credits  
                            # 2: packets are routed to the ports connected to the routers with less active ivc requests
                        # 3: packets are routed to the ports connected to the routers with less active ivc requests that are not granted 

    
                         



# 
    
    AVC_ATOMIC_EN=0
    STND_DEV_EN=0 # 1: generate standard devision  
    TIMSTMP_FIFO_NUM=8

  


generate_plot_command(){

rm -f plot_command.h

cat > plot_command.h << EOF
#ifndef PLOT_COMMAND_H
    #define PLOT_COMMAND_H

char * commandsForGnuplot[] = {
    "set terminal postscript eps enhanced color font 'Helvetica,15'",
    "set output 'temp.eps' ",
    "set style line 1 lc rgb \"red\"        lt 1 lw 2 pt 4  ps 1.5",
    "set style line 2 lc rgb \"blue\"       lt 1 lw 2 pt 6  ps 1.5", 
    "set style line 3 lc rgb \"green\"      lt 1 lw 2 pt 10 ps 1.5",
    "set style line 4 lc rgb '#8B008B'     lt 1 lw 2 pt 14 ps 1.5",//darkmagenta
    "set style line 5 lc rgb '#B8860B'     lt 1 lw 2 pt 2  ps 1.5", //darkgoldenrod
    "set style line 6 lc rgb \"gold\"     lt 1 lw 2 pt 3  ps 1.5",
    "set style line 7 lc rgb '#FF8C00'     lt 1 lw 2 pt 10 ps 1.5",//darkorange
    "set style line 8 lc rgb \"black\"     lt 1 lw 2 pt 1  ps 1.5",
    "set style line 9 lc rgb \"spring-green\"     lt 1 lw 2 pt 8  ps 1.5",
    "set style line 10 lc rgb \"yellow4\"     lt 1 lw 2 pt 0  ps 1.5",
    "set yrange [0:45]",
    "set xrange [0:]",
    
    0
};

#endif

EOF

    mv -f plot_command.h    $plot_c_path/plot_command.h    
    cd $plot_c_path
    make
    cp $plot_c_path/plot $multiple_path/plot_bin
    cd $script_path    

}




################
#    
#    regenerate_NoC
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


################
#    
#    merg_files
#
################    
        
                
merg_files(){
    if [ $STND_DEV_EN -eq 1 ]
    then 

        target="_std"
    else
        target="_all"

    fi         

    data_file=$data_path/${plot_name}${target}".txt"
    plot_file=$plot_path/${plot_name}${target}".eps"
        
    printf "#name:"$CURVE_NAME"\n" >> $data_file
    cat     ${testbench_name}${target}".txt" >> $data_file
    printf "\n\n" >> $data_file
    
    ./plot_bin $data_file  $plot_file "Injection ratio flits/node/clk" "Average latency clk" "outside left"
    
    
    
    if [ $C  -gt  1 ] 
    then
    
        data_file=$data_path/$plot_name"_c0.txt"
        plot_file=$plot_path/$plot_name"_c0.eps"
    
    
        printf "#name:"$CURVE_NAME"\n" >> $data_file
        cat     $testbench_name"_c0.txt" >> $data_file
        printf "\n\n" >> $data_file
    
        ./plot_bin $data_file  $plot_file "Injection ratio flits/node/clk" "Average latency clk" "outside left"
    
        data_file=$data_path/$plot_name"_c1.txt"
        plot_file=$plot_path/$plot_name"_c1.eps"
    
    
        printf "#name:"$CURVE_NAME"\n" >> $data_file
        cat     $testbench_name"_c1.txt" >> $data_file
        printf "\n\n" >> $data_file
    
        ./plot_bin $data_file  $plot_file "Injection ratio flits/node/clk" "Average latency clk" "outside left"
    
    fi
    
    
    rm    $testbench_name*     
            
}    

gen_testbench_name(){
    testbench_name=$routename"_"$SSA_EN
        
}

gen_plot_name(){
    plot_name=$routename"_"$TRAFFIC"_"$PACKET_SIZE
    
}


    
    




################
#    
#    run_sim
#
################
run_sim(){

    for  SSA_EN in  "YES" "NO" 
    do    
        
        gen_testbench_name
        regenerate_NoC
    done
                
    



    cd $multiple_path
    
    for  SSA_EN in  "YES" "NO" 
    do    
        
        gen_testbench_name
        CMD="./$testbench_name $testbench_name"
        
        command $CMD &
    done
    
                
    # wait for all simulation to be done
    wait
    
    
    
    # merge the results in one file 
    VC_REALLOCATION_TYPE="NONATOMIC"
    
    for  SSA_EN in  "YES" "NO" 
    do    
        
        
        gen_testbench_name
        gen_plot_name
        CURVE_NAME=$SSA_EN
        merg_files
    done # ROUTE_NAME
    

    cd $script_path            
                                                                        
}        

                                                                                                                                        
generate_plot_command
            




        
 for PACKET_SIZE in 4 # 6
 do 
    for    TRAFFIC in  "HOTSPOT" "RANDOM" "TORNADO" #  "BIT_REVERSE"  "BIT_COMPLEMENT"  "RANDOM"   "TRANSPOSE1"   #"CUSTOM" 
    do
        
            
            run_sim
            
        
    done 
done #PACKET_SIZE
            
