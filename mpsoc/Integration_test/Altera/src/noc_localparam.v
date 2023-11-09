
`ifdef NOC_LOCAL_PARAM




//NoC parameters
	localparam TOPOLOGY="MESH";
	localparam T1=3;
	localparam T2=3;
	localparam T3=1;
	localparam V=2;
	localparam B=4;
	localparam LB=16;
	localparam Fpay=32;
	localparam ROUTE_NAME="XY";
	localparam PCK_TYPE =  "MULTI_FLIT";    //"SINGLE_FLIT";
	localparam MIN_PCK_SIZE=1;
	localparam BYTE_EN=0;
	localparam SSA_EN="YES";
	localparam CONGESTION_INDEX=3;
	localparam ESCAP_VC_MASK=2'b01;
	localparam VC_REALLOCATION_TYPE="NONATOMIC";
	localparam COMBINATION_TYPE="COMB_NONSPEC";
	localparam MUX_TYPE="BINARY";
	localparam C=0;
	localparam DEBUG_EN=1;
	localparam ADD_PIPREG_AFTER_CROSSBAR=1'b0;
	localparam FIRST_ARBITER_EXT_P_EN=1;
	localparam SWA_ARBITER_TYPE="RRA";
	localparam WEIGHTw=4;
	localparam AVC_ATOMIC_EN=0;	
 	localparam CVw=(C==0)? V : C * V;
	localparam CLASS_SETTING={CVw{1'b1}};
 	localparam SMART_MAX=0;
    localparam SELF_LOOP_EN="YES";
    localparam CAST_TYPE = "UNICAST";
	localparam MCAST_ENDP_LIST = 'b11110011;	
	//localparam MCAST_PRTLw=6;
	
	
	
	//simulation parameter	
	//localparam MAX_RATIO = 1000;
	localparam MAX_PCK_NUM = 1000000000;
	localparam MAX_PCK_SIZ = 16383; 
	localparam MAX_SIM_CLKs=  1000000000;
	localparam TIMSTMP_FIFO_NUM = 16;	

`endif
