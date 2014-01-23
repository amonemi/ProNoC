/*********************************************************************
							
	File: gpio.v 
	
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
	a simple wishbone compatible output port 

	Info: monemi@fkegraduate.utm.my

****************************************************************/


`include "../define.v"

module output_port #(
	parameter DATA_WIDTH	=	32,
	parameter PORT_WIDTH = 	7,
	parameter PORT_NUM	=	4,
	parameter SEL_WIDTH	=	4,
	parameter ADDR_WIDTH	=	(PORT_NUM==1) ? 2 : log2(PORT_NUM*2),
	parameter OUT_WIDTH	=	PORT_NUM * PORT_WIDTH
)
(
	input 										clk,
	input											reset,
	
	input		[ DATA_WIDTH-1		:	0]		sa_dat_i,
	input		[SEL_WIDTH-1		:	0]		sa_sel_i,
	input		[ADDR_WIDTH-1		:	0]		sa_addr_i,	
	input											sa_stb_i,
	input											sa_we_i,

	output	[ DATA_WIDTH-1		:	0]		sa_dat_o,
	output 										sa_ack_o,
	output 	[OUT_WIDTH-1		:	0]		gpio_out


);
	`LOG2 
	
	reg	[PORT_WIDTH-1		:	0	]	gpio_reg	[PORT_NUM-1		:	0];
	
	assign sa_ack_o	=	 sa_stb_i;
	assign sa_dat_o 	=	{ {(DATA_WIDTH-PORT_WIDTH){1'b0}}, gpio_reg	[sa_addr_i[ADDR_WIDTH-1	:	1]	]	};
	
	
	
	
			
	
	genvar i;
	generate
		for (i=0;	i<PORT_NUM; i=i+1'b1) begin : port_lp
			always @ (posedge clk or posedge reset) begin
				if(reset) begin 
					gpio_reg[i]	<= {PORT_WIDTH{1'b0}};
				end else begin 
					if(sa_stb_i &  sa_we_i & i== sa_addr_i[ADDR_WIDTH-1	:	1]) gpio_reg[i]	<=  sa_dat_i[PORT_WIDTH-1		:	0];
				end
			end
	
		assign gpio_out [(i+1)*PORT_WIDTH-1	:	i*PORT_WIDTH]	= gpio_reg[i];
		end//for
	endgenerate



endmodule
