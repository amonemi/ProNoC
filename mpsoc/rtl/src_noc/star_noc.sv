`timescale 1ns / 1ps

/**************************************
 * Module: tree
 * Date:2019-01-01  
 * Author: alireza     
 *
 * 
Description: 

    Star      

 ***************************************/

 
module  star_noc_top 
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
		  
 
	    router_top # (
			.P(NE)
		)
		the_router
		(              
			.current_r_addr  (1'b0), 
			.chan_in         (chan_in_all), 
			.chan_out        (chan_out_all), 
			.clk             (clk            ), 
			.reset           (reset          )
		);
	

endmodule


module star_conventional_routing #(
		parameter NE                = 8		
		)
		(	
		dest_e_addr,
		destport
);    

	function integer log2;
		input integer number; begin   
			log2=(number <=1) ? 1: 0;    
			while(2**log2<number) begin    
				log2=log2+1;    
			end        
		end   
	endfunction // log2 
  	
	localparam EAw = log2(NE);      

	input   [EAw-1   :0] dest_e_addr;
	output  [EAw-1   :0] destport;
	// the destination endpoint address & connection port number are the same in star topology
	assign destport = dest_e_addr;
endmodule	
