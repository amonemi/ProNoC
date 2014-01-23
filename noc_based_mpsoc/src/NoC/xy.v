/**********************************************************************
	File: xy.v 
	
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

	The XY routing computaion module. it is used just by 	NI. The routers
	use the look-ahead routing 
	
	Info: monemi@fkegraduate.utm.my


********************************************************************/


`include "../define.v"

module xy #(
	parameter PORT_NUM					=	5,
	parameter X_NODE_NUM					=	4,
	parameter Y_NODE_NUM					=	3,
	parameter SW_X_ADDR					=	2,
	parameter SW_Y_ADDR					=	1,
	parameter SENDER_PORT				=	0, // 0:Local  1:East, 2:North, 3:West, 4:South 
	parameter X_NODE_NUM_WIDTH			=	log2(X_NODE_NUM),
	parameter Y_NODE_NUM_WIDTH			=	log2(Y_NODE_NUM),
	parameter PORT_NUM_BCD_WIDTH		=	log2(PORT_NUM),
	parameter PORT_SEL_WIDTH			=	PORT_NUM-1//assum that no port whants to send a packet to itself!
	
	)
	(
	input 	[X_NODE_NUM_WIDTH-1		:0]	dest_x_node_in,
	input		[Y_NODE_NUM_WIDTH-1		:0]	dest_y_node_in,
	output	[PORT_NUM_BCD_WIDTH-1	:0]	port_num_out// one extra bit will be removed by switch_in latter
	);
	
	`LOG2
	
	/*
	localparam LOCAL	=		5'b00001;
	localparam EAST	=		5'b00010;	
	localparam NORTH	=		5'b00100;
	localparam WEST	=		5'b01000;
	localparam SOUTH	=		5'b10000;
	*/
	
	localparam LOCAL	=		3'd0;  
	localparam EAST	=		3'd1; 
	localparam NORTH	=		3'd2;  
	localparam WEST	=		3'd3;  
	localparam SOUTH	=		3'd4;  
	
	
	reg [PORT_NUM_BCD_WIDTH-1			:0]	port_num_next;
	
	
	wire signed [X_NODE_NUM_WIDTH		:0] xc;//current 
	wire signed [X_NODE_NUM_WIDTH		:0] xd;//destination
	wire signed [Y_NODE_NUM_WIDTH		:0] yc;//current 
	wire signed [Y_NODE_NUM_WIDTH		:0] yd;//destination
	wire signed [X_NODE_NUM_WIDTH		:0] xdiff;
	wire signed [Y_NODE_NUM_WIDTH		:0] ydiff; 
	
	
	assign 	xc 	={1'b0, SW_X_ADDR [X_NODE_NUM_WIDTH-1		:0]};
	assign 	yc 	={1'b0, SW_Y_ADDR [Y_NODE_NUM_WIDTH-1		:0]};
	assign	xd		={1'b0, dest_x_node_in};
	assign	yd 	={1'b0, dest_y_node_in};
	assign 	xdiff	= xd-xc;
	assign	ydiff	= yd-yc;
	
	/*
	genvar i;
	generate 
		for(i=0;	i<PORT_NUM; i=i+1'b1 ) begin : loop
			if			(i< SENDER_PORT)		assign	port_sel_out[i		]= port_num_next[i];
			else if	(i> SENDER_PORT)		assign	port_sel_out[i-1	]= port_num_next[i];
		end
	endgenerate
	*/
	
	assign	port_num_out= port_num_next;
	
	always@(*)begin
			port_num_next	= LOCAL;
			if				(xdiff	> 0)		port_num_next	= EAST;
			else if		(xdiff	< 0)		port_num_next	= WEST;
			else begin
				if			(ydiff	> 0)		port_num_next	= SOUTH;
				else if 	(ydiff	< 0)		port_num_next	= NORTH;
			end
	end
	

endmodule
