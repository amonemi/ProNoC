// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

/**********************************************************************
**    File:  mesh_torus_noc.v
**    
**    Copyright (C) 2014-2017  Alireza Monemi
**    
**    This file is part of ProNoC 
**
**    ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**    you can redistribute it and/or modify it under the terms of the GNU
**    Lesser General Public License as published by the Free Software Foundation,
**    either version 2 of the License, or (at your option) any later version.
**
**     ProNoC is distributed in the hope that it will be useful, but WITHOUT
**     ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
**     or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
**     Public License for more details.
**
**     You should have received a copy of the GNU Lesser General Public
**     License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
**
**
**    Description: 
**    the NoC top module. It generate one of the mesh, torus, ring, or line  topologies by 
**    connecting routers  
**
**************************************************************/


`define router_id(x,y)                         ((y * NX) +    x)
`define endp_id(x,y,l)                         ((y * NX) +    x) * NL + l 



module mesh_torus_noc_top 
		import pronoc_pkg::*; 
	(

    reset,
    clk,    
    chan_in_all,
    chan_out_all  
);

    
	input   clk,reset;
	//local ports 
	input   smartflit_chanel_t chan_in_all  [NE-1 : 0];
	output  smartflit_chanel_t chan_out_all [NE-1 : 0];
	
	//all routers port 
	smartflit_chanel_t    router_chan_in   [NR-1 :0][MAX_P-1 : 0];
	smartflit_chanel_t    router_chan_out  [NR-1 :0][MAX_P-1 : 0];

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
	
				router_top #(
					.P               (MAX_P          )
					) the_router (
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
						assign  router_chan_in[x][FORWARD]= {SMARTFLIT_CHANEL_w{1'b0}};										      
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
						assign  router_chan_in[x][BACKWARD]={SMARTFLIT_CHANEL_w{1'b0}};					
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
             	
					router_top #(
						.P               (MAX_P          )
					) the_router (
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
						assign router_chan_in[`router_id(x,y)][EAST] = {SMARTFLIT_CHANEL_w{1'b0}};					
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
						assign router_chan_in[`router_id(x,y)][NORTH] =  {SMARTFLIT_CHANEL_w{1'b0}};												
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
						assign    router_chan_in[`router_id(x,y)][WEST] =   {SMARTFLIT_CHANEL_w{1'b0}};						
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
						assign  router_chan_in[`router_id(x,y)][SOUTH]=  {SMARTFLIT_CHANEL_w{1'b0}};						
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
