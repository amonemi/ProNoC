`timescale 1ns/1ps
`include "../define.v"

module look_ahead_routing_sync #(
	parameter TOPOLOGY					=	"TORUS", // "MESH" or "TORUS"  
	parameter ROUTE_ALGRMT				=	"XY",		//"XY" or "MINIMAL"
	parameter PORT_NUM					=	5,
	parameter X_NODE_NUM					=	4,
	parameter Y_NODE_NUM					=	3,
	parameter SW_X_ADDR					=	2,
	parameter SW_Y_ADDR					=	1,
	parameter PORT_NUM_BCD_WIDTH		=	log2(PORT_NUM),
	parameter X_NODE_NUM_WIDTH			=	log2(X_NODE_NUM),
	parameter Y_NODE_NUM_WIDTH			=	log2(Y_NODE_NUM)
	
	)
	(
	input [X_NODE_NUM_WIDTH-1		:0]	dest_x_node_in,
	input [Y_NODE_NUM_WIDTH-1		:0]	dest_y_node_in,
	output[PORT_NUM_BCD_WIDTH-1	:0]	port_num_out,// one extra bit will be removed by switch_in latter
	input 										clk,
	input											reset

	);
	`LOG2
	
	reg [X_NODE_NUM_WIDTH-1			:0]	dest_x_node;
	reg [Y_NODE_NUM_WIDTH-1			:0]	dest_y_node;
	
	
	// routing algorithm
	route_compute  #(
	   .ROUTE_TYPE			("LOOK_AHEAD"),
		.TOPOLOGY			(TOPOLOGY), 
		.ROUTE_ALGRMT		(ROUTE_ALGRMT),
		.PORT_NUM			(PORT_NUM),
		.X_NODE_NUM			(X_NODE_NUM),
		.Y_NODE_NUM			(Y_NODE_NUM),
		.SW_X_ADDR			(SW_X_ADDR),
		.SW_Y_ADDR			(SW_Y_ADDR)
	
	)
	routing
	(
		.dest_x_node_in	(dest_x_node), 
		.dest_y_node_in	(dest_y_node), 
		.port_num_out		(port_num_out)
	);
	
	
	

	always @(posedge clk or posedge reset)begin
		if(reset)begin
			dest_x_node	<= {X_NODE_NUM_WIDTH{1'b0}};
			dest_y_node	<= {Y_NODE_NUM_WIDTH{1'b0}};
		
		end else begin
			dest_x_node	<= dest_x_node_in;
			dest_y_node	<= dest_y_node_in;
		
		end//else reset
	end//always
endmodule

/******************************************************

					route_compute

******************************************************/



module route_compute #(
	parameter ROUTE_TYPE					=	"NORMAL", // "NORMAL" or "LOOK_AHEAD"
	parameter TOPOLOGY					=	"TORUS", // "MESH" or "TORUS"  
	parameter ROUTE_ALGRMT				=	"MINIMAL",//"XY" or "MINIMAL"
	parameter PORT_NUM					=	5,
	parameter X_NODE_NUM					=	4,
	parameter Y_NODE_NUM					=	4,
	parameter SW_X_ADDR					=	2,
	parameter SW_Y_ADDR					=	1,
	parameter PORT_NUM_BCD_WIDTH		=	log2(PORT_NUM),
	parameter X_NODE_NUM_WIDTH			=	log2(X_NODE_NUM),
	parameter Y_NODE_NUM_WIDTH			=	log2(Y_NODE_NUM)
	
	)
	(
	input 	[X_NODE_NUM_WIDTH-1		:0]	dest_x_node_in,
	input		[Y_NODE_NUM_WIDTH-1		:0]	dest_y_node_in,
	output	[PORT_NUM_BCD_WIDTH-1	:0]	port_num_out// one extra bit will be removed by cross bar switch later
	);
	`LOG2
	// just to get rid of Warning (10230):  truncated value with size 32 to match size of target (2)
	localparam [X_NODE_NUM_WIDTH-1	:	0] CURRENT_X_ADDR =SW_X_ADDR [X_NODE_NUM_WIDTH-1	:	0];
	localparam [Y_NODE_NUM_WIDTH-1	:	0] CURRENT_Y_ADDR =SW_Y_ADDR [Y_NODE_NUM_WIDTH-1	:	0];
	
	generate
		if(ROUTE_TYPE == "NORMAL") begin :normal
		
			normal_routing #(
				.TOPOLOGY					(TOPOLOGY),	
				.ROUTE_ALGRMT				(ROUTE_ALGRMT),
				.PORT_NUM					(PORT_NUM),
				.X_NODE_NUM					(X_NODE_NUM),
				.Y_NODE_NUM					(Y_NODE_NUM),
				.SW_X_ADDR					(SW_X_ADDR),
				.SW_Y_ADDR					(SW_Y_ADDR)
			) normal_routing
			(
			.current_router_x_addr			(CURRENT_X_ADDR),
			.current_router_y_addr			(CURRENT_Y_ADDR),
			.dest_x_node_in					(dest_x_node_in),
			.dest_y_node_in					(dest_y_node_in),
			.port_num_out						(port_num_out)// one extra bit will be removed by switch_in latter
			);
		
		
		end else if(ROUTE_TYPE == "LOOK_AHEAD") begin :look_ahead
		
			look_ahead_routing #(
				.TOPOLOGY					(TOPOLOGY),	
				.ROUTE_ALGRMT				(ROUTE_ALGRMT),
				.PORT_NUM					(PORT_NUM),
				.X_NODE_NUM					(X_NODE_NUM),
				.Y_NODE_NUM					(Y_NODE_NUM),
				.SW_X_ADDR					(SW_X_ADDR),
				.SW_Y_ADDR					(SW_Y_ADDR)
			) normal_routing
			(
			.dest_x_node_in					(dest_x_node_in),
			.dest_y_node_in					(dest_y_node_in),
			.port_num_out						(port_num_out)// one extra bit will be removed by switch_in latter
			);
			end
	endgenerate

endmodule 




/***************************************************
					normal routing 
	
***************************************************/
module normal_routing #(
	parameter TOPOLOGY					=	"TORUS", // "MESH" or "TORUS"  
	parameter ROUTE_ALGRMT					=	"MINIMAL",//"XY" or "MINIMAL"
	parameter PORT_NUM					=	5,
	parameter X_NODE_NUM					=	4,
	parameter Y_NODE_NUM					=	4,
	parameter SW_X_ADDR					=	2,
	parameter SW_Y_ADDR					=	1,
	parameter PORT_NUM_BCD_WIDTH		=	log2(PORT_NUM),
	parameter X_NODE_NUM_WIDTH			=	log2(X_NODE_NUM),
	parameter Y_NODE_NUM_WIDTH			=	log2(Y_NODE_NUM)
	
	)
	(
	input 	[X_NODE_NUM_WIDTH-1		:0]	current_router_x_addr,
	input		[Y_NODE_NUM_WIDTH-1		:0]	current_router_y_addr,
	input 	[X_NODE_NUM_WIDTH-1		:0]	dest_x_node_in,
	input		[Y_NODE_NUM_WIDTH-1		:0]	dest_y_node_in,
	output	[PORT_NUM_BCD_WIDTH-1	:0]	port_num_out// one extra bit will be removed by cross bar switch later
	);
	
	`LOG2

	generate 
		if(ROUTE_ALGRMT	==	"XY") begin : xy_routing_blk
			xy_routing #(
				.TOPOLOGY	(TOPOLOGY),	
				.PORT_NUM	(PORT_NUM),
				.X_NODE_NUM	(X_NODE_NUM),
				.Y_NODE_NUM	(Y_NODE_NUM)
			) xy
			(
			.current_router_x_addr			(current_router_x_addr),
			.current_router_y_addr			(current_router_y_addr),
			.dest_x_node_in					(dest_x_node_in),
			.dest_y_node_in					(dest_y_node_in),
			.port_num_out						(port_num_out)// one extra bit will be removed by switch_in latter
			);
		end else if(ROUTE_ALGRMT	==	"MINIMAL") begin : minimal_routing_blk
			minimal_routing #(
				.TOPOLOGY	(TOPOLOGY),
				.PORT_NUM	(PORT_NUM),
				.X_NODE_NUM	(X_NODE_NUM),
				.Y_NODE_NUM	(Y_NODE_NUM)
			) minimal
			(
			.current_router_x_addr			(current_router_x_addr),
			.current_router_y_addr			(current_router_y_addr),
			.dest_x_node_in					(dest_x_node_in),
			.dest_y_node_in					(dest_y_node_in),
			.port_num_out						(port_num_out)// one extra bit will be removed by switch_in latter
			);
	
	
	
		end
	endgenerate

endmodule




/***************************************************
					look-ahead routing 
	call the normal routing  twice in cascade mode
***************************************************/


module look_ahead_routing #(
	parameter TOPOLOGY					=	"TORUS", // "MESH" or "TORUS"  
	parameter ROUTE_ALGRMT				=	"MINIMAL",//"XY" or "MINIMAL"
	parameter PORT_NUM					=	5,
	parameter X_NODE_NUM					=	4,
	parameter Y_NODE_NUM					=	4,
	parameter SW_X_ADDR					=	2,
	parameter SW_Y_ADDR					=	1,
	parameter PORT_NUM_BCD_WIDTH		=	log2(PORT_NUM),
	parameter X_NODE_NUM_WIDTH			=	log2(X_NODE_NUM),
	parameter Y_NODE_NUM_WIDTH			=	log2(Y_NODE_NUM)
	
	)
	(
	input 	[X_NODE_NUM_WIDTH-1		:0]	dest_x_node_in,
	input		[Y_NODE_NUM_WIDTH-1		:0]	dest_y_node_in,
	output	[PORT_NUM_BCD_WIDTH-1	:0]	port_num_out// one extra bit will be removed by cross bar switch later
	);

	`LOG2
	wire 	[PORT_NUM_BCD_WIDTH-1	:0] port_num_out_first;
	reg 	[X_NODE_NUM_WIDTH-1		:0] next_router_x_addr;
	reg 	[Y_NODE_NUM_WIDTH-1		:0] next_router_y_addr;
	
	localparam LOCAL	=		3'd0;  
	localparam EAST	=		3'd1; 
	localparam NORTH	=		3'd2;  
	localparam WEST	=		3'd3;  
	localparam SOUTH	=		3'd4; 
	
	// just to get rid of Warning (10230): Verilog HDL assignment warning at look_ahead.v(71): truncated value with size 32 to match size of target (2)
	localparam [X_NODE_NUM_WIDTH-1	:	0] CURRENT_X_ADDR =SW_X_ADDR [X_NODE_NUM_WIDTH-1	:	0];
	localparam [Y_NODE_NUM_WIDTH-1	:	0] CURRENT_Y_ADDR =SW_Y_ADDR [Y_NODE_NUM_WIDTH-1	:	0];
	localparam [X_NODE_NUM_WIDTH-1	:	0] LAST_X_ADDR 	=X_NODE_NUM[X_NODE_NUM_WIDTH-1	:	0]-1'b1;
	localparam [Y_NODE_NUM_WIDTH-1	:	0] LAST_Y_ADDR 	=Y_NODE_NUM[Y_NODE_NUM_WIDTH-1	:	0]-1'b1;
	
	
	
	normal_routing #(
		.TOPOLOGY	(TOPOLOGY),
		.ROUTE_ALGRMT	(ROUTE_ALGRMT),
		.PORT_NUM	(PORT_NUM),
		.X_NODE_NUM	(X_NODE_NUM),
		.Y_NODE_NUM	(Y_NODE_NUM)
	)first_level
	(
		.current_router_x_addr			(CURRENT_X_ADDR),
		.current_router_y_addr			(CURRENT_Y_ADDR),
		.dest_x_node_in					(dest_x_node_in),
		.dest_y_node_in					(dest_y_node_in),
		.port_num_out						(port_num_out_first)// one extra bit will be removed by switch_in latter
	);
	
	
	
	normal_routing #(
		.TOPOLOGY	(TOPOLOGY),	
		.ROUTE_ALGRMT	(ROUTE_ALGRMT),
		.PORT_NUM	(PORT_NUM),
		.X_NODE_NUM	(X_NODE_NUM),
		.Y_NODE_NUM	(Y_NODE_NUM)	
	)second_level
	(
		.current_router_x_addr	(next_router_x_addr),
		.current_router_y_addr	(next_router_y_addr),
		.dest_x_node_in			(dest_x_node_in),
		.dest_y_node_in			(dest_y_node_in),
		.port_num_out				(port_num_out)// one extra bit will be removed by switch_in latter
	);
		
	
		always @(*) begin
			case(port_num_out_first) 
			
				EAST:	begin	
					next_router_x_addr= (SW_X_ADDR==LAST_X_ADDR ) ? {X_NODE_NUM_WIDTH{1'b0}} : CURRENT_X_ADDR+1'b1;
					next_router_y_addr=  CURRENT_Y_ADDR;	
				end
				NORTH:	begin	
					next_router_x_addr= CURRENT_X_ADDR;
					next_router_y_addr= (SW_Y_ADDR==0)? LAST_Y_ADDR  : CURRENT_Y_ADDR-1'b1;
				end
				WEST:		begin 
					next_router_x_addr= (SW_X_ADDR==0) ? LAST_X_ADDR  : CURRENT_X_ADDR-1'b1;
					next_router_y_addr=  CURRENT_Y_ADDR;
				end
				SOUTH:	begin
					next_router_x_addr= CURRENT_X_ADDR;
					next_router_y_addr= (SW_Y_ADDR== LAST_Y_ADDR ) ? {Y_NODE_NUM_WIDTH{1'b0}}: CURRENT_Y_ADDR+1'b1;
				end
				default begin 
					next_router_x_addr= {X_NODE_NUM_WIDTH{1'bX}};
					next_router_y_addr= {Y_NODE_NUM_WIDTH{1'bX}};
				end
			endcase
		end//always
endmodule


/*****************************************************

				xy_mesh_routing

*****************************************************/


module xy_mesh_routing #(
	parameter PORT_NUM					=	5,
	parameter X_NODE_NUM					=	4,
	parameter Y_NODE_NUM					=	3,
	parameter X_NODE_NUM_WIDTH			=	log2(X_NODE_NUM),
	parameter Y_NODE_NUM_WIDTH			=	log2(Y_NODE_NUM),
	parameter PORT_NUM_BCD_WIDTH		=	log2(PORT_NUM),
	parameter PORT_SEL_WIDTH			=	PORT_NUM-1//assum that no port whants to send a packet to itself!
	
	)
	(
	input 	[X_NODE_NUM_WIDTH-1		:0]	current_router_x_addr,
	input		[Y_NODE_NUM_WIDTH-1		:0]	current_router_y_addr,
	input 	[X_NODE_NUM_WIDTH-1		:0]	dest_x_node_in,
	input		[Y_NODE_NUM_WIDTH-1		:0]	dest_y_node_in,
	output	[PORT_NUM_BCD_WIDTH-1	:0]	port_num_out// one extra bit will be removed by switch_in latter
	);
	
	`LOG2
	
	
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
	
	
	assign 	xc 	={1'b0, current_router_x_addr [X_NODE_NUM_WIDTH-1		:0]};
	assign 	yc 	={1'b0, current_router_y_addr [Y_NODE_NUM_WIDTH-1		:0]};
	assign	xd		={1'b0, dest_x_node_in};
	assign	yd 	={1'b0, dest_y_node_in};
	assign 	xdiff	= xd-xc;
	assign	ydiff	= yd-yc;
	
		
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


/*************************************************

				xy _torus_routing 

************************************************/


module xy_torus_routing #(
	parameter PORT_NUM					=	5,
	parameter X_NODE_NUM					=	4,
	parameter Y_NODE_NUM					=	3,
	parameter X_NODE_NUM_WIDTH			=	log2(X_NODE_NUM),
	parameter Y_NODE_NUM_WIDTH			=	log2(Y_NODE_NUM),
	parameter PORT_NUM_BCD_WIDTH		=	log2(PORT_NUM),
	parameter PORT_SEL_WIDTH			=	PORT_NUM-1//assum that no port whants to send a packet to itself!
	
	)
	(
	input 	[X_NODE_NUM_WIDTH-1		:0]	current_router_x_addr,
	input		[Y_NODE_NUM_WIDTH-1		:0]	current_router_y_addr,
	input 	[X_NODE_NUM_WIDTH-1		:0]	dest_x_node_in,
	input		[Y_NODE_NUM_WIDTH-1		:0]	dest_y_node_in,
	output	[PORT_NUM_BCD_WIDTH-1	:0]	port_num_out// one extra bit will be removed by switch_in latter
	);
	
	`LOG2
	
	
	localparam LOCAL	=		3'd0;  
	localparam EAST	=		3'd1; 
	localparam NORTH	=		3'd2;  
	localparam WEST	=		3'd3;  
	localparam SOUTH	=		3'd4;  
	
	
	reg  [PORT_NUM_BCD_WIDTH-1				:0]	port_num_next;
	wire [X_NODE_NUM_WIDTH-1				:0]	x_addr_low,x_addr_high,x_addr_diff_f,x_addr_diff_b;
	wire													x_des_bigger;
	
	wire [Y_NODE_NUM_WIDTH-1				:0]	y_addr_low,y_addr_high,y_addr_diff_f,y_addr_diff_b;
	wire 													y_des_bigger;
	
	assign x_des_bigger 	=(dest_x_node_in > current_router_x_addr);
	assign x_addr_low	  	=(x_des_bigger)?	current_router_x_addr	: 	dest_x_node_in;
	assign x_addr_high  	=(x_des_bigger)?	dest_x_node_in 			:	current_router_x_addr;
	assign x_addr_diff_f	= x_addr_high - x_addr_low; 
	assign x_addr_diff_b = x_addr_low + X_NODE_NUM[X_NODE_NUM_WIDTH-1				:0] -  x_addr_high;
	
	assign y_des_bigger 	=(dest_y_node_in > current_router_y_addr);
	assign y_addr_low	  	=(y_des_bigger)?	current_router_y_addr	: 	dest_y_node_in ;
	assign y_addr_high  	=(y_des_bigger)?	dest_y_node_in 			: 	current_router_y_addr;
	assign y_addr_diff_f	= y_addr_high - y_addr_low; 
	assign y_addr_diff_b = y_addr_low + Y_NODE_NUM[Y_NODE_NUM_WIDTH-1				:0] -  y_addr_high;
	
		
	assign	port_num_out= port_num_next;
	
	always@(*)begin
			port_num_next	= LOCAL;
			if			(x_addr_diff_f > 0 ) begin 
				if		(x_addr_diff_f	<= x_addr_diff_b )			 port_num_next	= (x_des_bigger)? EAST: WEST;
				else 	port_num_next	= (x_des_bigger)? WEST: EAST;
			end
			else if	(y_addr_diff_f > 0 ) begin 
				if		(y_addr_diff_f	<= y_addr_diff_b )			 port_num_next	= (y_des_bigger)? SOUTH: NORTH;
				else 	port_num_next	= (y_des_bigger)? NORTH: SOUTH;
			end
	end
		
endmodule
	
	
	
/*************************************************

				xy _routing 

************************************************/


module xy_routing #(
	parameter TOPOLOGY					=	"MESH",//"TORUS"
	parameter PORT_NUM					=	5,
	parameter X_NODE_NUM					=	4,
	parameter Y_NODE_NUM					=	3,
	parameter X_NODE_NUM_WIDTH			=	log2(X_NODE_NUM),
	parameter Y_NODE_NUM_WIDTH			=	log2(Y_NODE_NUM),
	parameter PORT_NUM_BCD_WIDTH		=	log2(PORT_NUM),
	parameter PORT_SEL_WIDTH			=	PORT_NUM-1//assum that no port whants to send a packet to itself!
	
	)
	(
	input 	[X_NODE_NUM_WIDTH-1		:0]	current_router_x_addr,
	input		[Y_NODE_NUM_WIDTH-1		:0]	current_router_y_addr,
	input 	[X_NODE_NUM_WIDTH-1		:0]	dest_x_node_in,
	input		[Y_NODE_NUM_WIDTH-1		:0]	dest_y_node_in,
	output	[PORT_NUM_BCD_WIDTH-1	:0]	port_num_out// one extra bit will be removed by switch_in latter
	);
	`LOG2
	generate 
		if(TOPOLOGY == "MESH") begin : mesh
			xy_mesh_routing #(
				.PORT_NUM	(PORT_NUM),
				.X_NODE_NUM	(X_NODE_NUM),
				.Y_NODE_NUM	(Y_NODE_NUM)	
			)xy_mesh
			(
				.current_router_x_addr	(current_router_x_addr),
				.current_router_y_addr	(current_router_y_addr),
				.dest_x_node_in			(dest_x_node_in),
				.dest_y_node_in			(dest_y_node_in),
				.port_num_out				(port_num_out)// one extra bit will be removed by switch_in latter
			);
	
		end else if(TOPOLOGY == "TORUS") begin : torus
			xy_torus_routing #(
				.PORT_NUM	(PORT_NUM),
				.X_NODE_NUM	(X_NODE_NUM),
				.Y_NODE_NUM	(Y_NODE_NUM)	
			)xy_torus
			(
				.current_router_x_addr	(current_router_x_addr),
				.current_router_y_addr	(current_router_y_addr),
				.dest_x_node_in			(dest_x_node_in),
				.dest_y_node_in			(dest_y_node_in),
				.port_num_out				(port_num_out)// one extra bit will be removed by switch_in latter
			);
		
		
		end
	
	endgenerate
	endmodule
	
	
	
	
/*****************************************************

				minimal_mesh_routing

*****************************************************/


module minimal_mesh_routing #(
	parameter PORT_NUM					=	5,
	parameter X_NODE_NUM					=	4,
	parameter Y_NODE_NUM					=	3,
	parameter X_NODE_NUM_WIDTH			=	log2(X_NODE_NUM),
	parameter Y_NODE_NUM_WIDTH			=	log2(Y_NODE_NUM),
	parameter PORT_NUM_BCD_WIDTH		=	log2(PORT_NUM),
	parameter PORT_SEL_WIDTH			=	PORT_NUM-1//assum that no port whants to send a packet to itself!
	
	)
	(
	input 	[X_NODE_NUM_WIDTH-1		:0]	current_router_x_addr,
	input		[Y_NODE_NUM_WIDTH-1		:0]	current_router_y_addr,
	input 	[X_NODE_NUM_WIDTH-1		:0]	dest_x_node_in,
	input		[Y_NODE_NUM_WIDTH-1		:0]	dest_y_node_in,
	output	[PORT_NUM_BCD_WIDTH-1	:0]	port_num_out// one extra bit will be removed by switch_in latter
	);
	
	`LOG2
	
	
	localparam LOCAL	=		3'd0;  
	localparam EAST	=		3'd1; 
	localparam NORTH	=		3'd2;  
	localparam WEST	=		3'd3;  
	localparam SOUTH	=		3'd4;  
	
	
	reg  [PORT_NUM_BCD_WIDTH-1				:0]	port_num_next;
	wire [X_NODE_NUM_WIDTH-1				:0]	x_addr_low,x_addr_high,x_addr_diff_f;
	wire													x_des_bigger;
	
	wire [Y_NODE_NUM_WIDTH-1				:0]	y_addr_low,y_addr_high,y_addr_diff_f;
	wire 													y_des_bigger;
	
	assign x_des_bigger 	=(dest_x_node_in > current_router_x_addr);
	assign x_addr_low	  	=(x_des_bigger)?	current_router_x_addr	: 	dest_x_node_in;
	assign x_addr_high  	=(x_des_bigger)?	dest_x_node_in 			:	current_router_x_addr;
	assign x_addr_diff_f	= x_addr_high - x_addr_low; 
	
	
	assign y_des_bigger 	=(dest_y_node_in > current_router_y_addr);
	assign y_addr_low	  	=(y_des_bigger)?	current_router_y_addr	: 	dest_y_node_in ;
	assign y_addr_high  	=(y_des_bigger)?	dest_y_node_in 			: 	current_router_y_addr;
	assign y_addr_diff_f	= y_addr_high - y_addr_low; 
	
	
		
	assign	port_num_out= port_num_next;
	
	always@(*)begin
			port_num_next	= LOCAL;
			if			(x_addr_diff_f==0 && y_addr_diff_f==0 )	 port_num_next	= LOCAL;
			else  if	(x_addr_diff_f	>y_addr_diff_f )  			 port_num_next	= (x_des_bigger)? EAST: WEST;
			else 	if (x_addr_diff_f	<= y_addr_diff_f )	  		 port_num_next	= (y_des_bigger)? SOUTH: NORTH;
	end
		
endmodule


/*************************************************

				minimal _torus_routing 

************************************************/


module minimal_torus_routing #(
	parameter PORT_NUM					=	5,
	parameter X_NODE_NUM					=	4,
	parameter Y_NODE_NUM					=	3,
	parameter X_NODE_NUM_WIDTH			=	log2(X_NODE_NUM),
	parameter Y_NODE_NUM_WIDTH			=	log2(Y_NODE_NUM),
	parameter PORT_NUM_BCD_WIDTH		=	log2(PORT_NUM),
	parameter PORT_SEL_WIDTH			=	PORT_NUM-1//assum that no port whants to send a packet to itself!
	
	)
	(
	input 	[X_NODE_NUM_WIDTH-1		:0]	current_router_x_addr,
	input		[Y_NODE_NUM_WIDTH-1		:0]	current_router_y_addr,
	input 	[X_NODE_NUM_WIDTH-1		:0]	dest_x_node_in,
	input		[Y_NODE_NUM_WIDTH-1		:0]	dest_y_node_in,
	output	[PORT_NUM_BCD_WIDTH-1	:0]	port_num_out// one extra bit will be removed by switch_in latter
	);
	
	`LOG2
	
	
	localparam LOCAL	=		3'd0;  
	localparam EAST	=		3'd1; 
	localparam NORTH	=		3'd2;  
	localparam WEST	=		3'd3;  
	localparam SOUTH	=		3'd4;  
	
	
	reg  [PORT_NUM_BCD_WIDTH-1				:0]	port_num_next;
	wire [X_NODE_NUM_WIDTH-1				:0]	x_addr_low,x_addr_high,x_addr_diff_f,x_addr_diff_b,x_min_of_b_f;
	wire													x_des_bigger;
	
	wire [Y_NODE_NUM_WIDTH-1				:0]	y_addr_low,y_addr_high,y_addr_diff_f,y_addr_diff_b,y_min_of_b_f;
	wire 													y_des_bigger;
	
	assign x_des_bigger 	=(dest_x_node_in > current_router_x_addr);
	assign x_addr_low	  	=(x_des_bigger)?	current_router_x_addr	: 	dest_x_node_in;
	assign x_addr_high  	=(x_des_bigger)?	dest_x_node_in 			:	current_router_x_addr;
	assign x_addr_diff_f	= x_addr_high - x_addr_low; 
	assign x_addr_diff_b = x_addr_low + X_NODE_NUM[X_NODE_NUM_WIDTH-1				:0] -  x_addr_high;
	assign x_min_of_b_f	= (x_addr_diff_f >  x_addr_diff_b )? x_addr_diff_b : x_addr_diff_f;
	
	assign y_des_bigger 	=(dest_y_node_in > current_router_y_addr);
	assign y_addr_low	  	=(y_des_bigger)?	current_router_y_addr	: 	dest_y_node_in ;
	assign y_addr_high  	=(y_des_bigger)?	dest_y_node_in 			: 	current_router_y_addr;
	assign y_addr_diff_f	= y_addr_high - y_addr_low; 
	assign y_addr_diff_b = y_addr_low + Y_NODE_NUM[Y_NODE_NUM_WIDTH-1				:0] -  y_addr_high;
	assign y_min_of_b_f	= (y_addr_diff_f >  y_addr_diff_b )? y_addr_diff_b : y_addr_diff_f;
	
		
	assign	port_num_out= port_num_next;
	
	always@(*)begin
			port_num_next	= LOCAL;
			if( x_min_of_b_f ==0 && y_min_of_b_f==0) port_num_next	= LOCAL;
			else begin   
				if(x_min_of_b_f > y_min_of_b_f) begin
					if		(x_addr_diff_f	<= x_addr_diff_b )			 port_num_next	= (x_des_bigger)? EAST: WEST;
					else 	port_num_next	= (x_des_bigger)? WEST: EAST;
				end else if(x_min_of_b_f <= y_min_of_b_f ) begin
					if		(y_addr_diff_f	<= y_addr_diff_b )			 port_num_next	= (y_des_bigger)? SOUTH: NORTH;
					else 	port_num_next	= (y_des_bigger)? NORTH: SOUTH;
				end
			end
	end//always
		
	endmodule
	

	
	
/*************************************************

				minimal_routing 

************************************************/


module minimal_routing #(
	parameter TOPOLOGY					=	"MESH",//"TORUS"
	parameter PORT_NUM					=	5,
	parameter X_NODE_NUM					=	4,
	parameter Y_NODE_NUM					=	3,
	parameter X_NODE_NUM_WIDTH			=	log2(X_NODE_NUM),
	parameter Y_NODE_NUM_WIDTH			=	log2(Y_NODE_NUM),
	parameter PORT_NUM_BCD_WIDTH		=	log2(PORT_NUM),
	parameter PORT_SEL_WIDTH			=	PORT_NUM-1//assum that no port whants to send a packet to itself!
	
	)
	(
	input 	[X_NODE_NUM_WIDTH-1		:0]	current_router_x_addr,
	input		[Y_NODE_NUM_WIDTH-1		:0]	current_router_y_addr,
	input 	[X_NODE_NUM_WIDTH-1		:0]	dest_x_node_in,
	input		[Y_NODE_NUM_WIDTH-1		:0]	dest_y_node_in,
	output	[PORT_NUM_BCD_WIDTH-1	:0]	port_num_out// one extra bit will be removed by switch_in latter
	);
	`LOG2
	generate 
		if(TOPOLOGY == "MESH") begin 
			minimal_mesh_routing #(
				.PORT_NUM	(PORT_NUM),
				.X_NODE_NUM	(X_NODE_NUM),
				.Y_NODE_NUM	(Y_NODE_NUM)	
			)second_level
			(
				.current_router_x_addr	(current_router_x_addr),
				.current_router_y_addr	(current_router_y_addr),
				.dest_x_node_in			(dest_x_node_in),
				.dest_y_node_in			(dest_y_node_in),
				.port_num_out				(port_num_out)// one extra bit will be removed by switch_in latter
			);
	
		end else if(TOPOLOGY == "TORUS") begin
			minimal_torus_routing #(
				.PORT_NUM	(PORT_NUM),
				.X_NODE_NUM	(X_NODE_NUM),
				.Y_NODE_NUM	(Y_NODE_NUM)	
			)second_level
			(
				.current_router_x_addr	(current_router_x_addr),
				.current_router_y_addr	(current_router_y_addr),
				.dest_x_node_in			(dest_x_node_in),
				.dest_y_node_in			(dest_y_node_in),
				.port_num_out				(port_num_out)// one extra bit will be removed by switch_in latter
			);
		
		
		end
	
	endgenerate
	endmodule
	
	

