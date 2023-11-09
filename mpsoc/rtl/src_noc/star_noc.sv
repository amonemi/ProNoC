`include "pronoc_def.v"

/**************************************
 * Module: tree
 * Date:2019-01-01  
 * Author: alireza     
 *
 * 
Description: 

    Star      

 ***************************************/

 
module  star_noc_top #(
	parameter NOC_ID=0
) (
		reset,
		clk,    
		chan_in_all,
		chan_out_all,
		router_event
	);
  
  	`NOC_CONF
  
	input   clk,reset;
	//Endpoints ports 
	input   smartflit_chanel_t chan_in_all  [NE-1 : 0];
	output  smartflit_chanel_t chan_out_all [NE-1 : 0];
	
	//Events
	output  router_event_t  router_event [NR-1 : 0][MAX_P-1 : 0];
		  
 
	    router_top # (
			.NOC_ID(NOC_ID),
			.P(NE)
		)
		the_router
		(              
			.current_r_id    (0),
			.current_r_addr  (1'b0), 
			.chan_in         (chan_in_all), 
			.chan_out        (chan_out_all), 
			.router_event    (router_event[0]),
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
