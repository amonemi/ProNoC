module  emulator_top (
	output [0:0]LEDR,
	output [1:0]LEDG,
	input  [0:0]KEY,
	input  CLOCK_50
); 
	
		
	

	//NoC parameters will be defined by user
	`define NOC_PARAM
	`include "noc_parameters.v"
 	
	


	wire clk, reset, reset_noc, reset_injector, reset_noc_sync, reset_injector_sync, done;
	wire jtag_reset_injector, jtag_reset_noc;
	
	assign clk 	= CLOCK_50;
	assign reset	= ~KEY[0];
	assign LEDR[0]	= done;
	assign LEDG[0]	= reset_noc;
	assign LEDG[1]	= reset_injector;

	
	
	
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
			
		
		
