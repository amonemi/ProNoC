module intrrupt_test_top (
	output [6:0]HEX0,
	output [6:0]HEX1,
	output [0:0]LEDG,
	input  [2:0]KEY,
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

// soc 	
intrrupt_test #(
	.ram_RAM_TAG_STRING("00") 
	
)uut
(
	
	.ss_clk_in(CLOCK_50), 
	.ss_reset_in(reset), 
	.aeMB_sys_ena_i(1'b1), 
	.ext_int_ext_int_i(~KEY[2:1]), 
	.seg0_port_o(HEX0), 
	.seg1_port_o(HEX1)
);
	
endmodule	
