/**********************************************************************
	File: mpsoc.v 
	
	Copyright (C) 2013  Alireza Monemi

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	
	Purpose:
	 Generating a mesh based multiprocessor system on (MPSOC) based on
	 aeMB processor. The code tested on the Altera DE2-115 
	 educational. U can connect the external SDRAM to one of the NoC
	 routers by enablaing it as input parameter. 
	 
	Info: monemi@fkegraduate.utm.my
********************************************************************/	
	
	
	
/*	
	
	
	// the routers address in mesh topology
	CORE_NUM
	(x,y)
	
	0						  	1									X_NODE_NUM-1
	(0		,	0)			 	(1		,		0)	....			(X_NODE_NUM-1,		0)
	
	X_NODE_NUM		  		X_NODE_NUM+1					2*X_NODE_NUM-1
	(0		,	1)				(1		,		1)	....			(X_NODE_NUM-1,		1)
		.
		.
	(Y_NODE_NUM-1)*X_NODE_NUM								Y_NODE_NUM*X_NODE_NUM-1
	(0,Y_NODE_NUM)			(1,Y_NODE_NUM)	.....			(X_NODE_NUM-1,Y_NODE_NUM-1)


//routers port interconnection  


in[CORE_NUM][port_num]


in	[x,y][1] <------	 	out [x+1		,y	 ][3]	;
in	[x,y][2] <------		out [x		,y-1][4] ;
in	[x,y][3] <------		out [x-1		,y	 ][1]	;
in	[x,y][4] <------		out [x		,y+1][2]	;
	
port num
local = 0
east  = 1
north = 2
west  = 3
south = 4


****************************/

`include "../define.v"



module aeMB_mpsoc #(
	parameter NI_CTRL_SIMULATION		=	"aeMB", 
	/*"aeMB" or "testbench". 
		Definig it as " aeMB" will generate the same MPSoC for both simulation and 
		implementation.
		Defining it as "testbench" will remove the processors 
		in simulation. Hence, the simulation time will be decreased. The tasks to control
		NI pins are written in tasks.V file */
		
	parameter VC_NUM_PER_PORT 			=	`VC_NUM_PER_PORT_DEF ,
	parameter PYLD_WIDTH 				=	`PYLD_WIDTH_DEF,
	parameter BUFFER_NUM_PER_VC		=	`BUFFER_NUM_PER_VC_DEF,
	
	parameter X_NODE_NUM					=	`X_NODE_NUM_DEF,
	parameter Y_NODE_NUM					=	`Y_NODE_NUM_DEF,
	parameter AEMB_RAM_WIDTH_IN_WORD	=	`AEMB_RAM_WIDTH_IN_WORD_DEF,
	parameter NOC_S_ADDR_WIDTH			=	`NOC_S_ADDR_WIDTH_DEF,
	parameter SW_OUTPUT_REGISTERED	=	0,// 1: registered , 0 not registered
		
	parameter SDRAM_EN					=	`SDRAM_EN_DEF,//  0 : disabled  1: enabled 
	parameter SDRAM_SW_X_ADDR			=	`SDRAM_SW_X_ADDR_DEF,
	parameter SDRAM_SW_Y_ADDR			=	`SDRAM_SW_Y_ADDR_DEF,
	parameter SDRAM_NI_CONNECT_PORT	=	`SDRAM_NI_CONNECT_PORT_DEF, 
	parameter SDRAM_ADDR_WIDTH			=	`SDRAM_ADDR_WIDTH_DEF,
	parameter CAND_VC_SEL_MODE			=	0,
	
	//aeMB parameter
	parameter RAM_EN						=	1,					
	parameter NOC_EN						=	1,
	parameter GPIO_EN						=	1,
	parameter GPIO_PORT_WIDTH			=	1,
	parameter GPIO_PORT_NUM				=	1,
	parameter AEMB_IWB 					= 32, ///< INST bus width
   parameter AEMB_DWB 					= 32, ///< DATA bus width
	
	//parameter JTAG_INTERFACE_EN		=	1, // if disabled the jtag can just send packet but can not recieve any packet
	//parameter JTAG_SW_X_ADDR			=	0,
	//parameter JTAG_SW_Y_ADDR			=	0,
	//parameter JTAG_ni_CONNECT_PORT	=	0,
	
	parameter PORT_NUM					=	5,
	parameter FLIT_TYPE_WIDTH			=	2,
	parameter PORT_SEL_WIDTH			=	PORT_NUM-1,//assum that no port whants to send a packet to itself!
	parameter VC_ID_WIDTH				=	VC_NUM_PER_PORT,
	parameter FLIT_WIDTH					=	PYLD_WIDTH+ FLIT_TYPE_WIDTH+VC_ID_WIDTH,
	parameter FLIT_ARRAY_WIDTH			=	FLIT_WIDTH		*	PORT_NUM,
	parameter CREDIT_ARRAY_WIDTH		=	VC_NUM_PER_PORT	*	PORT_NUM,
	parameter TOTAL_ROUTERS_NUM		=	X_NODE_NUM		* Y_NODE_NUM,
	
	parameter CPU_ADR_WIDTH 			=	AEMB_DWB-2,
	parameter CPU_ADDR_ARRAY_WIDTH 	=	CPU_ADR_WIDTH * TOTAL_ROUTERS_NUM,
	parameter CPU_DATA_ARRAY_WIDTH	=	32 * TOTAL_ROUTERS_NUM
	//parameter RAM_ARRAY_ADDR_WIDTH	=	M_ADDR_SIZE*TOTAL_ROUTERS_NUM
	
)(
		
	input														reset,
	input 													clk,
	output	[TOTAL_ROUTERS_NUM-1			:0]		led,
	
	output  [12									:0] 		sdram_addr,        // sdram_wire.addr
	output  [1									:0]  		sdram_ba,          //           .ba
	output         										sdram_cas_n,       //           .cas_n
	output         										sdram_cke,         //           .cke
	output         										sdram_cs_n,        //           .cs_n
	inout   [31									:0]		sdram_dq,          //           .dq
	output  [3									:0] 		sdram_dqm,         //           .dqm
	output         										sdram_ras_n,       //           .ras_n
	output         										sdram_we_n,        //           .we_n
	output         										sdram_clk		    //  sdram_clk.clk
	
		
	//synthesis translate_off 
	//In case we want to handle NI interface using testbench not aeMB 
	,
	
	input 	[CPU_ADDR_ARRAY_WIDTH-1		:0] 	cpu_adr_i_array,
   input		[TOTAL_ROUTERS_NUM-1			:0]	cpu_cyc_i,		
   input 	[CPU_DATA_ARRAY_WIDTH-1		:0] 	cpu_dat_i_array,		
   input 	[TOTAL_ROUTERS_NUM*4-1		:0] 	cpu_sel_i_array,		
   input		[TOTAL_ROUTERS_NUM-1			:0]	cpu_stb_i,		
   input		[TOTAL_ROUTERS_NUM-1			:0]	cpu_wre_i,	
	
	output	[TOTAL_ROUTERS_NUM-1			:0]	cpu_ack_o,		
   output 	[CPU_DATA_ARRAY_WIDTH-1		:0]	cpu_dat_o_array		
	
	
		
	//synthesis translate_on
			
	
		
	);
	
	


			
wire [FLIT_ARRAY_WIDTH-1		:	0] router_flit_in_array 	[TOTAL_ROUTERS_NUM-1			:0];
wire [PORT_NUM-1					:	0] router_wr_in_en_array	[TOTAL_ROUTERS_NUM-1			:0];	
wire [CREDIT_ARRAY_WIDTH-1		:	0] router_credit_out_array	[TOTAL_ROUTERS_NUM-1			:0];
wire [PORT_NUM-1					:	0]	router_wr_out_en_array	[TOTAL_ROUTERS_NUM-1			:0];
wire [FLIT_ARRAY_WIDTH-1		:	0] router_flit_out_array 	[TOTAL_ROUTERS_NUM-1			:0];
wire [CREDIT_ARRAY_WIDTH-1		:	0]	router_credit_in_array	[TOTAL_ROUTERS_NUM-1			:0];


wire [FLIT_WIDTH-1				:	0]	ni_flit_out					[TOTAL_ROUTERS_NUM-1			:0];   
wire [TOTAL_ROUTERS_NUM-1		:	0]	ni_flit_out_wr; 
wire [VC_NUM_PER_PORT-1			:	0]	ni_credit_in 				[TOTAL_ROUTERS_NUM-1			:0];
wire [FLIT_WIDTH-1				:	0]	ni_flit_in 					[TOTAL_ROUTERS_NUM-1			:0];   
wire [TOTAL_ROUTERS_NUM-1		:	0]	ni_flit_in_wr;  
wire [VC_NUM_PER_PORT-1			:	0]	ni_credit_out 				[TOTAL_ROUTERS_NUM-1			:0];					


//synthesis translate_off 
//In case we want to handle NI interface using testbench not aeMB 
	
	wire 	[AEMB_DWB-1						:2] 		cpu_adr_i		[TOTAL_ROUTERS_NUM-1			:0];	
   wire	[31								:0] 		cpu_dat_i		[TOTAL_ROUTERS_NUM-1			:0];			
   wire 	[3									:0] 		cpu_sel_i		[TOTAL_ROUTERS_NUM-1			:0];			
	wire 	[31								:0]		cpu_dat_o		[TOTAL_ROUTERS_NUM-1			:0];			
 
 //synthesis translate_on



  
 
genvar x,y;
generate 

	for	(x=0;	x<X_NODE_NUM; x=x+1) begin :x_loop
		for	(y=0;	y<Y_NODE_NUM;	y=y+1) begin: y_loop
		
	if( SDRAM_EN	==	1 && x == SDRAM_SW_X_ADDR	&& y ==  SDRAM_SW_Y_ADDR) begin : sdram_gen
		
			sdram_core #(
				.VC_NUM_PER_PORT			(VC_NUM_PER_PORT),
				.PYLD_WIDTH 				(PYLD_WIDTH),
				.BUFFER_NUM_PER_VC		(BUFFER_NUM_PER_VC),
				.FLIT_TYPE_WIDTH			(FLIT_TYPE_WIDTH),
				.PORT_NUM					(PORT_NUM),
				.X_NODE_NUM					(X_NODE_NUM),
				.Y_NODE_NUM					(Y_NODE_NUM),
				.SW_X_ADDR					(SDRAM_SW_X_ADDR),
				.SW_Y_ADDR					(SDRAM_SW_Y_ADDR),
				.NIC_CONNECT_PORT			(SDRAM_NI_CONNECT_PORT),
				.SDRAM_ADDR_WIDTH			(SDRAM_ADDR_WIDTH),
				.CAND_VC_SEL_MODE			(CAND_VC_SEL_MODE)
			)
			the_sdram
			(
				.reset						(reset) ,	
				.clk							(clk) ,
				
				// NOC interfaces
				.flit_out					(ni_flit_out				[`CORE_NUM(x,y)]),	
				.flit_out_wr				(ni_flit_out_wr			[`CORE_NUM(x,y)]),	
				.credit_in					(ni_credit_in				[`CORE_NUM(x,y)]), 
				
				.flit_in						(ni_flit_in				[`CORE_NUM(x,y)]),	
				.flit_in_wr					(ni_flit_in_wr			[`CORE_NUM(x,y)]),	
				.credit_out					(ni_credit_out			[`CORE_NUM(x,y)]) ,
				
				.sdram_addr					(sdram_addr) ,	
				.sdram_ba					(sdram_ba) ,	
				.sdram_cas_n				(sdram_cas_n) ,	
				.sdram_cke					(sdram_cke) ,	
				.sdram_cs_n					(sdram_cs_n) ,	
				.sdram_dq					(sdram_dq) ,	
				.sdram_dqm					(sdram_dqm) ,	
				.sdram_ras_n				(sdram_ras_n) ,	
				.sdram_we_n					(sdram_we_n) ,	
				.sdram_clk					(sdram_clk) 	
			);
	
	end else begin : aeMB_core_gen 


		aeMB_IP #(
				.RAM_EN						(RAM_EN),					
				.NOC_EN						(NOC_EN),
				.GPIO_EN						(GPIO_EN),
				.GPIO_PORT_WIDTH			(GPIO_PORT_WIDTH),
				.GPIO_PORT_NUM				(GPIO_PORT_NUM),
				.AEMB_IWB  					(AEMB_IWB), ///< INST bus width
				.AEMB_DWB 					(AEMB_DWB), ///< DATA bus width
				.NI_CTRL_SIMULATION		(NI_CTRL_SIMULATION),
				.NOC_S_ADDR_WIDTH			(NOC_S_ADDR_WIDTH),
				.VC_NUM_PER_PORT			(VC_NUM_PER_PORT),
				.PYLD_WIDTH 				(PYLD_WIDTH),
				.BUFFER_NUM_PER_VC		(BUFFER_NUM_PER_VC),
				.FLIT_TYPE_WIDTH			(FLIT_TYPE_WIDTH),
				.PORT_NUM					(PORT_NUM),
				.X_NODE_NUM					(X_NODE_NUM),
				.Y_NODE_NUM					(Y_NODE_NUM),
				.SW_X_ADDR					(x),
				.SW_Y_ADDR					(y),
				.NIC_CONNECT_PORT			(0),		// 0:Local  1:East, 2:North, 3:West, 4:South 
				.AEMB_RAM_WIDTH_IN_WORD	(AEMB_RAM_WIDTH_IN_WORD),
				.CORE_NUMBER				(`CORE_NUM(x,y))
			)
			ip_core
			(
				.reset_in					(reset) ,	
				.clk							(clk) ,
				.sys_int_i					(1'b0),
				.sys_ena_i					(1'b1),
				.gpio							(led							[`CORE_NUM(x,y)]),
	
				// NOC interfaces
	
				.flit_out					(ni_flit_out				[`CORE_NUM(x,y)]),	
				.flit_out_wr				(ni_flit_out_wr			[`CORE_NUM(x,y)]),	
				.credit_in					(ni_credit_in				[`CORE_NUM(x,y)]), 
				
				.flit_in						(ni_flit_in					[`CORE_NUM(x,y)]),	
				.flit_in_wr					(ni_flit_in_wr				[`CORE_NUM(x,y)]),	
				.credit_out					(ni_credit_out				[`CORE_NUM(x,y)]) 
				//synthesis translate_off
				,
				.cpu_dat_i					(cpu_dat_i			 		[`CORE_NUM(x,y)]),	
				.cpu_sel_i					(cpu_sel_i					[`CORE_NUM(x,y)]),
				.cpu_adr_i					(cpu_adr_i					[`CORE_NUM(x,y)]),	
				.cpu_stb_i					(cpu_stb_i					[`CORE_NUM(x,y)]),	
				.cpu_wre_i					(cpu_wre_i					[`CORE_NUM(x,y)]),
				.cpu_cyc_i					(cpu_cyc_i					[`CORE_NUM(x,y)]),
				.cpu_dat_o					(cpu_dat_o					[`CORE_NUM(x,y)]),	
				.cpu_ack_o					(cpu_ack_o					[`CORE_NUM(x,y)])
				
				//synthesis translate_on
			
			
				
			
			); 
		end
	
		router#(
				.VC_NUM_PER_PORT			(VC_NUM_PER_PORT),
				.BUFFER_NUM_PER_VC		(BUFFER_NUM_PER_VC),
				.PORT_NUM					(PORT_NUM),
				.PYLD_WIDTH 				(PYLD_WIDTH),
				.FLIT_TYPE_WIDTH			(FLIT_TYPE_WIDTH),
				.X_NODE_NUM					(X_NODE_NUM),
				.Y_NODE_NUM					(Y_NODE_NUM	),
				.SW_X_ADDR					(x),
				.SW_Y_ADDR					(y),
				.SW_OUTPUT_REGISTERED	(SW_OUTPUT_REGISTERED)
				
		
		)
		the_router
		(
			.wr_in_en_array				(router_wr_in_en_array		[`CORE_NUM(x,y)]),
			.flit_in_array					(router_flit_in_array		[`CORE_NUM(x,y)]),
			.credit_out_array				(router_credit_out_array	[`CORE_NUM(x,y)]),
			.wr_out_en_array				(router_wr_out_en_array		[`CORE_NUM(x,y)]),
			.flit_out_array				(router_flit_out_array		[`CORE_NUM(x,y)]),
			.credit_in_array				(router_credit_in_array		[`CORE_NUM(x,y)]),
			.clk								(clk),
			.reset							(reset)
		);

//routers pin assignment

		
//in	[x,y][1] = 	out [x+1		,y	 ][3]	;
//in	[x,y][2] =	out [x		,y-1][4] ;
//in	[x,y][3] =	out [x-1		,y	 ][1]	;
//in	[x,y][4] =	out [x		,y+1][2]	;

	
	//connection to the naibour nodes	
	if(x	<	X_NODE_NUM-1) begin
		assign	router_flit_in_array 	[`SELECT_WIRE(x,y,1,FLIT_WIDTH)] 		= router_flit_out_array 	[`SELECT_WIRE((x+1),y,3,FLIT_WIDTH)];
		assign	router_credit_in_array	[`SELECT_WIRE(x,y,1,VC_NUM_PER_PORT)]	= router_credit_out_array	[`SELECT_WIRE((x+1),y,3,VC_NUM_PER_PORT)];
		assign	router_wr_in_en_array	[`CORE_NUM(x,y)][1]							= router_wr_out_en_array	[`CORE_NUM((x+1),y)][3];
	end else begin
		assign	router_flit_in_array 	[`SELECT_WIRE(x,y,1,FLIT_WIDTH)] 		=	{FLIT_WIDTH{1'b0}};
		assign	router_credit_in_array	[`SELECT_WIRE(x,y,1,VC_NUM_PER_PORT)]	=	{VC_NUM_PER_PORT{1'b0}};
		assign	router_wr_in_en_array	[`CORE_NUM(x,y)][1]							=	1'b0;
	end 
		
	
	if(y>0) begin
		assign	router_flit_in_array 	[`SELECT_WIRE(x,y,2,FLIT_WIDTH)]			=	router_flit_out_array 	[`SELECT_WIRE(x,(y-1),4,FLIT_WIDTH)];
		assign	router_credit_in_array	[`SELECT_WIRE(x,y,2,VC_NUM_PER_PORT)]	=  router_credit_out_array	[`SELECT_WIRE(x,(y-1),4,VC_NUM_PER_PORT)];
		assign	router_wr_in_en_array	[`CORE_NUM(x,y)][2]							=	router_wr_out_en_array	[`CORE_NUM(x,(y-1))][4];
	end else begin 
		assign 	router_flit_in_array 	[`SELECT_WIRE(x,y,2,FLIT_WIDTH)]			=	{FLIT_WIDTH{1'b0}};
		assign	router_credit_in_array	[`SELECT_WIRE(x,y,2,VC_NUM_PER_PORT)]	=	{VC_NUM_PER_PORT{1'b0}};
		assign	router_wr_in_en_array	[`CORE_NUM(x,y)][2]							=	1'b0;
	end
	
	
	if(x>0)begin
		assign	router_flit_in_array 	[`SELECT_WIRE(x,y,3,FLIT_WIDTH)]			=	router_flit_out_array 	[`SELECT_WIRE((x-1),y,1,FLIT_WIDTH)] ;
		assign	router_credit_in_array	[`SELECT_WIRE(x,y,3,VC_NUM_PER_PORT)]	=  router_credit_out_array	[`SELECT_WIRE((x-1),y,1,VC_NUM_PER_PORT)] ;
		assign	router_wr_in_en_array	[`CORE_NUM(x,y)][3]							=	router_wr_out_en_array	[`CORE_NUM((x-1),y)][1];
	
	end else begin
			assign	router_flit_in_array 	[`SELECT_WIRE(x,y,3,FLIT_WIDTH)]			=  {FLIT_WIDTH{1'b0}};
			assign	router_credit_in_array	[`SELECT_WIRE(x,y,3,VC_NUM_PER_PORT)]	=	{VC_NUM_PER_PORT{1'b0}};
			assign	router_wr_in_en_array	[`CORE_NUM(x,y)][3]							=	1'b0;
		end	
	
	if(y	<	Y_NODE_NUM-1)begin
		assign	router_flit_in_array 	[`SELECT_WIRE(x,y,4,FLIT_WIDTH)]			=	router_flit_out_array 	[`SELECT_WIRE(x,(y+1),2,FLIT_WIDTH)];
		assign	router_credit_in_array	[`SELECT_WIRE(x,y,4,VC_NUM_PER_PORT)]	= 	router_credit_out_array	[`SELECT_WIRE(x,(y+1),2,VC_NUM_PER_PORT)];
		assign	router_wr_in_en_array	[`CORE_NUM(x,y)][4]							=	router_wr_out_en_array	[`CORE_NUM(x,(y+1))][2];
	end else 	begin
		assign	router_flit_in_array 	[`SELECT_WIRE(x,y,4,FLIT_WIDTH)]			=  {FLIT_WIDTH{1'b0}};
		assign	router_credit_in_array	[`SELECT_WIRE(x,y,4,VC_NUM_PER_PORT)]	=	{VC_NUM_PER_PORT{1'b0}};
		assign	router_wr_in_en_array	[`CORE_NUM(x,y)][4]							=	1'b0;
	end	
	
	//connection to the ip_core
	assign		router_flit_in_array 	[`SELECT_WIRE(x,y,0,FLIT_WIDTH)]			=	ni_flit_out		[`CORE_NUM(x,y)];
	assign		router_credit_in_array	[`SELECT_WIRE(x,y,0,VC_NUM_PER_PORT)]	=	ni_credit_out		[`CORE_NUM(x,y)];
	assign		router_wr_in_en_array	[`CORE_NUM(x,y)][0]							=	ni_flit_out_wr	[`CORE_NUM(x,y)];
		
	
	assign		ni_flit_in				[`CORE_NUM(x,y)] = router_flit_out_array 	[`SELECT_WIRE(x,y,0,FLIT_WIDTH)];
	assign		ni_flit_in_wr 			[`CORE_NUM(x,y)] = router_wr_out_en_array	[`CORE_NUM(x,y)][0];
	assign		ni_credit_in			[`CORE_NUM(x,y)] = router_credit_out_array[`SELECT_WIRE(x,y,0,VC_NUM_PER_PORT)];
	
		


//synthesis translate_off
	
	assign cpu_adr_i	 			[`CORE_NUM(x,y)]		=	cpu_adr_i_array 	[(`CORE_NUM(x,y)+1)*(CPU_ADR_WIDTH)-1			: `CORE_NUM(x,y)*CPU_ADR_WIDTH];
	assign cpu_dat_i				[`CORE_NUM(x,y)]		=  cpu_dat_i_array 	[(`CORE_NUM(x,y)+1)*32-1			: `CORE_NUM(x,y)*32	];
	assign cpu_sel_i				[`CORE_NUM(x,y)]		=	cpu_sel_i_array [(`CORE_NUM(x,y)+1)*4-1			: `CORE_NUM(x,y)*4	];
	assign cpu_dat_o_array	[(`CORE_NUM(x,y)+1)*32-1	: `CORE_NUM(x,y)*32] = cpu_dat_o	[`CORE_NUM(x,y)];
	
//synthesis	translate_on	
	
		
	

	end //y
	end //x
endgenerate


	



endmodule
