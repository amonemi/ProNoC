module lcd_test_top (

	output [0:0]LEDR,
	output [0:0]LEDG,
	input  [0:0]KEY,
	input  CLOCK_50,

	//////////// LCD //////////
	output		          		LCD_BLON,
	inout		       [7:0]		LCD_DATA,
	output		          		LCD_EN,
	output		          		LCD_ON,
	output		          		LCD_RS,
	output		          		LCD_RW
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
	
	
	
	

 lcd_test top (
	.aeMB_sys_ena_i(1'b1), 
	.ss_clk_in(CLOCK_50), 
	.ss_reset_in(reset), 
	.lcd_lcd_data(LCD_DATA), 
	.lcd_lcd_en(LCD_EN), 
	.lcd_lcd_rs(LCD_RS), 
	.lcd_lcd_rw(LCD_RW)
);

///////////////////////////////////////////
// LCD config
assign LCD_BLON = 1'b0; // not supported
assign LCD_ON = 1'b1; // alwasy on





endmodule

