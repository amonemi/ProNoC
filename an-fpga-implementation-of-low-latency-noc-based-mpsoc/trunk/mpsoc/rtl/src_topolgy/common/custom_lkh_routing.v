`timescale 1ns / 1ps

module custom_lkh_routing  #(
	parameter TOPOLOGY = "CUSTOM_NAME",
        parameter ROUTE_NAME = "CUSTOM_NAME",
	parameter ROUTE_TYPE = "DETERMINISTIC",
	parameter RAw = 3,  
	parameter EAw = 3,   
	parameter DSTPw=4  
)
(
	current_r_addr,
	dest_e_addr,
	src_e_addr,
	destport,
	reset,
	clk
);
    
	input   [RAw-1   :0] current_r_addr;
	input   [EAw-1   :0] dest_e_addr;
	input   [EAw-1   :0] src_e_addr;
	output  [DSTPw-1 :0] destport;	
	input reset,clk;

    generate 
    
    
    
     
	
    
     
	//do not modify this line ===Tcustom1Rcustom===
    if(TOPOLOGY == "custom1" && ROUTE_NAME== "custom" ) begin : Tcustom1Rcustom
     
	   Tcustom1Rcustom_look_ahead_routing  #(
            .RAw(RAw),  
            .EAw(EAw),   
            .DSTPw(DSTPw)  
        )
        the_lkh_routing
        (
            .current_r_addr(current_r_addr),
            .dest_e_addr(dest_e_addr),
            .src_e_addr(src_e_addr),
            .destport(destport),
            .reset(reset),
            .clk(clk)        
        );    
    
    end	
    
    endgenerate
    	
 
    	
 
    	
 
    	
 
    	
 
    	
 
    

endmodule
