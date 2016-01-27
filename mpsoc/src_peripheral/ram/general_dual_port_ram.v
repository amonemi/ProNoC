/*********************************************************************
							
	File: general_dual_port_ram.v
	
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
	general_dual_port_ram. Does not support 	byte enable

	Info: monemi@fkegraduate.utm.my

****************************************************************/
`timescale 1ns / 1ps



module general_dual_port_ram #(
    parameter Dw    =32, 
    parameter Aw    =10,    
    parameter TAGw  =3
    )
    (
        clk,
        reset,    
        sa_dat_i,sb_dat_i,
        sa_addr_i,sb_addr_i,
        sa_tag_i,sb_tag_i,
        sa_stb_i,sb_stb_i,
        sa_we_i,sb_we_i,
        sa_dat_o,sb_dat_o,
        sa_ack_o,sb_ack_o
    );
    input                               clk;
    input                               reset;
    
    input       [Dw-1       :   0]      sa_dat_i, sb_dat_i;
    input       [Aw-1       :   0]      sa_addr_i, sb_addr_i;
    input       [TAGw-1     :   0]      sa_tag_i, sb_tag_i;
    input                               sa_stb_i,sb_stb_i;
    input                               sa_we_i,sb_we_i;

    output      [Dw-1       :   0]      sa_dat_o, sb_dat_o;
    output                              sa_ack_o,sb_ack_o;
    
    wire        [TAGw-1     :   0]      sa_cti_i, sb_cti_i;
    
    assign  sa_cti_i = sa_tag_i;
    assign  sb_cti_i= sb_tag_i;
    
    wire    [(Dw-1) :0] data_a, data_b;
    wire    [(Aw-1) :0] addr_a, addr_b;
    wire                                 we_a, we_b;
    wire    [(Dw-1) :0] q_a, q_b;
    reg                                  sa_ack_classic, sb_ack_classic,sa_ack_classic_next,sb_ack_classic_next;
    wire                                 sa_ack_burst,sb_ack_burst;
    
    assign sa_dat_o         =   q_a;
    assign data_a           =   sa_dat_i ;
    assign addr_a           =   sa_addr_i;
    assign we_a             =   sa_stb_i &  sa_we_i;
    assign sa_ack_burst     =   sa_stb_i ; //the ack is registerd inside the master in burst mode 
    
    
    assign sa_ack_o = (sa_cti_i == 3'b000 ) ? sa_ack_classic : sa_ack_burst;

    
    
    
    always @(*) begin
        sa_ack_classic_next =  (~sa_ack_o) & sa_stb_i;
    end
    
    always @(posedge clk ) begin
        if(reset) begin 
            sa_ack_classic  <= 1'b0;
        end else begin 
            sa_ack_classic  <= sa_ack_classic_next;
        end     
    end
   
    
    
    
    assign sb_dat_o     =   q_b;
    assign data_b           =   sb_dat_i ;
    assign addr_b           =   sb_addr_i;
    assign we_b             =   sb_stb_i &  sb_we_i;
    assign sb_ack_burst =  sb_stb_i ;
    assign sb_ack_o = (sb_cti_i == 3'b000 ) ? sb_ack_classic : sb_ack_burst;
    
    
    
    always @(*) begin
        sb_ack_classic_next =  (~sb_ack_o) & sb_stb_i;
    end
    
    always @(posedge clk ) begin
        if(reset) begin 
            sb_ack_classic <= 1'b0;
        end else begin 
            sb_ack_classic <= sb_ack_classic_next;      
        end     
    end
    
    
     dual_port_ram
    #( 
        .Dw (Dw),
        .Aw (Aw)
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
        .q_b            (q_b));



   
  
     
     
     
endmodule


/*******************
    
    dual_port_ram

********************/


// Quartus II Verilog Template
// True Dual Port RAM with single clock


module dual_port_ram
#(
    parameter Dw=8, 
    parameter Aw=6 
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

 
    /*
    //synthesis translate_off
    integer i;
    initial begin
    
    for(i=0;i<2**Aw;i=i+1)
        ram[i]=i+ (CORE_NUMBER << 25);
    end //initial
    
    
    //synthesis translate_on
    */
endmodule




