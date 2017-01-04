/**************************************
* Module: ni_sep
* Date:2016-10-03  
* Author: alireza     
*
* Description: 
***************************************/




/**********************************************************************
    File: ni.v 
    
    Copyright (C) 2013  Alireza Monemi

    This AUTOram is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This AUTOram is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this AUTOram.  If not, see <http://www.gnu.org/licenses/>.
    
    
    Purpose:
    A DMA based NI for connecting the NoC router to a processor. The NI has 3 
    memory mapped registers:
         // ni status register
    STATUS_ADDR          =   0,
    // update memory pinter, packet size and send packet read command. If memory pointer and packet size width are smaller than COMB_MEM_PTR_W and COMB_PCK_SIZE_W respectively.
    RD_MEM_PCKSIZ_ADDR   =   1,  
    // update memory pinter, packet size and send packet write command. If memory pointer and packet size width are smaller than COMB_MEM_PTR_W and COMB_PCK_SIZE_W respectively.
    WR_MEM_PCKSIZ_ADDR   =   2,      
    //update packet size  
    PCK_SIZE_ADDR        =   3,
    //update the memory pointer address and send read command. The packet size must be updated before setting this register. use it when memory pointer width is larger than COMB_MEM_PTR_W
    RD_MEM_ADDR          =   4,     
    //update the memory pointer address and send write command. The packet size must be updated before setting this register. use it when memory pointer width is larger than COMB_MEM_PTR_W
    WR_MEM_ADDR          =   5;
    
        status_reg  
            bit_loc         flag_name
            12              rsv_pck_isr
            11              rd_done_isr
            10              wr_done_isr
            9               rsv_pck_int_en
            8               rd_done_int_en
            7               wr_done_int_en
            6               all_vcs_full
            5               any_vc_has_data
            4               rd_no_pck_err
            3               rd_ovr_size_err
            2               rd_done
            1               wr_done
            0               busy
            
        
        
        RD/WR registers ={pck_size_next,memory_ptr_next}
    
    Info: monemi@fkegraduate.utm.my
    *************************************************************************/


`timescale 1ns/1ps



module  ni_sep #(
    parameter V    = 4,     // V
    parameter P    = 5,     // router port num
    parameter B    = 4,     // buffer space :flit per VC 
    parameter NX   = 2, // number of node in x axis
    parameter NY   = 2, // number of node in y axis
    parameter Fpay = 32,
    parameter TOPOLOGY =    "MESH",//"MESH","TORUS"
    parameter ROUTE_TYPE   =   "DETERMINISTIC",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter ROUTE_NAME    =   "XY",
    parameter DEBUG_EN =   1,  
    parameter COMB_MEM_PTR_W=20,
    parameter COMB_PCK_SIZE_W= 12,
    
    //wishbone port parameters
    parameter Dw            =   32,
    parameter S_Aw          =   3,
    parameter M_Aw          =   32,
    parameter TAGw          =   3,
    parameter SELw          =   4    
    )
    (
    
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
   
    //wishbone slave interface signals
    s_dat_i,
    s_sel_i,
    s_addr_i,  
    s_cti_i,
    s_stb_i,
    s_cyc_i,
    s_we_i,    
    s_dat_o,
    s_ack_o,
   


   
    //wishbone master read
    m_rd_sel_o,
    m_rd_dat_o,
    m_rd_addr_o,
    m_rd_cti_o,
    m_rd_stb_o,
    m_rd_cyc_o,
    m_rd_we_o,
    m_rd_ack_i,    
  
    
    
    //wishbone master interface signals
    m_wr_sel_o,
    m_wr_addr_o,
    m_wr_cti_o,
    m_wr_stb_o,
    m_wr_cyc_o,
    m_wr_we_o,
    m_wr_dat_i,
    m_wr_ack_i,    
   
    
    //intruupt interface
    irq
    
    
); 
 
    function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
    endfunction // log2 
   
    localparam  Fw     =    2+V+Fpay, //flit width
                Xw =   log2(NX),
                Yw =   log2(NY); 
                   
         
                

  
    
    
    input reset;
    input clk;
    
    
    // NOC interfaces
    input   [Xw-1   :   0]  current_x;
    input   [Yw-1   :   0]  current_y;
    output  [Fw-1   :   0]  flit_out;     
    output                  flit_out_wr;   
    input   [V-1    :   0]  credit_in;
    input   [Fw-1   :   0]  flit_in; 
    input                   flit_in_wr;   
    output  [V-1    :   0]  credit_out;     
    
    

    //wishbone slave interface signals
    input   [Dw-1       :   0]      s_dat_i;
    input   [SELw-1     :   0]      s_sel_i;
    input   [S_Aw-1     :   0]      s_addr_i;  
    input   [TAGw-1     :   0]      s_cti_i;
    input                           s_stb_i;
    input                           s_cyc_i;
    input                           s_we_i;    
    output      [Dw-1       :   0]  s_dat_o;
    output                          s_ack_o;
   
    
    
     //wishbone master read packet interface
    output  [SELw-1          :   0] m_rd_sel_o;
    output  [Dw-1            :   0] m_rd_dat_o;
    output  [M_Aw-1          :   0] m_rd_addr_o;
    output  [TAGw-1          :   0] m_rd_cti_o;
    output                          m_rd_stb_o;
    output                          m_rd_cyc_o;
    output                          m_rd_we_o;
    input                           m_rd_ack_i;    
   
    
    //wishbone master write packet interface
    output  [SELw-1          :   0] m_wr_sel_o;
    output  [M_Aw-1          :   0] m_wr_addr_o;
    output  [TAGw-1          :   0] m_wr_cti_o;
    output                          m_wr_stb_o;
    output                          m_wr_cyc_o;
    output                          m_wr_we_o;
    input   [Dw-1           :  0]   m_wr_dat_i;
    input                           m_wr_ack_i;    
  
    
    //intruupt interface
    output                          irq;
    


    wire      [Dw-1       :   0]  s_rd_dat_o,s_wr_dat_o;
    wire                          s_rd_ack_o,s_wr_ack_o;
    wire                          irq_rd , irq_wr;

    assign                        s_dat_o= s_rd_dat_o | s_wr_dat_o;
    assign                        s_ack_o= s_rd_ack_o | s_wr_ack_o;
    assign                        irq = irq_rd | irq_wr;
    
    sub_ni_rd #(
    	.V(V),
    	.P(P),
    	.B(B),
    	.NX(NX),
    	.NY(NY),
    	.Fpay(Fpay),
    	.TOPOLOGY(TOPOLOGY),
    	.ROUTE_TYPE(ROUTE_TYPE),
    	.ROUTE_NAME(ROUTE_NAME),
    	.DEBUG_EN(DEBUG_EN),
    	.COMB_MEM_PTR_W(COMB_MEM_PTR_W),
    	.COMB_PCK_SIZE_W(COMB_PCK_SIZE_W),
    	.Dw(Dw),
    	.S_Aw(S_Aw),
    	.M_Aw(M_Aw),
    	.TAGw(TAGw),
    	.SELw(SELw)
    )
    ni_rd(
    	.reset(reset),
    	.clk(clk),
    	.current_x(current_x),
    	.current_y(current_y),
    	.flit_in(flit_in),
    	.flit_in_wr(flit_in_wr),
    	.credit_out(credit_out),
    	.s_dat_i(s_dat_i),
    	.s_sel_i(s_sel_i),
    	.s_addr_i(s_addr_i),
    	.s_cti_i(s_cti_i),
    	.s_stb_i(s_stb_i),
    	.s_cyc_i(s_cyc_i),
    	.s_we_i(s_we_i),
    	.s_dat_o(s_rd_dat_o),
    	.s_ack_o(s_rd_ack_o),
    	
    	.m_sel_o(m_rd_sel_o),
    	.m_dat_o(m_rd_dat_o),
    	.m_addr_o(m_rd_addr_o),
    	.m_cti_o(m_rd_cti_o),
    	.m_stb_o(m_rd_stb_o),
    	.m_cyc_o(m_rd_cyc_o),
    	.m_we_o(m_rd_we_o),
    	.m_ack_i(m_rd_ack_i),
    	.irq(irq_rd)
    );


    sub_ni_wr #(
    	.V(V),
        .P(P),
        .B(B),
        .NX(NX),
        .NY(NY),
        .Fpay(Fpay),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_TYPE(ROUTE_TYPE),
        .ROUTE_NAME(ROUTE_NAME),
        .DEBUG_EN(DEBUG_EN),
        .COMB_MEM_PTR_W(COMB_MEM_PTR_W),
        .COMB_PCK_SIZE_W(COMB_PCK_SIZE_W),
        .Dw(Dw),
        .S_Aw(S_Aw),
        .M_Aw(M_Aw),
        .TAGw(TAGw),
        .SELw(SELw)
    )
    ni_wr(
    	.reset(reset),
    	.clk(clk),
    	.current_x(current_x),
    	.current_y(current_y),
    	.flit_out(flit_out),
    	.flit_out_wr(flit_out_wr),
    	.credit_in(credit_in),
    	.s_dat_i(s_dat_i),
    	.s_sel_i(s_sel_i),
    	.s_addr_i(s_addr_i),
    	.s_cti_i(s_cti_i),
    	.s_stb_i(s_stb_i),
    	.s_cyc_i(s_cyc_i),
    	.s_we_i(s_we_i),
    	.s_dat_o(s_wr_dat_o),
    	.s_ack_o(s_wr_ack_o),
    	.m_sel_o(m_wr_sel_o),
    	.m_addr_o(m_wr_addr_o),
    	.m_cti_o(m_wr_cti_o),
    	.m_stb_o(m_wr_stb_o),
    	.m_cyc_o(m_wr_cyc_o),
    	.m_we_o(m_wr_we_o),
    	.m_dat_i(m_wr_dat_i),
    	.m_ack_i(m_wr_ack_i),
    	.irq(irq_wr)
    );




endmodule

