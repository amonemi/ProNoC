`ifndef PRONOC_DEF
`define PRONOC_DEF

    `timescale      1ns/1ps

	//`define SYNC_RESET_MODE    	/* Reset is asynchronous by default. Uncomment this line for having synchronous reset*/
	//`define ACTIVE_LOW_RESET_MODE /* Reset is active high by deafult. Uncomment this line for having active low reset*/



	`ifdef SYNC_RESET_MODE 
			`define pronoc_clk_reset_edge  posedge clk
	`else 
		`ifdef ACTIVE_LOW_RESET_MODE 
	   	 	`define pronoc_clk_reset_edge  posedge clk or negedge reset
		`else 
			`define pronoc_clk_reset_edge  posedge clk or posedge reset		
		`endif  
	`endif   
	   



	`ifdef ACTIVE_LOW_RESET_MODE 
	   	 	`define pronoc_reset !reset
		`else 
			`define pronoc_reset  reset
	`endif  



    `ifdef USE_LIB
         `uselib lib=`USE_LIB    
    `endif


/****************
	TRACE dump 
*****************/    
   //uncomment following define to enable TRACE dumping
   
   
   // `define TRACE_DUMP_PER_NoC	    // dump all in/out traces to the NoC in single file
   // `define TRACE_DUMP_PER_ROUTER	    // dump each router in/out traces in a seprate file
  // `define TRACE_DUMP_PER_PORT	    // dump each router port in/out in a single file
 




`endif

