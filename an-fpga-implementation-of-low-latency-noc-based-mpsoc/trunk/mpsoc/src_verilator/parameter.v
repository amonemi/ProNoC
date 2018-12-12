 `ifdef     INCLUDE_PARAM 
 
 
	

//NoC parameters
 	localparam TOPOLOGY="MESH";
 	localparam NX= 2;
 	localparam NY= 2;
 	localparam V=2;
 	localparam B=4;
 	localparam Fpay=32;
 	localparam ROUTE_NAME="XY";
 	localparam SSA_EN="NO";
 	localparam CONGESTION_INDEX=3;
 	localparam ESCAP_VC_MASK=2'b01;
 	localparam VC_REALLOCATION_TYPE="NONATOMIC";
 	localparam COMBINATION_TYPE="COMB_NONSPEC";
 	localparam MUX_TYPE="BINARY";
 	localparam C=0;
 	localparam DEBUG_EN=0;
 	localparam ADD_PIPREG_AFTER_CROSSBAR=1'b0;
 	localparam FIRST_ARBITER_EXT_P_EN=1;
 	localparam SWA_ARBITER_TYPE="RRA";
 	localparam WEIGHTw=4;
 	localparam AVC_ATOMIC_EN=0;
 	localparam ROUTE_SUBFUNC="XY";
 	localparam MAX_SBP_NUM =0;
 	localparam CLASS_SETTING={V{1'b1}};
  	localparam  CVw=(C==0)? V : C * V;
  
	/* verilator lint_off WIDTH */ 
	localparam  P=(TOPOLOGY=="RING" || TOPOLOGY=="LINE")? 3 : 5;
 	localparam  ROUTE_TYPE = (ROUTE_NAME == "XY" || ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
                        (ROUTE_NAME == "DUATO" || ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE"; 
	/* verilator lint_on WIDTH */
	//simulation parameter	
	

 
 `endif