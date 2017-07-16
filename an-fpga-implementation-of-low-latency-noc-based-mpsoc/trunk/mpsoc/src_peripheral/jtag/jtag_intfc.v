/**********************************************************************
**	File:  jtag_intfc.v 
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
**	Jtag interface for Altera FPGAs
**		.
**
*******************************************************************/


module  jtag_intfc #(
    parameter NI_BASE_ADDR     = 32'hx, //must be set by top level
    parameter JTAG_BASE_ADDR   = 32'hxx,
    parameter WR_RAM_TAG       ="J0",
    parameter RD_RAM_TAG       ="J1",
    parameter WR_RAMw          =8,
      //wishbone port parameters
   
    parameter Dw            =   32,
    parameter S_Aw          =   WR_RAMw+1,
    parameter M_Aw          =   32,
    parameter TAGw          =   3,
    parameter SELw          =   4

)(
    
   //source_probe
   /*
    busy,
    start_source,
    wr_pck_size,
    x_dest,y_dest,
    memory_pointer,   
    */

    //wishbone slave interface signals
    s_dat_i,
    s_sel_i,
    s_addr_i,  
    s_tag_i,
    s_stb_i,
    s_cyc_i,
    s_we_i,    
    s_dat_o,
    s_ack_o,
    s_err_o,
    s_rty_o,


   
    //wishbone master interface signals
    m_sel_o,
    m_dat_o,
    m_addr_o,
    m_tag_o,
    m_stb_o,
    m_cyc_o,
    m_we_o,
    m_dat_i,
    m_ack_i,    
    m_err_i,
    m_rty_i,
    
    //intruupt interface
    irq,

    reset_all_o,
    reset_cpus_o,

    //
    reset,
    clk




);

 localparam  WR_RAM_ID = {"ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=",WR_RAM_TAG};
     
	localparam  CLASS_IN_HDR_WIDTH      =8,
            DEST_IN_HDR_WIDTH       =8,
            X_Y_IN_HDR_WIDTH        =4;


//source_probe

/*
output reg busy;
input  start_source;
input [WR_RAMw        :   0] wr_pck_size;
input [X_Y_IN_HDR_WIDTH-1	:0] x_dest,y_dest;
input [31						:0] memory_pointer;

assign {reset_all_o,reset_cpus_o}=2'b01;
*/          
            



//wishbone slave interface signals
    input   [Dw-1       :   0]      s_dat_i;
    input   [SELw-1     :   0]      s_sel_i;
    input   [S_Aw-1     :   0]      s_addr_i;  
    input   [TAGw-1     :   0]      s_tag_i;
    input                           s_stb_i;
    input                           s_cyc_i;
    input                           s_we_i;
    
    output      [Dw-1       :   0]  s_dat_o;
    output                          s_ack_o;
    output                          s_err_o;
    output                          s_rty_o;
    
    
    //wishbone master interface signals
    output reg [SELw-1          :   0] m_sel_o;
    output reg [Dw-1            :   0] m_dat_o;
    output reg [M_Aw-1          :   0] m_addr_o;
    output reg [TAGw-1          :   0] m_tag_o;
    output reg                         m_stb_o;
    output reg                         m_cyc_o;
    output reg                         m_we_o;
    input       [Dw-1           :  0]  m_dat_i;
    input                              m_ack_i;    
    input                              m_err_i;
    input                              m_rty_i;
    //intrrupt interface
    output                          irq;
    
    input                           clk,reset;
  
    output  reset_all_o,  reset_cpus_o;

	
    


  

				
   wire [S_Aw-1     :   0]   ram_wr_addr_i;				
   wire [Dw-1       :   0]   ram_wr_dat_o,hdr_flit_payload; 
	reg  [S_Aw-1     :   0]   s_addr_i_reg;  

    //jtag source prob
	 
   reg busy;
   wire start_source;
   wire [WR_RAMw        		:0] wr_pck_size;
   wire [X_Y_IN_HDR_WIDTH-1	:0] x_dest,y_dest;
   wire [31						:0] memory_pointer;
	
	localparam SOURCEw=32+WR_RAMw+1+X_Y_IN_HDR_WIDTH+X_Y_IN_HDR_WIDTH;
  
    jtag_sp #(
	.INDEX(2),
        .Pw(1),
        .Sw(3)
    
    )
    source_probe
    (  
        .probe(busy),
        .source({reset_all_o,reset_cpus_o,start_source})

    );
  
   jtag_sp #(
		  .INDEX(3),
        .Pw(1),
        .Sw(SOURCEw)
    
    )
    source_probe
    (  
        .probe(busy),
        .source({wr_pck_size,y_dest,x_dest,memory_pointer})

    );
  





 assign hdr_flit_payload={{CLASS_IN_HDR_WIDTH{1'b1}},{DEST_IN_HDR_WIDTH{1'b0}},x_dest,y_dest,{(2*X_Y_IN_HDR_WIDTH){1'b0}}};
	
                 
   assign ram_wr_addr_i= s_addr_i[ WR_RAMw :0] -2'd2;	 
   assign s_dat_o=(s_addr_i_reg==0)?  hdr_flit_payload:
						(s_addr_i_reg==1)?	 memory_pointer:
											 ram_wr_dat_o;

    prog_ram_single_port #(
        .Aw(WR_RAMw),
        .Dw(Dw),
        .FPGA_FAMILY("ALTERA"),
        .RAM_TAG_STRING(WR_RAM_TAG),
        .SELw(4),
        .TAGw(3)
    ) pc_write_ram
    (
        .clk        (clk),
        .reset      (reset),
        .sa_ack_o   (s_ack_o),
        .sa_addr_i  (ram_wr_addr_i),
        .sa_cyc_i   (s_cyc_i),
        .sa_dat_i   (32'd0),
        .sa_dat_o   (ram_wr_dat_o),
        .sa_err_o   (s_err_o),
        .sa_rty_o   (s_rty_o),
        .sa_sel_i   (s_sel_i),
        .sa_stb_i   (s_stb_i),
        .sa_tag_i   (s_tag_i),
        .sa_we_i    (1'b0)
    );            
                  
        
  
  
  
  
   reg sent_start,start_source_delayed;
    
   always @(posedge clk or posedge reset)begin
    if(reset)begin 
         sent_start<=1'b0;
         start_source_delayed<=1'b0;
           
    end
    else begin
        start_source_delayed    <=start_source;
        sent_start<= (start_source_delayed & ~start_source);  // sent_start is asserted at negedge of sent_start       
         
     end    
   end
   
   localparam ST_NUM        =5,
                 IDEAL      =1,
                 WRITE_NI_PCK_SIZE=2,
                 WRITE_NI_MEM_PTR=4,
                 WAIT_1     =8,
                 WAIT_NI_DONE=16;
        
    
    
    reg [ST_NUM-1  : 0]ps,ns;
    
    localparam 
     NI_STATUS_ADDR          =   NI_BASE_ADDR+0,
    // update memory pinter, packet size and send packet read command. If memory pointer and packet size width are smaller than COMB_MEM_PTR_W and COMB_PCK_SIZE_W respectively.
    NI_RD_MEM_PCKSIZ_ADDR   =   NI_BASE_ADDR+1,  
    // update memory pinter, packet size and send packet write command. If memory pointer and packet size width are smaller than COMB_MEM_PTR_W and COMB_PCK_SIZE_W respectively.
    NI_WR_MEM_PCKSIZ_ADDR   =   NI_BASE_ADDR+2,      
    //update packet size  
    NI_PCK_SIZE_ADDR        =   NI_BASE_ADDR+3,
    //update the memory pointer address and send read command. The packet size must be updated before setting this register. use it when memory pointer width is larger than COMB_MEM_PTR_W
    NI_RD_MEM_ADDR          =   NI_BASE_ADDR+4,     
    //update the memory pointer address and send write command. The packet size must be updated before setting this register. use it when memory pointer width is larger than COMB_MEM_PTR_W
    NI_WR_MEM_ADDR          =   NI_BASE_ADDR+5;
    
    
                  
    localparam   NI_BUSY_LOC=         0;  
                     
    
    reg [2:0] cnt;
    reg       cnt_inc;
    
    always @(*)begin
        ns=ps;
        m_sel_o     =4'b1111;
        m_dat_o       =0;
        m_addr_o      = NI_STATUS_ADDR ;
        m_tag_o       =3'd0;
        m_stb_o       =1'b0;
        m_cyc_o       =1'b0;
        m_we_o        =1'b0;
        busy            =1'b1;
        cnt_inc     =1'b0;
        case(ps)
        IDEAL: begin 
            if(sent_start) ns= WRITE_NI_PCK_SIZE;
            busy            =1'b0;
        end
        WRITE_NI_PCK_SIZE: begin 
            m_dat_o     = wr_pck_size+1;// hdr
            m_addr_o        = NI_PCK_SIZE_ADDR;
            if(m_ack_i) ns= WRITE_NI_MEM_PTR;
            m_stb_o=1'b1;
            m_cyc_o=1'b1;
            m_we_o=1'b1;
        
        
        end
        WRITE_NI_MEM_PTR: begin
            m_dat_o     = (JTAG_BASE_ADDR<<2);
            m_addr_o        = NI_WR_MEM_ADDR;
            if(m_ack_i) ns= WAIT_1;
            m_stb_o=1'b1;
            m_cyc_o=1'b1;
            m_we_o=1'b1;
        end
        WAIT_1: begin
            if(cnt==3'd7)ns= WAIT_NI_DONE;
            cnt_inc=1'b1;
        
        end
        WAIT_NI_DONE: begin 
            if(m_ack_i)begin 
					ns=(m_dat_i[NI_BUSY_LOC])? WAIT_1  :IDEAL;
            end
				m_addr_o    =   NI_STATUS_ADDR;
            m_stb_o =1'b1;
            m_cyc_o =1'b1;
            m_we_o  =1'b0;      
        end
        endcase
    end
    
    
    
    
    
    always @(posedge clk or posedge reset)begin 
        if(reset) begin
            ps<= IDEAL;
            cnt<= 3'd0;
				s_addr_i_reg<=0;
        end else begin 
            ps<=ns;
				s_addr_i_reg<=s_addr_i;
            if( cnt_inc) cnt<= cnt +1'b1;
            else             cnt<= 3'd0;
        
        end 
    end
    
   
   
   

endmodule

/*****************
    
    jtag_sp

******************/

module jtag_sp #(
	 parameter INDEX=2,
    parameter Pw=8,
    parameter Sw=8
    
)(
    probe,
    source);

    input   [Pw:0]  probe;
    output  [Sw:0]  source;

    wire [Sw:0] sub_wire0;
    wire [Sw:0] source = sub_wire0[Sw:0];

    altsource_probe altsource_probe_component (
                .probe (probe),
                .source (sub_wire0)
                // synopsys translate_off
                ,
                .clrn (),
                .ena (),
                .ir_in (),
                .ir_out (),
                .jtag_state_cdr (),
                .jtag_state_cir (),
                .jtag_state_e1dr (),
                .jtag_state_sdr (),
                .jtag_state_tlr (),
                .jtag_state_udr (),
                .jtag_state_uir (),
                .raw_tck (),
                .source_clk (),
                .source_ena (),
                .tdi (),
                .tdo (),
                .usr1 ()
                // synopsys translate_on
                );
    defparam
        altsource_probe_component.enable_metastability = "NO",
        altsource_probe_component.instance_id = "JTAG",
        altsource_probe_component.probe_width = Pw,
        altsource_probe_component.sld_auto_instance_index = "NO",
        altsource_probe_component.sld_instance_index = INDEX,
        altsource_probe_component.source_initial_value = " 0",
        altsource_probe_component.source_width = Sw;


endmodule


