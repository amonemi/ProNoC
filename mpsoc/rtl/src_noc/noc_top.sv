`include "pronoc_def.v"
/**********************************************************************
**    File:  noc_top.sv
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
**    the NoC top module. 
**
**************************************************************/



module  noc_top 
	import pronoc_pkg::*; 
(
	reset,
	clk,    
	chan_in_all,
	chan_out_all,
	router_event
);
  
  	
	input   clk,reset;
	//Endpoints ports 
	input   smartflit_chanel_t chan_in_all  [NE-1 : 0];
	output  smartflit_chanel_t chan_out_all [NE-1 : 0];
	//Events
	output  router_event_t  router_event [NR-1 : 0][MAX_P-1 : 0];
 
   


	generate 
	/* verilator lint_off WIDTH */
	if (TOPOLOGY ==    "MESH" || TOPOLOGY ==    "FMESH" || TOPOLOGY ==  "TORUS" || TOPOLOGY == "RING" || TOPOLOGY == "LINE") begin : tori_noc 
	/* verilator lint_on WIDTH */
		mesh_torus_noc_top noc_top (
			.reset         (reset        ), 
			.clk           (clk          ), 
			.chan_in_all   (chan_in_all  ), 
			.chan_out_all  (chan_out_all ),
			.router_event  (router_event )
		);
	
    
    end else if (TOPOLOGY == "FATTREE") begin : fat_
    
        fattree_noc_top noc_top (
        		.reset         (reset        ), 
        		.clk           (clk          ), 
        		.chan_in_all   (chan_in_all  ), 
        		.chan_out_all  (chan_out_all ),
        		.router_event  (router_event )
        );
        
        
    end else if (TOPOLOGY == "TREE") begin : tree_
        tree_noc_top  noc_top ( 
        	.reset         (reset        ), 
        	.clk           (clk          ), 
        	.chan_in_all   (chan_in_all  ), 
        	.chan_out_all  (chan_out_all ),
        	.router_event  (router_event )
        );
    end else if (TOPOLOGY == "STAR") begin : star_
    	star_noc_top  noc_top ( 
    			.reset         (reset        ), 
    			.clk           (clk          ), 
    			.chan_in_all   (chan_in_all  ), 
    			.chan_out_all  (chan_out_all ),
    			.router_event  (router_event )
    		);
    	
    end else begin :custom_

	custom_noc_top noc_top ( 
			.reset         (reset        ), 
			.clk           (clk          ), 
			.chan_in_all   (chan_in_all  ), 
			.chan_out_all  (chan_out_all ),
			.router_event  (router_event )
		);

    end     
    endgenerate
endmodule






/**********************************
The noc top module that can be called in Verilog module. 

***********************************/

module  noc_top_v 
   import pronoc_pkg::*; 
   (
    flit_out_all,
    flit_out_wr_all,
    credit_in_all,
    flit_in_all,
    flit_in_wr_all,  
    credit_out_all,
    reset,
    clk
 );

	
	input   clk,reset;
	output [NEFw-1 : 0] flit_out_all;
    output [NE-1 : 0] flit_out_wr_all;
    input  [NEV-1 : 0] credit_in_all;
    input  [NEFw-1 : 0] flit_in_all;
    input  [NE-1 : 0] flit_in_wr_all;  
    output [NEV-1 : 0] credit_out_all;


	//struct typed array ports which cannot be caled in verilog 
	smartflit_chanel_t chan_in_all  [NE-1 : 0];
	smartflit_chanel_t chan_out_all [NE-1 : 0];

	noc_top the_top(
		.reset(reset),
		.clk(clk),    
		.chan_in_all(chan_in_all),
		.chan_out_all(chan_out_all),
		.router_event  (  )
	);

	
	
	
	genvar i;
	generate 
	for (i=0; i<NE; i=i+1) begin : lp1
		assign chan_in_all[i].flit_chanel.flit    = flit_in_all [Fw*(i+1)-1 : Fw*i];		
		assign chan_in_all[i].flit_chanel.credit  = credit_in_all [V*(i+1)-1 : V*i]; 
		assign chan_in_all[i].flit_chanel.flit_wr  = flit_in_wr_all[i]; 

		assign flit_out_all [Fw*(i+1)-1 : Fw*i] = chan_out_all[i].flit_chanel.flit;		
		assign credit_out_all [V*(i+1)-1 : V*i] = chan_out_all[i].flit_chanel.credit;
		assign flit_out_wr_all[i] = chan_out_all[i].flit_chanel.flit_wr; 

	end
	endgenerate

endmodule
 
