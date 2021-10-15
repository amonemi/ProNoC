`timescale 1 ps / 1 ps

module testbench;


    reg clk;
    reg reset;
    wire [3: 0]led;
    reg  [3: 0]btn;


   initial begin 
       clk = 1'b0;
       forever clk = #10 ~clk;
   end 

  initial begin
	reset=1'b1;
	#10
	@(posedge clk) #1 reset=1'b0;

   end


	 xilinx_jtag_test uut (
    		.clk(clk),
    		.led(led),
   		.btn(btn),
		.reset(reset)
	);





endmodule



