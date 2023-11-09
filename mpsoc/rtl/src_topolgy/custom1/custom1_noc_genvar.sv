
/**************************************************************************
**	WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
**	OVERWRITTEN AND LOST. Rename this file if you wish to do any modification.
****************************************************************************/


/**********************************************************************
**	File: /home/alireza/work/git/pronoc/mpsoc/rtl/src_topolgy/custom1/custom1_noc_genvar.sv
**    
**	Copyright (C) 2014-2021  Alireza Monemi
**    
**	This file is part of ProNoC 2.1.0 
**
**	ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**	you can redistribute it and/or modify it under the terms of the GNU
**	Lesser General Public License as published by the Free Software Foundation,
**	either version 2 of the License, or (at your option) any later version.
**
** 	ProNoC is distributed in the hope that it will be useful, but WITHOUT
** 	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
** 	or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
** 	Public License for more details.
**
** 	You should have received a copy of the GNU Lesser General Public
** 	License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
******************************************************************************/ 

`include "pronoc_def.v"

module   custom1_noc_genvar    
#(
	parameter NOC_ID=0
)(

    reset,
    clk,    
    chan_in_all,
    chan_out_all,
    router_event  
);

`NOC_CONF
    

	input  reset;
	input  clk;
	input  smartflit_chanel_t chan_in_all  [NE-1 : 0];
	output smartflit_chanel_t chan_out_all [NE-1 : 0];

//Events
	output  router_event_t  router_event [NR-1 : 0][MAX_P-1 : 0];

//all routers port 
	smartflit_chanel_t    router_chan_in   [NR-1 :0][MAX_P-1 : 0];
	smartflit_chanel_t    router_chan_out  [NR-1 :0][MAX_P-1 : 0];


	wire [RAw-1 : 0] current_r_addr [NR-1 : 0];







   

	genvar i;
	generate	
	
	for( i=0; i<4; i=i+1) begin : router_3_port_lp
	localparam RID = i;
	assign current_r_addr [RID] = RID[RAw-1: 0]; 

	router_top #(
		.NOC_ID(NOC_ID),
		.P(3)
	)
	router_3_port
	(	
		.clk(clk), 
		.reset(reset),
		.current_r_id(RID),
		.current_r_addr(current_r_addr[RID]),	
		.chan_in  (router_chan_in [RID] [2 : 0]), 
		.chan_out (router_chan_out[RID] [2 : 0]),
		.router_event(router_event[RID] [2 : 0])	
	);
    
    
    
	end    
			
	for( i=0; i<8; i=i+1) begin : router_4_port_lp
	localparam RID = i+4;
	assign current_r_addr [RID] = RID[RAw-1: 0]; 

	router_top #(
		.NOC_ID(NOC_ID),
		.P(4)
	)
	router_4_port
	(	
		.clk(clk), 
		.reset(reset),
		.current_r_id(RID),
		.current_r_addr(current_r_addr[RID]),	
		.chan_in  (router_chan_in [RID] [3 : 0]), 
		.chan_out (router_chan_out[RID] [3 : 0]),
		.router_event(router_event[RID] [3 : 0])	
	);
    
    
    
	end    
			
	for( i=0; i<4; i=i+1) begin : router_5_port_lp
	localparam RID = i+12;
	assign current_r_addr [RID] = RID[RAw-1: 0]; 

	router_top #(
		.NOC_ID(NOC_ID),
		.P(5)
	)
	router_5_port
	(	
		.clk(clk), 
		.reset(reset),
		.current_r_id(RID),
		.current_r_addr(current_r_addr[RID]),	
		.chan_in  (router_chan_in [RID] [4 : 0]), 
		.chan_out (router_chan_out[RID] [4 : 0]),
		.router_event(router_event[RID] [4 : 0])	
	);
    
    
    
	end    
			endgenerate


//Connect R0 input ports 0 to  T0 output ports 0
		assign  router_chan_in [0][0] = chan_in_all [0];
		assign  chan_out_all [0] = router_chan_out [0][0];
//Connect R0 input ports 1 to  R14 output ports 3
		assign  router_chan_in [0][1] = router_chan_out [10][3];
//Connect R0 input ports 2 to  R13 output ports 3
		assign  router_chan_in [0][2] = router_chan_out [9][3];
//Connect R1 input ports 0 to  T1 output ports 0
		assign  router_chan_in [1][0] = chan_in_all [1];
		assign  chan_out_all [1] = router_chan_out [1][0];
//Connect R1 input ports 1 to  R7 output ports 3
		assign  router_chan_in [1][1] = router_chan_out [7][3];
//Connect R1 input ports 2 to  R2 output ports 2
		assign  router_chan_in [1][2] = router_chan_out [2][2];
//Connect R2 input ports 0 to  T2 output ports 0
		assign  router_chan_in [2][0] = chan_in_all [2];
		assign  chan_out_all [2] = router_chan_out [2][0];
//Connect R2 input ports 1 to  R15 output ports 2
		assign  router_chan_in [2][1] = router_chan_out [11][2];
//Connect R2 input ports 2 to  R1 output ports 2
		assign  router_chan_in [2][2] = router_chan_out [1][2];
//Connect R3 input ports 0 to  T3 output ports 0
		assign  router_chan_in [3][0] = chan_in_all [3];
		assign  chan_out_all [3] = router_chan_out [3][0];
//Connect R3 input ports 1 to  R15 output ports 3
		assign  router_chan_in [3][1] = router_chan_out [11][3];
//Connect R3 input ports 2 to  R4 output ports 2
		assign  router_chan_in [3][2] = router_chan_out [4][2];
//Connect R4 input ports 0 to  T4 output ports 0
		assign  router_chan_in [4][0] = chan_in_all [4];
		assign  chan_out_all [4] = router_chan_out [4][0];
//Connect R4 input ports 1 to  R9 output ports 2
		assign  router_chan_in [4][1] = router_chan_out [13][2];
//Connect R4 input ports 2 to  R3 output ports 2
		assign  router_chan_in [4][2] = router_chan_out [3][2];
//Connect R4 input ports 3 to  R6 output ports 3
		assign  router_chan_in [4][3] = router_chan_out [6][3];
//Connect R5 input ports 0 to  T5 output ports 0
		assign  router_chan_in [5][0] = chan_in_all [5];
		assign  chan_out_all [5] = router_chan_out [5][0];
//Connect R5 input ports 1 to  R11 output ports 4
		assign  router_chan_in [5][1] = router_chan_out [15][4];
//Connect R5 input ports 2 to  R6 output ports 2
		assign  router_chan_in [5][2] = router_chan_out [6][2];
//Connect R5 input ports 3 to  R13 output ports 2
		assign  router_chan_in [5][3] = router_chan_out [9][2];
//Connect R6 input ports 0 to  T6 output ports 0
		assign  router_chan_in [6][0] = chan_in_all [6];
		assign  chan_out_all [6] = router_chan_out [6][0];
//Connect R6 input ports 1 to  R9 output ports 3
		assign  router_chan_in [6][1] = router_chan_out [13][3];
//Connect R6 input ports 2 to  R5 output ports 2
		assign  router_chan_in [6][2] = router_chan_out [5][2];
//Connect R6 input ports 3 to  R4 output ports 3
		assign  router_chan_in [6][3] = router_chan_out [4][3];
//Connect R7 input ports 0 to  T7 output ports 0
		assign  router_chan_in [7][0] = chan_in_all [7];
		assign  chan_out_all [7] = router_chan_out [7][0];
//Connect R7 input ports 1 to  R12 output ports 3
		assign  router_chan_in [7][1] = router_chan_out [8][3];
//Connect R7 input ports 2 to  R14 output ports 2
		assign  router_chan_in [7][2] = router_chan_out [10][2];
//Connect R7 input ports 3 to  R1 output ports 1
		assign  router_chan_in [7][3] = router_chan_out [1][1];
//Connect R12 input ports 0 to  T8 output ports 0
		assign  router_chan_in [8][0] = chan_in_all [8];
		assign  chan_out_all [8] = router_chan_out [8][0];
//Connect R12 input ports 1 to  R8 output ports 4
		assign  router_chan_in [8][1] = router_chan_out [12][4];
//Connect R12 input ports 2 to  R10 output ports 3
		assign  router_chan_in [8][2] = router_chan_out [14][3];
//Connect R12 input ports 3 to  R7 output ports 1
		assign  router_chan_in [8][3] = router_chan_out [7][1];
//Connect R13 input ports 0 to  T9 output ports 0
		assign  router_chan_in [9][0] = chan_in_all [9];
		assign  chan_out_all [9] = router_chan_out [9][0];
//Connect R13 input ports 1 to  R8 output ports 2
		assign  router_chan_in [9][1] = router_chan_out [12][2];
//Connect R13 input ports 2 to  R5 output ports 3
		assign  router_chan_in [9][2] = router_chan_out [5][3];
//Connect R13 input ports 3 to  R0 output ports 2
		assign  router_chan_in [9][3] = router_chan_out [0][2];
//Connect R14 input ports 0 to  T10 output ports 0
		assign  router_chan_in [10][0] = chan_in_all [10];
		assign  chan_out_all [10] = router_chan_out [10][0];
//Connect R14 input ports 1 to  R8 output ports 3
		assign  router_chan_in [10][1] = router_chan_out [12][3];
//Connect R14 input ports 2 to  R7 output ports 2
		assign  router_chan_in [10][2] = router_chan_out [7][2];
//Connect R14 input ports 3 to  R0 output ports 1
		assign  router_chan_in [10][3] = router_chan_out [0][1];
//Connect R15 input ports 0 to  T11 output ports 0
		assign  router_chan_in [11][0] = chan_in_all [11];
		assign  chan_out_all [11] = router_chan_out [11][0];
//Connect R15 input ports 1 to  R10 output ports 4
		assign  router_chan_in [11][1] = router_chan_out [14][4];
//Connect R15 input ports 2 to  R2 output ports 1
		assign  router_chan_in [11][2] = router_chan_out [2][1];
//Connect R15 input ports 3 to  R3 output ports 1
		assign  router_chan_in [11][3] = router_chan_out [3][1];
//Connect R8 input ports 0 to  T12 output ports 0
		assign  router_chan_in [12][0] = chan_in_all [12];
		assign  chan_out_all [12] = router_chan_out [12][0];
//Connect R8 input ports 1 to  R11 output ports 1
		assign  router_chan_in [12][1] = router_chan_out [15][1];
//Connect R8 input ports 2 to  R13 output ports 1
		assign  router_chan_in [12][2] = router_chan_out [9][1];
//Connect R8 input ports 3 to  R14 output ports 1
		assign  router_chan_in [12][3] = router_chan_out [10][1];
//Connect R8 input ports 4 to  R12 output ports 1
		assign  router_chan_in [12][4] = router_chan_out [8][1];
//Connect R9 input ports 0 to  T13 output ports 0
		assign  router_chan_in [13][0] = chan_in_all [13];
		assign  chan_out_all [13] = router_chan_out [13][0];
//Connect R9 input ports 1 to  R11 output ports 3
		assign  router_chan_in [13][1] = router_chan_out [15][3];
//Connect R9 input ports 2 to  R4 output ports 1
		assign  router_chan_in [13][2] = router_chan_out [4][1];
//Connect R9 input ports 3 to  R6 output ports 1
		assign  router_chan_in [13][3] = router_chan_out [6][1];
//Connect R9 input ports 4 to  R10 output ports 2
		assign  router_chan_in [13][4] = router_chan_out [14][2];
//Connect R10 input ports 0 to  T14 output ports 0
		assign  router_chan_in [14][0] = chan_in_all [14];
		assign  chan_out_all [14] = router_chan_out [14][0];
//Connect R10 input ports 1 to  R11 output ports 2
		assign  router_chan_in [14][1] = router_chan_out [15][2];
//Connect R10 input ports 2 to  R9 output ports 4
		assign  router_chan_in [14][2] = router_chan_out [13][4];
//Connect R10 input ports 3 to  R12 output ports 2
		assign  router_chan_in [14][3] = router_chan_out [8][2];
//Connect R10 input ports 4 to  R15 output ports 1
		assign  router_chan_in [14][4] = router_chan_out [11][1];
//Connect R11 input ports 0 to  T15 output ports 0
		assign  router_chan_in [15][0] = chan_in_all [15];
		assign  chan_out_all [15] = router_chan_out [15][0];
//Connect R11 input ports 1 to  R8 output ports 1
		assign  router_chan_in [15][1] = router_chan_out [12][1];
//Connect R11 input ports 2 to  R10 output ports 1
		assign  router_chan_in [15][2] = router_chan_out [14][1];
//Connect R11 input ports 3 to  R9 output ports 1
		assign  router_chan_in [15][3] = router_chan_out [13][1];
//Connect R11 input ports 4 to  R5 output ports 1
		assign  router_chan_in [15][4] = router_chan_out [5][1];
  

  
             
endmodule
