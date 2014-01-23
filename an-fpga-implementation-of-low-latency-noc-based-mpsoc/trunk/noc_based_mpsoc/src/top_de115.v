/*********************************************************************
							
	File: top_de115.v 
	
	Copyright (C) 2014  Alireza Monemi

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
	The top module for DE2-115 Altra board. The global parameters for NoC
	are defined in "define.v" file

	Info: monemi@fkegraduate.utm.my

****************************************************************/



`include "define.v"
module top_de115 #(
	parameter X_NODE_NUM					=	`X_NODE_NUM_DEF,
	parameter Y_NODE_NUM					=	`Y_NODE_NUM_DEF,
	parameter TOTAL_ROUTERS_NUM		=	 X_NODE_NUM		* Y_NODE_NUM
)
(


		input 												CLOCK_50,
		input		[0								:	0]		KEY,
		output	[0								:	0]		LEDG,
		output	[TOTAL_ROUTERS_NUM-1		:	0]		LEDR,
		
		// DRAM interface
		output 	[12							:	0]		DRAM_ADDR,
		output	[1								:	0]		DRAM_BA,
		output												DRAM_CAS_N,
		output												DRAM_CKE,
		output												DRAM_CLK,
		output												DRAM_CS_N,
		inout		[31							:	0]		DRAM_DQ,
		output	[3								:	0]		DRAM_DQM,		
		output												DRAM_RAS_N,
		output												DRAM_WE_N
);
	
	


	wire													reset;
	wire													clk;
	wire	[TOTAL_ROUTERS_NUM-1			:0]		led;
	
	
	

	assign 	clk		=	CLOCK_50;
	assign 	LEDR		=	led;
	assign	LEDG[0]	=	reset;
	assign	reset		=	~KEY[0];

 aeMB_mpsoc the_mpsoc
(
	.reset						(reset),
	.clk							(clk),
	.led							(led),
	
	
	.sdram_addr					(DRAM_ADDR),        // sdram_wire.addr
	.sdram_ba					(DRAM_BA),          //           .ba
	.sdram_cas_n				(DRAM_CAS_N),       //           .cas_n
	.sdram_cke					(DRAM_CKE),         //           .cke
	.sdram_cs_n					(DRAM_CS_N),        //           .cs_n
	.sdram_dq					(DRAM_DQ),          //           .dq
	.sdram_dqm					(DRAM_DQM),         //           .dqm
	.sdram_ras_n				(DRAM_RAS_N),       //           .ras_n
	.sdram_we_n					(DRAM_WE_N),        //           .we_n
	.sdram_clk					(DRAM_CLK)		    	//  sdram_clk.clk
	
);

endmodule
