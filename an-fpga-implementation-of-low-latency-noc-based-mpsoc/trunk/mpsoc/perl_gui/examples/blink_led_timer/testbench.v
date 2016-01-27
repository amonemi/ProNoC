`timescale 1ns/1ps

module testbench;

reg		aeMB_sys_ena_i;

reg			clk;
reg			reset;

wire   	led_o;


led_tim #(
	.ram_RAM_TAG_STRING("00") ,
	.led_PORT_WIDTH(1)
)uut
(
	.aeMB_sys_ena_i(1'b1), 
	.ss_clk_in(clk), 
	.ss_reset_in(reset), 
	.led_port_o(led_o)
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

