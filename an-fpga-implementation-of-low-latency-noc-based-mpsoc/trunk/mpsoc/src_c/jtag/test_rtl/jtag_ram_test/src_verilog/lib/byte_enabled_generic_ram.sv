// Quartus II SystemVerilog Template
//
// True Dual-Port RAM with different read/write addresses and single read/write clock
// and with a control for writing single bytes into the memory word; byte enable

// Read during write produces old data on ports A and B and old data on mixed ports
// For device families that do not support this mode (e.g. Stratix V) the ram is not inferred


`timescale 1ns / 1ps

module byte_enabled_true_dual_port_ram	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v format
		parameter INITIAL_EN= "NO",
		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 4,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

generate
if (BYTES==1) begin : byte_en1
	byte_enabled_true_dual_port_ram_1 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==2) begin : byte_en2
	byte_enabled_true_dual_port_ram_2 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==3) begin : byte_en3
	byte_enabled_true_dual_port_ram_3 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==4) begin : byte_en4
	byte_enabled_true_dual_port_ram_4 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==5) begin : byte_en5
	byte_enabled_true_dual_port_ram_5 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==6) begin : byte_en6
	byte_enabled_true_dual_port_ram_6 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==7) begin : byte_en7
	byte_enabled_true_dual_port_ram_7 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==8) begin : byte_en8
	byte_enabled_true_dual_port_ram_8 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==9) begin : byte_en9
	byte_enabled_true_dual_port_ram_9 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==10) begin : byte_en10
	byte_enabled_true_dual_port_ram_10 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==11) begin : byte_en11
	byte_enabled_true_dual_port_ram_11 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==12) begin : byte_en12
	byte_enabled_true_dual_port_ram_12 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==13) begin : byte_en13
	byte_enabled_true_dual_port_ram_13 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==14) begin : byte_en14
	byte_enabled_true_dual_port_ram_14 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
if (BYTES==15) begin : byte_en15
	byte_enabled_true_dual_port_ram_15 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr1(addr1),
		.addr2(addr2),
		.be1(be1),
		.be2(be2),
		.data_in1(data_in1), 
		.data_in2(data_in2), 
		.we1(we1),
		.we2(we2),
		.clk(clk),
		.data_out1(data_out1),
		.data_out2(data_out2)
	);
end
endgenerate
endmodule:  byte_enabled_true_dual_port_ram

module byte_enabled_true_dual_port_ram_1	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 1,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_1

module byte_enabled_true_dual_port_ram_2	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 2,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_2

module byte_enabled_true_dual_port_ram_3	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 3,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
		if(be1[2]) ram[addr1][2] <= data_in_sep1[2];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];
		if(be2[2]) ram[addr2][2] <= data_in_sep2[2];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_3

module byte_enabled_true_dual_port_ram_4	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 4,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
		if(be1[2]) ram[addr1][2] <= data_in_sep1[2];
		if(be1[3]) ram[addr1][3] <= data_in_sep1[3];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];
		if(be2[2]) ram[addr2][2] <= data_in_sep2[2];
		if(be2[3]) ram[addr2][3] <= data_in_sep2[3];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_4

module byte_enabled_true_dual_port_ram_5	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 5,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
		if(be1[2]) ram[addr1][2] <= data_in_sep1[2];
		if(be1[3]) ram[addr1][3] <= data_in_sep1[3];
		if(be1[4]) ram[addr1][4] <= data_in_sep1[4];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];
		if(be2[2]) ram[addr2][2] <= data_in_sep2[2];
		if(be2[3]) ram[addr2][3] <= data_in_sep2[3];
		if(be2[4]) ram[addr2][4] <= data_in_sep2[4];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_5

module byte_enabled_true_dual_port_ram_6	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 6,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
		if(be1[2]) ram[addr1][2] <= data_in_sep1[2];
		if(be1[3]) ram[addr1][3] <= data_in_sep1[3];
		if(be1[4]) ram[addr1][4] <= data_in_sep1[4];
		if(be1[5]) ram[addr1][5] <= data_in_sep1[5];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];
		if(be2[2]) ram[addr2][2] <= data_in_sep2[2];
		if(be2[3]) ram[addr2][3] <= data_in_sep2[3];
		if(be2[4]) ram[addr2][4] <= data_in_sep2[4];
		if(be2[5]) ram[addr2][5] <= data_in_sep2[5];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_6

module byte_enabled_true_dual_port_ram_7	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 7,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
		if(be1[2]) ram[addr1][2] <= data_in_sep1[2];
		if(be1[3]) ram[addr1][3] <= data_in_sep1[3];
		if(be1[4]) ram[addr1][4] <= data_in_sep1[4];
		if(be1[5]) ram[addr1][5] <= data_in_sep1[5];
		if(be1[6]) ram[addr1][6] <= data_in_sep1[6];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];
		if(be2[2]) ram[addr2][2] <= data_in_sep2[2];
		if(be2[3]) ram[addr2][3] <= data_in_sep2[3];
		if(be2[4]) ram[addr2][4] <= data_in_sep2[4];
		if(be2[5]) ram[addr2][5] <= data_in_sep2[5];
		if(be2[6]) ram[addr2][6] <= data_in_sep2[6];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_7

module byte_enabled_true_dual_port_ram_8	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 8,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
		if(be1[2]) ram[addr1][2] <= data_in_sep1[2];
		if(be1[3]) ram[addr1][3] <= data_in_sep1[3];
		if(be1[4]) ram[addr1][4] <= data_in_sep1[4];
		if(be1[5]) ram[addr1][5] <= data_in_sep1[5];
		if(be1[6]) ram[addr1][6] <= data_in_sep1[6];
		if(be1[7]) ram[addr1][7] <= data_in_sep1[7];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];
		if(be2[2]) ram[addr2][2] <= data_in_sep2[2];
		if(be2[3]) ram[addr2][3] <= data_in_sep2[3];
		if(be2[4]) ram[addr2][4] <= data_in_sep2[4];
		if(be2[5]) ram[addr2][5] <= data_in_sep2[5];
		if(be2[6]) ram[addr2][6] <= data_in_sep2[6];
		if(be2[7]) ram[addr2][7] <= data_in_sep2[7];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_8

module byte_enabled_true_dual_port_ram_9	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 9,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
		if(be1[2]) ram[addr1][2] <= data_in_sep1[2];
		if(be1[3]) ram[addr1][3] <= data_in_sep1[3];
		if(be1[4]) ram[addr1][4] <= data_in_sep1[4];
		if(be1[5]) ram[addr1][5] <= data_in_sep1[5];
		if(be1[6]) ram[addr1][6] <= data_in_sep1[6];
		if(be1[7]) ram[addr1][7] <= data_in_sep1[7];
		if(be1[8]) ram[addr1][8] <= data_in_sep1[8];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];
		if(be2[2]) ram[addr2][2] <= data_in_sep2[2];
		if(be2[3]) ram[addr2][3] <= data_in_sep2[3];
		if(be2[4]) ram[addr2][4] <= data_in_sep2[4];
		if(be2[5]) ram[addr2][5] <= data_in_sep2[5];
		if(be2[6]) ram[addr2][6] <= data_in_sep2[6];
		if(be2[7]) ram[addr2][7] <= data_in_sep2[7];
		if(be2[8]) ram[addr2][8] <= data_in_sep2[8];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_9

module byte_enabled_true_dual_port_ram_10	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 10,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
		if(be1[2]) ram[addr1][2] <= data_in_sep1[2];
		if(be1[3]) ram[addr1][3] <= data_in_sep1[3];
		if(be1[4]) ram[addr1][4] <= data_in_sep1[4];
		if(be1[5]) ram[addr1][5] <= data_in_sep1[5];
		if(be1[6]) ram[addr1][6] <= data_in_sep1[6];
		if(be1[7]) ram[addr1][7] <= data_in_sep1[7];
		if(be1[8]) ram[addr1][8] <= data_in_sep1[8];
		if(be1[9]) ram[addr1][9] <= data_in_sep1[9];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];
		if(be2[2]) ram[addr2][2] <= data_in_sep2[2];
		if(be2[3]) ram[addr2][3] <= data_in_sep2[3];
		if(be2[4]) ram[addr2][4] <= data_in_sep2[4];
		if(be2[5]) ram[addr2][5] <= data_in_sep2[5];
		if(be2[6]) ram[addr2][6] <= data_in_sep2[6];
		if(be2[7]) ram[addr2][7] <= data_in_sep2[7];
		if(be2[8]) ram[addr2][8] <= data_in_sep2[8];
		if(be2[9]) ram[addr2][9] <= data_in_sep2[9];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_10

module byte_enabled_true_dual_port_ram_11	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 11,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
		if(be1[2]) ram[addr1][2] <= data_in_sep1[2];
		if(be1[3]) ram[addr1][3] <= data_in_sep1[3];
		if(be1[4]) ram[addr1][4] <= data_in_sep1[4];
		if(be1[5]) ram[addr1][5] <= data_in_sep1[5];
		if(be1[6]) ram[addr1][6] <= data_in_sep1[6];
		if(be1[7]) ram[addr1][7] <= data_in_sep1[7];
		if(be1[8]) ram[addr1][8] <= data_in_sep1[8];
		if(be1[9]) ram[addr1][9] <= data_in_sep1[9];
		if(be1[10]) ram[addr1][10] <= data_in_sep1[10];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];
		if(be2[2]) ram[addr2][2] <= data_in_sep2[2];
		if(be2[3]) ram[addr2][3] <= data_in_sep2[3];
		if(be2[4]) ram[addr2][4] <= data_in_sep2[4];
		if(be2[5]) ram[addr2][5] <= data_in_sep2[5];
		if(be2[6]) ram[addr2][6] <= data_in_sep2[6];
		if(be2[7]) ram[addr2][7] <= data_in_sep2[7];
		if(be2[8]) ram[addr2][8] <= data_in_sep2[8];
		if(be2[9]) ram[addr2][9] <= data_in_sep2[9];
		if(be2[10]) ram[addr2][10] <= data_in_sep2[10];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_11

module byte_enabled_true_dual_port_ram_12	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 12,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
		if(be1[2]) ram[addr1][2] <= data_in_sep1[2];
		if(be1[3]) ram[addr1][3] <= data_in_sep1[3];
		if(be1[4]) ram[addr1][4] <= data_in_sep1[4];
		if(be1[5]) ram[addr1][5] <= data_in_sep1[5];
		if(be1[6]) ram[addr1][6] <= data_in_sep1[6];
		if(be1[7]) ram[addr1][7] <= data_in_sep1[7];
		if(be1[8]) ram[addr1][8] <= data_in_sep1[8];
		if(be1[9]) ram[addr1][9] <= data_in_sep1[9];
		if(be1[10]) ram[addr1][10] <= data_in_sep1[10];
		if(be1[11]) ram[addr1][11] <= data_in_sep1[11];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];
		if(be2[2]) ram[addr2][2] <= data_in_sep2[2];
		if(be2[3]) ram[addr2][3] <= data_in_sep2[3];
		if(be2[4]) ram[addr2][4] <= data_in_sep2[4];
		if(be2[5]) ram[addr2][5] <= data_in_sep2[5];
		if(be2[6]) ram[addr2][6] <= data_in_sep2[6];
		if(be2[7]) ram[addr2][7] <= data_in_sep2[7];
		if(be2[8]) ram[addr2][8] <= data_in_sep2[8];
		if(be2[9]) ram[addr2][9] <= data_in_sep2[9];
		if(be2[10]) ram[addr2][10] <= data_in_sep2[10];
		if(be2[11]) ram[addr2][11] <= data_in_sep2[11];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_12

module byte_enabled_true_dual_port_ram_13	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 13,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
		if(be1[2]) ram[addr1][2] <= data_in_sep1[2];
		if(be1[3]) ram[addr1][3] <= data_in_sep1[3];
		if(be1[4]) ram[addr1][4] <= data_in_sep1[4];
		if(be1[5]) ram[addr1][5] <= data_in_sep1[5];
		if(be1[6]) ram[addr1][6] <= data_in_sep1[6];
		if(be1[7]) ram[addr1][7] <= data_in_sep1[7];
		if(be1[8]) ram[addr1][8] <= data_in_sep1[8];
		if(be1[9]) ram[addr1][9] <= data_in_sep1[9];
		if(be1[10]) ram[addr1][10] <= data_in_sep1[10];
		if(be1[11]) ram[addr1][11] <= data_in_sep1[11];
		if(be1[12]) ram[addr1][12] <= data_in_sep1[12];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];
		if(be2[2]) ram[addr2][2] <= data_in_sep2[2];
		if(be2[3]) ram[addr2][3] <= data_in_sep2[3];
		if(be2[4]) ram[addr2][4] <= data_in_sep2[4];
		if(be2[5]) ram[addr2][5] <= data_in_sep2[5];
		if(be2[6]) ram[addr2][6] <= data_in_sep2[6];
		if(be2[7]) ram[addr2][7] <= data_in_sep2[7];
		if(be2[8]) ram[addr2][8] <= data_in_sep2[8];
		if(be2[9]) ram[addr2][9] <= data_in_sep2[9];
		if(be2[10]) ram[addr2][10] <= data_in_sep2[10];
		if(be2[11]) ram[addr2][11] <= data_in_sep2[11];
		if(be2[12]) ram[addr2][12] <= data_in_sep2[12];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_13

module byte_enabled_true_dual_port_ram_14	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 14,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];


	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
		if(be1[2]) ram[addr1][2] <= data_in_sep1[2];
		if(be1[3]) ram[addr1][3] <= data_in_sep1[3];
		if(be1[4]) ram[addr1][4] <= data_in_sep1[4];
		if(be1[5]) ram[addr1][5] <= data_in_sep1[5];
		if(be1[6]) ram[addr1][6] <= data_in_sep1[6];
		if(be1[7]) ram[addr1][7] <= data_in_sep1[7];
		if(be1[8]) ram[addr1][8] <= data_in_sep1[8];
		if(be1[9]) ram[addr1][9] <= data_in_sep1[9];
		if(be1[10]) ram[addr1][10] <= data_in_sep1[10];
		if(be1[11]) ram[addr1][11] <= data_in_sep1[11];
		if(be1[12]) ram[addr1][12] <= data_in_sep1[12];
		if(be1[13]) ram[addr1][13] <= data_in_sep1[13];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];
		if(be2[2]) ram[addr2][2] <= data_in_sep2[2];
		if(be2[3]) ram[addr2][3] <= data_in_sep2[3];
		if(be2[4]) ram[addr2][4] <= data_in_sep2[4];
		if(be2[5]) ram[addr2][5] <= data_in_sep2[5];
		if(be2[6]) ram[addr2][6] <= data_in_sep2[6];
		if(be2[7]) ram[addr2][7] <= data_in_sep2[7];
		if(be2[8]) ram[addr2][8] <= data_in_sep2[8];
		if(be2[9]) ram[addr2][9] <= data_in_sep2[9];
		if(be2[10]) ram[addr2][10] <= data_in_sep2[10];
		if(be2[11]) ram[addr2][11] <= data_in_sep2[11];
		if(be2[12]) ram[addr2][12] <= data_in_sep2[12];
		if(be2[13]) ram[addr2][13] <= data_in_sep2[13];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_14

module byte_enabled_true_dual_port_ram_15	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 15,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be1,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH_R-1:0] data_in1, 
	input [DATA_WIDTH_R-1:0] data_in2, 
	input we1, we2, clk,
	output [DATA_WIDTH_R-1:0] data_out1,
	output [DATA_WIDTH_R-1:0] data_out2
);

wire [BYTE_WIDTH-1	:	0] data_in_sep1[BYTES-1	:	0];
wire [BYTE_WIDTH-1	:	0] data_in_sep2[BYTES-1	:	0];

genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep1[i]=data_in1[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	assign data_in_sep2[i]=data_in2[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
		if(be1[0]) ram[addr1][0] <= data_in_sep1[0];
		if(be1[1]) ram[addr1][1] <= data_in_sep1[1];
		if(be1[2]) ram[addr1][2] <= data_in_sep1[2];
		if(be1[3]) ram[addr1][3] <= data_in_sep1[3];
		if(be1[4]) ram[addr1][4] <= data_in_sep1[4];
		if(be1[5]) ram[addr1][5] <= data_in_sep1[5];
		if(be1[6]) ram[addr1][6] <= data_in_sep1[6];
		if(be1[7]) ram[addr1][7] <= data_in_sep1[7];
		if(be1[8]) ram[addr1][8] <= data_in_sep1[8];
		if(be1[9]) ram[addr1][9] <= data_in_sep1[9];
		if(be1[10]) ram[addr1][10] <= data_in_sep1[10];
		if(be1[11]) ram[addr1][11] <= data_in_sep1[11];
		if(be1[12]) ram[addr1][12] <= data_in_sep1[12];
		if(be1[13]) ram[addr1][13] <= data_in_sep1[13];
		if(be1[14]) ram[addr1][14] <= data_in_sep1[14];
	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		if(be2[0]) ram[addr2][0] <= data_in_sep2[0];
		if(be2[1]) ram[addr2][1] <= data_in_sep2[1];
		if(be2[2]) ram[addr2][2] <= data_in_sep2[2];
		if(be2[3]) ram[addr2][3] <= data_in_sep2[3];
		if(be2[4]) ram[addr2][4] <= data_in_sep2[4];
		if(be2[5]) ram[addr2][5] <= data_in_sep2[5];
		if(be2[6]) ram[addr2][6] <= data_in_sep2[6];
		if(be2[7]) ram[addr2][7] <= data_in_sep2[7];
		if(be2[8]) ram[addr2][8] <= data_in_sep2[8];
		if(be2[9]) ram[addr2][9] <= data_in_sep2[9];
		if(be2[10]) ram[addr2][10] <= data_in_sep2[10];
		if(be2[11]) ram[addr2][11] <= data_in_sep2[11];
		if(be2[12]) ram[addr2][12] <= data_in_sep2[12];
		if(be2[13]) ram[addr2][13] <= data_in_sep2[13];
		if(be2[14]) ram[addr2][14] <= data_in_sep2[14];

		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_15

module byte_enabled_single_port_ram	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 4,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input we, clk,
	output [DATA_WIDTH_R-1:0] data_out

);

generate
if (BYTES==1) begin : byte_en1
	byte_enabled_single_port_ram_1 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==2) begin : byte_en2
	byte_enabled_single_port_ram_2 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==3) begin : byte_en3
	byte_enabled_single_port_ram_3 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==4) begin : byte_en4
	byte_enabled_single_port_ram_4 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==5) begin : byte_en5
	byte_enabled_single_port_ram_5 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==6) begin : byte_en6
	byte_enabled_single_port_ram_6 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==7) begin : byte_en7
	byte_enabled_single_port_ram_7 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==8) begin : byte_en8
	byte_enabled_single_port_ram_8 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==9) begin : byte_en9
	byte_enabled_single_port_ram_9 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==10) begin : byte_en10
	byte_enabled_single_port_ram_10 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==11) begin : byte_en11
	byte_enabled_single_port_ram_11 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==12) begin : byte_en12
	byte_enabled_single_port_ram_12 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==13) begin : byte_en13
	byte_enabled_single_port_ram_13 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==14) begin : byte_en14
	byte_enabled_single_port_ram_14 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
if (BYTES==15) begin : byte_en15
	byte_enabled_single_port_ram_15 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		 .INITIAL_EN(INITIAL_EN),
		 .INIT_FILE(INIT_FILE) 		
	)
	ram_inst
	(
		.addr(addr),
		.be(be),
		.data_in(data_in), 
		.we(we),
		.clk(clk),
		.data_out(data_out)
		
	);
end
endgenerate
endmodule : byte_enabled_single_port_ram

module byte_enabled_single_port_ram_1	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 1,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_1

module byte_enabled_single_port_ram_2	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 2,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_2

module byte_enabled_single_port_ram_3	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 3,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
		if(be[2]) ram[addr][2] <= data_in_sep[2];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_3

module byte_enabled_single_port_ram_4	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 4,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
		if(be[2]) ram[addr][2] <= data_in_sep[2];
		if(be[3]) ram[addr][3] <= data_in_sep[3];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_4

module byte_enabled_single_port_ram_5	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 5,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
		if(be[2]) ram[addr][2] <= data_in_sep[2];
		if(be[3]) ram[addr][3] <= data_in_sep[3];
		if(be[4]) ram[addr][4] <= data_in_sep[4];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_5

module byte_enabled_single_port_ram_6	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 6,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate
	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
		if(be[2]) ram[addr][2] <= data_in_sep[2];
		if(be[3]) ram[addr][3] <= data_in_sep[3];
		if(be[4]) ram[addr][4] <= data_in_sep[4];
		if(be[5]) ram[addr][5] <= data_in_sep[5];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_6

module byte_enabled_single_port_ram_7	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 7,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate
	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
		if(be[2]) ram[addr][2] <= data_in_sep[2];
		if(be[3]) ram[addr][3] <= data_in_sep[3];
		if(be[4]) ram[addr][4] <= data_in_sep[4];
		if(be[5]) ram[addr][5] <= data_in_sep[5];
		if(be[6]) ram[addr][6] <= data_in_sep[6];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_7

module byte_enabled_single_port_ram_8	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 8,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
		if(be[2]) ram[addr][2] <= data_in_sep[2];
		if(be[3]) ram[addr][3] <= data_in_sep[3];
		if(be[4]) ram[addr][4] <= data_in_sep[4];
		if(be[5]) ram[addr][5] <= data_in_sep[5];
		if(be[6]) ram[addr][6] <= data_in_sep[6];
		if(be[7]) ram[addr][7] <= data_in_sep[7];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_8

module byte_enabled_single_port_ram_9	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 9,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
		if(be[2]) ram[addr][2] <= data_in_sep[2];
		if(be[3]) ram[addr][3] <= data_in_sep[3];
		if(be[4]) ram[addr][4] <= data_in_sep[4];
		if(be[5]) ram[addr][5] <= data_in_sep[5];
		if(be[6]) ram[addr][6] <= data_in_sep[6];
		if(be[7]) ram[addr][7] <= data_in_sep[7];
		if(be[8]) ram[addr][8] <= data_in_sep[8];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_9

module byte_enabled_single_port_ram_10	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 10,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate
	
	reg [DATA_WIDTH_R-1:0] data_reg;
	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
		if(be[2]) ram[addr][2] <= data_in_sep[2];
		if(be[3]) ram[addr][3] <= data_in_sep[3];
		if(be[4]) ram[addr][4] <= data_in_sep[4];
		if(be[5]) ram[addr][5] <= data_in_sep[5];
		if(be[6]) ram[addr][6] <= data_in_sep[6];
		if(be[7]) ram[addr][7] <= data_in_sep[7];
		if(be[8]) ram[addr][8] <= data_in_sep[8];
		if(be[9]) ram[addr][9] <= data_in_sep[9];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_10

module byte_enabled_single_port_ram_11	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 11,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1) begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
		if(be[2]) ram[addr][2] <= data_in_sep[2];
		if(be[3]) ram[addr][3] <= data_in_sep[3];
		if(be[4]) ram[addr][4] <= data_in_sep[4];
		if(be[5]) ram[addr][5] <= data_in_sep[5];
		if(be[6]) ram[addr][6] <= data_in_sep[6];
		if(be[7]) ram[addr][7] <= data_in_sep[7];
		if(be[8]) ram[addr][8] <= data_in_sep[8];
		if(be[9]) ram[addr][9] <= data_in_sep[9];
		if(be[10]) ram[addr][10] <= data_in_sep[10];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_11

module byte_enabled_single_port_ram_12	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 12,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
		if(be[2]) ram[addr][2] <= data_in_sep[2];
		if(be[3]) ram[addr][3] <= data_in_sep[3];
		if(be[4]) ram[addr][4] <= data_in_sep[4];
		if(be[5]) ram[addr][5] <= data_in_sep[5];
		if(be[6]) ram[addr][6] <= data_in_sep[6];
		if(be[7]) ram[addr][7] <= data_in_sep[7];
		if(be[8]) ram[addr][8] <= data_in_sep[8];
		if(be[9]) ram[addr][9] <= data_in_sep[9];
		if(be[10]) ram[addr][10] <= data_in_sep[10];
		if(be[11]) ram[addr][11] <= data_in_sep[11];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_12

module byte_enabled_single_port_ram_13	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 13,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
		if(be[2]) ram[addr][2] <= data_in_sep[2];
		if(be[3]) ram[addr][3] <= data_in_sep[3];
		if(be[4]) ram[addr][4] <= data_in_sep[4];
		if(be[5]) ram[addr][5] <= data_in_sep[5];
		if(be[6]) ram[addr][6] <= data_in_sep[6];
		if(be[7]) ram[addr][7] <= data_in_sep[7];
		if(be[8]) ram[addr][8] <= data_in_sep[8];
		if(be[9]) ram[addr][9] <= data_in_sep[9];
		if(be[10]) ram[addr][10] <= data_in_sep[10];
		if(be[11]) ram[addr][11] <= data_in_sep[11];
		if(be[12]) ram[addr][12] <= data_in_sep[12];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_13

module byte_enabled_single_port_ram_14	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 14,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
		if(be[2]) ram[addr][2] <= data_in_sep[2];
		if(be[3]) ram[addr][3] <= data_in_sep[3];
		if(be[4]) ram[addr][4] <= data_in_sep[4];
		if(be[5]) ram[addr][5] <= data_in_sep[5];
		if(be[6]) ram[addr][6] <= data_in_sep[6];
		if(be[7]) ram[addr][7] <= data_in_sep[7];
		if(be[8]) ram[addr][8] <= data_in_sep[8];
		if(be[9]) ram[addr][9] <= data_in_sep[9];
		if(be[10]) ram[addr][10] <= data_in_sep[10];
		if(be[11]) ram[addr][11] <= data_in_sep[11];
		if(be[12]) ram[addr][12] <= data_in_sep[12];
		if(be[13]) ram[addr][13] <= data_in_sep[13];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_14

module byte_enabled_single_port_ram_15	#(
		parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file in v forma
		parameter INITIAL_EN= "NO", 
 		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 15,
		DATA_WIDTH_R = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr,
	input [BYTES-1:0] be,
	input [DATA_WIDTH_R-1:0] data_in, 
	input  we, clk,
	output [DATA_WIDTH_R-1:0] data_out
	
);

wire [BYTE_WIDTH-1	:	0] data_in_sep[BYTES-1	:	0];


genvar i;
generate 
for (i=0;i<BYTES;i=i+1)begin : bloop
	assign data_in_sep[i]=data_in[(i+1)*BYTE_WIDTH-1	:	i*BYTE_WIDTH];
	
end
endgenerate

	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];
	
	generate 
		if (INITIAL_EN ==  "YES") begin : init
		   initial $readmemh(INIT_FILE,ram);	
		end
	endgenerate

	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
		if(be[0]) ram[addr][0] <= data_in_sep[0];
		if(be[1]) ram[addr][1] <= data_in_sep[1];
		if(be[2]) ram[addr][2] <= data_in_sep[2];
		if(be[3]) ram[addr][3] <= data_in_sep[3];
		if(be[4]) ram[addr][4] <= data_in_sep[4];
		if(be[5]) ram[addr][5] <= data_in_sep[5];
		if(be[6]) ram[addr][6] <= data_in_sep[6];
		if(be[7]) ram[addr][7] <= data_in_sep[7];
		if(be[8]) ram[addr][8] <= data_in_sep[8];
		if(be[9]) ram[addr][9] <= data_in_sep[9];
		if(be[10]) ram[addr][10] <= data_in_sep[10];
		if(be[11]) ram[addr][11] <= data_in_sep[11];
		if(be[12]) ram[addr][12] <= data_in_sep[12];
		if(be[13]) ram[addr][13] <= data_in_sep[13];
		if(be[14]) ram[addr][14] <= data_in_sep[14];
	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_15
