module  emulator_top
(

//////// CLOCK //////////
	OSC_50_BANK2,
	OSC_50_BANK3,
	OSC_50_BANK4,
	OSC_50_BANK5,
	OSC_50_BANK6,
	OSC_50_BANK7,
	
	//////// CPU RESET //////////
	CPU_RESET_n,
	
	
	//////// LED x 8 //////////
	LED,

	//////// BUTTON x 4 //////////
	BUTTON,
	
	//////// SWITCH x 8 //////////
	SW,

	//////// SLIDE SWITCH x 4 //////////
	SLIDE_SW


);



	//////////// CLOCK //////////
	input						OSC_50_BANK2;
	input						OSC_50_BANK3;
	input						OSC_50_BANK4;
	input						OSC_50_BANK5;
	input						OSC_50_BANK6;
	input						OSC_50_BANK7;


	//////// CPU RESET //////////
	input		          	CPU_RESET_n;



	//////////// LED x 8 //////////
	output		  [7:0]		LED;

	//////////// BUTTON x 4 //////////
	input		     [3:0]		BUTTON;

	//////////// SWITCH x 8 //////////
	input		     [7:0]		SW;

	//////////// SLIDE SWITCH x 4 //////////
	input		     [3:0]		SLIDE_SW;



	

	
		
	

	//NoC parameters will be defined by user
	`define NOC_PARAM
	`include "noc_parameters.v"
 	
	

	wire clk, reset, reset_noc, reset_injector, reset_noc_sync, reset_injector_sync, done;
	wire jtag_reset_injector, jtag_reset_noc;
	
		

	assign  clk		= 	OSC_50_BANK2;
	assign	reset 		=	~CPU_RESET_n;	
	assign  LED[0]		=	~done;
 	assign  LED[1]		= 	~reset_noc;
	assign  LED[2]		= 	~reset_injector;
 	assign  LED[7:3]	= 	5'b11111;


	
	
	reg[31:0]time_cnt;

	//  two reset sources which can be controled using jtag. One for reseting NoC another packet injectors
	jtag_source_probe #(
		.VJTAG_INDEX(127),
	 	.Dw(2)	//source/probe width in bits
 	)the_reset(
		.probe({1'b0,done}),
		.source({jtag_reset_injector,jtag_reset_noc})
	);


	assign  reset_noc		=	(jtag_reset_noc | reset);
	assign  reset_injector		=	(jtag_reset_injector | reset);	

	altera_reset_synchronizer noc_rst_sync
	(
		.reset_in(reset_noc), 
		.clk(clk),
		.reset_out(reset_noc_sync)
	);


	altera_reset_synchronizer inject_rst_sync
	(
		.reset_in(reset_injector), 
		.clk(clk),
		.reset_out(reset_injector_sync)
	);
	
	
	
	noc_emulator #(
	`include "pass_parameters.v"
		 
	)
	noc_emulate_top
	(
		.reset(reset_noc_sync),
		.jtag_ctrl_reset(reset_injector_sync),
		.clk(clk),
		.done(done)
	);
	
	
	jtag_source_probe #(
		.VJTAG_INDEX(126),
	 	.Dw(32)	//source/probe width in bits
		
    
    	) 
	src_pb
    	(
		.probe(time_cnt),
		.source()
     	);
	
	
	always @(posedge clk or posedge reset)begin
		if(reset) begin
			time_cnt<=0;
		end else begin
			 if(!done) time_cnt<=time_cnt+1;			
		end	
	end
	



endmodule
			
		
		
