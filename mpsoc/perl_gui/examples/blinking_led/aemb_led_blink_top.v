module aemb_led_blink_top (
	output [0:0]LEDR,
	output [0:0]LEDG,
	input  [0:0]KEY,
	input  CLOCK_50
	); 
	wire reset_in,jtag_reset,reset;

	assign	reset_in	=	~KEY[0];
	assign  LEDG[0]		=	reset;
	assign  reset		=	(jtag_reset | reset_in);

// a reset source which can be controled using altera in-system source editor
reset_jtag the_reset(
	.probe(),
	.source(jtag_reset)
);


module aemb_led_blink #(
 	.CORE_ID(0) ,
	.ram_Dw(32) ,
	.ram_Aw(10) ,
	.led_PORT_WIDTH(1)
)soc
(
	.cpu_sys_ena_i(1'b1),  
	.ss_clk_in(CLOCK_50),  
	.ss_reset_in(reset),  
	.led_port_o(LEDR[0])
);

	
endmodule	
