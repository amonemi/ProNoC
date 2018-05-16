
/**********************************************************************
**	File:  ni_slave.v 
**	Date:2017-06-30  
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
**	NI with internal input/output memory. generated using NI_master 
**	connected to two dualport memory
**	
**
*******************************************************************/

`timescale  1ns/1ps

module  ni_slave #(
    parameter MAX_TRANSACTION_WIDTH=10, // Maximum transaction size will be 2 power of MAX_DMA_TRANSACTION_WIDTH words 
    parameter INPUT_MEM_Aw = 10, // input mmeory address width 
    parameter OUTPUT_MEM_Aw = 10, // input mmeory address width 
    parameter MAX_BURST_SIZE =256, // in words
    parameter DEBUG_EN = 1, 
    //NoC parameters
    parameter CLASS_HDR_WIDTH     =8,
    parameter ROUTING_HDR_WIDTH   =8,
    parameter DST_ADR_HDR_WIDTH  =8,
    parameter SRC_ADR_HDR_WIDTH   =8,
    parameter TOPOLOGY =    "MESH",//"MESH","TORUS","RING" 
    parameter ROUTE_NAME    =   "XY",
    parameter NX = 4,   // number of node in x axis
    parameter NY = 4,   // number of node in y axis
    parameter C = 4,    //  number of flit class 
    parameter V=4,
    parameter B = 4,
    parameter Fpay = 32,
    parameter CRC_EN= "NO",// "YES","NO" if CRC is enable then the CRC32 of all packet data is calculated and sent via tail flit. 
    parameter SWA_ARBITER_TYPE = "RRA", // RRA WRRA
    parameter WEIGHTw          = 4, // weight width of WRRA
   
    //wishbone port parameters
    parameter Dw            =   32,
    parameter S_Aw          =   7,
    parameter M_Aw          =   32,
    parameter TAGw          =   3,
    parameter SELw          =   4


)
(
    // global 
    reset,
    clk,
    
    //noc interface  
    current_x,
    current_y,   
    flit_out,     
    flit_out_wr,   
    credit_in,
    flit_in,   
    flit_in_wr,   
    credit_out,     
     
    //wishbone slave control registers interface 
    ctrl_dat_i,
    ctrl_sel_i,
    ctrl_addr_i,  
    ctrl_cti_i,
    ctrl_stb_i,
    ctrl_cyc_i,
    ctrl_we_i,    
    ctrl_dat_o,
    ctrl_ack_o,
    
    //wishbone slave input buffer interface 
    in_dat_i,
    in_sel_i,
    in_addr_i,  
    in_cti_i,
    in_stb_i,
    in_cyc_i,
    in_we_i,    
    in_dat_o,
    in_ack_o,
    
    //wishbone slave output buffer interface 
    out_dat_i,
    out_sel_i,
    out_addr_i,  
    out_cti_i,
    out_stb_i,
    out_cyc_i,
    out_we_i,    
    out_dat_o,
    out_ack_o,
    
     //intruupt interface
    irq       
);


      

    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 

     localparam Fw     =    2+V+Fpay, //flit width
                Xw =   log2(NX),
                Yw =   log2(NY);


    input reset,clk;
    output irq;    
    
      // NOC interfaces
    input   [Xw-1   :   0]  current_x;
    input   [Yw-1   :   0]  current_y;
    output  [Fw-1   :   0]  flit_out;     
    output                  flit_out_wr;   
    input   [V-1    :   0]  credit_in;
    input   [Fw-1   :   0]  flit_in; 
    input                   flit_in_wr;   
    output  [V-1    :   0]  credit_out;     
    

    input   [Dw-1       :   0]      ctrl_dat_i;
    input   [SELw-1     :   0]      ctrl_sel_i;
    input   [S_Aw-1     :   0]      ctrl_addr_i;  
    input   [TAGw-1     :   0]      ctrl_cti_i;
    input                           ctrl_stb_i;
    input                           ctrl_cyc_i;
    input                           ctrl_we_i;    
    output  [Dw-1       :   0]      ctrl_dat_o;
    output                          ctrl_ack_o;


    input   [Dw-1       :   0]      in_dat_i;
    input   [SELw-1     :   0]      in_sel_i;
    input   [S_Aw-1     :   0]      in_addr_i;  
    input   [TAGw-1     :   0]      in_cti_i;
    input                           in_stb_i;
    input                           in_cyc_i;
    input                           in_we_i;
    output  [Dw-1       :   0]      in_dat_o;
    output                          in_ack_o;


    input   [Dw-1       :   0]      out_dat_i;
    input   [SELw-1     :   0]      out_sel_i;
    input   [S_Aw-1     :   0]      out_addr_i;  
    input   [TAGw-1     :   0]      out_cti_i;
    input                           out_stb_i;
    input                           out_cyc_i;
    input                           out_we_i;
    output  [Dw-1       :   0]      out_dat_o;
    output                          out_ack_o;



    //wishbone read master interface signals
    wire  [SELw-1          :   0] m_send_sel_o;
    wire  [M_Aw-1          :   0] m_send_addr_o;
    wire  [TAGw-1          :   0] m_send_cti_o;
    wire                          m_send_stb_o;
    wire                          m_send_cyc_o;
    wire                          m_send_we_o;
    wire   [Dw-1           :  0]  m_send_dat_i;
    wire                          m_send_ack_i;    
     
     //wishbone write master interface signals
    wire  [SELw-1          :   0] m_receive_sel_o;
    wire  [Dw-1            :   0] m_receive_dat_o;
    wire  [M_Aw-1          :   0] m_receive_addr_o;
    wire  [TAGw-1          :   0] m_receive_cti_o;
    wire                          m_receive_stb_o;
    wire                          m_receive_cyc_o;
    wire                          m_receive_we_o;
    wire                          m_receive_ack_i;   

	ni_master #(
		.MAX_TRANSACTION_WIDTH(MAX_TRANSACTION_WIDTH),
		.MAX_BURST_SIZE(MAX_BURST_SIZE),
		.DEBUG_EN(DEBUG_EN),
		.CLASS_HDR_WIDTH(CLASS_HDR_WIDTH),
		.ROUTING_HDR_WIDTH(ROUTING_HDR_WIDTH),
		.DST_ADR_HDR_WIDTH(DST_ADR_HDR_WIDTH),
		.SRC_ADR_HDR_WIDTH(SRC_ADR_HDR_WIDTH),
		.TOPOLOGY(TOPOLOGY),
		.ROUTE_NAME(ROUTE_NAME),
		.NX(NX),
		.NY(NY),
		.C(C),
		.V(V),
		.B(B),
		.Fpay(Fpay),
		.CRC_EN(CRC_EN),
		.Dw(Dw),
		.S_Aw(S_Aw),
		.M_Aw(M_Aw),
		.TAGw(TAGw),
		.SELw(SELw),
		.SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
		.WEIGHTw(WEIGHTw)
	)
	ni_master
	(
		.reset(reset),
		.clk(clk),
		.current_x(current_x),
		.current_y(current_y),
		.flit_out(flit_out),
		.flit_out_wr(flit_out_wr),
		.credit_in(credit_in),
		.flit_in(flit_in),
		.flit_in_wr(flit_in_wr),
		.credit_out(credit_out),
		.s_dat_i(ctrl_dat_i),
		.s_sel_i(ctrl_sel_i),
		.s_addr_i(ctrl_addr_i),
		.s_cti_i(ctrl_cti_i),
		.s_stb_i(ctrl_stb_i),
		.s_cyc_i(ctrl_cyc_i),
		.s_we_i(ctrl_we_i),
		.s_dat_o(ctrl_dat_o),
		.s_ack_o(ctrl_ack_o),
		.m_send_sel_o(m_send_sel_o),
		.m_send_addr_o(m_send_addr_o),
		.m_send_cti_o(m_send_cti_o),
		.m_send_stb_o(m_send_stb_o),
		.m_send_cyc_o(m_send_cyc_o),
		.m_send_we_o(m_send_we_o),
		.m_send_dat_i(m_send_dat_i),
		.m_send_ack_i(m_send_ack_i),
		.m_receive_sel_o(m_receive_sel_o),
		.m_receive_dat_o(m_receive_dat_o),
		.m_receive_addr_o(m_receive_addr_o),
		.m_receive_cti_o(m_receive_cti_o),
		.m_receive_stb_o(m_receive_stb_o),
		.m_receive_cyc_o(m_receive_cyc_o),
		.m_receive_we_o(m_receive_we_o),
		.m_receive_ack_i(m_receive_ack_i),
		.irq(irq)
	);




wb_dual_port_ram #(
	.INITIAL_EN("NO"),
	.Dw(Dw),
	.Aw(INPUT_MEM_Aw),
	.BYTE_WR_EN("NO"),
	.FPGA_VENDOR("GENERIC"),
	.PORT_A_BURST_MODE("ENABLED"),
	.PORT_B_BURST_MODE("ENABLED"),
	.TAGw(3),
	.SELw(4),
	.CTIw(3),
	.BTEw(2)
)
output_buffer
(
	.clk(clk),
	.reset(reset),
	.sa_dat_i(in_dat_i),
    .sb_dat_i(),
    .sa_sel_i(in_sel_i),
    .sb_sel_i(m_send_sel_o),
    .sa_addr_i(in_addr_i),
    .sb_addr_i(m_send_addr_o),
    .sa_stb_i(in_stb_i),
    .sb_stb_i(m_send_stb_o),
    .sa_cyc_i(in_cyc_i),
    .sb_cyc_i(m_send_cyc_o),
    .sa_we_i(in_we_i),
    .sb_we_i(m_send_we_o),
    .sa_cti_i(in_cti_i),
    .sb_cti_i(m_send_cti_o),
    .sa_bte_i(4'b0000),
    .sb_bte_i(4'b0000),
    .sa_dat_o(in_dat_o),
    .sb_dat_o(m_send_dat_i),
    .sa_ack_o(in_ack_o),
    .sb_ack_o(m_send_ack_i),
    .sa_tag_i(),
    .sb_tag_i(),
    .sa_err_o( ),
    .sb_err_o( ),
    .sa_rty_o( ),
    .sb_rty_o( )
);



wb_dual_port_ram #(
    .INITIAL_EN("NO"),
    .Dw(Dw),
    .Aw(OUTPUT_MEM_Aw),
    .BYTE_WR_EN("NO"),
    .FPGA_VENDOR("GENERIC"),
    .PORT_A_BURST_MODE("ENABLED"),
    .PORT_B_BURST_MODE("ENABLED"),
    .TAGw(3),
    .SELw(4),
    .CTIw(3),
    .BTEw(2)
)
input_buffer
(
    .clk(clk),
    .reset(reset),
    .sa_dat_i(out_dat_i),
    .sb_dat_i(m_receive_dat_o),
    .sa_sel_i(out_sel_i),
    .sb_sel_i(m_receive_sel_o),
    .sa_addr_i(out_addr_i),
    .sb_addr_i(m_receive_addr_o), 
    .sa_stb_i(out_stb_i),
    .sb_stb_i(m_receive_stb_o),
    .sa_cyc_i(out_cyc_i),
    .sb_cyc_i(m_receive_cyc_o),
    .sa_we_i(out_we_i),
    .sb_we_i(m_receive_we_o),
    .sa_cti_i(out_cti_i),
    .sb_cti_i(m_receive_cti_o),
    .sa_bte_i( 4'b0000),
    .sb_bte_i( 4'b0000),
    .sa_dat_o(out_dat_o),
    .sb_dat_o(),
    .sa_ack_o(out_ack_o),
    .sb_ack_o(m_receive_ack_i),
    .sa_tag_i( ),
    .sb_tag_i( ),
    .sa_err_o( ),
    .sb_err_o( ),
    .sa_rty_o( ),
    .sb_rty_o( )

);




endmodule

