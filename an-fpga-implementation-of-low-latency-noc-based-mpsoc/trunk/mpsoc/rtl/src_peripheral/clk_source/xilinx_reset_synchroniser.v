/**************************************
* Module: xilinx_reset_synchroniser
* Date:2020-07-16  
* Author: alireza     
*
* Description: 
***************************************/

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


module  xilinx_reset_synchroniser #(
     parameter ASYNC_RESET = 0
)(
    input clk,
    input aresetin,
    output sync_reset

);


    generate if (ASYNC_RESET) begin
    // -----------------------------------------------
    // Assert asynchronously, deassert synchronously.
    // -----------------------------------------------
        
        (* ASYNC_REG = "true" *) reg sreg1, sreg2; 
        always @(posedge clk or posedge aresetin) begin
            if(aresetin) begin
                sreg1 <= 1'b1; 
                sreg2 <= 1'b1;
            end 
            else begin 
                sreg1 <= 1'b0; 
                sreg2 <= sreg1; 
            end 
        end 
        assign sync_reset = sreg2; 
        
    end else begin
    // -----------------------------------------------
    // Assert synchronously, deassert synchronously.
    // -----------------------------------------------
        (*preserve*) reg sreg3, sreg4; 
        always @(posedge clk  ) begin
                sreg3 <= aresetin; 
                sreg4 <= sreg3;          
        end 
        
        assign sync_reset = sreg4;      
    
    end 
    endgenerate

endmodule

