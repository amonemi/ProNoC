/**********************************************************************
**  File:  pronoc_jtag_source_probe.v
**  
**    
**  Copyright (C) 2020  Alireza Monemi
**    
**  This file is part of ProNoC 
**
**  ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**  you can redistribute it and/or modify it under the terms of the GNU
**  Lesser General Public License as published by the Free Software Foundation,
**  either version 2 of the License, or (at your option) any later version.
**
**  ProNoC is distributed in the hope that it will be useful, but WITHOUT
**  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
**  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
**  Public License for more details.
**
**  You should have received a copy of the GNU Lesser General Public
**  License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
**
**
**  Description: 
**  A source/probe that can be controled using xilinx bscan chain or Altera vjtag. 
**
*******************************************************************/


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


module pronoc_jtag_source_probe #(
    parameter Dw=2,  //probe/probe width in bits 
   
    parameter JTAG_CONNECT= "XILINX_JTAG_WB" ,// "ALTERA_JTAG_WB" , "XILINX_JTAG_WB"  
    parameter JTAG_INDEX= 0,
    parameter JDw =32,// should be a fixed value for all IPs coneccting to JTAG
    parameter JAw=32, // should be a fixed value for all IPs coneccting to JTAG
    parameter JINDEXw=8,
    parameter JSTATUSw=8,
    parameter J2WBw = (JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+1+JDw+JAw : 1,
    parameter WB2Jw= (JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+JSTATUSw+JINDEXw+1+JDw  : 1
 

)(
	reset,
	clk,
	source_o,
	probe_i,
	//jtag o wb interface. Valid only for XILINX_JTAG_WB 
    jtag_to_wb, 
    wb_to_jtag 
);

    input reset,clk;
	input		[Dw-1	:0]  probe_i;
	output	reg [Dw-1	:0]  source_o;

    input  [J2WBw-1 : 0] jtag_to_wb;
    output [WB2Jw-1: 0] wb_to_jtag;

    wire we;
    wire [JDw-1 : 0] wb_to_jtag_dat; 
    wire [JDw-1 : 0] jtag_to_wb_dat;

    generate 
    /* verilator lint_off WIDTH */
    if(JTAG_CONNECT == "ALTERA_JTAG_WB")begin:altera_jwb
    /* verilator lint_on WIDTH */
        reg jtag_ack;
        wire    jtag_we_o, jtag_stb_o;
    
     
        vjtag_wb #(
            .VJTAG_INDEX(JTAG_INDEX),
            .DW(Dw),
            .AW(2),
            .SW(1),
        
            //wishbone port parameters
            .M_Aw(2),
            .TAGw(3)
        )
        vjtag_inst
        (
            .clk(clk),
            .reset(reset),  
            .status_i(0), // Jtag can read memory size as status
             //wishbone master interface signals
            .m_sel_o(),
            .m_dat_o(jtag_to_wb_dat),
            .m_addr_o( ),
            .m_cti_o(),
            .m_stb_o(jtag_stb_o),
            .m_cyc_o(),
            .m_we_o(jtag_we_o),
            .m_dat_i(wb_to_jtag_dat),
            .m_ack_i(jtag_ack)     
        
        );
    
            assign we = jtag_stb_o & jtag_we_o;
        
            always @(posedge clk )begin 
                jtag_ack<=jtag_stb_o;   
            end
            assign wb_to_jtag[0] = clk;
        
    end//altera_jwb
    
    
    
/* verilator lint_off WIDTH */  
    else if(JTAG_CONNECT == "XILINX_JTAG_WB")begin: xilinx_jwb 
/* verilator lint_on WIDTH */     
    
      
        
        wire [JSTATUSw-1 : 0] wb_to_jtag_status;
        wire [JINDEXw-1 : 0] wb_to_jtag_index;
     
        wire [JAw-1 : 0] jtag_to_wb_addr;
        wire jtag_to_wb_stb;
        wire jtag_to_wb_we;
       
        wire wb_to_jtag_ack;
        
        assign wb_to_jtag = {wb_to_jtag_status,wb_to_jtag_ack,wb_to_jtag_dat,wb_to_jtag_index,clk};
        assign {jtag_to_wb_addr,jtag_to_wb_stb,jtag_to_wb_we,jtag_to_wb_dat} = jtag_to_wb;
        
            
        reg ack_reg;
        assign  we = jtag_to_wb_stb & jtag_to_wb_we;
        
        assign wb_to_jtag_status = 0;
        assign wb_to_jtag_index = JTAG_INDEX;
      
        
        assign wb_to_jtag_ack = ack_reg;
        always @(posedge clk )begin 
            ack_reg<=jtag_to_wb_stb;   
        end
        
    end else begin 
        assign wb_to_jtag[0] = clk;
    end

    endgenerate




      always @(posedge clk) begin 
            if(reset) begin 
                source_o <= {Dw{1'b0}};
            end else begin 
                if (we) source_o <= jtag_to_wb_dat[Dw-1 : 0];
            end
        end
        
               
        assign wb_to_jtag_dat [Dw-1 : 0] = probe_i; 



endmodule
