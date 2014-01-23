`include "define.v"
module sram_core #(
	parameter VC_NUM_PER_PORT 		=	2,
	parameter PYLD_WIDTH 			=	32,
	parameter BUFFER_NUM_PER_VC	=	16,
	parameter FLIT_TYPE_WIDTH		=	2,
	parameter PORT_NUM				=	5,
	parameter X_NODE_NUM				=	4,
	parameter Y_NODE_NUM				=	3,
	parameter SW_X_ADDR				=	2,
	parameter SW_Y_ADDR				=	1,
	parameter NIC_CONNECT_PORT		=	0, // 0:Local  1:East, 2:North, 3:West, 4:South 
	parameter RAM_ADDR_WIDTH		=	20,
	parameter CAND_VC_SEL_MODE		=	0,
	parameter VC_ID_WIDTH			=	VC_NUM_PER_PORT,
	parameter FLIT_WIDTH				=	PYLD_WIDTH+FLIT_TYPE_WIDTH+VC_ID_WIDTH,
	parameter CORE_NUMBER			=	`CORE_NUM(SW_X_ADDR,SW_Y_ADDR)
	)
	(
		input					 							clk,                
		input  				 							reset,   
				
		// NOC interfaces
		output	[FLIT_WIDTH-1				:0] 	flit_out,     
		output 			  			   				flit_out_wr,   
		input 	[VC_NUM_PER_PORT-1		:0]	credit_in,
	
		input		[FLIT_WIDTH-1				:0] 	flit_in,     
		input 	    			   					flit_in_wr,   
		output 	[VC_NUM_PER_PORT-1		:0]	credit_out,
		
		
		output  [12:0] sdram_addr,        // sdram_wire.addr
		output  [1:0]  sdram_ba,          //           .ba
		output         sdram_cas_n,       //           .cas_n
		output         sdram_cke,         //           .cke
		output         sdram_cs_n,        //           .cs_n
		inout   [31:0] sdram_dq,          //           .dq
		output  [3:0]  sdram_dqm,         //           .dqm
		output         sdram_ras_n,       //           .ras_n
		output         sdram_we_n,        //           .we_n
		output         sdram_clk		    //  sdram_clk.clk
	);

	
	
	

// sdram controller interface
		wire [RAM_ADDR_WIDTH-1			:	0] 	sdram_s_address;       
		wire [3								:	0]		sdram_s_byteenable_n;  
		wire												sdram_s_chipselect;
		wire [31								:	0]		sdram_s_writedata;
		wire  											sdram_s_read_n;
		wire												sdram_s_write_n;
		wire	[31							:	0]		sdram_s_readdata;
		wire												sdram_s_readdatavalid;
		wire	 											sdram_s_waitrequest;

		assign sdram_s_waitrequest = 1'b0;
		assign sram_s_byteenable_n = 4'd0;
		
sram sram_inst
(
	.clk_clk						(clk) ,	// input  clk_clk
	.reset_reset_n				(~reset) ,	// input  reset_reset_n
	.sram0_s_address			(sram_s_address) ,	// input [19:0] sram0_s_address
	.sram0_s_byteenable		(~sram_s_byteenable_n[1:0]) ,	// input [1:0] sram0_s_byteenable
	.sram0_s_read				(~sram_s_read_n) ,	// input  sram0_s_read
	.sram0_s_write				(~sram_s_write_n) ,	// input  sram0_s_write
	.sram0_s_writedata		(sram_s_writedata [15:0]) ,	// input [15:0] sram0_s_writedata
	.sram0_s_readdata			(sram_s_readdata[15:0]) ,	// output [15:0] sram0_s_readdata
	.sram0_s_readdatavalid	(sram_s_readdatavalid) ,	// output  sram0_s_readdatavalid
	.sram0_wire_DQ				(sram0_wire_DQ) ,	// inout [15:0] sram0_wire_DQ
	.sram0_wire_ADDR			(sram0_wire_ADDR) ,	// output [19:0] sram0_wire_ADDR
	.sram0_wire_LB_N			(sram0_wire_LB_N) ,	// output  sram0_wire_LB_N
	.sram0_wire_UB_N			(sram0_wire_UB_N) ,	// output  sram0_wire_UB_N
	.sram0_wire_CE_N			(sram0_wire_CE_N) ,	// output  sram0_wire_CE_N
	.sram0_wire_OE_N			(sram0_wire_OE_N) ,	// output  sram0_wire_OE_N
	.sram0_wire_WE_N			(sram0_wire_WE_N) ,	// output  sram0_wire_WE_N
	.sram1_wire_DQ				(sram1_wire_DQ) ,	// inout [15:0] sram1_wire_DQ
	.sram1_wire_ADDR			(sram1_wire_ADDR) ,	// output [19:0] sram1_wire_ADDR
	.sram1_wire_LB_N			(sram1_wire_LB_N) ,	// output  sram1_wire_LB_N
	.sram1_wire_UB_N			(sram1_wire_UB_N) ,	// output  sram1_wire_UB_N
	.sram1_wire_CE_N			(sram1_wire_CE_N) ,	// output  sram1_wire_CE_N
	.sram1_wire_OE_N			(sram1_wire_OE_N) ,	// output  sram1_wire_OE_N
	.sram1_wire_WE_N			(sram1_wire_WE_N) ,	// output  sram1_wire_WE_N
	.sram1_s_address			(sram_s_address) ,	// input [19:0] sram_1_s_address
	.sram1_s_byteenable		(~sram_s_byteenable_n[2:1]) ,	// input [1:0] sram_1_s_byteenable
	.sram1_s_read				(~sram_s_read_n) ,	// input  sram_1_s_read
	.sram1_s_write				(~sram_s_write_n) ,	// input  sram_1_s_write
	.sram1_s_writedata		(sram_s_writedata [31: 16]) ,	// input [15:0] sram_1_s_writedata
	.sram1_s_readdata			(sram_s_readdata [31: 16]) ,	// output [15:0] sram_1_s_readdata
	.sram1_s_readdatavalid	() 	// output  sram_1_s_readdatavalid
);




ext_ram_nic #(
	
	.VC_NUM_PER_PORT 		(VC_NUM_PER_PORT ),
	.PYLD_WIDTH 			(PYLD_WIDTH),
	.BUFFER_NUM_PER_VC	(BUFFER_NUM_PER_VC),
	.FLIT_TYPE_WIDTH		(FLIT_TYPE_WIDTH),
	.PORT_NUM				(PORT_NUM),
	.X_NODE_NUM				(X_NODE_NUM	),
	.Y_NODE_NUM				(Y_NODE_NUM	),
	.SW_X_ADDR				(SW_X_ADDR),
	.SW_Y_ADDR				(SW_Y_ADDR),
	.NIC_CONNECT_PORT		(NIC_CONNECT_PORT	), // 0:Local  1:East, 2:North, 3:West, 4:South 
	.SDRAM_ADDR_WIDTH		(SDRAM_ADDR_WIDTH),
	.CAND_VC_SEL_MODE		(CAND_VC_SEL_MODE)
	
	)
	the_sdram_nic
	(
		.clk							(clk),                
		.reset						(reset),   
				
		// NOC interfaces
		.flit_out					(flit_out),     
		.flit_out_wr				(flit_out_wr),   
		.credit_in					(credit_in),
	
		.flit_in						(flit_in),     
		.flit_in_wr					(flit_in_wr),   
		.credit_out					(credit_out),
		
		// sdram controller interface
		.ram_address				(sram_s_address),       
		.ram_byteenable_n			(sram_s_byteenable_n),  
		.ram_chipselect			(sram_s_chipselect),
		.ram_writedata				(sram_s_writedata),
		.ram_read_n					(sram_s_read_n),
		.ram_write_n				(sram_s_write_n),
		.ram_readdata				(sram_s_readdata),
		.ram_readdatavalid		(sram_s_readdatavalid),
		.ram_waitrequest			(sram_s_waitrequest)
		
	);


endmodule
