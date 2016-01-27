/*********************************************************************
							
	File: general_single_port_ram.v
	
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
	ram_single_port. General single port ram. Does not support
	byte enable

	Info: monemi@fkegraduate.utm.my

****************************************************************/


`timescale 1ns / 1ps



module  general_single_port_ram #(
	parameter Dw	=32, 
	parameter Aw	=10,	
	parameter TAGw	=3
	
)
(
    clk,
    reset,
	
    //wishbone bus interface
    sa_dat_i,
   // sa_sel_i,
    sa_addr_i,  
    sa_tag_i,
    sa_stb_i,
    sa_cyc_i,
    sa_we_i,    
    sa_dat_o,
    sa_ack_o,
    sa_err_o,
    sa_rty_o
    
);
    input                  clk;
    input                  reset;
    
     
    
     //wishbone bus interface
    input       [Dw-1       :   0]      sa_dat_i;
   // input       [SELw-1     :   0]      sa_sel_i;
    input       [Aw-1       :   0]      sa_addr_i;  
    input       [TAGw-1     :   0]      sa_tag_i;
    input                               sa_stb_i;
    input                               sa_cyc_i;
    input                               sa_we_i;
    
    output      [Dw-1       :   0]      sa_dat_o;
    output                              sa_ack_o;
    output                              sa_err_o;
    output                              sa_rty_o;
    
    
    
    
    wire   [TAGw-1 :   0]   sa_cti_i;
	
	assign  sa_cti_i = sa_tag_i;
	
	
	wire   [Dw-1   :   0]  data_a;
	wire   [Aw-1   :   0]  addr_a;
	wire				   we_a;
	wire   [(Dw-1) :   0]  q_a;
	reg 				   sa_ack_classic, sa_ack_classic_next;
	wire				   sa_ack_burst;
	
	assign sa_dat_o        =   q_a;
	assign data_a          =   sa_dat_i ;
	assign addr_a          =   sa_addr_i;
	assign we_a            =   sa_stb_i &  sa_we_i;
	assign sa_ack_burst	   =   sa_stb_i ; //the ack is registerd inside the master in burst mode 
	assign sa_err_o        =   1'b0;
    assign sa_rty_o        =   1'b0; 
	
	assign sa_ack_o = (sa_cti_i == 3'b000 ) ? sa_ack_classic : sa_ack_burst;

	
	always @(*) begin
		sa_ack_classic_next	=  (~sa_ack_o) & sa_stb_i;
	end
	
	always @(posedge clk ) begin
		if(reset) begin 
			sa_ack_classic	<= 1'b0;
		end else begin 
			sa_ack_classic	<= sa_ack_classic_next;
		end 	
	end
	
	
	
	
	single_port_ram #(
		.Dw(Dw),
		.Aw(Aw)
	)
	single_port_ram(
		.data(data_a),
		.addr(addr_a),
		.we(we_a),
		.clk(clk),
		.q(q_a)
	);
	
	
	 
	 
	 
endmodule



/*****************************

        single_port_ram


*****************************/

// Quartus II Verilog Template
// Single port RAM with single read/write address 

module single_port_ram #(
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


