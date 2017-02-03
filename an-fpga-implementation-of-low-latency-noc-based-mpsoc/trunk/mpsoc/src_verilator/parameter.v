 `ifdef     INCLUDE_PARAM 

 parameter V=4;
 parameter TOPOLOGY="MESH";
 parameter P=(TOPOLOGY=="RING")? 3 : 5;
 parameter B=5;
 parameter NX=8;
 parameter NY=8;
 parameter C=4;
 parameter Fpay=32;
 parameter MUX_TYPE="ONE_HOT";
 parameter VC_REALLOCATION_TYPE="NONATOMIC";
 parameter COMBINATION_TYPE="COMB_NONSPEC";
 parameter FIRST_ARBITER_EXT_P_EN=0;
 parameter ROUTE_NAME="XY";
 parameter CONGESTION_INDEX=3;
 parameter C0_p=25;
 parameter C1_p=25;
 parameter C2_p=25;
 parameter C3_p=25;
 parameter TRAFFIC="RANDOM";
 parameter HOTSPOT_PERCENTAGE=3;
 parameter HOTSOPT_NUM=4;
 parameter HOTSPOT_CORE_1=18;
 parameter HOTSPOT_CORE_2=50;
 parameter HOTSPOT_CORE_3=22;
 parameter HOTSPOT_CORE_4=54;
 parameter HOTSPOT_CORE_5=18;
 parameter MAX_PCK_NUM=256000;
 parameter MAX_SIM_CLKs=100000;
 parameter MAX_PCK_SIZ=10;
 parameter TIMSTMP_FIFO_NUM=8;
 parameter ROUTE_TYPE = (ROUTE_NAME == "XY" || ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
			            (ROUTE_NAME == "DUATO" || ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE"; 
 parameter DEBUG_EN=1;
 parameter ROUTE_SUBFUNC= "NORTH_LAST";
 parameter AVC_ATOMIC_EN= 0;
 parameter AVG_LATENCY_METRIC= "HEAD_2_TAIL";
 parameter ADD_PIPREG_AFTER_CROSSBAR= 0;
 parameter CVw=(C==0)? V : C * V;
 parameter [CVw-1:   0] CLASS_SETTING = 16'b111111111111111;
 parameter [V-1	:	0] ESCAP_VC_MASK=4'b0001;
 parameter SSA_EN= "NO";
 

 `endif 