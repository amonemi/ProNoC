`timescale 1ns / 1ps

module custom_ni_routing  #(
    parameter TOPOLOGY = "CUSTOM_NAME",
    parameter ROUTE_NAME = "CUSTOM_NAME",
    parameter ROUTE_TYPE = "DETERMINISTIC",
    parameter RAw  = 4,  
    parameter EAw  = 4,   
    parameter DSTPw = 4   
)
(
    dest_e_addr,
    src_e_addr,
    destport        
);    

    input   [EAw-1   :0] dest_e_addr;
    input   [EAw-1   :0] src_e_addr;
    output  [DSTPw-1 :0] destport;   


   generate 
    
     
     
	
    
     
	
     
	//do not modify this line ===Tcustom1Rcustom===
    if(TOPOLOGY == "custom1" && ROUTE_NAME== "custom" ) begin : Tcustom1Rcustom
    
        Tcustom1Rcustom_conventional_routing  #(
            .RAw(RAw),  
            .EAw(EAw),   
            .DSTPw(DSTPw)  
        )
        the_conventional_routing
        (
            .dest_e_addr(dest_e_addr),
            .src_e_addr(src_e_addr),
            .destport(destport)        
        );    
    
    end	
    
    endgenerate
    	
 
    	
 
    	
 
    	
 
    	
 
    	
 
    	
 
    	
 
    	
 
    	
 
 

endmodule
 
 
