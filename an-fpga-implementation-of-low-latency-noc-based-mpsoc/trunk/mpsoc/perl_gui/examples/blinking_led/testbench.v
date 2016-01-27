`timescale 1ns/1ps

module testbench;

reg		aeMB_sys_ena_i;

reg			clk;
reg			reset;

wire   	led_o;


soc1 soc (
	aeMB_sys_ena_i, 
	clk, 
	reset, 
	led_o
);

initial begin 
	clk=0;
	forever clk=#10 ~clk;
end


initial begin 
	reset=1'b1;
	aeMB_sys_ena_i=1;
	
	#200 
	reset=1'b0;

end



endmodule

