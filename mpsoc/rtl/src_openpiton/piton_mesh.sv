`timescale      1ns/1ps

`include "define.tmp.h"
		                                      
/*********************************            
 *                                            
 *   pack openpiton routers ports	          
 * 	                                          
 * 	******************************/           
			                                  
module piton_router_top                       
	                 
(                                        
		                                      
	clk,                                  
	reset,                             
	  
	current_r_addr,
						
	chan_in,                              
	chan_out				              
);                                        
	  
	import piton_pkg::*;  
	import pronoc_pkg::*;          
	
	localparam P=5;                        
		                                      
	                                          
	input 	clk, reset;  
	input   [RAw-1 : 0] current_r_addr;
	
		                                      
	input  piton_chan_t chan_in  [P-1 : 0];   
	output piton_chan_t chan_out [P-1 : 0];	  
		  
	
	wire [`NOC_X_WIDTH-1:0] myLocX;       // thi
	wire [`NOC_Y_WIDTH-1:0] myLocY;             
	wire [`NOC_CHIPID_WIDTH-1:0] myChipID;
	
	  
	assign myLocY = (current_r_addr / `PITON_X_TILES ) % `PITON_Y_TILES ;
	assign myLocX = (current_r_addr % `PITON_X_TILES );
	assign myChipID =0;
  		                                      
	dynamic_node_top_wrap router              
		(                                         
			.clk(clk),                            
			.reset_in(reset),                     
			// dataIn (to input blocks)           
			.dataIn_N(chan_in[NORTH].data),       
			.dataIn_E(chan_in[EAST ].data),       
			.dataIn_S(chan_in[SOUTH].data),       
			.dataIn_W(chan_in[WEST ].data),       
			.dataIn_P(chan_in[LOCAL].data),       
			// validIn (to input blocks)          
			.validIn_N(chan_in[NORTH].valid),     
			.validIn_E(chan_in[EAST ].valid),     
			.validIn_S(chan_in[SOUTH].valid),     
			.validIn_W(chan_in[WEST ].valid),     
			.validIn_P(chan_in[LOCAL].valid),     
			// yummy (from nighboring inputlocks) 
			.yummyIn_N(chan_in[NORTH].yummy),     
			.yummyIn_E(chan_in[EAST ].yummy),     
			.yummyIn_S(chan_in[SOUTH].yummy),     
			.yummyIn_W(chan_in[WEST ].yummy),     
			.yummyIn_P(chan_in[LOCAL].yummy),     
			// My Absolute Address                
			.myLocX(myLocX),                      
			.myLocY(myLocY),                      
			.myChipID(myChipID),                  
			//.ec_cfg(15'b0),//ec_dyn_cfg[14:0]), 
			//.store_meter_partner_address_X(5'b0)
			//.store_meter_partner_address_Y(5'b0)
			// DataOut (from crossbar)            
			.dataOut_N(chan_out[NORTH].data),     
			.dataOut_E(chan_out[EAST ].data),     
			.dataOut_S(chan_out[SOUTH].data),     
			.dataOut_W(chan_out[WEST ].data),     
			.dataOut_P(chan_out[LOCAL].data),     
			// validOut (from crossbar)           
			.validOut_N(chan_out[NORTH].valid),   
			.validOut_E(chan_out[EAST ].valid),   
			.validOut_S(chan_out[SOUTH].valid),   
			.validOut_W(chan_out[WEST ].valid),   
			.validOut_P(chan_out[LOCAL].valid),   
			// yummyOut (to neighboring outpu     
			.yummyOut_N(chan_out[NORTH].yummy),   
			.yummyOut_E(chan_out[EAST ].yummy),   
			.yummyOut_W(chan_out[WEST].yummy),   
			.yummyOut_S(chan_out[SOUTH ].yummy),   
			.yummyOut_P(chan_out[LOCAL].yummy),   
			// thanksIn (to CGNO)                 
			.thanksIn_P()//?                      
		);	                                  
		                                      
endmodule		                              

/*********************
 * piton_mesh 
 * 
 * ********************/

`define router_id(x,y)                         ((y * NX) +    x)
`define endp_id(x,y,l)                         ((y * NX) +    x) * NL + l 


module piton_mesh
	
(                                        
		                                      
	clk,                                  
	reset,                                
	    
	chan_in_all,                              
	chan_out_all				              
);                                     


	import piton_pkg::*;     
	import pronoc_pkg::*;    
	
 	input clk, reset;                                
	    
 
 	//local ports 
 	input   piton_chan_t chan_in_all  [NE-1 : 0];
 	output  piton_chan_t chan_out_all [NE-1 : 0];
	
 	//all routers port 
 	piton_chan_t    router_chan_in   [NR-1 :0][MAX_P-1 : 0];
 	piton_chan_t    router_chan_out  [NR-1 :0][MAX_P-1 : 0];

 	wire [RAw-1 : 0] current_r_addr [NR-1 : 0];


 	// mesh torus            
 	localparam
 		EAST   =       3'd1, 
 		NORTH  =       3'd2,  
 		WEST   =       3'd3,  
 		SOUTH  =       3'd4;
 	//ring line            
 	localparam 
 		FORWARD =  2'd1,
 		BACKWARD=  2'd2;


 	genvar x,y,l;
 	generate 
 	/* verilator lint_off WIDTH */ 
 	if( TOPOLOGY == "RING" || TOPOLOGY == "LINE") begin : ring_line 
 	/* verilator lint_on WIDTH */ 
 		for  (x=0;   x<NX; x=x+1) begin :Router_
             
                       
 			assign current_r_addr [x] = x[RAw-1: 0];   
	
 			piton_router_top the_router (
 						.current_r_addr  (current_r_addr [x]), 
 						.chan_in         (router_chan_in [x]), 
 						.chan_out        (router_chan_out[x]), 
 						.clk             (clk            ), 
 						.reset           (reset          ));
	
 				if(x    <   NX-1) begin: not_last_node            
 					assign  router_chan_in[x][FORWARD] = router_chan_out [(x+1)][BACKWARD];
 				end else begin :last_node
 					/* verilator lint_off WIDTH */ 
 					if(TOPOLOGY == "LINE") begin : line_last_x
 						/* verilator lint_on WIDTH */ 
 						assign  router_chan_in[x][FORWARD]= {PITON_CHANEL_w{1'b0}};										      
 					end else begin : ring_last_x
 						assign router_chan_in[x][FORWARD]= router_chan_out [0][BACKWARD];
 					end
 				end 
            
 				if(x>0)begin :not_first_x
 					assign router_chan_in[x][BACKWARD]= router_chan_out [(x-1)][FORWARD];					
 				end else begin :first_x
 					/* verilator lint_off WIDTH */ 
 					if(TOPOLOGY == "LINE") begin : line_first_x
 						/* verilator lint_on WIDTH */ 
 						assign  router_chan_in[x][BACKWARD]={PITON_CHANEL_w{1'b0}};					
 					end else begin : ring_first_x
 						assign  router_chan_in[x][BACKWARD]= router_chan_out [(NX-1)][FORWARD];											
 					end
 				end            
            
 				// connect other local ports
 				for  (l=0;   l<NL; l=l+1) begin :locals
 					localparam ENDPID = `endp_id(x,0,l); 
 					localparam LOCALP = (l==0) ? l : l + R2R_CHANELS_MESH_TORI; // first local port is connected to router port 0. The rest are connected at the end  
 					assign router_chan_in[x][LOCALP]= chan_in_all [ENDPID];
 					assign chan_out_all [ENDPID] = router_chan_out[x][LOCALP];
					                
 				end// locals               
 			end//x    
			
 		end else begin :mesh_torus
 			for (y=0;    y<NY;    y=y+1) begin: y_loop
 				for (x=0;    x<NX; x=x+1) begin :x_loop
 					localparam R_ADDR = (y<<NXw) + x;            
 					localparam ROUTER_NUM = (y * NX) +    x;					
 					assign current_r_addr [ROUTER_NUM] = R_ADDR[RAw-1 :0];
             	
 					piton_router_top  the_router (
 							.current_r_addr  (current_r_addr [ROUTER_NUM]),    
 							.chan_in         (router_chan_in [ROUTER_NUM]), 
 							.chan_out        (router_chan_out[ROUTER_NUM]), 
 							.clk             (clk            ), 
 							.reset           (reset          ));
					
							
 					/*
    in [x,y][east] <------  out [x+1 ,y  ][west] ;
    in [x,y][north] <------ out [x   ,y-1][south] ;
    in [x,y][west] <------  out [x-1 ,y  ][east] ;
    in [x,y][south] <------ out [x   ,y+1][north] ;
 					 */    
        
        
 					if(x    <    NX-1) begin: not_last_x
 						assign router_chan_in[`router_id(x,y)][EAST]= router_chan_out [`router_id(x+1,y)][WEST];
 						//assign    router_credit_in_all [`SELECT_WIRE(x,y,EAST,V)] = router_credit_out_all [`SELECT_WIRE((x+1),y,WEST,V)];					
 					end else begin :last_x
 						/* verilator lint_off WIDTH */ 
 						if(TOPOLOGY == "MESH") begin :last_x_mesh
 							/* verilator lint_on WIDTH */ 
 							assign router_chan_in[`router_id(x,y)][EAST] = {PITON_CHANEL_w{1'b0}};					
 							/* verilator lint_off WIDTH */ 
 						end else if(TOPOLOGY == "TORUS") begin : last_x_torus
 							/* verilator lint_on WIDTH */ 
 							assign router_chan_in[`router_id(x,y)][EAST] = router_chan_out [`router_id(0,y)][WEST];						
 							/* verilator lint_off WIDTH */ 
 						end else if(TOPOLOGY == "FMESH") begin : last_x_fmesh //connect to endp
 							/* verilator lint_on WIDTH */ 
 							localparam EAST_ID = NX*NY*NL + 2*NX + NY +y; 
 							assign router_chan_in [`router_id(x,y)][EAST] =    chan_in_all [EAST_ID];
 							assign chan_out_all [EAST_ID] = router_chan_out [`router_id(x,y)][EAST];						 
 						end //topology
 					end 
            
        
 					if(y>0) begin : not_first_y
 						assign router_chan_in[`router_id(x,y)][NORTH] =  router_chan_out [`router_id(x,(y-1))][SOUTH];					
 					end else begin :first_y
 						/* verilator lint_off WIDTH */ 
 						if(TOPOLOGY == "MESH") begin : first_y_mesh
 							/* verilator lint_on WIDTH */ 
 							assign router_chan_in[`router_id(x,y)][NORTH] =  {PITON_CHANEL_w{1'b0}};												
 							/* verilator lint_off WIDTH */ 
 						end else if(TOPOLOGY == "TORUS") begin :first_y_torus
 							/* verilator lint_on WIDTH */ 
 							assign router_chan_in[`router_id(x,y)][NORTH] =  router_chan_out [`router_id(x,(NY-1))][SOUTH];						
 							/* verilator lint_off WIDTH */ 
 						end else if(TOPOLOGY == "FMESH") begin : first_y_fmesh //connect to endp
 							/* verilator lint_on WIDTH */ 	
 							localparam NORTH_ID = NX*NY*NL + x; 
 							assign router_chan_in [`router_id(x,y)][NORTH] =    chan_in_all [NORTH_ID];
 							assign chan_out_all [NORTH_ID] = router_chan_out [`router_id(x,y)][NORTH];
 						end//topology
 					end//y>0
            
            
 					if(x>0)begin :not_first_x
 						assign    router_chan_in[`router_id(x,y)][WEST] =  router_chan_out [`router_id((x-1),y)][EAST];					
 					end else begin :first_x
 						/* verilator lint_off WIDTH */ 
 						if(TOPOLOGY == "MESH") begin :first_x_mesh
 							/* verilator lint_on WIDTH */ 
 							assign    router_chan_in[`router_id(x,y)][WEST] =   {PITON_CHANEL_w{1'b0}};						
 							/* verilator lint_off WIDTH */                
 						end else if(TOPOLOGY == "TORUS") begin :first_x_torus
 							/* verilator lint_on WIDTH */ 
 							assign    router_chan_in[`router_id(x,y)][WEST] =   router_chan_out [`router_id((NX-1),y)][EAST] ;						
 							/* verilator lint_off WIDTH */ 
 						end else if(TOPOLOGY == "FMESH") begin : first_x_fmesh //connect to endp
 							/* verilator lint_on WIDTH */ 	
 							localparam WEST_ID = NX*NY*NL +2*NX + y; 
 							assign router_chan_in [`router_id(x,y)][WEST] =    chan_in_all [WEST_ID];
 							assign chan_out_all [WEST_ID] = router_chan_out [`router_id(x,y)][WEST];						
 						end//topology
 					end    
            
 					if(y    <    NY-1) begin : firsty
 						assign  router_chan_in[`router_id(x,y)][SOUTH] =    router_chan_out [`router_id(x,(y+1))][NORTH];					
 					end else     begin : lasty
 						/* verilator lint_off WIDTH */ 
 						if(TOPOLOGY == "MESH") begin :ly_mesh
 							/* verilator lint_on WIDTH */ 
 							assign  router_chan_in[`router_id(x,y)][SOUTH]=  {PITON_CHANEL_w{1'b0}};						
 							/* verilator lint_off WIDTH */ 
 						end else if(TOPOLOGY == "TORUS") begin :ly_torus
 							/* verilator lint_on WIDTH */ 
 							assign  router_chan_in[`router_id(x,y)][SOUTH]=    router_chan_out [`router_id(x,0)][NORTH];						
 						end else if(TOPOLOGY == "FMESH") begin : ly_fmesh //connect to endp
 							/* verilator lint_on WIDTH */ 	
 							localparam SOUTH_ID = NX*NY*NL + NX + x; 
 							assign router_chan_in [`router_id(x,y)][SOUTH] =    chan_in_all [SOUTH_ID];
 							assign chan_out_all [SOUTH_ID] = router_chan_out [`router_id(x,y)][SOUTH];
 						end//topology
 					end          
        
        
 					// endpoint(s) connection
 					// connect other local ports
 					for  (l=0;   l<NL; l=l+1) begin :locals
 						localparam ENDPID = `endp_id(x,y,l); 
 						localparam LOCALP = (l==0) ? l : l + R2R_CHANELS_MESH_TORI; // first local port is connected to router port 0. The rest are connected at the end  
                
 						assign router_chan_in [`router_id(x,y)][LOCALP] =    chan_in_all [ENDPID];
 						assign chan_out_all [ENDPID] = router_chan_out [`router_id(x,y)][LOCALP];			
                              
 					end// locals                 
    
 				end //y
 			end //x
 		end// mesh_torus        
    
 	endgenerate
	
endmodule	




module piton_mesh_pronoc_wrap
	               
                     
	(                                        
		                                      
			clk,                                  
			reset,                                
	    
			chan_in_all,                              
			chan_out_all				              
		);                          
	import piton_pkg::*;     
	import pronoc_pkg::*;          
    
	input   clk,reset;
	//local ports  ProNoC interface
	input   smartflit_chanel_t chan_in_all  [NE-1 : 0];
	output  smartflit_chanel_t chan_out_all [NE-1 : 0];

	
	
	//piton interface  
	piton_chan_t piton_chan_in_all  [NE-1 : 0];
	piton_chan_t piton_chan_out_all [NE-1 : 0];
	
	
	piton_mesh pmesh(                                        
              
		.clk         (clk         ),                         
		.reset       (reset       ),                     
		.chan_in_all (piton_chan_in_all ),                             
		.chan_out_all(piton_chan_out_all)				              
		);                                     

	localparam
		NX = T1,
		NY = T2,
		RXw = log2(NX),    // number of node in x axis
		RYw = log2(NY),
		EXw = log2(NX),    // number of node in x axis
		EYw = log2(NY);   // number of node in y axis
    
    
	wire [RXw-1 : 0] current_x [NE-1 : 0];
	wire [RYw-1 : 0] current_y [NE-1 : 0];
	reg [`XY_WIDTH-1:0] myLocX [NE-1 : 0];       // thi
	reg [`XY_WIDTH-1:0] myLocY [NE-1 : 0];             
	reg [`CHIP_ID_WIDTH-1:0] myChipID[NE-1 : 0];
	
	genvar i;
	generate 
	for (i=0; i<NE;i++) begin :E_
		
		
		mesh_tori_router_addr_decode #(
				.TOPOLOGY(TOPOLOGY),
				.T1(T1),
				.T2(T2),
				.T3(T3),
				.RAw(RAw)
			)
			r_addr_decode
			(
				.r_addr(i[RAw-1:0]),
				.rx(current_x[i]),
				.ry(current_y[i]),
				.valid()
			);
		
		
		always @(*) begin 
			myLocX[i]   = {`XY_WIDTH{1'b0}};
			myLocY[i]   = {`XY_WIDTH{1'b0}};
			myChipID[i] = {`CHIP_ID_WIDTH{1'b0}};
		
			myLocX[i]  [RXw-1 : 0] = current_x[i];
			myLocY[i]  [RYw-1 : 0] = current_y[i];
			
		end
		
		piton_to_pronoc_wrapper #(.NOC_NUM(1),.TILE_NUM(i),.CHIP_SET_PORT(0),.FLATID_WIDTH(FLATID_WIDTH)) pi2pr_wrapper1
			(
				.default_chipid(myChipID[i]), .default_coreid_x(myLocX[i]), .default_coreid_y(myLocY[i]), .flat_tileid(i[FLATID_WIDTH-1 : 0]),	
				.reset(reset),
				.clk (clk),
				.dataIn (piton_chan_out_all[i].data),
				.validIn(piton_chan_out_all[i].valid),
				.yummyIn(piton_chan_out_all[i].yummy),
				.chan_out(chan_out_all[i]),
				.current_r_addr_i(i[RAw-1:0])
			);	

		pronoc_to_piton_wrapper  #(.NOC_NUM(1),.TILE_NUM(i),.FLATID_WIDTH(FLATID_WIDTH)) pr2pi_wrapper1
			(
				.default_chipid(myChipID[i]), .default_coreid_x(myLocX[i]), .default_coreid_y(myLocY[i]), .flat_tileid(i[FLATID_WIDTH-1:0]),	
				.reset(reset),
				.clk (clk),
				.dataOut (piton_chan_in_all[i].data ),
				.validOut(piton_chan_in_all[i].valid ),
				.yummyOut(piton_chan_in_all[i].yummy ),
				.chan_in (chan_in_all[i] ),
				.current_r_addr_o( )
			);			
		
	end
	endgenerate

endmodule




