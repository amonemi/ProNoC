 `ifdef     INCLUDE_PARAM 

 parameter V=4;
 parameter P=5;
 parameter B=4;
 parameter NX=8;
 parameter NY=8;
 parameter C=1;
 parameter Fpay=32;
 parameter MUX_TYPE="ONE_HOT";
 parameter VC_REALLOCATION_TYPE="NONATOMIC";
 parameter COMBINATION_TYPE="BASELINE";
 parameter FIRST_ARBITER_EXT_P_EN=0;
 parameter TOPOLOGY="MESH";
 parameter ROUTE_NAME="XY";
 parameter CONGESTION_INDEX=2;
 parameter C0_p=100;
 parameter C1_p=0;
 parameter C2_p=0;
 parameter C3_p=0;
 parameter TRAFFIC="RANDOM";
 parameter HOTSPOT_PERCENTAGE=3;
 parameter HOTSOPT_NUM=4;
 parameter HOTSPOT_CORE_1=9;
 parameter HOTSPOT_CORE_2=25;
 parameter HOTSPOT_CORE_3=11;
 parameter HOTSPOT_CORE_4=27;
 parameter HOTSPOT_CORE_5=18;
 parameter MAX_PCK_NUM=628000;
 parameter MAX_SIM_CLKs=100000;
 parameter MAX_PCK_SIZ=10;
 parameter TIMSTMP_FIFO_NUM=64;
 parameter [V-1	:	0] ESCAP_VC_MASK=1;
 parameter ROUTE_TYPE = (ROUTE_NAME == "XY" || ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
			            (ROUTE_NAME == "DUATO" || ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE"; 
 parameter DEBUG_EN=1;
 parameter ROUTE_SUBFUNC= "NORTH_LAST";
 parameter AVC_ATOMIC_EN= 0;
 parameter AVG_LATENCY_METRIC= "HEAD_2_TAIL"; 
 parameter ADD_PIPREG_AFTER_CROSSBAR=0;
 parameter ADD_PIPREG_BEFORE_CROSSBAR=0;
 parameter CVw=(C==0)? V : C * V;
 parameter [CVw-1:   0] CLASS_SETTING = {CVw{1'b1}}; // shows how each class can use VCs   
 parameter [V-1  :   0] ESCAP_VC_MASK = 4'b1000;  // mask scape vc, valid only for full adaptive 
 
 

 `endif 