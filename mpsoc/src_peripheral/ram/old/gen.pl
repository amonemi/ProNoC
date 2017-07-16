#! /usr/bin/perl -w
my $B=16;




my $file= 'module byte_enabled_true_dual_port_ram	#(
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
';
 
for (my $i=1; $i<$B; $i++){

$file=$file."if (BYTES==$i) begin : byte_en$i
	byte_enabled_true_dual_port_ram_$i 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH)		
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
";
}
$file=$file."endgenerate
endmodule:  byte_enabled_true_dual_port_ram\n";




for (my $i=1; $i<$B; $i++){


$file=$file."
module byte_enabled_true_dual_port_ram_$i	#(
		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = $i,
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

	reg [DATA_WIDTH_R-1:0] data_reg1;
	reg [DATA_WIDTH_R-1:0] data_reg2;

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we1) begin
";
for (my $j=0;$j<$i;$j++){
$file=$file."		if(be1[$j]) ram[addr1][$j] <= data_in_sep1[$j];\n";
}
$file=$file."	
		end
	data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;
   
	// port B
	always@(posedge clk)
	begin
		if(we2) begin
";
for (my $j=0;$j<$i;$j++){
$file=$file."		if(be2[$j]) ram[addr2][$j] <= data_in_sep2[$j];\n";
}
$file=$file."
		
		end
	data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : byte_enabled_true_dual_port_ram_$i
";
}







my $file2= 'module byte_enabled_single_port_ram	#(
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
';
 
for (my $i=1; $i<$B; $i++){

$file2=$file2."if (BYTES==$i) begin : byte_en$i
	byte_enabled_single_port_ram_$i 
		#(
		.BYTE_WIDTH(BYTE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH)		
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
";
}
$file2=$file2."endgenerate
endmodule : byte_enabled_single_port_ram\n";




for (my $i=1; $i<$B; $i++){


$file2=$file2."
module byte_enabled_single_port_ram_$i	#(
		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = $i,
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

	reg [DATA_WIDTH_R-1:0] data_reg;
	

	// port A
	integer k;
	
	always@(posedge clk)
	begin
		if(we) begin
";
for (my $j=0;$j<$i;$j++){
$file2=$file2."		if(be[$j]) ram[addr][$j] <= data_in_sep[$j];\n";
}
$file2=$file2."	
		end
	data_reg <= ram[addr];
	end

	assign data_out = data_reg;	

endmodule : byte_enabled_single_port_ram_$i
";
}






print "$file\n$file2";





