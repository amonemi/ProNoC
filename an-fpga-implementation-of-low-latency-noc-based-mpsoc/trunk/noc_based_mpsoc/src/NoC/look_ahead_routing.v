`include "../define.v"
module look_ahead_routing #(
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
	look_ahead_xy #(
		.PORT_NUM			(PORT_NUM),
		.X_NODE_NUM			(X_NODE_NUM),
		.Y_NODE_NUM			(Y_NODE_NUM),
		.SW_X_ADDR			(SW_X_ADDR),
		.SW_Y_ADDR			(SW_Y_ADDR)
	
	)
	the_xy_routing
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
