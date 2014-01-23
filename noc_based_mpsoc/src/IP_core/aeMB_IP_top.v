module aeMB_IP_top (
	input 												CLOCK_50,
	input		[1								:	0]		KEY,
	output	[1								:	0]		LEDG,
	output	[6								:	0]		HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7


);


	
	parameter SEVEN_SEG_NUM		=	8;

	wire	[(SEVEN_SEG_NUM	*7)-1		:0] seven_segment;
	
	wire													reset,reset_in,sys_en,sys_en_n;
	wire													clk;
	
	
	assign	sys_en	= ~ sys_en_n;

	assign 	clk		=	CLOCK_50;
	assign	LEDG[0]	=	reset;
	assign	{HEX7,HEX6,HEX5,HEX4,HEX3,HEX2,HEX1,HEX0} = seven_segment;
	
	assign	reset_in		=	~KEY[0];

	
	
	signal_holder #(
		.DELAY_COUNT(1000)
	)
	hold_reset
	(
		.reset_in	(reset_in),
		.clk			(clk),
		.reset_out	(reset)
	);
	
	signal_holder #(
		.DELAY_COUNT(100)
	)
	hold_en
	(
		.reset_in	(reset),
		.clk			(clk),
		.reset_out	(sys_en_n)
	);
	
	
	aeMB_IP IP (
	.clk (clk),
	.reset_in(reset),
	.sys_int_i(1'b0),
	.sys_ena_i(sys_en),
	.gpio(seven_segment)
);

	

	
	
	



endmodule
