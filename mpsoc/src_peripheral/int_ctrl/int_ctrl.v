/**********************************************************************
**	File:  int_ctrl.v 
**	
**    
**	Copyright (C) 2014-2017  Alireza Monemi
**    
**	This file is part of ProNoC 
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
**
**
**	Description: 
**	Intrrupt control module. It is used for CPUs with only one input 
**	intrrupt pin to support multiple intrrupt signals 	
**
**
*******************************************************************/














// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


module int_ctrl #(
	
	parameter INT_NUM		= 3, // number of intrupt  max 32,
	parameter Dw  =    32,   // wishbone bus data width
    parameter Aw  = 3,     // wishbone bus address width
    parameter SELw= 4    // wishbone bus sel width
)
(
    clk,
    reset,
	
	// wishbone interface
    sa_dat_i,
    sa_sel_i,
    sa_addr_i,	
    sa_stb_i,
    sa_we_i,
    sa_dat_o,
    sa_ack_o,
    sa_err_o,
    sa_rty_o,
  

	//intruupt interface
    int_i,
    int_o
	
);
	
	
	
	input                       clk,reset;
	
    // wishbone interface
    input   [Dw-1       :   0]  sa_dat_i;
    input   [SELw-1     :   0]  sa_sel_i;
    input   [Aw-1       :   0]  sa_addr_i;  
    input                       sa_stb_i;
    input                       sa_we_i;
    output  [Dw-1       :   0]  sa_dat_o;
    output  reg                 sa_ack_o;
    //intruupt interface
    input   [INT_NUM-1  :   0]  int_i;
    output                      int_o;
	
     output  sa_err_o, sa_rty_o;
   assign  sa_err_o=1'b0;
   assign  sa_rty_o=1'b0;
	
	
	
	localparam 	[Aw-1		:	0]		MER_REG_ADDR	=	0;
	localparam	[Aw-1		:	0]		IER_REG_ADDR	=	1;
	localparam	[Aw-1		:	0]		IAR_REG_ADDR	=	2;
	localparam	[Aw-1		:	0]		IPR_REG_ADDR	=	3;
	
	localparam  LD_ZERO   		= (INT_NUM >2 )? INT_NUM-2 : 0; 
	//localparam  DATA_BUS_MASK	= (EXT_INT_EN <<2)	 + (TIMER_EN << 1)+ NOC_EN ;
//internal register 	
	reg [INT_NUM-1	:	0]	ipr,ier,iar;
	reg [INT_NUM-1	:	0]	ipr_next,ier_next,iar_next;
	reg [INT_NUM-1	:	0] read,read_next;
	reg [1:0]				mer,mer_next;
	
	wire [INT_NUM-1:0]  sa_dat_i_masked, int_i_masked;
	
	assign sa_dat_i_masked = sa_dat_i;// & 	DATA_BUS_MASK [INT_NUM-1:0];
	assign int_i_masked    = int_i 	 ;//& 	DATA_BUS_MASK [INT_NUM-1:0];
	always@(*) begin 
		mer_next			= mer;
		ier_next			= ier;
		iar_next			= iar	& ~ int_i_masked;
		ipr_next			= (ipr	| int_i_masked) & ier;
		
		read_next		=	read;
		if(sa_stb_i )
			if(sa_we_i ) begin 
				case(sa_addr_i)
					MER_REG_ADDR:	mer_next	=	sa_dat_i[1:0];	
					IER_REG_ADDR:	ier_next	=	sa_dat_i_masked[INT_NUM-1	:	0];
					IAR_REG_ADDR:	begin 
										iar_next	=	iar | sa_dat_i_masked[INT_NUM-1		:	0];//set iar by writting 1
										ipr_next	= ipr &	~sa_dat_i_masked[INT_NUM-1		:	0];//reset ipr by writting 1
					end
					default:		ipr_next			= ipr	| int_i_masked;
				endcase
			end//we
			else begin
				case(sa_addr_i)
					MER_REG_ADDR:	read_next		=	{{LD_ZERO{1'b0}},mer};
					IER_REG_ADDR:	read_next		=	ier;
					IAR_REG_ADDR:	read_next		=	iar;
					IPR_REG_ADDR:	read_next		=	ipr;
					default:			read_next		=	read;
				endcase
			end
		end//stb
		
		always @(posedge clk) begin
		if(reset)begin 
			mer		<= 2'b0;
			ier		<= {INT_NUM{1'b0}};
			iar		<= {INT_NUM{1'b0}};
			ipr		<= {INT_NUM{1'b0}};
			read		<=	{INT_NUM{1'b0}};
			sa_ack_o	<=	1'b0;
		end else begin 
			mer		<= mer_next;
			ier		<= ier_next;
			iar		<= iar_next;
			ipr		<= ipr_next;
			read		<= read_next;
			sa_ack_o	<= sa_stb_i && ~sa_ack_o;
		end
	end
	
		assign int_o	= ((mer == 2'b11)	&& ((ier & ipr)>0)	) ? 1'b1	:1'b0;
		assign sa_dat_o = {{(Dw-INT_NUM){1'b0}},read};
	
	
	
	
	
	
	
	endmodule
	
