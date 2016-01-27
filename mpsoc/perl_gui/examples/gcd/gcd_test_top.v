module gcd_test_top (
	output [6:0]HEX0,HEX1,HEX2,HEX3,
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

// soc 	
//wire [31:0] segnemts;
//assign {HEX3,HEX2,HEX1,HEX0}=segnemts;

gcd_test uut(
	.aeMB_sys_ena_i(1'b1), 
	.ss_clk_in(CLOCK_50),  
	.ss_reset_in(reset),
	.display_port_o({HEX3,HEX2,HEX1,HEX0})
);

	
endmodule	
