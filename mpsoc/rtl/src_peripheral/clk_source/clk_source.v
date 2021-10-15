// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


module clk_source #(
	parameter FPGA_VENDOR = "ALTERA" // "ALTERA" , "XILINX"
	)(
	input   reset_in,
	input   clk_in,
	output  reset_out,
	output	clk_out

);

	generate 
	if(  FPGA_VENDOR == "ALTERA" ) begin :altera 
		
		altera_reset_synchronizer sync(
			.reset_in	(reset_in), 
			.clk		(clk_in),
	    		.reset_out	(reset_out)
		);

	end else if(  FPGA_VENDOR == "XILINX" ) begin :xilinx 	
		
		xilinx_reset_synchroniser sync(
			.clk		(clk_in),
			.aresetin	(reset_in),
			.sync_reset	(reset_out)
		);


	end
	endgenerate


	assign clk_out=clk_in;


endmodule




