
/**********************************************************************
**	File:  timer.v
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
**	A simple, general purpose, Wishbone bus-based, 32-bit timer
**	
**
*******************************************************************/ 


`timescale 1ns / 1ps

module timer #(
		parameter PRESCALER_WIDTH		=	8, // Prescaler counter width.
		parameter Dw  =	32,   // wishbone bus data width
		parameter Aw  = 3,     // wishbone bus address width
		parameter SELw=	4,    // wishbone bus sel width
		parameter TAGw=3,
		parameter CNTw=32     // timer width


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
  
	
	//intruupt interface
	irq
);

    function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
   endfunction // log2 
   

    input                       clk;
    input                       reset;
    
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
    
  
    assign  sa_err_o=1'b0;
    assign  sa_rty_o=1'b0;
    //intruupt interface
    output                      irq;



    localparam TCSR_ADDR	=	0;	//timer control register
    localparam TLR_ADDR		=	1;	//timer load register
    localparam TCMR_ADDR	=	2;// timer compare value register
    
    
   
    localparam	DEV_CTRL_WIDTH	=	log2(PRESCALER_WIDTH);
    
    localparam TCSR_REG_WIDTH	=	4+DEV_CTRL_WIDTH;
    localparam TCR_REG_WIDTH	=	TCSR_REG_WIDTH-1;
/***************************
tcr: timer control register
bit 

PRESCALER_WIDTH+3: 4:	prescaler_ctrl
3	:	timer_isr
2	:	rst_on_cmp_value
1	:	int_enble_on_cmp_value
0	:	timer enable 




***************************/
    reg 	[TCSR_REG_WIDTH-1		:	0]	tcsr;
    wire	[TCSR_REG_WIDTH-1		:	0]	tcsr_next;	//timer control register 
    reg	[TCR_REG_WIDTH-1		:	0]	tcr_next;
    reg	timer_isr_next;
    
    reg 	[PRESCALER_WIDTH-1	:	0]	prescaler_counter,prescaler_counter_next;
    
    wire 	[PRESCALER_WIDTH-1	:	0]	dev_one_hot;
    wire	[PRESCALER_WIDTH-2	:	0]	dev_cmp_val;
    
    wire timer_en,int_en,rst_on_cmp,timer_isr;
    wire prescaler_rst,counter_rst;
    wire [DEV_CTRL_WIDTH-1	:	0] prescaler_ctrl;
    
    
    
    reg [CNTw-1		:	0]	counter,counter_next,cmp,cmp_next,read,read_next;



    assign {timer_isr,prescaler_ctrl,rst_on_cmp,int_en,timer_en} = tcsr;
    assign dev_cmp_val	=	dev_one_hot[PRESCALER_WIDTH-1	:	1];
    assign prescaler_rst	=	prescaler_counter [PRESCALER_WIDTH-2 :   0]	==	dev_cmp_val;
    assign counter_rst	=	(rst_on_cmp)? (counter		==	cmp) : 1'b0;
    assign sa_dat_o		=	read;
    assign irq = timer_isr;
    assign tcsr_next		={timer_isr_next,tcr_next};


    bin_to_one_hot #(
	   .BIN_WIDTH		(DEV_CTRL_WIDTH),
	   .ONE_HOT_WIDTH	(PRESCALER_WIDTH)
	)
	conv
	(
	   .bin_code		(prescaler_ctrl),
	   .one_hot_code	(dev_one_hot)
	);

	always @(posedge clk or posedge reset) begin 
		if(reset) begin 
			counter				<= {CNTw{1'b0}};
			cmp					<=	{CNTw{1'b1}};
			prescaler_counter	<=	{PRESCALER_WIDTH{1'b0}};
			tcsr					<=	{TCSR_REG_WIDTH{1'b0}};
			read					<=	{CNTw{1'b0}};
			sa_ack_o				<=	1'b0;
		end else begin 
			counter				<= counter_next;
			cmp					<=	cmp_next;
			prescaler_counter	<=	prescaler_counter_next;
			tcsr					<=	tcsr_next;
			read					<= read_next;
			sa_ack_o				<= sa_stb_i && ~sa_ack_o;
		end
	end
	
	always@(*)begin 
		counter_next			= counter;
		prescaler_counter_next	= prescaler_counter;
		timer_isr_next			=(timer_isr | (counter_rst & prescaler_rst) ) &  int_en;
		tcr_next					= tcsr[TCR_REG_WIDTH-1		:	0];
		cmp_next					= cmp;
		read_next				=	read;
		//counters
		if(timer_en)begin 
				if(prescaler_rst)	begin 
					prescaler_counter_next	=	{PRESCALER_WIDTH{1'b0}};
					if(counter_rst) begin 
						counter_next	=	{CNTw{1'b0}};
					end else begin 
						counter_next	=	counter +1'b1;
					end // count_rst
				end else begin
						prescaler_counter_next	=	prescaler_counter	+1'b1;
				end //dev_rst
		end//time_en
		
		if(sa_stb_i )begin
			if(sa_we_i ) begin 
				case(sa_addr_i)
					TCSR_ADDR:	begin 
						tcr_next 		= 	sa_dat_i[TCR_REG_WIDTH-1	:	0];
						timer_isr_next	=	timer_isr & ~sa_dat_i[TCSR_REG_WIDTH-1];// reset isr by writting 1
					end
					TLR_ADDR:	counter_next	= 	sa_dat_i[CNTw-1	:	0];
					TCMR_ADDR:	cmp_next			=	sa_dat_i[CNTw-1	:	0];	
					default:			cmp_next			= 	cmp;
				endcase
			end//we
			else begin
				case(sa_addr_i)
					TCSR_ADDR:	read_next		=	{{(Dw-TCSR_REG_WIDTH){1'b0}},tcsr};
					TLR_ADDR:	read_next		=	counter;
					TCMR_ADDR:	read_next		=	cmp;
					default:			read_next		=	read;
				endcase
			end
		end//stb
	end//always



endmodule
