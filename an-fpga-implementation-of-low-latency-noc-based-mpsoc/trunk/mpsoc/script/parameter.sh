#!/bin/sh

CORE_NUM(){
  # local variable x and y with passed args    
  local x=$1
  local y=$2

  echo $(( $x + ($y*$NX) ))
}


# NoC parameters:
    V=2   # number of VC per port
    TOPOLOGY="MESH" #"MESH" or "TORUS"
    P="localparam P=  (TOPOLOGY==\"RING\" || TOPOLOGY==\"LINE\")? 3 : 5"    # number of port per router 
    B=4   # buffer space :flit per VC 
    NX=8  # number of node in x axis
    NY=8  # number of node in y axis
    C=1   #  number of flit class 
    Fpay=32    #flit payload width
    MUX_TYPE="ONE_HOT"  #crossbar multiplexer type : "ONE_HOT" or "BINARY"
    VC_REALLOCATION_TYPE="NONATOMIC" # "ATOMIC" or "NONATOMIC"
    COMBINATION_TYPE="COMB_NONSPEC" # "BASELINE" or "COMB_SPEC1" or "COMB_SPEC2" or "COMB_NONSPEC"
    FIRST_ARBITER_EXT_P_EN=0  
    
    ROUTE_NAME="XY" # Routing algorithm
    #    mesh :  "XY"        , "WEST_FIRST"      , "NORTH_LAST"      , "NEGETIVE_FIRST"      , "DUATO"
    #   torus:  "TRANC_XY"  , "TRANC_WEST_FIRST", "TRANC_NORTH_LAST", "TRANC_NEGETIVE_FIRST", "TRANC_DUATO"
    
    
    CLASS_SETTING="{CVw{1'b1}}"   
    
    SSA_EN="NO"  # "YES","NO"
    SWA_ARBITER_TYPE="RRA" # "RRA"  ,"WRRA"
    WEIGHTw=4
    
    ADD_PIPREG_AFTER_CROSSBAR=0
    
#simulation parameters:
    C0_p=100    #  the percentage of injected packets with class 0 
    C1_p=0
    C2_p=0
    C3_p=0
     
    
    
 # Simulation parameters: 
    AVG_LATENCY_METRIC="HEAD_2_TAIL"  
    # HEAD_2_TAIL : The average latency is calculated based on the time when the head flit is injected until the tail flit is received
    # HEAD_2_HEAD : The average latency is calculated based on the time when the head flit is injected until it reachs the destination
    TRAFFIC="TRANSPOSE2"     # "RANDOM", "TRANSPOSE1","TRANSPOSE2", "HOTSPOT";
    #Hotspot Traffic setting
    HOTSPOT_PERCENTAGE=3               #maximum 20
    HOTSOPT_NUM=4                    #maximum 5
    HOTSPOT_CORE_1=$(CORE_NUM 1 1)
    HOTSPOT_CORE_2=$(CORE_NUM 1 3)
    HOTSPOT_CORE_3=$(CORE_NUM 3 1)
    HOTSPOT_CORE_4=$(CORE_NUM 3 3)
    HOTSPOT_CORE_5=$(CORE_NUM 2 2)
    
                 
    
    
    MAX_PCK_NUM=128000
    MAX_SIM_CLKs=100000
    MAX_PCK_SIZ=10  # maximum flit number in a single packet
    TIMSTMP_FIFO_NUM=64
    
   
    
    ESCAP_VC_MASK="1"  # mask escape vc
    DEBUG_EN=1
    
    CONGESTION_INDEX=3    # 0: packets are routed to the ports with more available VCs
                        # 1: packets are routed to the ports with more available credits  
                            # 2: packets are routed to the ports connected to the routers with less active ivc requests
                        # 3: packets are routed to the ports connected to the routers with less active ivc requests that are not granted 

    
                         
# Simulation C file constant:  
    PACKET_SIZE=2    # packet size in flit. Minimum is 2


# 
    ROUTE_SUBFUNC="NORTH_LAST"  # "NORTH_LAST" ,"XY"
    AVC_ATOMIC_EN=0
    STND_DEV_EN=0 # 1: generate standard devision  
    
generate_parameter_v (){
    printf " \`ifdef     INCLUDE_PARAM \n\n" >> parameter.v        
    printf " parameter V=$V;\n" >> parameter.v
    printf " parameter TOPOLOGY=\"$TOPOLOGY\";\n" >> parameter.v    
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
       
    printf " parameter ROUTE_NAME=\"$ROUTE_NAME\";\n" >> parameter.v    
    printf " parameter CONGESTION_INDEX=$CONGESTION_INDEX;\n" >> parameter.v
    printf " parameter C0_p=$C0_p;\n" >> parameter.v    
    printf " parameter C1_p=$C1_p;\n" >> parameter.v 
    printf " parameter C2_p=$C2_p;\n" >> parameter.v
    printf " parameter C3_p=$C3_p;\n" >> parameter.v           
    printf " parameter TRAFFIC=\"$TRAFFIC\";\n" >> parameter.v    
    printf " parameter HOTSPOT_PERCENTAGE=$HOTSPOT_PERCENTAGE;\n" >> parameter.v    
    printf " parameter HOTSOPT_NUM=$HOTSOPT_NUM;\n" >> parameter.v    
    printf " parameter HOTSPOT_CORE_1=$HOTSPOT_CORE_1;\n" >> parameter.v    
    printf " parameter HOTSPOT_CORE_2=$HOTSPOT_CORE_2;\n" >> parameter.v    
    printf " parameter HOTSPOT_CORE_3=$HOTSPOT_CORE_3;\n" >> parameter.v    
    printf " parameter HOTSPOT_CORE_4=$HOTSPOT_CORE_4;\n" >> parameter.v    
    printf " parameter HOTSPOT_CORE_5=$HOTSPOT_CORE_5;\n" >> parameter.v    
    printf " parameter MAX_PCK_NUM=$MAX_PCK_NUM;\n" >> parameter.v    
    printf " parameter MAX_SIM_CLKs=$MAX_SIM_CLKs;\n" >> parameter.v    
    printf " parameter MAX_PCK_SIZ=$MAX_PCK_SIZ;\n" >> parameter.v    
    printf " parameter TIMSTMP_FIFO_NUM=$TIMSTMP_FIFO_NUM;\n" >> parameter.v    
    printf " parameter ROUTE_TYPE = (ROUTE_NAME == \"XY\" || ROUTE_NAME == \"TRANC_XY\" )?    \"DETERMINISTIC\" : \n" >> parameter.v    
    printf "                        (ROUTE_NAME == \"DUATO\" || ROUTE_NAME == \"TRANC_DUATO\" )?   \"FULL_ADAPTIVE\": \"PAR_ADAPTIVE\"; \n" >> parameter.v              
    printf " parameter DEBUG_EN=$DEBUG_EN;\n" >> parameter.v     
    printf " parameter ROUTE_SUBFUNC= \"$ROUTE_SUBFUNC\";\n">> parameter.v     
    printf " parameter AVC_ATOMIC_EN= $AVC_ATOMIC_EN;\n">> parameter.v    
    printf " parameter AVG_LATENCY_METRIC= \"$AVG_LATENCY_METRIC\";\n">> parameter.v    
    printf " parameter ADD_PIPREG_AFTER_CROSSBAR= $ADD_PIPREG_AFTER_CROSSBAR;\n" >>  parameter.v
    printf " parameter CVw=(C==0)? V : C * V;\n" >>  parameter.v
    printf " parameter [CVw-1:   0] CLASS_SETTING = $CLASS_SETTING;\n">>  parameter.v 
    printf " parameter [V-1    :    0] ESCAP_VC_MASK=$ESCAP_VC_MASK;\n" >> parameter.v    
    printf " parameter SSA_EN= \"$SSA_EN\";\n">> parameter.v  
    printf " parameter SWA_ARBITER_TYPE=\"$SWA_ARBITER_TYPE\";\n">> parameter.v    
    printf " parameter WEIGHTw=$WEIGHTw;\n">> parameter.v                    
    printf " \n\n \`endif " >> parameter.v        
    
    
}

generate_parameter_h (){
    printf " #ifndef     INCLUDE_PARAM\n " >> parameter.h     
    printf " #define   INCLUDE_PARAM\n\n" >> parameter.h    
    printf "\t #define    V    $V\n" >> parameter.h    
    printf "\t #define    B    $B\n" >> parameter.h    
    printf "\t #define    NX    $NX\n" >> parameter.h    
    printf "\t #define    NY    $NY\n" >> parameter.h    
    printf "\t #define    C    $C\n" >> parameter.h    
    printf "\t #define    Fpay    $Fpay\n" >> parameter.h    
    printf "\t #define    MUX_TYPE    \"$MUX_TYPE\"\n" >> parameter.h    
    printf "\t #define    VC_REALLOCATION_TYPE    \"$VC_REALLOCATION_TYPE\"\n" >> parameter.h    
    printf "\t #define    COMBINATION_TYPE    \"$COMBINATION_TYPE\"\n" >> parameter.h    
    printf "\t #define    FIRST_ARBITER_EXT_P_EN    $FIRST_ARBITER_EXT_P_EN\n" >> parameter.h     
    printf "\t #define    TOPOLOGY    \"$TOPOLOGY\"\n" >> parameter.h    
    printf "\t #define    ROUTE_NAME    \"$ROUTE_NAME\"\n" >> parameter.h    
    printf "\t #define    C0_p    $C0_p\n" >> parameter.h    
    printf "\t #define    C1_p    $C1_p\n" >> parameter.h 
    printf "\t #define    C2_p    $C2_p\n" >> parameter.h
    printf "\t #define    C3_p    $C3_p\n" >> parameter.h       
    printf "\t #define    TRAFFIC    \"$TRAFFIC\"\n" >> parameter.h    
    printf "\t #define    HOTSPOT_PERCENTAGE    $HOTSPOT_PERCENTAGE\n" >> parameter.h    
    printf "\t #define    HOTSOPT_NUM    $HOTSOPT_NUM\n" >> parameter.h    
    printf "\t #define    HOTSPOT_CORE_1    $HOTSPOT_CORE_1\n" >> parameter.h    
    printf "\t #define    HOTSPOT_CORE_2    $HOTSPOT_CORE_2\n" >> parameter.h    
    printf "\t #define    HOTSPOT_CORE_3    $HOTSPOT_CORE_3\n" >> parameter.h    
    printf "\t #define    HOTSPOT_CORE_4    $HOTSPOT_CORE_4\n" >> parameter.h    
    printf "\t #define    HOTSPOT_CORE_5    $HOTSPOT_CORE_5\n" >> parameter.h    
    printf "\t #define    MAX_PCK_NUM            $MAX_PCK_NUM\n" >> parameter.h    
    printf "\t #define    MAX_SIM_CLKs        $MAX_SIM_CLKs\n" >> parameter.h    
    printf "\t #define    MAX_PCK_SIZ            $MAX_PCK_SIZ\n" >> parameter.h    
    printf "\t #define    TIMSTMP_FIFO_NUM    $TIMSTMP_FIFO_NUM\n" >> parameter.h    
    printf "\t #define    PACKET_SIZE    $PACKET_SIZE\n" >> parameter.h  
    printf "\t #define    DEBUG_EN    $DEBUG_EN\n" >> parameter.h     
    printf "\t #define    ROUTE_SUBFUNC \"$ROUTE_SUBFUNC\"\n" >> parameter.h     
    printf "\t #define    AVC_ATOMIC_EN $AVC_ATOMIC_EN\n" >> parameter.h    
    printf "\t #define    CONGESTION_INDEX $CONGESTION_INDEX\n">>parameter.h
    printf "\t #define    STND_DEV_EN    $STND_DEV_EN\n">> parameter.h
    printf "\t #define    AVG_LATENCY_METRIC    \"$AVG_LATENCY_METRIC\"\n">> parameter.h    
    printf "\t #define    ADD_PIPREG_AFTER_CROSSBAR  $ADD_PIPREG_AFTER_CROSSBAR\n" >>   parameter.h
    printf "\t #define    CVw    (C==0)? V : C * V\n" >>  parameter.h
    printf "\t #define    CLASS_SETTING   \"$CLASS_SETTING\"\n">>  parameter.h 
    printf "\t #define    ESCAP_VC_MASK    $ESCAP_VC_MASK\n">>  parameter.h
    printf "\t #define    SSA_EN \"$SSA_EN\"\n" >> parameter.h 
    printf "\t #define    SWA_ARBITER_TYPE \"$SWA_ARBITER_TYPE\"\n">> parameter.h    
    printf "\t #define    WEIGHTw=$WEIGHTw\n">> parameter.h                                            
    printf " \n\n #endif " >> parameter.h        
        
}
