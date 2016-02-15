`timescale 1ns/1ps

module testbench;

reg clk,reset;
reg [1:0] ext_int;
wire [6:0] seg1,seg0;


intrrupt_test uut(
	.aeMB_sys_ena_i(1'b1), 
	.ss_clk_in(clk), 
	.ss_reset_in(reset), 
	.ext_int_ext_int_i(ext_int), 
	.seg0_port_o(seg0), 
	.seg1_port_o(seg1)
);


initial begin 
	clk=0;
	forever clk=#10 ~clk;
end


initial begin 
	reset=1'b1;
	ext_int=2'b0;	
	#200 
	reset=1'b0;

end


endmodule
