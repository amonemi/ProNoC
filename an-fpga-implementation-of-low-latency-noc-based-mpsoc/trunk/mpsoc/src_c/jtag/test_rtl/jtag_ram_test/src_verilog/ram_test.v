
/**************************************************************************
**	WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
**	OVERWRITTEN AND LOST. Rename this file if you wish to do any modification.
****************************************************************************/


/**********************************************************************
**	File: ram_test.v
**    
**	Copyright (C) 2014-2018  Alireza Monemi
**    
**	This file is part of ProNoC 1.7.0 
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
******************************************************************************/ 

`timescale 1ns / 1ps
module ram_test #(
 	parameter	CORE_ID=0,
	parameter	SW_LOC="/home/alireza/mywork/mpsoc_work/SOC/ram_test/sw" ,
	parameter	ram_Dw=32 ,
	parameter	ram_Aw=12
)(
	ss_clk_in, 
	ss_reset_in
);
  
  	function integer log2;
  		input integer number; begin	
          	log2=0;	
          	while(2**log2<number) begin	
        		  	log2=log2+1;	
         		end	
        		end	
     	endfunction // log2 
     	
     	function   [15:0]i2s;   
          input   integer c;  integer i;  integer tmp; begin 
              tmp =0; 
              for (i=0; i<2; i=i+1'b1) begin 
              tmp =  tmp +    (((c % 10)   + 6'd48) << i*8); 
                  c       =   c/10; 
              end 
              i2s = tmp[15:0];
          end     
     endfunction //i2s
  
 	localparam	programer_DW=32;
	localparam	programer_AW=32;
	localparam	programer_S_Aw=   7;
	localparam	programer_M_Aw=   32;
	localparam	programer_TAGw=   3;
	localparam	programer_SELw=   4;
	localparam	programer_VJTAG_INDEX=CORE_ID;

 	localparam	ram_BYTE_WR_EN="YES";
	localparam	ram_FPGA_VENDOR="ALTERA";
	localparam	ram_JTAG_CONNECT= "ALTERA_IMCE";
	localparam	ram_JTAG_INDEX=CORE_ID;
	localparam	ram_TAGw=3;
	localparam	ram_SELw=ram_Dw/8;
	localparam	ram_CTIw=3;
	localparam	ram_BTEw=2;
	localparam	ram_BURST_MODE="DISABLED";
	localparam	ram_MEM_CONTENT_FILE_NAME="ram0";
	localparam	ram_INITIAL_EN="NO";
	localparam	ram_INIT_FILE_PATH=SW_LOC;

 	localparam	bus_M=1;
	localparam	bus_S=1;
	localparam	bus_Dw=32;
	localparam	bus_Aw=32;
	localparam	bus_SELw=bus_Dw/8;
	localparam	bus_TAGw=3;
	localparam	bus_CTIw=3;
	localparam	bus_BTEw=2 ;

 
//Wishbone slave base address based on instance name
 	localparam 	ram_WB0_BASE_ADDR	=	32'h00000000;
 	localparam 	ram_WB0_END_ADDR	=	32'h00000fff;
 
 
//Wishbone slave base address based on module name. 
 	localparam 	single_port_ram0_WB0_BASE_ADDR	=	32'h00000000;
 	localparam 	single_port_ram0_WB0_END_ADDR	=	32'h00000fff;
 
 	input			ss_clk_in;
 	input			ss_reset_in;

  	wire			 ss_socket_clk_0_clk_o;
 	wire			 ss_socket_reset_0_reset_o;

  	wire			 programer_plug_clk_0_clk_i;
 	wire			 programer_plug_wb_master_0_ack_i;
 	wire	[ programer_M_Aw-1          :   0 ] programer_plug_wb_master_0_adr_o;
 	wire	[ programer_TAGw-1          :   0 ] programer_plug_wb_master_0_cti_o;
 	wire			 programer_plug_wb_master_0_cyc_o;
 	wire	[ programer_DW-1           :  0 ] programer_plug_wb_master_0_dat_i;
 	wire	[ programer_DW-1            :   0 ] programer_plug_wb_master_0_dat_o;
 	wire	[ programer_SELw-1          :   0 ] programer_plug_wb_master_0_sel_o;
 	wire			 programer_plug_wb_master_0_stb_o;
 	wire			 programer_plug_wb_master_0_we_o;
 	wire			 programer_plug_reset_0_reset_i;

  	wire			 ram_plug_clk_0_clk_i;
 	wire			 ram_plug_reset_0_reset_i;
 	wire			 ram_plug_wb_slave_0_ack_o;
 	wire	[ ram_Aw-1       :   0 ] ram_plug_wb_slave_0_adr_i;
 	wire	[ ram_BTEw-1     :   0 ] ram_plug_wb_slave_0_bte_i;
 	wire	[ ram_CTIw-1     :   0 ] ram_plug_wb_slave_0_cti_i;
 	wire			 ram_plug_wb_slave_0_cyc_i;
 	wire	[ ram_Dw-1       :   0 ] ram_plug_wb_slave_0_dat_i;
 	wire	[ ram_Dw-1       :   0 ] ram_plug_wb_slave_0_dat_o;
 	wire			 ram_plug_wb_slave_0_err_o;
 	wire			 ram_plug_wb_slave_0_rty_o;
 	wire	[ ram_SELw-1     :   0 ] ram_plug_wb_slave_0_sel_i;
 	wire			 ram_plug_wb_slave_0_stb_i;
 	wire	[ ram_TAGw-1     :   0 ] ram_plug_wb_slave_0_tag_i;
 	wire			 ram_plug_wb_slave_0_we_i;

  	wire			 bus_plug_clk_0_clk_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_ack_o;
 	wire			 bus_socket_wb_master_0_ack_o;
 	wire	[ bus_Aw*bus_M-1      :   0 ] bus_socket_wb_master_array_adr_i;
 	wire	[ bus_Aw-1:0 ] bus_socket_wb_master_0_adr_i;
 	wire	[ bus_BTEw*bus_M-1    :   0 ] bus_socket_wb_master_array_bte_i;
 	wire	[ bus_BTEw-1:0 ] bus_socket_wb_master_0_bte_i;
 	wire	[ bus_CTIw*bus_M-1    :   0 ] bus_socket_wb_master_array_cti_i;
 	wire	[ bus_CTIw-1:0 ] bus_socket_wb_master_0_cti_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_cyc_i;
 	wire			 bus_socket_wb_master_0_cyc_i;
 	wire	[ bus_Dw*bus_M-1      :   0 ] bus_socket_wb_master_array_dat_i;
 	wire	[ bus_Dw-1:0 ] bus_socket_wb_master_0_dat_i;
 	wire	[ bus_Dw*bus_M-1      :   0 ] bus_socket_wb_master_array_dat_o;
 	wire	[ bus_Dw-1:0 ] bus_socket_wb_master_0_dat_o;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_err_o;
 	wire			 bus_socket_wb_master_0_err_o;
 	wire	[ bus_Aw-1       :   0 ] bus_socket_wb_addr_map_0_grant_addr;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_rty_o;
 	wire			 bus_socket_wb_master_0_rty_o;
 	wire	[ bus_SELw*bus_M-1    :   0 ] bus_socket_wb_master_array_sel_i;
 	wire	[ bus_SELw-1:0 ] bus_socket_wb_master_0_sel_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_stb_i;
 	wire			 bus_socket_wb_master_0_stb_i;
 	wire	[ bus_TAGw*bus_M-1    :   0 ] bus_socket_wb_master_array_tag_i;
 	wire	[ bus_TAGw-1:0 ] bus_socket_wb_master_0_tag_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_we_i;
 	wire			 bus_socket_wb_master_0_we_i;
 	wire			 bus_plug_reset_0_reset_i;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_ack_i;
 	wire			 bus_socket_wb_slave_0_ack_i;
 	wire	[ bus_Aw*bus_S-1      :   0 ] bus_socket_wb_slave_array_adr_o;
 	wire	[ bus_Aw-1:0 ] bus_socket_wb_slave_0_adr_o;
 	wire	[ bus_BTEw*bus_S-1    :   0 ] bus_socket_wb_slave_array_bte_o;
 	wire	[ bus_BTEw-1:0 ] bus_socket_wb_slave_0_bte_o;
 	wire	[ bus_CTIw*bus_S-1    :   0 ] bus_socket_wb_slave_array_cti_o;
 	wire	[ bus_CTIw-1:0 ] bus_socket_wb_slave_0_cti_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_cyc_o;
 	wire			 bus_socket_wb_slave_0_cyc_o;
 	wire	[ bus_Dw*bus_S-1      :   0 ] bus_socket_wb_slave_array_dat_i;
 	wire	[ bus_Dw-1:0 ] bus_socket_wb_slave_0_dat_i;
 	wire	[ bus_Dw*bus_S-1      :   0 ] bus_socket_wb_slave_array_dat_o;
 	wire	[ bus_Dw-1:0 ] bus_socket_wb_slave_0_dat_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_err_i;
 	wire			 bus_socket_wb_slave_0_err_i;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_rty_i;
 	wire			 bus_socket_wb_slave_0_rty_i;
 	wire	[ bus_SELw*bus_S-1    :   0 ] bus_socket_wb_slave_array_sel_o;
 	wire	[ bus_SELw-1:0 ] bus_socket_wb_slave_0_sel_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_addr_map_0_sel_one_hot;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_stb_o;
 	wire			 bus_socket_wb_slave_0_stb_o;
 	wire	[ bus_TAGw*bus_S-1    :   0 ] bus_socket_wb_slave_array_tag_o;
 	wire	[ bus_TAGw-1:0 ] bus_socket_wb_slave_0_tag_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_we_o;
 	wire			 bus_socket_wb_slave_0_we_o;

 
//Take the default value for ports that defined by interfaces but did not assigned to any wires.
 	assign bus_socket_wb_master_0_bte_i = {bus_BTEw{1'b0}};
 	assign bus_socket_wb_master_0_tag_i = {bus_TAGw{1'b0}};


 clk_source  ss 	(
		.clk_in(ss_clk_in),
		.clk_out(ss_socket_clk_0_clk_o),
		.reset_in(ss_reset_in),
		.reset_out(ss_socket_reset_0_reset_o)
	);
 vjtag_wb #(
 		.DW(programer_DW),
		.AW(programer_AW),
		.S_Aw(programer_S_Aw),
		.M_Aw(programer_M_Aw),
		.TAGw(programer_TAGw),
		.SELw(programer_SELw),
		.VJTAG_INDEX(programer_VJTAG_INDEX)
	)  programer 	(
		.clk(programer_plug_clk_0_clk_i),
		.m_ack_i(programer_plug_wb_master_0_ack_i),
		.m_addr_o(programer_plug_wb_master_0_adr_o),
		.m_cti_o(programer_plug_wb_master_0_cti_o),
		.m_cyc_o(programer_plug_wb_master_0_cyc_o),
		.m_dat_i(programer_plug_wb_master_0_dat_i),
		.m_dat_o(programer_plug_wb_master_0_dat_o),
		.m_sel_o(programer_plug_wb_master_0_sel_o),
		.m_stb_o(programer_plug_wb_master_0_stb_o),
		.m_we_o(programer_plug_wb_master_0_we_o),
		.reset(programer_plug_reset_0_reset_i),
		.status_i()
	);
 wb_single_port_ram #(
 		.Dw(ram_Dw),
		.Aw(ram_Aw),
		.BYTE_WR_EN(ram_BYTE_WR_EN),
		.FPGA_VENDOR(ram_FPGA_VENDOR),
		.JTAG_CONNECT(ram_JTAG_CONNECT),
		.JTAG_INDEX(1),
		.TAGw(ram_TAGw),
		.SELw(ram_SELw),
		.CTIw(ram_CTIw),
		.BTEw(ram_BTEw),
		.BURST_MODE(ram_BURST_MODE),
		.MEM_CONTENT_FILE_NAME(ram_MEM_CONTENT_FILE_NAME),
		.INITIAL_EN(ram_INITIAL_EN),
		.INIT_FILE_PATH(ram_INIT_FILE_PATH)
	)  ram 	(
		.clk(ram_plug_clk_0_clk_i),
		.reset(ram_plug_reset_0_reset_i),
		.sa_ack_o(ram_plug_wb_slave_0_ack_o),
		.sa_addr_i(ram_plug_wb_slave_0_adr_i),
		.sa_bte_i(ram_plug_wb_slave_0_bte_i),
		.sa_cti_i(ram_plug_wb_slave_0_cti_i),
		.sa_cyc_i(ram_plug_wb_slave_0_cyc_i),
		.sa_dat_i(ram_plug_wb_slave_0_dat_i),
		.sa_dat_o(ram_plug_wb_slave_0_dat_o),
		.sa_err_o(ram_plug_wb_slave_0_err_o),
		.sa_rty_o(ram_plug_wb_slave_0_rty_o),
		.sa_sel_i(ram_plug_wb_slave_0_sel_i),
		.sa_stb_i(ram_plug_wb_slave_0_stb_i),
		.sa_tag_i(ram_plug_wb_slave_0_tag_i),
		.sa_we_i(ram_plug_wb_slave_0_we_i)
	);
 wishbone_bus #(
 		.M(bus_M),
		.S(bus_S),
		.Dw(bus_Dw),
		.Aw(bus_Aw),
		.SELw(bus_SELw),
		.TAGw(bus_TAGw),
		.CTIw(bus_CTIw),
		.BTEw(bus_BTEw)
	)  bus 	(
		.clk(bus_plug_clk_0_clk_i),
		.m_ack_o_all(bus_socket_wb_master_array_ack_o),
		.m_adr_i_all(bus_socket_wb_master_array_adr_i),
		.m_bte_i_all(bus_socket_wb_master_array_bte_i),
		.m_cti_i_all(bus_socket_wb_master_array_cti_i),
		.m_cyc_i_all(bus_socket_wb_master_array_cyc_i),
		.m_dat_i_all(bus_socket_wb_master_array_dat_i),
		.m_dat_o_all(bus_socket_wb_master_array_dat_o),
		.m_err_o_all(bus_socket_wb_master_array_err_o),
		.m_grant_addr(bus_socket_wb_addr_map_0_grant_addr),
		.m_rty_o_all(bus_socket_wb_master_array_rty_o),
		.m_sel_i_all(bus_socket_wb_master_array_sel_i),
		.m_stb_i_all(bus_socket_wb_master_array_stb_i),
		.m_tag_i_all(bus_socket_wb_master_array_tag_i),
		.m_we_i_all(bus_socket_wb_master_array_we_i),
		.reset(bus_plug_reset_0_reset_i),
		.s_ack_i_all(bus_socket_wb_slave_array_ack_i),
		.s_adr_o_all(bus_socket_wb_slave_array_adr_o),
		.s_bte_o_all(bus_socket_wb_slave_array_bte_o),
		.s_cti_o_all(bus_socket_wb_slave_array_cti_o),
		.s_cyc_o_all(bus_socket_wb_slave_array_cyc_o),
		.s_dat_i_all(bus_socket_wb_slave_array_dat_i),
		.s_dat_o_all(bus_socket_wb_slave_array_dat_o),
		.s_err_i_all(bus_socket_wb_slave_array_err_i),
		.s_rty_i_all(bus_socket_wb_slave_array_rty_i),
		.s_sel_o_all(bus_socket_wb_slave_array_sel_o),
		.s_sel_one_hot(bus_socket_wb_addr_map_0_sel_one_hot),
		.s_stb_o_all(bus_socket_wb_slave_array_stb_o),
		.s_tag_o_all(bus_socket_wb_slave_array_tag_o),
		.s_we_o_all(bus_socket_wb_slave_array_we_o)
	);
 

 
 	assign  programer_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  programer_plug_wb_master_0_ack_i = bus_socket_wb_master_0_ack_o;
 	assign  bus_socket_wb_master_0_adr_i  = programer_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_0_cti_i  = programer_plug_wb_master_0_cti_o;
 	assign  bus_socket_wb_master_0_cyc_i  = programer_plug_wb_master_0_cyc_o;
 	assign  programer_plug_wb_master_0_dat_i = bus_socket_wb_master_0_dat_o[programer_DW-1           :  0];
 	assign  bus_socket_wb_master_0_dat_i  = programer_plug_wb_master_0_dat_o;
 	assign  bus_socket_wb_master_0_sel_i  = programer_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_0_stb_i  = programer_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_0_we_i  = programer_plug_wb_master_0_we_o;
 	assign  programer_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;

 
 	assign  ram_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  ram_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_0_ack_i  = ram_plug_wb_slave_0_ack_o;
 	assign  ram_plug_wb_slave_0_adr_i = bus_socket_wb_slave_0_adr_o[ram_Aw-1       :   0];
 	assign  ram_plug_wb_slave_0_bte_i = bus_socket_wb_slave_0_bte_o[ram_BTEw-1     :   0];
 	assign  ram_plug_wb_slave_0_cti_i = bus_socket_wb_slave_0_cti_o[ram_CTIw-1     :   0];
 	assign  ram_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_0_cyc_o;
 	assign  ram_plug_wb_slave_0_dat_i = bus_socket_wb_slave_0_dat_o[ram_Dw-1       :   0];
 	assign  bus_socket_wb_slave_0_dat_i  = ram_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_err_i  = ram_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_0_rty_i  = ram_plug_wb_slave_0_rty_o;
 	assign  ram_plug_wb_slave_0_sel_i = bus_socket_wb_slave_0_sel_o[ram_SELw-1     :   0];
 	assign  ram_plug_wb_slave_0_stb_i = bus_socket_wb_slave_0_stb_o;
 	assign  ram_plug_wb_slave_0_tag_i = bus_socket_wb_slave_0_tag_o[ram_TAGw-1     :   0];
 	assign  ram_plug_wb_slave_0_we_i = bus_socket_wb_slave_0_we_o;

 
 	assign  bus_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  bus_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;

 	assign bus_socket_wb_master_0_ack_o = bus_socket_wb_master_array_ack_o;
 	assign bus_socket_wb_master_array_adr_i = bus_socket_wb_master_0_adr_i;
 	assign bus_socket_wb_master_array_bte_i = bus_socket_wb_master_0_bte_i;
 	assign bus_socket_wb_master_array_cti_i = bus_socket_wb_master_0_cti_i;
 	assign bus_socket_wb_master_array_cyc_i = bus_socket_wb_master_0_cyc_i;
 	assign bus_socket_wb_master_array_dat_i = bus_socket_wb_master_0_dat_i;
 	assign bus_socket_wb_master_0_dat_o = bus_socket_wb_master_array_dat_o;
 	assign bus_socket_wb_master_0_err_o = bus_socket_wb_master_array_err_o;
 	assign bus_socket_wb_master_0_rty_o = bus_socket_wb_master_array_rty_o;
 	assign bus_socket_wb_master_array_sel_i = bus_socket_wb_master_0_sel_i;
 	assign bus_socket_wb_master_array_stb_i = bus_socket_wb_master_0_stb_i;
 	assign bus_socket_wb_master_array_tag_i = bus_socket_wb_master_0_tag_i;
 	assign bus_socket_wb_master_array_we_i = bus_socket_wb_master_0_we_i;
 	assign bus_socket_wb_slave_array_ack_i = bus_socket_wb_slave_0_ack_i;
 	assign bus_socket_wb_slave_0_adr_o = bus_socket_wb_slave_array_adr_o;
 	assign bus_socket_wb_slave_0_bte_o = bus_socket_wb_slave_array_bte_o;
 	assign bus_socket_wb_slave_0_cti_o = bus_socket_wb_slave_array_cti_o;
 	assign bus_socket_wb_slave_0_cyc_o = bus_socket_wb_slave_array_cyc_o;
 	assign bus_socket_wb_slave_array_dat_i = bus_socket_wb_slave_0_dat_i;
 	assign bus_socket_wb_slave_0_dat_o = bus_socket_wb_slave_array_dat_o;
 	assign bus_socket_wb_slave_array_err_i = bus_socket_wb_slave_0_err_i;
 	assign bus_socket_wb_slave_array_rty_i = bus_socket_wb_slave_0_rty_i;
 	assign bus_socket_wb_slave_0_sel_o = bus_socket_wb_slave_array_sel_o;
 	assign bus_socket_wb_slave_0_stb_o = bus_socket_wb_slave_array_stb_o;
 	assign bus_socket_wb_slave_0_tag_o = bus_socket_wb_slave_array_tag_o;
 	assign bus_socket_wb_slave_0_we_o = bus_socket_wb_slave_array_we_o;

 
//Wishbone slave address match
 /* ram wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[0] = ((bus_socket_wb_addr_map_0_grant_addr >= ram_WB0_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr <= ram_WB0_END_ADDR));
 endmodule

