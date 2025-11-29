`timescale 1ns / 1ps

module custom_conv_routing  #(
    parameter TOPOLOGY = "CUSTOM_NAME",
    parameter ROUTE_NAME = "CUSTOM_NAME",
    parameter ROUTE_TYPE = "DETERMINISTIC",
    parameter RAw = 3,  
    parameter EAw = 3,   
    parameter DSTPw=4  
)(
    current_r_addr,
    dest_e_addr,
    src_e_addr,
    destport
);
    
    input   [RAw-1   :0] current_r_addr;
    input   [EAw-1   :0] dest_e_addr;
    input   [EAw-1   :0] src_e_addr;
    output  [DSTPw-1 :0] destport;    


    generate
    
    //do not modify this line ===Tcustom1Rcustom===
    /* verilator lint_off WIDTH */
    if(TOPOLOGY == "custom1" && ROUTE_NAME== "custom" ) begin : Tcustom1Rcustom
    /* verilator lint_on WIDTH */
        Tcustom1Rcustom_conv_routing_comb  #(
            .RAw(RAw),
            .EAw(EAw),
            .DSTPw(DSTPw)
        ) the_routing (
            .current_r_addr(current_r_addr),
            .dest_e_addr(dest_e_addr),
            .src_e_addr(src_e_addr),
            .destport(destport)
        );
    end
    endgenerate
 
 
 
 
endmodule
