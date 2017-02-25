
/****************
*simple_dual_port_ram
*
*****************/



// Quartus II Verilog Template
// Simple Dual Port RAM with separate read/write addresses and
// single read/write clock

module eth_simple_dual_port_ram #(
	parameter Dw=8, 
	parameter Aw=6
)
(
	data,
	read_addr, 
	write_addr,
	we,
	clk,
	q
);

	input 	[Dw-1	:0] data;
	input 	[Aw-1	:0] read_addr;
	input 	[Aw-1	:0] write_addr;
	input we;
	input clk;
	output reg [Dw-1	:0] q;


	// Declare the RAM variable
	reg [Dw-1:0] ram [2**Aw-1:0];

	always @ (posedge clk)
	begin
		// Write
		if (we)
			ram[write_addr] <= data;

		// Read (if read_addr == write_addr, return OLD data).	To return
		// NEW data, use = (blocking write) rather than <= (non-blocking write)
		// in the write assignment.	 NOTE: NEW data may require extra bypass
		// logic around the RAM.
		q <= ram[read_addr];
	end

endmodule








/*****************************

        single_port_ram


*****************************/

// Quartus II Verilog Template
// Single port RAM with single read/write address 

module eth_single_port_ram #(
    parameter Dw=8,
    parameter Aw=6
)
(
    data,
    addr,
    we,
    clk,
    q
);

    input [(Dw-1):0] data;
    input [(Aw-1):0] addr;
    input we, clk;
    output [(Dw-1):0] q;

    // Declare the RAM variable
    reg [Dw-1:0] ram[2**Aw-1:0];

    // Variable to hold the registered read address
    reg [Aw-1:0] addr_reg;

    always @ (posedge clk)
    begin
        // Write
        if (we)
            ram[addr] <= data;
            addr_reg <= addr;
    end

    // Continuous assignment implies read returns NEW data.
    // This is the natural behavior of the TriMatrix memory
    // blocks in Single Port mode.  
    assign q = ram[addr_reg];

endmodule
