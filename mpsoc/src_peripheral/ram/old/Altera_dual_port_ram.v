/*********************************************************************
							
	File: Altera_dual_port_ram.v 
	
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
	Altera_dual_port_ram. 

	Info: monemi@fkegraduate.utm.my

****************************************************************/


`timescale 1ns / 1ps



module Altera_dual_port_ram #(
	parameter Dw	=32, 
	parameter Aw	=10,
	parameter TAGw	=3,
	parameter SELw	=4,
	parameter CTIw   =   3,
	parameter BTEw   =   2,
	parameter RAM_TAG_STRING =0 // used only for initialling the memory
	
	
)
(
    clk,
    reset,
	
    //wishbone bus interface
    sa_dat_i,
    sa_sel_i,
    sa_addr_i,  
    sa_tag_i,
    sa_cti_i,
    sa_bte_i,
    sa_stb_i,
    sa_cyc_i,
    sa_we_i,    
    sa_dat_o,
    sa_ack_o,
    sa_err_o,
    sa_rty_o,

    //wishbone bus interface
    sb_dat_i,
    sb_sel_i,
    sb_addr_i,  
    sb_tag_i,
    sb_cti_i,
    sb_bte_i,
    sb_stb_i,
    sb_cyc_i,
    sb_we_i,    
    sb_dat_o,
    sb_ack_o,
    sb_err_o,
    sb_rty_o

    
);
    input                  clk;
    input                  reset;
    
     
    function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
   endfunction // log2 
	
     //wishbone bus interface
    input       [Dw-1       :   0]      sa_dat_i;
    input       [SELw-1     :   0]      sa_sel_i;
    input       [Aw-1       :   0]      sa_addr_i;  
    input       [TAGw-1     :   0]      sa_tag_i;
    input                               sa_stb_i;
    input                               sa_cyc_i;
    input                               sa_we_i;
    input       [CTIw-1     :   0]      sa_cti_i;
    input       [BTEw-1     :   0]      sa_bte_i;
    
    output      [Dw-1       :   0]      sa_dat_o;
    output                              sa_ack_o;
    output                              sa_err_o;
    output                              sa_rty_o;
    
    input       [Dw-1       :   0]      sb_dat_i;
    input       [SELw-1     :   0]      sb_sel_i;
    input       [Aw-1       :   0]      sb_addr_i;  
    input       [TAGw-1     :   0]      sb_tag_i;
    input                               sb_stb_i;
    input                               sb_cyc_i;
    input                               sb_we_i;
    input       [CTIw-1     :   0]      sb_cti_i;
    input       [BTEw-1     :   0]      sb_bte_i;
    
    output      [Dw-1       :   0]      sb_dat_o;
    output                              sb_ack_o;
    output                              sb_err_o;
    output                              sb_rty_o;
    
    
    wire   [TAGw-1 :   0]   sa_cti_i, sb_cti_i;
	
    	
	
	wire   [Dw-1   :   0]  data_a,data_b;
	wire   [Aw-1   :   0]  addr_a,addr_b;
	wire				   we_a,we_b;
	wire   [Dw-1 :   0]  q_a,q_b;

	reg 				   sa_ack_classic, sa_ack_classic_next;
	wire				   sa_ack_ni_burst;
	reg 				   sb_ack_classic, sb_ack_classic_next;
	wire				   sb_ack_ni_burst;
	
	assign sa_dat_o        =   q_a;
	assign data_a          =   sa_dat_i ;
	assign addr_a          =   sa_addr_i;
	assign we_a            =   sa_stb_i &  sa_we_i;
	assign sa_ack_ni_burst =   sa_stb_i ; //the ack is registerd inside the master in burst mode 
	assign sa_err_o        =   1'b0;
	assign sa_rty_o        =   1'b0; 
	 
	assign sb_dat_o        =   q_b;
	assign data_b          =   sb_dat_i ;
	assign addr_b          =   sb_addr_i;
	assign we_b            =   sb_stb_i &  sb_we_i;
	assign sb_ack_ni_burst =   sb_stb_i ; //the ack is registerd inside the master in burst mode 
	assign sb_err_o        =   1'b0;
	assign sb_rty_o        =   1'b0; 
	 
	 
	// 3'b100 is reserved in wb4 interface. It used for ni
	assign sa_ack_o = (sa_cti_i == 3'b100 ) ?  sa_ack_ni_burst: sa_ack_classic;
	assign sb_ack_o = (sb_cti_i == 3'b100 ) ?  sb_ack_ni_burst: sb_ack_classic;
 
	localparam	CLASSIC =3'b000,
			CONSTANT_BURST = 3'b001, 
			INCRMNT_BURST  = 3'b010,
			END_BURST = 3'b111;

	always @(*) begin
		case(sa_cti_i)
			CLASSIC: 	sa_ack_classic_next	=  (~sa_ack_o) & sa_stb_i;
			default:	sa_ack_classic_next	=   sa_stb_i;
		endcase
	end

	always @(*) begin
		case(sb_cti_i)
			CLASSIC: 	sb_ack_classic_next	=  (~sb_ack_o) & sb_stb_i;
			default:	sb_ack_classic_next	=   sb_stb_i;
		endcase
	end
	
	always @(posedge clk ) begin
		if(reset) begin 
			sa_ack_classic	<= 1'b0;
			sb_ack_classic	<= 1'b0;
		end else begin 
			sa_ack_classic	<= sa_ack_classic_next;
			sb_ack_classic	<= sb_ack_classic_next;
		end 	
	end
	





`ifdef MODEL_TECH  
    localparam  INIT_FILE   = {"../../sw/ram",RAM_TAG_STRING,".mif"};
`else       
    localparam  INIT_FILE   = {"sw/ram",RAM_TAG_STRING,".mif"};
`endif  
	

	localparam  RAM_ID = {"ENABLE_RUNTIME_MOD=NO"};
	

// aletra dual port ram 
	altsyncram #(
		.operation_mode("BIDIR_DUAL_PORT"),
		.address_reg_b("CLOCK0"),
		.wrcontrol_wraddress_reg_b("CLOCK0"),
		.indata_reg_b("CLOCK0"),
		.outdata_reg_a("UNREGISTERED"),
		.outdata_reg_b("UNREGISTERED"),
		.width_a(Dw),
		.width_b(Dw),
		.lpm_hint(RAM_ID),
		.read_during_write_mode_mixed_ports("DONT_CARE"),
		.widthad_a(Aw),
		.widthad_b(Aw),
		.width_byteena_a(4),
		.init_file(INIT_FILE)
	
	) ram_inst(
		.clock0			(clk),
		
		.address_a		(addr_a),
		.wren_a			(we_a),
		.data_a			(data_a),
		.q_a			(q_a),
		.byteena_a      	(sa_sel_i),		 
		
		
		.address_b		(addr_b),
		.wren_b			(we_b),
		.data_b			(data_b),
		.q_b			(q_b),
		.byteena_b		(1'b1),		
		

		.rden_a 		(1'b1),
		.rden_b			(1'b1),
		.clock1			(1'b1),
		.clocken0 		(1'b1),
		.clocken1 		(1'b1),
		.clocken2 		(1'b1),
		.clocken3 		(1'b1),
		.aclr0			(1'b0),
		.aclr1			(1'b0),		
		.addressstall_a		(1'b0),
		.addressstall_b 	(1'b0),
		.eccstatus		(    )
	);




	
	

endmodule



