
/**********************************************************************
**	File:  ext_int.v
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
**	Wishbone bus based external intrrupt module
**
*******************************************************************/


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module ext_int #(
	parameter EXT_INT_NUM	=	3,//max 32
	parameter Aw		=	3,
	parameter SELw		=	4,
	parameter TAGw      =   3,
	parameter Dw		=	32

)(
    clk,
    reset,
    
    //wishbone bus interface
	sa_dat_i,
    sa_sel_i,
    sa_addr_i,  
    sa_tag_i,
    sa_stb_i,
    sa_cyc_i,
    sa_we_i,    
    sa_dat_o,
    sa_ack_o,
    sa_err_o,
    sa_rty_o,
    
    //interrupt ports
    ext_int_i,  
    ext_int_o 
);

    input                               clk;
    input                               reset;
    
    //wishbone bus interface
    input       [Dw-1       :   0]      sa_dat_i;
    input       [SELw-1     :   0]      sa_sel_i;
    input       [Aw-1       :   0]      sa_addr_i;  
    input       [TAGw-1     :   0]      sa_tag_i;
    input                               sa_stb_i;
    input                               sa_cyc_i;
    input                               sa_we_i;
    
    output      [Dw-1       :   0]      sa_dat_o;
    output  reg                         sa_ack_o;
    output                              sa_err_o;
    output                              sa_rty_o;
    
 
    //interrupt ports
    input   [EXT_INT_NUM-1      :   0]  ext_int_i;  
    output                              ext_int_o; //output to the interrupt controller
    



//interrupt registers							
	
	localparam	[Aw-1		:	0]		GER_REG_ADDR			=	0;
	localparam	[Aw-1		:	0]		IER_RISING_REG_ADDR	=	1;
	localparam	[Aw-1		:	0]		IER_FALLING_REG_ADDR	=	2;
	localparam	[Aw-1		:	0]		ISR_REG_ADDR			=	3;
	localparam	[Aw-1		:	0]		PIN_REG_ADDR			=	4;
	
		
	reg										ger,ger_next;
	reg	[EXT_INT_NUM-1			:	0]	ier_rise,ier_fall,isr,read,int_reg1,int_reg2;//2	
	reg	[EXT_INT_NUM-1			:	0]	ier_rise_next,ier_fall_next,isr_next,read_next,int_reg1_next,int_reg2_next;
	
	wire 	[EXT_INT_NUM-1			:	0]	triggered,rise_edge,fall_edge;
	
 
   	assign  sa_err_o=1'b0;
   	assign  sa_rty_o=1'b0;
	assign rise_edge = (ger)? 	ier_rise & ~int_reg2	& int_reg1	:	{EXT_INT_NUM{1'b0}};
	assign fall_edge = (ger)?	ier_fall & int_reg2 	& ~int_reg1	: 	{EXT_INT_NUM{1'b0}};
	
	assign	triggered	=	rise_edge |  fall_edge;
	
	always @ (posedge clk or posedge reset) begin
		if(reset) begin 
			ger		<=	1'b0;
			ier_rise	<= {EXT_INT_NUM{1'b0}};
			ier_fall	<= {EXT_INT_NUM{1'b0}};
			isr		<=	{EXT_INT_NUM{1'b0}};
			read		<=	{EXT_INT_NUM{1'b0}};	
			int_reg1	<=	{EXT_INT_NUM{1'b0}};
			int_reg2	<=	{EXT_INT_NUM{1'b0}};	
			sa_ack_o	<=	1'b0;
			
		end else begin 
			ger		<=	ger_next;
			ier_rise	<= ier_rise_next;
			ier_fall	<=	ier_fall_next;
			isr		<=	isr_next;
			read		<=	read_next;	
			int_reg1	<=	int_reg1_next;
			int_reg2	<=	int_reg2_next;	
			sa_ack_o	<=	 sa_stb_i && ~sa_ack_o;	
		end//			
	end//always
	
	always@(*) begin 
		int_reg2_next 	= int_reg1;
		int_reg1_next 	= ext_int_i;
		ger_next			= ger;
		ier_rise_next	= ier_rise;
		ier_fall_next	= ier_fall;
		isr_next			= isr | triggered; // set isr if the intrrupt is triggered 
		read_next		= read;
		if(sa_stb_i && sa_we_i ) begin 
			if( sa_addr_i 	==	GER_REG_ADDR			)		ger_next			= 	sa_dat_i[0];
			if( sa_addr_i 	== IER_RISING_REG_ADDR 	)		ier_rise_next	=	sa_dat_i[EXT_INT_NUM-1'b1		:	0];
			if( sa_addr_i 	== IER_FALLING_REG_ADDR	)		ier_fall_next	=	sa_dat_i[EXT_INT_NUM-1'b1		:	0];
			if( sa_addr_i 	== ISR_REG_ADDR  			) 		isr_next			=	isr & ~sa_dat_i[EXT_INT_NUM-1'b1		:	0];// reset isr by writting 1
		end
		if(sa_stb_i && ~sa_we_i) begin 
			case(sa_addr_i) 
				GER_REG_ADDR:				read_next	=	{{(EXT_INT_NUM-1){1'b0}},ger};
				IER_RISING_REG_ADDR:		read_next	=	ier_rise;
				IER_FALLING_REG_ADDR:	read_next	=	ier_fall;
				ISR_REG_ADDR:				read_next	=	isr;
				PIN_REG_ADDR:				read_next	=	ext_int_i;
				default						read_next	=	read; 
			endcase
		end
	end//always
				
			
	generate 
		if(EXT_INT_NUM!=Dw)begin
			assign sa_dat_o ={{(Dw-EXT_INT_NUM){1'b0}}, read};
		end else begin
			assign sa_dat_o = read;
		end
	endgenerate

	assign ext_int_o = |isr;
		
	
endmodule
