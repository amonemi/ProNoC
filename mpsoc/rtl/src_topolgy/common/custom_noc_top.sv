`timescale 1ns / 1ps

module   custom_noc_top 
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
	
	   

    generate 

	             

 
	//do not modify this line ===custom1===
    if(TOPOLOGY == "custom1" ) begin : Tcustom1
    
		custom1_noc_genvar the_noc			
		(	
		    .reset(reset),
		    .clk(clk),    
		    .chan_in_all(chan_in_all),
		    .chan_out_all(chan_out_all)  
		);
    
	end
    endgenerate
	



endmodule	 
