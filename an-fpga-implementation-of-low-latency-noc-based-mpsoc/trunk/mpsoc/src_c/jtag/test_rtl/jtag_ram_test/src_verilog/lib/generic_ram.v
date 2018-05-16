/**********************************************************************
**	File:  generic_ram.v
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
**	Generic single dual port ram
**	
**
*******************************************************************/

`timescale 1ns / 1ps


/********************
*	generic_dual_port_ram
********************/

module generic_dual_port_ram #(
    parameter Dw=8, 
    parameter Aw=6,
    parameter BYTE_WR_EN= "YES",//"YES","NO"
    parameter INITIAL_EN= "NO",
    parameter INIT_FILE= "sw/ram/ram0.txt"// ram initial file in hex ascii format
)
(
   data_a,
   data_b,
   addr_a,
   addr_b,
   byteena_a,
   byteena_b,
   we_a,
   we_b,
   clk,
   q_a,
   q_b
);

localparam BYTE_ENw= ( BYTE_WR_EN == "YES")? Dw/8 : 1;

    input [(Dw-1):0] data_a, data_b;
    input [(Aw-1):0] addr_a, addr_b;
    input [BYTE_ENw-1	:	0]	byteena_a, byteena_b;
    input we_a, we_b, clk;
    output  [(Dw-1):0] q_a, q_b;
    
generate 
if   ( BYTE_WR_EN == "NO") begin : no_byten

	dual_port_ram #( 
		.Dw (Dw),
		.Aw (Aw),
		.INITIAL_EN(INITIAL_EN),
		.INIT_FILE(INIT_FILE)
	)
	the_ram
	(
		.data_a     (data_a), 
		.data_b     (data_b),
		.addr_a     (addr_a),
		.addr_b     (addr_b),
		.we_a           (we_a),
		.we_b           (we_b),
		.clk            (clk),
		.q_a            (q_a),
		.q_b            (q_b)
	);

end else begin : byten

   byte_enabled_true_dual_port_ram #(
		.BYTE_WIDTH(8),
		.ADDRESS_WIDTH(Aw),
		.BYTES(Dw/8),
		.INITIAL_EN(INITIAL_EN),
		.INIT_FILE(INIT_FILE)
		
	)
	the_ram
	(
		.addr1		(addr_a),
		.addr2		(addr_b),
		.be1		(byteena_a),
		.be2		(byteena_b),
		.data_in1	(data_a), 
		.data_in2	(data_b), 
		.we1		(we_a),
		.we2		(we_b), 
		.clk		(clk),
		.data_out1	(q_a),
		.data_out2	(q_b)
	);
 end  
endgenerate 
     
endmodule






/********************
*	generic_single_port_ram
********************/



module generic_single_port_ram #(
    parameter Dw=8, 
    parameter Aw=6,
    parameter BYTE_WR_EN= "YES",//"YES","NO"
    parameter INITIAL_EN= "NO",
    parameter INIT_FILE= "sw/ram/ram0.txt"// ram initial file in hex ascii format
)
(
   data,
   addr,
   byteen,
   we,
   clk,
   q
   
);

	localparam BYTE_ENw= ( BYTE_WR_EN == "YES")? Dw/8 : 1;

	input [(Dw-1):0] data;
	input [(Aw-1):0] addr;
	input [BYTE_ENw-1	:	0]	byteen;
	input we, clk;
	output  [(Dw-1):0] q;
    
generate 
if   ( BYTE_WR_EN == "NO") begin : no_byten

	
	single_port_ram #( 
		.Dw (Dw),
		.Aw (Aw),
		.INITIAL_EN(INITIAL_EN),
		.INIT_FILE(INIT_FILE)
	)
	the_ram
	(
		.data     (data), 
		.addr     (addr),
		.we       (we),
		.clk      (clk),
		.q        (q)
	);

end else begin : byten

	byte_enabled_single_port_ram #(
		.BYTE_WIDTH(8),
		.ADDRESS_WIDTH(Aw),
		.BYTES(Dw/8),
		.INITIAL_EN(INITIAL_EN),
		.INIT_FILE(INIT_FILE)
		
	)
	the_ram
	(
		.addr	(addr),
		.be	(byteen),
		.data_in(data), 
		.we	(we),
		.clk	(clk),
		.data_out(q)
	);
end	
endgenerate    
     
endmodule

















/*******************
    
    dual_port_ram

********************/


// Quartus II Verilog Template
// True Dual Port RAM with single clock


module dual_port_ram
#(
    parameter Dw=8, 
    parameter Aw=6,
    parameter INITIAL_EN= "NO",
    parameter INIT_FILE= "sw/ram/ram0.txt"// ram initial file 
)
(
   data_a,
   data_b,
   addr_a,
   addr_b,
   we_a,
   we_b,
   clk,
   q_a,
   q_b
);


    input [(Dw-1):0] data_a, data_b;
    input [(Aw-1):0] addr_a, addr_b;
    input we_a, we_b, clk;
    output  reg [(Dw-1):0] q_a, q_b;

    // Declare the RAM variable
    reg [Dw-1:0] ram[2**Aw-1:0];

	// initial the memory if the file is defined
	generate 
		if (INITIAL_EN == "YES") begin : init
		    initial $readmemh(INIT_FILE,ram);
		end
	endgenerate


    // Port A 
    always @ (posedge clk)
    begin
        if (we_a) 
        begin
            ram[addr_a] <= data_a;
            q_a <= data_a;
        end
        else 
        begin
            q_a <= ram[addr_a];
        end 
    end 

    // Port B 
    always @ (posedge clk)
    begin
        if (we_b) 
        begin
            ram[addr_b] <= data_b;
            q_b <= data_b;
        end
        else 
        begin
            q_b <= ram[addr_b];
        end 
    end

 
   
endmodule



/****************
*simple_dual_port_ram
*
*****************/



// Quartus II Verilog Template
// Simple Dual Port RAM with separate read/write addresses and
// single read/write clock

module simple_dual_port_ram #(
	parameter Dw=8, 
	parameter Aw=6,
        parameter INITIAL_EN= "NO",
	parameter INIT_FILE= "sw/ram/ram0.txt"// ram initial file in hex ascii format
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

	// initial the memory if the file is defined
	generate 
		if (INITIAL_EN == "YES") begin : init
		    initial $readmemh(INIT_FILE,ram);
		end
	endgenerate

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

module single_port_ram #(
    parameter Dw=8,
    parameter Aw=6,
    parameter INITIAL_EN= "NO",
    parameter INIT_FILE= "sw/ram/ram0.txt"// ram initial file in hex ascii format
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

	// initial the memory if the file is defined
	generate 
		if (INITIAL_EN == "YES") begin : init
		    initial $readmemh(INIT_FILE,ram);
		end
	endgenerate

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




