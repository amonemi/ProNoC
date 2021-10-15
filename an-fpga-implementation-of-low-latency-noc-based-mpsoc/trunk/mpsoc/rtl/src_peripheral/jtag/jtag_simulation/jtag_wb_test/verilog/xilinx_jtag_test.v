`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/05/2020 06:13:04 PM
// Design Name: 
// Module Name: jtag_axi
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps

module xilinx_jtag_test (
    input clk,
    input reset,
    output [3: 0]led,
    input  [3: 0]btn
);
    
    
   
    
    parameter JDw=32;
    parameter JAw=32;
    parameter JINDEXw=8;
    parameter JSTATUSw=8;
    
    
   
   
    localparam  J2WBw= 1+1+JDw+JAw;
    localparam  WB2Jw=1+JSTATUSw+JINDEXw+1+JDw;
    
    
   

 xilinx_jtag_wb #(
    .JWB_NUM(1),
    .JDw(32),
    .JAw(32),
    .JINDEXw(8),
    .JSTATUSw(8),
    .CTRL_REG_INDEX(127)

)
jwb
(
   // clk, get the clock from wb interface
    .reset(reset),
    .cpu_en(led[0]),
    .system_reset(led[1]),
    .wb_to_jtag_all({{WB2Jw-1{1'b0}} ,clk}),
    .jtag_to_wb_all()
);

 
 
 /*
 reg ack;
 wire stb;
 wire we;
 wire [JDw-1 : 0] jtag_dout;
 always @ (posedge clk) ack<=stb;
 
  xilinx_jtag_mem_ctrl #(
    .Dw(32),
    .Aw(32),
    .INDEXw(8),
    .STATUSw(8)
)uut
(
       
    .wb_to_jtag_status(8'hCD),
    .wb_to_jtag_dat(32'hDEADBEEF),
    .wb_to_jtag_ack(ack),
    
    .jtag_to_wb_ir(),
    .jtag_to_wb_index(),
    .jtag_to_wb_dat(jtag_dout),
    .jtag_to_wb_addr(),
    .jtag_to_wb_stb(stb),
    .jtag_to_wb_we(we),
        
    .reset(reset),
    .clk(clk)
);
   
reg [3:0] dout; 
always @(posedge clk)begin 
    if(stb & we) dout <= jtag_dout[3:0];
end   

assign led = dout;
*/    
    
endmodule



 
