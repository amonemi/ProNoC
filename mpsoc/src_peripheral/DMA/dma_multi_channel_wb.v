/**********************************************************************
**	File:  dma.v
**	Date:2017-05-14   
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
**	weighted round robin arbiter	
**	A multi channel wishbone based DMA  and with support burst data transaction 
**	(Dose not support byte enable yet). 
***************************************/
 `timescale  1ns/1ps
 
 
 
 
 module dma_multi_chan_wb #(
    parameter CHANNEL=4,
    parameter MAX_TRANSACTION_WIDTH=10, // Maximum transaction size will be 2 power of MAX_DMA_TRANSACTION_WIDTH words 
    parameter MAX_BURST_SIZE =256, // in words
    parameter FIFO_B = 4,
    parameter DEBUG_EN = 1,
    //wishbone port parameters
    parameter Dw            =   32,
    parameter S_Aw          =   7,
    parameter M_Aw          =   32,
    parameter TAGw          =   3,
    parameter SELw          =   4


)
(
     // 
    reset,
    clk,
     
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
    

   
    //wishbone master rd interface signals
    m_rd_sel_o,
    m_rd_addr_o,
    m_rd_cti_o,
    m_rd_stb_o,
    m_rd_cyc_o,
    m_rd_we_o,
    m_rd_dat_i,
    m_rd_ack_i,    


     //wishbone master wr interface signals
     
    m_wr_sel_o,
    m_wr_dat_o,
    m_wr_addr_o,
    m_wr_cti_o,
    m_wr_stb_o,
    m_wr_cyc_o,
    m_wr_we_o,
    m_wr_ack_i,   
     
  
    //intruupt interface
    irq

);
 
    input reset,clk;
    
   //wishbone slave interface signals
    input   [Dw-1       :   0]      s_dat_i;
    input   [SELw-1     :   0]      s_sel_i;
    input   [S_Aw-1     :   0]      s_addr_i;  
    input   [TAGw-1     :   0]      s_cti_i;
    input                           s_stb_i;
    input                           s_cyc_i;
    input                           s_we_i;
    
    output      [Dw-1       :   0]  s_dat_o;
    output  reg                     s_ack_o;
  
    
    
    //wishbone read master interface signals
    output  [SELw-1          :   0] m_rd_sel_o;
    output  [M_Aw-1          :   0] m_rd_addr_o;
    output  [TAGw-1          :   0] m_rd_cti_o;
    output                          m_rd_stb_o;
    output                          m_rd_cyc_o;
    output                          m_rd_we_o;
    input   [Dw-1           :  0]   m_rd_dat_i;
    input                           m_rd_ack_i;    
     
     //wishbone write master interface signals
    output  [SELw-1          :   0] m_wr_sel_o;
    output  [Dw-1            :   0] m_wr_dat_o;
    output  [M_Aw-1          :   0] m_wr_addr_o;
    output  [TAGw-1          :   0] m_wr_cti_o;
    output                          m_wr_stb_o;
    output                          m_wr_cyc_o;
    output                          m_wr_we_o;
    input                           m_wr_ack_i;   
    
    output irq;
  
    wire                            s_ack_o_next;
    
 
     function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 
    
    
    localparam 
        CHw=log2(CHANNEL),
        BURST_SIZE_w= log2(MAX_BURST_SIZE);
    
     /*   wishbone slave adderess :
    
    [2:0]  
            0   :   DMA_STATUS_WB_ADDR
            1   :   BURST_SIZE_WB_ADDR  // The busrt size in words 
            2   :   DATA_SIZE_WB_ADDR,  // The transfer data size in byte  
            3   :   RD_STRT_WB_ADDR3,  // The source start address in byte       
            4   :   WR_STRT_WB_ADDR   // The destination start address in byte
                      
    [3+CHw:3]
                channel num       
      
    */
    
    wire [CHw-1 :   0] channel_addr = s_addr_i [3+CHw:3];
    wire [2     :   0] channel_s_addr_i = s_addr_i [2: 0];
    
  
    
     localparam [2  :   0]
        DMA_STATUS_WB_ADDR =3'd0, 
        BURST_SIZE_WB_ADDR =3'd1; // The busrt size in words
        
        
        
       
 
    reg [BURST_SIZE_w-1  :   0] burst_size, burst_size_next,burst_counter,burst_counter_next;
  
    
    wire [CHANNEL-1 :   0] channel_wr_is_busy, channel_rd_is_busy;
    wire [CHANNEL-1 :   0] channel_wr_enable,channel_rd_enable,channel_state_reg_enable;
    wire [CHANNEL-1 :   0] channel_burst_counter_ld, channel_burst_counter_dec;
    wire [CHANNEL-1 :   0] channel_fifo_wr, channel_fifo_rd;
    wire [CHANNEL-1 :   0] channel_fifo_full, channel_fifo_nearly_full, channel_fifo_empty;
    wire [CHANNEL-1 :   0] channel_rd_is_active,channel_wr_is_active;
    wire [CHw-1     :   0] rd_enable_binary,wr_enable_binary;
     
     
     
   wire  [SELw-1    :   0] channel_m_rd_sel_o  [CHANNEL-1 :   0];
   wire  [M_Aw-1    :   0] channel_m_rd_addr_o [CHANNEL-1 :   0];
   wire  [TAGw-1    :   0] channel_m_rd_cti_o  [CHANNEL-1 :   0];
   wire  [CHANNEL-1 :   0] channel_m_rd_stb_o; 
   wire  [CHANNEL-1 :   0] channel_m_rd_cyc_o; 
   wire  [CHANNEL-1 :   0] channel_m_rd_we_o; 
       
            
   wire  [SELw-1    :   0] channel_m_wr_sel_o  [CHANNEL-1 :   0];
   wire  [M_Aw-1    :   0] channel_m_wr_addr_o [CHANNEL-1 :   0];
   wire  [TAGw-1    :   0] channel_m_wr_cti_o  [CHANNEL-1 :   0];
   wire  [CHANNEL-1 :   0] channel_m_wr_stb_o; 
   wire  [CHANNEL-1 :   0] channel_m_wr_cyc_o; 
   wire  [CHANNEL-1 :   0] channel_m_wr_we_o; 
            
 
     
     
   
     
     
     
    
    wire burst_counter_ld = | channel_burst_counter_ld; 
    wire burst_counter_dec= | channel_burst_counter_dec;
    wire fifo_wr =  | channel_fifo_wr; 
    wire fifo_rd =  | channel_fifo_rd;
    
    wire last_burst = (burst_counter == 1);
    wire burst_is_set =  (burst_size>0);
    
    localparam STATUSw= 2 * CHw + 3 * CHANNEL;
    wire  [STATUSw-1  :0] status;  
    wire [CHANNEL-1 :   0] channel_is_active = channel_rd_is_busy|channel_wr_is_busy;
    assign status= {rd_enable_binary,wr_enable_binary,channel_rd_is_busy,channel_wr_is_busy,channel_is_active};
    assign s_dat_o={{(Dw-STATUSw){1'b0}}, status};
    
    
   
   bin_to_one_hot #(
   	.BIN_WIDTH(CHw),
   	.ONE_HOT_WIDTH(CHANNEL)
   )
   convert(
   	.bin_code(channel_addr),
   	.one_hot_code(channel_state_reg_enable)
   );
   
   
   
   
    assign s_ack_o_next    =   s_stb_i & (~s_ack_o);
    
    
    always @ (*)begin 
        burst_counter_next=burst_counter;
        burst_size_next= burst_size;
        if(burst_counter_ld)    burst_counter_next = burst_size;
        if(burst_counter_dec)   burst_counter_next= burst_counter- 1'b1;
        
        if(s_stb_i  &    s_we_i )   begin 
            if (channel_wr_is_busy == {CHANNEL{1'b0}})  begin   
                case(channel_s_addr_i)
                    BURST_SIZE_WB_ADDR: begin 
                        burst_size_next=s_dat_i [BURST_SIZE_w-1 : 0];    
                    end //BURST_SIZE_WB_ADDR
                endcase
            end      
        end
           
    end 
    
    
    always @ (posedge clk or posedge reset)begin 
        if(reset) begin 
            burst_counter <= {BURST_SIZE_w{1'b0}};
            burst_size <= {BURST_SIZE_w{1'b1}};
            s_ack_o <= 1'b0;   
        end else begin 
            burst_counter<= burst_counter_next; 
            burst_size <= burst_size_next; 
            s_ack_o <= s_ack_o_next;           
        end 
    end 
    
    
  
  
    
    
    genvar i;
    generate
    for (i=0;i<CHANNEL; i=i+1) begin : channel_
        dma_single_wb #(
        	.MAX_TRANSACTION_WIDTH(MAX_TRANSACTION_WIDTH),
        	.Dw(Dw),
        	.S_Aw(3),
        	.M_Aw(M_Aw),
        	.TAGw(TAGw),
        	.SELw(SELw)
        )
        channel_dma
        (
        	.reset(reset),
        	.clk(clk),
        	.status(),
        	
        	//active-enable signals
        	.rd_enable(channel_rd_enable[i]),
        	.wr_enable(channel_wr_enable[i]),
        	.state_reg_enable(channel_state_reg_enable[i]),
        	.rd_is_busy(channel_rd_is_busy[i]),
        	.wr_is_busy(channel_wr_is_busy[i]),
        	.rd_is_active(channel_rd_is_active[i]),
        	.wr_is_active(channel_wr_is_active[i]),
        	.burst_counter_ld(channel_burst_counter_ld[i]),
        	.burst_counter_dec(channel_burst_counter_dec[i]),
        	.burst_size_is_set(burst_is_set),
        	.last_burst(last_burst),
        	
        	//fifo
        	.fifo_wr(channel_fifo_wr[i]), 
            .fifo_rd(channel_fifo_rd[i]), 
            .fifo_full(channel_fifo_full[i]),
            .fifo_nearly_full(channel_fifo_nearly_full[i]),
            .fifo_empty(channel_fifo_empty[i]),
        	            
        	//wb salve
        	.s_dat_i(s_dat_i),
        	.s_sel_i(s_sel_i),
        	.s_addr_i(channel_s_addr_i),
        	.s_cti_i(s_cti_i),
        	.s_stb_i(s_stb_i),
        	.s_cyc_i(s_cyc_i),
        	.s_we_i(s_we_i),
        	//.s_dat_o(s_dat_o),
        	//.s_ack_o(s_ack_o),
        	
        	//
        	.m_rd_sel_o(channel_m_rd_sel_o[i]),
        	.m_rd_addr_o(channel_m_rd_addr_o[i]),
        	.m_rd_cti_o(channel_m_rd_cti_o[i]),
        	.m_rd_stb_o(channel_m_rd_stb_o[i]),
        	.m_rd_cyc_o(channel_m_rd_cyc_o[i]),
        	.m_rd_we_o(channel_m_rd_we_o[i]),
        //	.m_rd_dat_i(m_rd_dat_i),
        	.m_rd_ack_i(m_rd_ack_i),
        	
        	
        	.m_wr_sel_o(channel_m_wr_sel_o[i]),
        //	.m_wr_dat_o(channel_m_wr_dat_o[i]),
        	.m_wr_addr_o(channel_m_wr_addr_o[i]),
        	.m_wr_cti_o(channel_m_wr_cti_o[i]),
        	.m_wr_stb_o(channel_m_wr_stb_o[i]),
        	.m_wr_cyc_o(channel_m_wr_cyc_o[i]),
        	.m_wr_we_o(channel_m_wr_we_o[i]),
        	.m_wr_ack_i(m_wr_ack_i)
        );
    
    end  // for loop for channel
    
  
    if(CHANNEL> 1) begin : multi_channel
    
        // round roubin arbiter
        bus_arbiter # (
            .M (CHANNEL)
        )
        wr_arbiter
        (
            .request (channel_wr_is_active ),
            .grant  (channel_wr_enable),
            .clk (clk),
            .reset (reset)
        );
        
        
        
        
        bus_arbiter # (
            .M (CHANNEL)
        )
        rd_arbiter
        (
            .request (channel_rd_is_active),
            .grant  (channel_rd_enable),
            .clk (clk),
            .reset (reset)
        );
        
        
        one_hot_to_bin #(
            .ONE_HOT_WIDTH(CHANNEL),
            .BIN_WIDTH(CHw)
        )
        rd_en_conv
        (
            .one_hot_code(channel_rd_enable),
            .bin_code(rd_enable_binary)
        );
        
        
         one_hot_to_bin #(
            .ONE_HOT_WIDTH(CHANNEL),
            .BIN_WIDTH(CHw)
        )
        wr_en_conv
        (
            .one_hot_code(channel_wr_enable),
            .bin_code(wr_enable_binary)
        );
        
        
    end else begin : single_channel // if we have just one channel there is no needs for arbitration
        assign channel_wr_enable =  channel_wr_is_busy;
        assign channel_rd_enable =  channel_rd_is_busy;
        assign rd_enable_binary = 1'b0;
        assign wr_enable_binary = 1'b0;
    end
    endgenerate  
    
    
    //wb multiplexors
    
    assign m_rd_sel_o  = channel_m_rd_sel_o[rd_enable_binary];
    assign m_rd_addr_o = channel_m_rd_addr_o[rd_enable_binary];
    assign m_rd_cti_o  = channel_m_rd_cti_o[rd_enable_binary];
    assign m_rd_stb_o  = channel_m_rd_stb_o[rd_enable_binary];
    assign m_rd_cyc_o  = channel_m_rd_cyc_o[rd_enable_binary];
    assign m_rd_we_o   = channel_m_rd_we_o[rd_enable_binary];
       
            
            
    assign m_wr_sel_o = channel_m_wr_sel_o[wr_enable_binary];
    assign m_wr_addr_o= channel_m_wr_addr_o[wr_enable_binary];
    assign m_wr_cti_o = channel_m_wr_cti_o[wr_enable_binary];
    assign m_wr_stb_o = channel_m_wr_stb_o[wr_enable_binary];
    assign m_wr_cyc_o = channel_m_wr_cyc_o[wr_enable_binary];
    assign m_wr_we_o  = channel_m_wr_we_o[wr_enable_binary];
    
    
          
    
    
    
  
  
  shared_mem_fifos #(
  	.NUM(CHANNEL),
  	.B(FIFO_B),
  	.Dw(Dw),
  	.DEBUG_EN(DEBUG_EN)
  )
  the_shared_mem_fifos
  (
  	.din(m_rd_dat_i),
  	.fifo_num_wr(channel_rd_enable ), // when chnnel is in read mode it start writing on fifo
  	.fifo_num_rd(channel_wr_enable),
  	.wr_en(fifo_wr),
  	.rd_en(fifo_rd),
  	.dout(m_wr_dat_o),
  	.full(channel_fifo_full),
  	.nearly_full(channel_fifo_nearly_full),
  	.empty(channel_fifo_empty),  
  	.reset(reset),
  	.clk(clk)
  );
  
  
  
   
    
    
    
 endmodule
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
module dma_single_wb #(
   
    parameter MAX_TRANSACTION_WIDTH=10, // MAximum transaction size will be 2 power of MAX_DMA_TRANSACTION_WIDTH words 
    //wishbone port parameters
    parameter Dw            =   32,
    parameter S_Aw          =   7,
    parameter M_Aw          =   32,
    parameter TAGw          =   3,
    parameter SELw          =   4


)
(
     // 
    reset,
    clk,
    
    //ctrl signals
    rd_enable,
    wr_enable,
    state_reg_enable,
    rd_is_busy,
    wr_is_busy,
    rd_is_active,
    wr_is_active,
    last_burst,
    status,
    
    //fifo signals
    fifo_wr, 
    fifo_rd, 
    fifo_full,
    fifo_nearly_full,
    fifo_empty,
    
    //busrdt counter control signals
    burst_counter_ld,
    burst_counter_dec,
    burst_size_is_set,
     
     //wishbone slave interface signals
    s_dat_i,
    s_sel_i,
    s_addr_i,  
    s_cti_i,
    s_stb_i,
    s_cyc_i,
    s_we_i,    
   // s_dat_o,
   // s_ack_o,
    

   
    //wishbone master rd interface signals
    m_rd_sel_o,
    m_rd_addr_o,
    m_rd_cti_o,
    m_rd_stb_o,
    m_rd_cyc_o,
    m_rd_we_o,
  //  m_rd_dat_i,
    m_rd_ack_i,    


     //wishbone master wr interface signals
     
    m_wr_sel_o,
   // m_wr_dat_o,
    m_wr_addr_o,
    m_wr_cti_o,
    m_wr_stb_o,
    m_wr_cyc_o,
    m_wr_we_o,
    m_wr_ack_i  
     
  
    

);


    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 

    localparam
        WORLD_SIZE = Dw/8,
        OFFSET_w= log2(WORLD_SIZE);
        
        
        
        
        
    //state machine registers/parameters
    localparam
        RD_ST_NUM=3,
        WR_ST_NUM=3;
    localparam [RD_ST_NUM-1 :   0]
        RD_IDEAL = 1,
        RD_ACTIVE =2,
        RD_RELEASE_WB=4;    
        
        
    localparam [WR_ST_NUM-1:0]
        WR_IDEAL = 1,
        WR_READ_FIFO=2,
        WR_ACTIVE =4;
        
    
    localparam [2 : 0]
        CLASSIC = 3'b000,
        CONST_ADDR_BURST = 3'b010,
        INCREMENT_BURST = 3'b011,
        END_OF_BURST = 3'b111;
        
        
      //control Registers/ parameters 
    
    localparam [S_Aw-1  :   0]
        DMA_STATUS_WB_ADDR =0, 
        BURST_SIZE_WB_ADDR =1, // The busrt size in words
        DATA_SIZE_WB_ADDR =2,  // The transfer data size in byte
        RD_STRT_WB_ADDR =   3, // The source start address in byte       
        WR_STRT_WB_ADDR=4; // the destination start address in byte   
            

    localparam STATUSw=RD_ST_NUM+WR_ST_NUM+1;
   
    output  [STATUSw-1  :0] status;  


    input reset,clk,rd_enable,wr_enable, state_reg_enable;
    output reg rd_is_busy, wr_is_busy;
    output reg burst_counter_ld,    burst_counter_dec;
    input burst_size_is_set;
    input last_burst;
    output reg rd_is_active, wr_is_active;
    
    
    //fifo
    output reg  fifo_wr, fifo_rd;
    input       fifo_full, fifo_nearly_full, fifo_empty;
    
    
     //wishbone slave interface signals
    input   [Dw-1       :   0]      s_dat_i;
    input   [SELw-1     :   0]      s_sel_i;
    input   [S_Aw-1     :   0]      s_addr_i;  
    input   [TAGw-1     :   0]      s_cti_i;
    input                           s_stb_i;
    input                           s_cyc_i;
    input                           s_we_i;
    
  //  output      [Dw-1       :   0]  s_dat_o;
  //  output  reg                     s_ack_o;
  
    
    
    //wishbone read master interface signals
    output  [SELw-1          :   0] m_rd_sel_o;
    output  [M_Aw-1          :   0] m_rd_addr_o;
    output reg [TAGw-1       :   0] m_rd_cti_o;
    output                          m_rd_stb_o;
    output   reg                    m_rd_cyc_o;
    output                          m_rd_we_o;
   // input   [Dw-1           :  0]   m_rd_dat_i;
    input                           m_rd_ack_i;    
     
     //wishbone write master interface signals
    output  [SELw-1          :   0] m_wr_sel_o;
  //  output  [Dw-1            :   0] m_wr_dat_o;
    output  [M_Aw-1          :   0] m_wr_addr_o;
    output  reg [TAGw-1      :   0] m_wr_cti_o;
    output                          m_wr_stb_o;
    output  reg                     m_wr_cyc_o;
    output                          m_wr_we_o;
    input                           m_wr_ack_i;   
    
  
     
     
     wire dma_busy;
    
    
   
        
   
    wire [S_Aw-1    :   0] wb_wr_rd_addr;
    assign wb_wr_rd_addr =   s_addr_i [S_Aw-1 :   0];
        
    
    reg [Dw-1   :   0] rd_start_addr,rd_start_addr_next; 
    reg [Dw-1   :   0] wr_start_addr,wr_start_addr_next;
    
    reg [MAX_TRANSACTION_WIDTH-1    :   0] data_size, data_size_next;
    reg [MAX_TRANSACTION_WIDTH-1    :   0] rd_counter, rd_counter_next;
    reg [MAX_TRANSACTION_WIDTH-1    :   0] wr_counter, wr_counter_next;
   
    
    

    
        
        
    reg  rd_start, rd_done,wr_done;  
  
    wire last_data = (rd_counter == data_size-1'b1);
   
   
  
    
    
    reg [RD_ST_NUM-1    :0] rd_ps,rd_ns; // read  peresent state, read next sate 
    reg [WR_ST_NUM-1    :0] wr_ps,wr_ns; // read  peresent state, read next sate
    
    reg wr_is_busy_next, rd_is_busy_next;
   
   
    assign status= {wr_ps,rd_ps,dma_busy};
   // assign s_dat_o={{(Dw-STATUSw){1'b0}}, status};
   
     
     
    
    assign dma_busy = (rd_ps!= RD_IDEAL) | (wr_ps!= WR_IDEAL);
    
   
    assign m_rd_addr_o =  rd_start_addr + rd_counter;
    assign m_wr_addr_o =  wr_start_addr + wr_counter;
    assign m_rd_stb_o =  m_rd_cyc_o;
    assign m_wr_stb_o =  m_wr_cyc_o;
    assign m_wr_we_o = 1'b1;
    assign m_rd_we_o = 1'b0;
    //assign m_rd_cti_o = ( rd_data_end | burst_data_end | fifo_nearly_full) ? END_OF_BURST : CONST_ADDR_BURST;
    //assign m_wr_cti_o = (fifo_has_one_word & ~fifo_wr) ? END_OF_BURST : CONST_ADDR_BURST;
    assign m_wr_sel_o = 4'b1111;
    assign m_rd_sel_o = 4'b1111;
    
 //  assign  rd_is_busy = (rd_ps == RD_ACTIVE);
 //   assign  wr_is_busy = (wr_ps == WR_ACTIVE);
    
    
    
    //read state machine
    always @ (*) begin 
        // default values 
        rd_ns = rd_ps;
        rd_counter_next=rd_counter;
        burst_counter_ld=1'b0;
        burst_counter_dec=1'b0;
        m_rd_cti_o =  CONST_ADDR_BURST;
        m_rd_cyc_o=1'b0;
        fifo_wr=1'b0;
        rd_done = 1'b0;
        rd_is_active =1'b0;
        
            case(rd_ps)
                RD_IDEAL: begin 
                   if(rd_start) begin 
                        if (burst_size_is_set && (data_size>0)) begin 
                            rd_counter_next= {MAX_TRANSACTION_WIDTH{1'b0}};
                            burst_counter_ld=1'b1;
                            rd_ns = RD_ACTIVE;
                        end else begin // sett error reg
                        
                       end
                   end
                end // RD_IDEAL
                RD_ACTIVE: begin 
                    rd_is_active =1'b1; // this signal sends request to the rd_arbiter, the granted signal is rd_enable
                    if(rd_enable) begin 
                        m_rd_cyc_o=1'b1; 
                        if(last_data |  last_burst | (fifo_nearly_full & !fifo_rd))  m_rd_cti_o= END_OF_BURST;  
                        if(fifo_nearly_full & !fifo_rd)  rd_ns = RD_RELEASE_WB;
                               
                                
                        if (m_rd_ack_i) begin 
                                fifo_wr=1'b1;
                                rd_counter_next=rd_counter +1'b1;
                                burst_counter_dec=1'b1;
                                                                    
                                if(last_data) begin 
                                  rd_ns = RD_IDEAL;
                                  rd_done = 1'b1;
                                  
                                end else if (last_burst | (fifo_nearly_full & !fifo_rd)) begin 
                                  rd_ns = RD_RELEASE_WB;
                                 
                                end 
                        end 
                    end
                         
                end // RD_ACTIVE
                RD_RELEASE_WB: begin 
                    //burst_counter_next = burst_size;
                     
                      burst_counter_ld=1'b1;
                    if(!fifo_full) begin 
                        rd_ns = RD_ACTIVE;
                    end
                
                end //RD_RELEASE_WB
                    default: begin
                    
                    
                    end
            endcase      
    end//alays
    
 
 
 
 //write state machine    
    always @ (*) begin 
        // default values 
        wr_ns = wr_ps;
        wr_counter_next=wr_counter;
        m_wr_cyc_o=1'b0;
        m_wr_cti_o= CONST_ADDR_BURST;
        fifo_rd=1'b0;
        wr_done=1'b0;
        wr_is_active =1'b0;
        if (rd_start ) wr_counter_next = {MAX_TRANSACTION_WIDTH{1'b0}}; 
        
       
            case(wr_ps)
                WR_IDEAL: begin                   
                    if(!fifo_empty)begin 
                        wr_ns = WR_READ_FIFO;                         
                    end 
                    
                end // WR_IDEAL
                WR_READ_FIFO: begin 
                     wr_is_active =1'b1; // this signal sends request to the wr_arbiter, the granted signal is wr_enable
                     if(wr_enable) begin 
                          wr_ns = WR_ACTIVE; 
                          fifo_rd=1'b1;
                    end
                end
                
                
                WR_ACTIVE: begin 
                     wr_is_active =1'b1; // this signal sends request to the wr_arbiter, the granted signal is wr_enable
                     if(wr_enable) begin 
                            m_wr_cyc_o=1'b1; 
                            if (fifo_empty) begin 
                                m_wr_cti_o= END_OF_BURST;                             
                            end
                            if (m_wr_ack_i) begin 
                                wr_counter_next=wr_counter +1'b1;   
                                if (fifo_empty) begin 
                                    wr_ns = WR_IDEAL; 
                                    wr_done=1'b1;
                                end else begin 
                                    fifo_rd=1'b1;
                                end                 
                            end 
                     end               
                end // WR_ACTIVE
                default: begin
                    
                    
                    end
            endcase
       
    end//alays
    
    
    

    
    // update control registers
    always @ (*) begin 
        //default values
        rd_start_addr_next= rd_start_addr;
        wr_start_addr_next=wr_start_addr;
        data_size_next= data_size;
      //  burst_size_next= burst_size;
        rd_start = 1'b0;
        if(s_stb_i  &    s_we_i & state_reg_enable)   begin 
            if (!dma_busy)  begin   
                case(wb_wr_rd_addr)
                    RD_STRT_WB_ADDR: begin                    
                        rd_start_addr_next={{OFFSET_w{1'b0}},s_dat_i [Dw-1    : OFFSET_w]};
                    end //RD_STRT_WB_ADDR
                    DATA_SIZE_WB_ADDR: begin 
                        data_size_next=s_dat_i [MAX_TRANSACTION_WIDTH+OFFSET_w-1 :   OFFSET_w]; 
                    end //DATA_SIZE_WB_ADDR
                    BURST_SIZE_WB_ADDR: begin 
              //          burst_size_next=s_dat_i [BURST_SIZE_w-1 : 0];    
                    end //BURST_SIZE_WB_ADDR
                    WR_STRT_WB_ADDR: begin 
                        wr_start_addr_next= {{OFFSET_w{1'b0}},s_dat_i [Dw-1 :   OFFSET_w]};
                        rd_start = 1'b1;
                    end //WR_STRT_WB_ADDR
                          default :begin 
                          
                          
                          end                         
                 endcase//wb_wr_rd_addr
            end//if
        end//if
   end// always
    
    
    
    always @(*)begin 
        rd_is_busy_next= rd_is_busy;
        if(rd_start) rd_is_busy_next =1'b1;
        else if(rd_done) rd_is_busy_next=1'b0;
    end
    
    wire wr_start = ~fifo_empty;
     always @(*)begin 
        wr_is_busy_next= wr_is_busy;
        if(wr_done) wr_is_busy_next =1'b0;
        else if(wr_start) wr_is_busy_next=1'b1;
    end
    
   
    
    
    //registers assigmnet
    
    always @ (posedge clk or posedge reset)begin 
        if(reset) begin 
            rd_ps <= RD_IDEAL;
            wr_ps <= WR_IDEAL;
         //   s_ack_o <= 1'b0;
            rd_start_addr <= {Dw{1'b0}};
            wr_start_addr <= {Dw{1'b0}};
            data_size <= {MAX_TRANSACTION_WIDTH{1'b0}};
          //  burst_size <= {BURST_SIZE_w{1'b0}};   
            rd_counter <=  {MAX_TRANSACTION_WIDTH{1'b0}};
            wr_counter <=   {MAX_TRANSACTION_WIDTH{1'b0}}; 
            rd_is_busy<= 1'b0;
            wr_is_busy<= 1'b0;
       //     burst_counter <= {BURST_SIZE_w{1'b0}};
          
        end else begin 
            rd_ps <= rd_ns;
            wr_ps <= wr_ns;
            rd_start_addr <= rd_start_addr_next;
            wr_start_addr <= wr_start_addr_next;
            data_size <= data_size_next;
   //         burst_size <= burst_size_next;  
            rd_counter <=  rd_counter_next;
            wr_counter <=  wr_counter_next; 
            rd_is_busy <=rd_is_busy_next;
            wr_is_busy <=wr_is_busy_next;
       //     burst_counter<= burst_counter_next;            
       //     s_ack_o<=s_ack_o_next;
        end 
    end 
    
    
    
    
/*
    dma_fifo  #(
         .Dw(Dw),//data_width
         .B(FIFO_B) // buffer num
    ) 
    the_fifo
    (
         .din(m_rd_dat_i),   
         .wr_en(fifo_wr), 
         .rd_en(fifo_rd), 
         .dout(m_wr_dat_o),  
         .full(fifo_full),
         .nearly_full(fifo_nearly_full),
         .empty(fifo_empty),
         .reset(reset),
         .clk(clk)
    );
*/
 





endmodule




/**************
*   shared memory multi channel fifo  
*
****************/ 

module shared_mem_fifos #(
    parameter NUM      =   4,
    parameter B        =   4,   // buffer space :flit per VC 
    parameter Dw     =   32,
    parameter DEBUG_EN =   1
     
    )   
    (
        din,     // Data in
        fifo_num_wr,//write vertual channel   
        fifo_num_rd,//read vertual channel    
        wr_en,   // Write enable
        rd_en,   // Read the next word
        dout,    // Data out
        full,
        nearly_full,
        empty,
        reset,
        clk
        
    );

   
   
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 
    
    localparam      V       =   NUM,
                    Fw      =   Dw,   //flit width
                    BV      =   B   *   V;
    
    
    input  [Fw-1      :0]   din;     // Data in
    input  [V-1       :0]   fifo_num_wr;//write vertual channel   
    input  [V-1       :0]   fifo_num_rd;//read vertual channel    
    input                   wr_en;   // Write enable
    input                   rd_en;   // Read the next word
    output [Fw-1       :0]  dout;    // Data out
    
    output [V-1 :   0] full;
    output [V-1 :   0] nearly_full;
    output [V-1 :   0] empty;
    
    
    
   
    input                   reset;
    input                   clk;
   
    
    localparam BVw              =   log2(BV),
               Bw               =   (B==1)? 1 : log2(B),
               Vw               =  (V==1)? 1 : log2(V),
               DEPTHw           =   Bw+1,
               BwV              =   Bw * V,
               BVwV             =   BVw * V,
               RAM_DATA_WIDTH   =   Fw ;
               
               
               
    wire  [RAM_DATA_WIDTH-1     :   0] fifo_ram_din;
    wire  [RAM_DATA_WIDTH-1     :   0] fifo_ram_dout;
    wire  [V-1                  :   0] wr;
    wire  [V-1                  :   0] rd;
    reg   [DEPTHw-1             :   0] depth    [V-1            :0];
    
    
    assign fifo_ram_din = din;
    assign dout = fifo_ram_dout;    
    assign  wr  =   (wr_en)?  fifo_num_wr : {V{1'b0}};
    assign  rd  =   (rd_en)?  fifo_num_rd : {V{1'b0}};
    
    
    //assign dout = queue[rd_ptr];
   
    
    

genvar i;

generate 
    if((2**Bw)==B)begin :pow2
        /*****************      
          Buffer width is power of 2
        ******************/
    reg [Bw- 1      :   0] rd_ptr [V-1          :0];
    reg [Bw- 1      :   0] wr_ptr [V-1          :0];
    
    
    
    
    wire [BwV-1    :    0]  rd_ptr_array;
    wire [BwV-1    :    0]  wr_ptr_array;
    wire [Bw-1     :    0]  vc_wr_addr;
    wire [Bw-1     :    0]  vc_rd_addr; 
    wire [Vw-1     :    0]  wr_select_addr;
    wire [Vw-1     :    0]  rd_select_addr; 
    wire [Bw+Vw-1  :    0]  wr_addr;
    wire [Bw+Vw-1  :    0]  rd_addr;
    
    
    
    
    assign  wr_addr =   {wr_select_addr,vc_wr_addr};
    assign  rd_addr =   {rd_select_addr,vc_rd_addr};
    
    
    
    one_hot_mux #(
        .IN_WIDTH       (BwV),
        .SEL_WIDTH      (V) 
    )
    wr_ptr_mux
    (
        .mux_in         (wr_ptr_array),
        .mux_out            (vc_wr_addr),
        .sel                (fifo_num_wr)
    );
    
        
    
    one_hot_mux #(
        .IN_WIDTH       (BwV),
        .SEL_WIDTH      (V) 
    )
    rd_ptr_mux
    (
        .mux_in         (rd_ptr_array),
        .mux_out            (vc_rd_addr),
        .sel                (fifo_num_rd)
    );
    
    
    
    one_hot_to_bin #(
    .ONE_HOT_WIDTH  (V)
    
    )
    wr_vc_start_addr
    (
    .one_hot_code   (fifo_num_wr),
    .bin_code       (wr_select_addr)

    );
    
    one_hot_to_bin #(
    .ONE_HOT_WIDTH  (V)
    
    )
    rd_vc_start_addr
    (
    .one_hot_code   (fifo_num_rd),
    .bin_code       (rd_select_addr)

    );

    fifo_ram    #(
        .DATA_WIDTH (RAM_DATA_WIDTH),
        .ADDR_WIDTH (BVw ),
        .SSA_EN("NO")       
    )
    the_queue
    (
        .wr_data        (fifo_ram_din), 
        .wr_addr        (wr_addr[BVw-1  :   0]),
        .rd_addr        (rd_addr[BVw-1  :   0]),
        .wr_en          (wr_en),
        .rd_en          (rd_en),
        .clk            (clk),
        .rd_data        (fifo_ram_dout)
    );  

    for(i=0;i<V;i=i+1) begin :loop0
    
        assign full[i] = (depth [i] == B);
        assign nearly_full[i] = depth[i] >= B-1;
        assign empty[i] = depth[i] == {DEPTHw{1'b0}};
    
        
        assign  wr_ptr_array[(i+1)*Bw- 1        :   i*Bw]   =       wr_ptr[i];
        assign  rd_ptr_array[(i+1)*Bw- 1        :   i*Bw]   =       rd_ptr[i];
        //assign    vc_nearly_full[i] = (depth[i] >= B-1);
       
    
    
        always @(posedge clk or posedge reset)
        begin
            if (reset) begin
                rd_ptr  [i] <= {Bw{1'b0}};
                wr_ptr  [i] <= {Bw{1'b0}};
                depth   [i] <= {DEPTHw{1'b0}};
            end
            else begin
                if (wr[i] ) wr_ptr[i] <= wr_ptr [i]+ 1'h1;
                if (rd[i] ) rd_ptr [i]<= rd_ptr [i]+ 1'h1;
                if (wr[i] & ~rd[i]) depth [i]<=
//synthesis translate_off
//synopsys  translate_off
                   #1
//synopsys  translate_on
//synthesis translate_on
                   depth[i] + 1'h1;
                else if (~wr[i] & rd[i]) depth [i]<=
//synthesis translate_off
//synopsys  translate_off
                   #1
//synopsys  translate_on
//synthesis translate_on
                   depth[i] - 1'h1;
            end//else
        end//always


//synthesis translate_off
//synopsys  translate_off
    
        always @(posedge clk) begin
            if(~reset)begin
                if (wr[i] && (depth[i] == B) && !rd[i])
                    $display("%t: ERROR: Attempt to write to full FIFO: %m",$time);
                if (rd[i] && (depth[i] == {DEPTHw{1'b0}}   ))
                    $display("%t: ERROR: Attempt to read an empty FIFO: %m",$time);
                
          end//~reset      
        //if (wr_en)       $display($time, " %h is written on fifo ",din);
        end//always
//synopsys  translate_on
//synthesis translate_on
    end//for
    
    
    
    end  else begin :no_pow2    //pow2





    /*****************      
        Buffer width is not power of 2
     ******************/




    
    //pointers
    reg [BVw- 1     :   0] rd_ptr [V-1          :0];
    reg [BVw- 1     :   0] wr_ptr [V-1          :0];
    
    // memory address
    wire [BVw- 1    :   0]  wr_addr;
    wire [BVw- 1    :   0]  rd_addr;
    
    //pointer array      
    wire [BVwV- 1   :   0]  wr_addr_all;
    wire [BVwV- 1   :   0]  rd_addr_all;
    
    for(i=0;i<V;i=i+1) begin :loop0
        
        assign  wr_addr_all[(i+1)*BVw- 1        :   i*BVw]   =       wr_ptr[i];
        assign  rd_addr_all[(i+1)*BVw- 1        :   i*BVw]   =       rd_ptr[i];       
        assign full[i] = (depth [i] == B);
        assign nearly_full[i] = depth[i] >= B-1;
        assign empty[i] = depth[i] == {DEPTHw{1'b0}};
    
    
        always @(posedge clk or posedge reset)
        begin
            if (reset) begin
                rd_ptr  [i] <= (B*i);
                wr_ptr  [i] <= (B*i);
                depth   [i] <= {DEPTHw{1'b0}};
            end
            else begin
                if (wr[i] ) wr_ptr[i] <=(wr_ptr[i]==(B*(i+1))-1)? (B*i) : wr_ptr [i]+ 1'h1;
                if (rd[i] ) rd_ptr[i] <=(rd_ptr[i]==(B*(i+1))-1)? (B*i) : rd_ptr [i]+ 1'h1;
                if (wr[i] & ~rd[i]) depth [i]<=
//synthesis translate_off
//synopsys  translate_off
                   #1
//synopsys  translate_on
//synthesis translate_on
                   depth[i] + 1'h1;
                else if (~wr[i] & rd[i]) depth [i]<=
//synthesis translate_off
//synopsys  translate_off
                   #1          
//synopsys  translate_on
//synthesis translate_on
                   depth[i] - 1'h1;
            end//else
        end//always  
        
        
//synthesis translate_off
//synopsys  translate_off
    
        always @(posedge clk) begin
            if(~reset)begin
                if (wr[i] && (depth[i] == B) && !rd[i])
                    $display("%t: ERROR: Attempt to write to full FIFO: %m",$time);
                if (rd[i] && (depth[i] == {DEPTHw{1'b0}}   ))
                    $display("%t: ERROR: Attempt to read an empty FIFO: %m",$time);
               
                
        //if (wr_en)       $display($time, " %h is written on fifo ",din);
            end//~reset
        end//always
    
//synopsys  translate_on
//synthesis translate_on
        
              
    
    end//FOR
    
    
    one_hot_mux #(
        .IN_WIDTH(BVwV),
        .SEL_WIDTH(V),
        .OUT_WIDTH(BVw)
    )
    wr_mux
    (
        .mux_in(wr_addr_all),
        .mux_out(wr_addr),
        .sel(fifo_num_wr)
    );
    
    one_hot_mux #(
        .IN_WIDTH(BVwV),
        .SEL_WIDTH(V),
        .OUT_WIDTH(BVw)
    )
    rd_mux
    (
        .mux_in(rd_addr_all),
        .mux_out(rd_addr),
        .sel(fifo_num_rd)
    );
    
    fifo_ram_mem_size #(
       .DATA_WIDTH (RAM_DATA_WIDTH),
       .MEM_SIZE (BV ),
       .SSA_EN("NO")       
    )
    the_queue
    (
        .wr_data        (fifo_ram_din), 
        .wr_addr        (wr_addr),
        .rd_addr        (rd_addr),
        .wr_en          (wr_en),
        .rd_en          (rd_en),
        .clk            (clk),
        .rd_data        (fifo_ram_dout)
    );  
    
    
    
    
    
    
    end
    endgenerate
    
    
    
    
  

//synthesis translate_off
//synopsys  translate_off
generate
if(DEBUG_EN) begin :dbg 
    always @(posedge clk) begin
        if(~reset)begin
            if(wr_en && fifo_num_wr == {V{1'b0}})
                    $display("%t: ERROR: Attempt to write when no wr channel is asserted: %m",$time);
            if(rd_en && fifo_num_rd == {V{1'b0}})
                    $display("%t: ERROR: Attempt to read when no rd channel  is asserted: %m",$time);
        end
    end
end 
endgenerate 
//synopsys  translate_on
//synthesis translate_on    

endmodule 

