
/**********************************************************************
**	File:  ni_master.v 
**	Date:2017-06-04
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
**	Description: multi-channel DMA-based network interace for 
**	handelling packetizing/depacketizing data to/form NoC. 
**	Can support CRC32 
**	
**
*******************************************************************/


 `timescale  1ns/1ps

module  ni_master #(    
    parameter MAX_TRANSACTION_WIDTH=10, // Maximum transaction size will be 2 power of MAX_DMA_TRANSACTION_WIDTH words 
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
     // 
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
    

   
    //wishbone master rd interface signals
    m_send_sel_o,
    m_send_addr_o,
    m_send_cti_o,
    m_send_stb_o,
    m_send_cyc_o,
    m_send_we_o,
    m_send_dat_i,
    m_send_ack_i,    


     //wishbone master wr interface signals
     
    m_receive_sel_o,
    m_receive_dat_o,
    m_receive_addr_o,
    m_receive_cti_o,
    m_receive_stb_o,
    m_receive_cyc_o,
    m_receive_we_o,
    m_receive_ack_i,
    
    //intruupt interface
    irq    

);
     localparam P=  (TOPOLOGY=="RING" || TOPOLOGY=="LINE")? 3 : 5;   
     localparam ROUTE_TYPE = (ROUTE_NAME == "XY" || ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
                           (ROUTE_NAME == "DUATO" || ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE";    

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
                Yw =   log2(NY),
                Cw =   log2(C);

 
    input reset,clk;
   

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
    
    output  reg    [Dw-1       :   0]  s_dat_o;
    output  reg                     s_ack_o;
  
    
    
    //wishbone read master interface signals
    output  [SELw-1          :   0] m_send_sel_o;
    output  [M_Aw-1          :   0] m_send_addr_o;
    output  [TAGw-1          :   0] m_send_cti_o;
    output                          m_send_stb_o;
    output                          m_send_cyc_o;
    output                          m_send_we_o;
    input   [Dw-1           :  0]   m_send_dat_i;
    input                           m_send_ack_i;    
     
     //wishbone write master interface signals
    output  [SELw-1          :   0] m_receive_sel_o;
    output  [Dw-1            :   0] m_receive_dat_o;
    output  [M_Aw-1          :   0] m_receive_addr_o;
    output  [TAGw-1          :   0] m_receive_cti_o;
    output                          m_receive_stb_o;
    output                          m_receive_cyc_o;
    output                          m_receive_we_o;
    input                           m_receive_ack_i;   
    
      //Interrupt  interface
    output                          irq;
  
  
    wire                            s_ack_o_next;
    
     
    
    localparam 
        CHw=log2(V),
        BURST_SIZE_w= log2(MAX_BURST_SIZE);
    
     /*   wishbone slave adderess :
    
    [3:0]  
            0   :   STATUS1_WB_ADDR           // status1:  {send_enable_binary,receive_enable_binary,send_vc_is_busy,receive_vc_is_busy,receive_vc_got_packet}
            1   :   STATUS2_WB_ADDR           // status2:   
            2   :   BURST_SIZE_WB_ADDR       // The busrt size in words 
            
            3   :   SEND_DATA_SIZE_WB_ADDR,  // The size of data to be sent in byte  
            4   :   SEND_STRT_WB_ADDR,       // The address of data to be sent   in byte       
            5   :   SEND_DEST_WB_ADDR        // The destination router address
            6   :   SEND_CTRL_WB_ADDR
            
            7   :   RECEIVE_DATA_SIZE_WB_ADDR // The size of recieved data in byte  
            8   :   RECEIVE_STRT_WB_ADDR      // The address pointer of reciever memory in byte
            9   :   RECEIVE_SRC_WB_ADDR       // The source router (the router which is sent this packet). 
            10  :   RECEIVE_CTRL_WB_ADDR      // The NI reciever control register 
            11  :   RECEIVE_MAX_BUFF_SIZ      // The reciver allocated buffer size in words. If the packet size is bigger tha the buffer size the rest of will be discarred
            
            
                     
                      
    [4+Vw:4]
                : Virtual channel num       
      
    */
    localparam CHANNEL_ADDRw= 4,
                    CHANNEL_REGw = 4;
    
    wire [CHw-1 :   0] vc_addr = s_addr_i [CHANNEL_REGw+CHw-1	:	CHANNEL_REGw];
    wire [CHANNEL_ADDRw-1     :   0] vc_s_addr_i = s_addr_i [CHANNEL_ADDRw-1: 0];
    
  
    
     localparam [CHANNEL_ADDRw-1  :   0]
        STATUS1_WB_ADDR  =   0,          // status 
        STATUS2_WB_ADDR  =   1,          // status 
        BURST_SIZE_WB_ADDR = 2,         // The busrt size in words 
        RECEIVE_DATA_SIZE_WB_ADDR = 7,  // The size of recieved data in byte  
        RECEIVE_SRC_WB_ADDR =9;         // The source router (the router which is sent this packet). 
        
        
        
        
       
 
    reg [BURST_SIZE_w-1  :   0] burst_size, burst_size_next,burst_counter,burst_counter_next;
  
    
    wire [V-1 :   0] receive_vc_is_busy, send_vc_is_busy;
    wire [V-1 :   0] receive_vc_enable,send_vc_enable,vc_state_reg_enable;
    wire [V-1 :   0] vc_burst_counter_ld, vc_burst_counter_dec;
    wire [V-1 :   0] vc_fifo_wr, vc_fifo_rd;
    wire [V-1 :   0] vc_fifo_full, vc_fifo_nearly_full, vc_fifo_empty;
    wire [V-1 :   0] send_vc_is_active,receive_vc_is_active;
    wire [CHw-1:  0] send_enable_binary,receive_enable_binary;
     
     
     
    wire  [SELw-1    :   0] vc_m_send_sel_o  [V-1 :   0];
    wire  [M_Aw-1    :   0] vc_m_send_addr_o [V-1 :   0];
    wire  [TAGw-1    :   0] vc_m_send_cti_o  [V-1 :   0];
    wire  [V-1 :   0] vc_m_send_stb_o; 
    wire  [V-1 :   0] vc_m_send_cyc_o; 
    wire  [V-1 :   0] vc_m_send_we_o; 
    wire  [V-1 :   0] save_hdr_info;    
            
    wire  [SELw-1    :   0] vc_m_receive_sel_o  [V-1 :   0];
    wire  [M_Aw-1    :   0] vc_m_receive_addr_o [V-1 :   0];
    wire  [TAGw-1    :   0] vc_m_receive_cti_o  [V-1 :   0];
    wire  [V-1 :   0] vc_m_receive_stb_o; 
    wire  [V-1 :   0] vc_m_receive_cyc_o; 
    wire  [V-1 :   0] vc_m_receive_we_o; 

    wire  [MAX_TRANSACTION_WIDTH-1    :   0] receive_counter [V-1 :   0];            
 
    wire  [V-1    :   0] send_vc_fsm_is_ideal,receive_vc_fsm_is_ideal;
    wire  [Dw-1   :   0] send_vc_start_addr [V-1   :  0]; 
    wire  [Dw-1   :   0] receive_vc_start_addr [V-1   :  0];
    wire  [V-1    :   0] receive_vc_got_packet;
    
    wire [MAX_TRANSACTION_WIDTH-1    :   0] send_vc_data_size [V-1   :  0];
    wire [MAX_TRANSACTION_WIDTH-1    :   0] receive_vc_max_buff_siz [V-1   :  0];
    wire [V-1   :  0]   send_vc_start, receive_vc_start; 
    wire  received_flit_is_tail,received_flit_is_hdr;
    
    wire [Xw-1   :   0]  vc_dest_x [V-1   :  0];
    wire [Yw-1   :   0]  vc_dest_y [V-1   :  0];
    wire [Cw-1   :   0]  vc_pck_class [V-1   :  0];   
    wire [V-1    :   0]  send_vc_send_hdr,send_vc_send_tail;
    wire [V-1    :   0]  send_vc_done,receive_vc_done;    
    wire [V-1	 :   0]  receive_vc_packet_is_saved;

    wire [Xw-1   :   0]  dest_x;
    wire [Yw-1   :   0]  dest_y;
    wire [Cw-1   :   0]  pck_class;  
    wire send_hdr, send_tail;
    wire [Fw-1   :   0] hdr_flit_out; 
     
    
    wire burst_counter_ld = | vc_burst_counter_ld; 
    wire burst_counter_dec= | vc_burst_counter_dec;
    wire fifo_wr = | vc_fifo_wr; 
    wire fifo_rd = | vc_fifo_rd;
    wire any_vc_got_pck;
    wire any_vc_send_done = | send_vc_done;     
    wire any_vc_save_done = | receive_vc_done;        
    wire last_burst = (burst_counter == 1);
    wire burst_is_set =  (burst_size>0);
    
    wire [Cw-1   :   0] class_in_next;
    wire [Xw-1   :   0] x_src_in_next;
    wire [Yw-1   :   0] y_src_in_next;
    wire [Fpay-1    :   0] tail_flit_out;
   
    reg [Cw-1   :   0] class_in [V-1    :   0];
    reg [Xw-1   :   0] x_src_in [V-1    :   0];
    reg [Yw-1   :   0] y_src_in [V-1    :   0];
    reg [V-1    :   0] crc_miss_match;
   
    reg     got_pck_isr, save_done_isr, send_done_isr,got_pck_int_en, save_done_int_en,send_done_int_en;
    reg     got_pck_isr_next, save_done_isr_next,send_done_isr_next,got_pck_int_en_next, save_done_int_en_next,send_done_int_en_next;
    
    
    localparam
        STATUS1w= 4 * V,
        STATUS2w= 2 * CHw + V + 6; 
    
    
    localparam 
        SEND_DONE_INT_EN_LOC=0,
        SAVE_DONE_INT_EN_LOC=1,
        GOT_PCK_INT_EN_LOC=2,              
        SAVE_DONE_ISR_LOC=3,
        SEND_DONE_ISR_LOC=4,
        GOT_PCK_ISR_LOC=5;         
    
    
    wire  [STATUS1w-1  :0] status1;
    wire  [STATUS2w-1  :0] status2;  
  
    assign status1= {send_vc_is_busy,receive_vc_is_busy,receive_vc_packet_is_saved,receive_vc_got_packet};
    assign status2= {send_enable_binary,receive_enable_binary,crc_miss_match,got_pck_isr, save_done_isr,send_done_isr,got_pck_int_en, save_done_int_en,send_done_int_en};
    
        
    
    assign  irq = (got_pck_isr & got_pck_int_en) | (save_done_isr & save_done_int_en) | (send_done_isr & send_done_int_en);
    
                   
                   
    //read wb registers                
    always @(*)begin 
        s_dat_o ={Dw{1'b0}};
        case(vc_s_addr_i)
        STATUS1_WB_ADDR: begin 
            s_dat_o = {{(Dw-STATUS1w){1'b0}}, status1};
        end 
        STATUS2_WB_ADDR: begin 
            s_dat_o = {{(Dw-STATUS2w){1'b0}}, status2};
        end
        RECEIVE_DATA_SIZE_WB_ADDR: begin        
            s_dat_o   [MAX_TRANSACTION_WIDTH-1    :   0] = receive_counter[vc_addr];
        end  
        RECEIVE_SRC_WB_ADDR: begin            
            s_dat_o[Xw-1     : 0] = x_src_in[vc_addr];   
            s_dat_o[(DST_ADR_HDR_WIDTH/2)+Yw-1: DST_ADR_HDR_WIDTH/2] = y_src_in[vc_addr];                                            
            s_dat_o[Cw+DST_ADR_HDR_WIDTH-1    :   DST_ADR_HDR_WIDTH]  =   class_in[vc_addr];             
        end        
        default: begin 
             s_dat_o = {{(Dw-STATUS1w){1'b0}}, status1};        
        end       
        endcase      
    end      
     
   
   
    
    //write wb registers
    always @ (*)begin 
        burst_counter_next=burst_counter;
        burst_size_next= burst_size;
        if(burst_counter_ld)    burst_counter_next = burst_size;
        if(burst_counter_dec)   burst_counter_next= burst_counter- 1'b1;
        
        //isr 
        got_pck_int_en_next  = got_pck_int_en;
        save_done_int_en_next= save_done_int_en;
        send_done_int_en_next= send_done_int_en;
        got_pck_isr_next  = got_pck_isr;          
        save_done_isr_next= save_done_isr;
        send_done_isr_next= send_done_isr;
        
        if(any_vc_got_pck)      got_pck_isr_next  = 1'b1;
        if(any_vc_save_done)    save_done_isr_next  = 1'b1;
        if(any_vc_send_done)    send_done_isr_next  = 1'b1;
        
        if(s_stb_i  &    s_we_i)   begin 
            case(vc_s_addr_i)
                    BURST_SIZE_WB_ADDR: begin 
                         if (send_vc_is_busy == {V{1'b0}}) burst_size_next=s_dat_i [BURST_SIZE_w-1 : 0];    
                    end //BURST_SIZE_WB_ADDR
                    STATUS2_WB_ADDR:    begin 
                        got_pck_int_en_next = s_dat_i[GOT_PCK_INT_EN_LOC];
                        save_done_int_en_next = s_dat_i[SAVE_DONE_INT_EN_LOC];
                        send_done_int_en_next = s_dat_i[SEND_DONE_INT_EN_LOC];
                        // reset isr register by writting one on them
                        if (s_dat_i[GOT_PCK_ISR_LOC]) got_pck_isr_next = 1'b0;
                        if (s_dat_i[SAVE_DONE_ISR_LOC]) save_done_isr_next = 1'b0;
                        if (s_dat_i[SEND_DONE_ISR_LOC]) send_done_isr_next = 1'b0;                   
                    end //STATUS2_WB_ADDR 
		    default begin

		    end                   
            endcase
        end        
           
    end 
    
    
    always @ (posedge clk or posedge reset)begin 
        if(reset) begin 
            burst_counter <= {BURST_SIZE_w{1'b0}};
            burst_size <= {BURST_SIZE_w{1'b1}};
            s_ack_o <= 1'b0;  
            got_pck_int_en <= 1'b0;
            save_done_int_en <= 1'b0;
            send_done_int_en <= 1'b0;
            got_pck_isr <= 1'b0;
            save_done_isr <= 1'b0;
            send_done_isr <= 1'b0; 
        end else begin 
            burst_counter<= burst_counter_next; 
            burst_size <= burst_size_next; 
            s_ack_o <= s_ack_o_next;  
            got_pck_int_en <= got_pck_int_en_next;
            save_done_int_en <= save_done_int_en_next;
            send_done_int_en <= send_done_int_en_next;
            got_pck_isr <= got_pck_isr_next;            
            save_done_isr <= save_done_isr_next;
            send_done_isr <= send_done_isr_next;         
        end 
    end 
    
   
    bin_to_one_hot #(
        .BIN_WIDTH(CHw),
        .ONE_HOT_WIDTH(V)
   )
   convert
   (
        .bin_code(vc_addr),
        .one_hot_code(vc_state_reg_enable)
   );
   
    assign s_ack_o_next    =   s_stb_i & (~s_ack_o);
    
    
    genvar i;
    generate
    for (i=0;i<V; i=i+1) begin : vc_
    
    
        ni_vc_wb_slave_regs #(
            .MAX_TRANSACTION_WIDTH(MAX_TRANSACTION_WIDTH),
            .DST_ADR_HDR_WIDTH(DST_ADR_HDR_WIDTH),
            .NX(NX),
            .NY(NY),
            .C(C),
            .Dw(Dw),
            .S_Aw(CHANNEL_REGw)
           
        )
        wb_slave_registers
        (
            .clk(clk),
            .reset(reset),
            .state_reg_enable(vc_state_reg_enable[i]),
            .send_fsm_is_ideal(send_vc_fsm_is_ideal[i]),
            .receive_fsm_is_ideal(receive_vc_fsm_is_ideal[i]),
            .send_start_addr(send_vc_start_addr[i]),
            .receive_start_addr(receive_vc_start_addr[i]),
            .receive_done(receive_vc_done[i]),
            .receive_packet_is_saved(receive_vc_packet_is_saved[i]),
    
            .send_data_size(send_vc_data_size[i]),
            .max_receive_buff_siz(receive_vc_max_buff_siz[i]),
            .dest_x(vc_dest_x[i]),
            .dest_y(vc_dest_y[i]),
            .pck_class(vc_pck_class[i]),
            .send_start(send_vc_start[i]),
            .receive_start(receive_vc_start[i]),
            .receive_vc_got_packet(receive_vc_got_packet[i]),
            .s_dat_i(s_dat_i),
            .s_addr_i(s_addr_i[CHANNEL_REGw-1:0]),
            .s_stb_i(s_stb_i),
            .s_cyc_i(s_cyc_i),
            .s_we_i(s_we_i)
        );
   
    
    
    
    
        ni_vc_dma #(
            .CRC_EN(CRC_EN),
            .MAX_TRANSACTION_WIDTH(MAX_TRANSACTION_WIDTH),
            .Dw(Dw),
            .M_Aw(M_Aw),
            .TAGw(TAGw),
            .SELw(SELw)
        )
        vc_dma
        (
            .reset(reset),
            .clk(clk),
            .status(),
            
            //active-enable signals
            .send_enable(send_vc_enable[i]),
            .receive_enable(receive_vc_enable[i]),
            .send_is_busy(send_vc_is_busy[i]),
            .receive_is_busy(receive_vc_is_busy[i]),
            .send_is_active(send_vc_is_active[i]),
            .receive_is_active(receive_vc_is_active[i]),
            .burst_counter_ld(vc_burst_counter_ld[i]),
            .burst_counter_dec(vc_burst_counter_dec[i]),
            .burst_size_is_set(burst_is_set),
            .last_burst(last_burst),
            .send_hdr(send_vc_send_hdr[i]),
            .send_tail(send_vc_send_tail[i]),
            .receive_counter(receive_counter[i]),
            .save_hdr_info(save_hdr_info[i]),
            .send_done(send_vc_done[i]),
            .receive_done(receive_vc_done[i]),    
                      
            .send_fsm_is_ideal(send_vc_fsm_is_ideal[i]),
            .receive_fsm_is_ideal(receive_vc_fsm_is_ideal[i]),
            .send_start_addr(send_vc_start_addr[i]),
            .receive_start_addr(receive_vc_start_addr[i]),
            .send_data_size(send_vc_data_size[i]),
            .max_receive_buff_siz(receive_vc_max_buff_siz[i]),
            .send_start(send_vc_start[i]),
            .receive_start(receive_vc_start[i]),
            .received_flit_is_tail(received_flit_is_tail),
            
            //fifo
            .send_fifo_wr(vc_fifo_wr[i]), 
            .send_fifo_full(vc_fifo_full[i]),
            .send_fifo_nearly_full(vc_fifo_nearly_full[i]),
            .send_fifo_rd(credit_in[i]),
            .receive_fifo_empty(vc_fifo_empty[i]),
            .receive_fifo_rd(vc_fifo_rd[i]), 
         
                        
                        
            //
            .m_send_sel_o(vc_m_send_sel_o[i]),
            .m_send_addr_o(vc_m_send_addr_o[i]),
            .m_send_cti_o(vc_m_send_cti_o[i]),
            .m_send_stb_o(vc_m_send_stb_o[i]),
            .m_send_cyc_o(vc_m_send_cyc_o[i]),
            .m_send_we_o(vc_m_send_we_o[i]),
        //  .m_send_dat_i(m_send_dat_i),
            .m_send_ack_i(m_send_ack_i),
            
            
            .m_receive_sel_o(vc_m_receive_sel_o[i]),
        //  .m_receive_dat_o(vc_m_receive_dat_o[i]),
            .m_receive_addr_o(vc_m_receive_addr_o[i]),
            .m_receive_cti_o(vc_m_receive_cti_o[i]),
            .m_receive_stb_o(vc_m_receive_stb_o[i]),
            .m_receive_cyc_o(vc_m_receive_cyc_o[i]),
            .m_receive_we_o(vc_m_receive_we_o[i]),
            .m_receive_ack_i(m_receive_ack_i)
        );
        
        
        always @ (posedge clk or posedge reset)begin 
            if(reset) begin 
                class_in[i]<= {Cw{1'b0}};
                x_src_in[i]<= {Xw{1'b0}};
                y_src_in[i]<= {Yw{1'b0}};
            end else if(save_hdr_info[i])begin 
                class_in[i]<= class_in_next;
                x_src_in[i]<= x_src_in_next;
                y_src_in[i]<= y_src_in_next;
            end
        end//always
   
    end  // for loop for channel
    
    if(  CRC_EN == "YES") begin :crc_blk
  
      reg fifo_rd_delayed;
      always @(posedge clk or posedge reset)begin 
        if(reset) fifo_rd_delayed <=1'b0;
        else fifo_rd_delayed <= fifo_rd;
      end
  
      wire send_crc_enable =  flit_out_wr & ~send_hdr &   ~send_tail;
      wire receive_crc_enable =  fifo_rd_delayed & ~ received_flit_is_tail & ~received_flit_is_hdr;
      wire [31:0]  send_crc_out,receive_crc_out;
                                        
        crc_32_multi_channel #(
            .CHANNEL(V)
        )
        send_crc
        (
            .reset(reset),
            .clk(clk),
            .crc_reset(send_hdr),
            .crc_enable(send_crc_enable),
            .channel_in(send_enable_binary),
            .data_in(m_send_dat_i [Fpay-1 : 0]),
            .crc_out(send_crc_out)
        );
        
        
        
        crc_32_multi_channel #(
        	.CHANNEL(V)
        )
         receive_crc
         (
        	.reset(reset),
        	.clk(clk),
        	.crc_reset(received_flit_is_hdr),
        	.crc_enable(receive_crc_enable),
        	.channel_in(receive_enable_binary),
        	.data_in(m_receive_dat_o[Fpay-1 : 0]),
        	.crc_out(receive_crc_out)
        );
        
        for (i=0;i<V;i=i+1) begin: crc_v
            always @ (posedge clk or posedge reset)begin 
                if(reset) begin 
                    crc_miss_match[i] <= 1'b0;
                end else begin 
                    if(receive_enable_binary==i && received_flit_is_tail && m_receive_stb_o ) begin 
                        crc_miss_match[i] <= receive_crc_out[31:0] != m_receive_dat_o[31 : 0];
                    end                
                end
            
            end
        end//for
        
        assign tail_flit_out[31 : 0]  =  send_crc_out;
    end   else begin : no_crc 
        assign tail_flit_out   =  m_send_dat_i [Fpay-1 : 0];
        always @ ( *) crc_miss_match = {V{1'b0}};
    end
   
    
   
    
  
    if(V> 1) begin : multi_channel
    
        // round roubin arbiter
        bus_arbiter # (
            .M (V)
        )
        receive_arbiter
        (
            .request (receive_vc_is_active),
            .grant  (receive_vc_enable),
            .clk (clk),
            .reset (reset)
        );
                
        bus_arbiter # (
            .M (V)
        )
        send_arbiter
        (
            .request (send_vc_is_active),
            .grant  (send_vc_enable),
            .clk (clk),
            .reset (reset)
        );
        
        
        one_hot_to_bin #(
            .ONE_HOT_WIDTH(V),
            .BIN_WIDTH(CHw)
        )
        send_en_conv
        (
            .one_hot_code(send_vc_enable),
            .bin_code(send_enable_binary)
        );
        
        
         one_hot_to_bin #(
            .ONE_HOT_WIDTH(V),
            .BIN_WIDTH(CHw)
        )
        receive_en_conv
        (
            .one_hot_code(receive_vc_enable),
            .bin_code(receive_enable_binary)
        );
        
        
    end else begin : single_channel // if we have just one channel there is no need for arbitration
        assign receive_vc_enable =  receive_vc_is_active;
        assign send_vc_enable =  send_vc_is_active;
        assign send_enable_binary = 1'b0;
        assign receive_enable_binary = 1'b0;
    end
    endgenerate  
    
     header_flit_generator #(
        .CLASS_HDR_WIDTH(CLASS_HDR_WIDTH),
        .ROUTING_HDR_WIDTH(ROUTING_HDR_WIDTH),
        .DST_ADR_HDR_WIDTH(DST_ADR_HDR_WIDTH),
        .SRC_ADR_HDR_WIDTH(SRC_ADR_HDR_WIDTH),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_TYPE(ROUTE_TYPE),
        .ROUTE_NAME(ROUTE_NAME),
        .V(V),
        .P(P),
        .NX(NX),
        .NY(NY),
        .C(C),
        .Fpay(Fpay)
    )
    the_header_flit_generator
    (
        .flit_out(hdr_flit_out),
        .class_in(pck_class),
        .x_dst_in(dest_x),
        .y_dst_in(dest_y),
        .x_src_in(current_x),
        .y_src_in(current_y),
        .vc_num_in(send_vc_enable)
    );
    
  
   
  wire [V-1    :   0] wr_vc_send =  (fifo_wr) ? send_vc_enable : {V{1'b0}};  
 
    
  ovc_status #(
    .V(V),
    .B(B)
  )
  the_ovc_status
  (
    .wr_in(wr_vc_send),
    .credit_in(credit_in),
    .full_vc(vc_fifo_full),
    .nearly_full_vc(vc_fifo_nearly_full),
    .empty_vc( ),
    .clk(clk),
    .reset(reset)
  );
    
    
    // header info mux    
    assign dest_x = vc_dest_x[send_enable_binary];
    assign dest_y = vc_dest_y[send_enable_binary];
    assign pck_class  = vc_pck_class[send_enable_binary];
    assign send_hdr = send_vc_send_hdr[send_enable_binary]; 
    assign send_tail = send_vc_send_tail[send_enable_binary]; 
    
    //wb multiplexors    
    assign m_send_sel_o  = vc_m_send_sel_o[send_enable_binary];
    assign m_send_addr_o = vc_m_send_addr_o[send_enable_binary];
    assign m_send_cti_o  = vc_m_send_cti_o[send_enable_binary];
    assign m_send_stb_o  = vc_m_send_stb_o[send_enable_binary];
    assign m_send_cyc_o  = vc_m_send_cyc_o[send_enable_binary];
    assign m_send_we_o   = vc_m_send_we_o[send_enable_binary];
       
                        
    assign m_receive_sel_o = vc_m_receive_sel_o[receive_enable_binary];
    assign m_receive_addr_o= vc_m_receive_addr_o[receive_enable_binary];
    assign m_receive_cti_o = vc_m_receive_cti_o[receive_enable_binary];
    assign m_receive_stb_o = vc_m_receive_stb_o[receive_enable_binary];
    assign m_receive_cyc_o = vc_m_receive_cyc_o[receive_enable_binary];
    assign m_receive_we_o  = vc_m_receive_we_o[receive_enable_binary];
    
    
          
    wire [V-1    :   0]  flit_in_vc_num = flit_in [Fpay+V-1    :   Fpay]; 
    wire [V-1    :   0]  ififo_vc_not_empty; 
    assign vc_fifo_empty = ~ ififo_vc_not_empty;
    assign receive_vc_got_packet = ififo_vc_not_empty;
   
    wire [Fw-1  :   0] fifo_dout;
    
    flit_buffer #(
        .V(V),
        .B(B),
        .Fpay(Fpay),
        .DEBUG_EN(DEBUG_EN),
        .SSA_EN("NO")
     )
     the_ififo
     (
        .din(flit_in),     // Data in
        .vc_num_wr(flit_in_vc_num),//write vertual channel    
        .wr_en(flit_in_wr),   // Write enable
        .vc_num_rd(receive_vc_enable),//read vertual channel     
        .rd_en(fifo_rd),   // Read the next word
        .dout(fifo_dout),    // Data out
        .vc_not_empty(ififo_vc_not_empty),
        .reset(reset),
        .clk(clk),
        .ssa_rd({V{1'b0}})   
    ); 
    
    
   extract_header_flit_info #(
        .CLASS_HDR_WIDTH(8),
        .ROUTING_HDR_WIDTH(8),
        .DST_ADR_HDR_WIDTH(8),
        .SRC_ADR_HDR_WIDTH(8),
        .TOPOLOGY(TOPOLOGY),
        .V(V),
        .P(P),
        .NX(NX),
        .NY(NY),
        .C(C),
        .Fpay(Fpay),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw)
        
    )
    extract_header_info
    (
        .flit_in(fifo_dout),
        .flit_in_we(),
        .class_o(class_in_next),
        .destport_o(),
        .x_dst_o(),
        .y_dst_o(),
        .x_src_o(x_src_in_next),
        .y_src_o(y_src_in_next),
        .vc_num_o(),
        .hdr_flit_wr_o( ),
        .flg_hdr_o( ),
        .weight_o()
    );  
  
  
  assign m_receive_dat_o = fifo_dout[Dw-1   :   0];
  assign received_flit_is_tail = fifo_dout[Fw-2];
  assign received_flit_is_hdr  = fifo_dout[Fw-1];
  
  assign any_vc_got_pck = received_flit_is_hdr & flit_in_wr;
  
    localparam [1:0] 
        HDR_FLAG           =   2'b10,
        BDY_FLAG            =   2'b00,
        TAIL_FLAG          =   2'b01;
 
  assign credit_out = vc_fifo_rd;
  assign flit_out_wr= fifo_wr; 
  
  assign flit_out [Fpay+V-1 : Fpay] = send_vc_enable;
    
  assign flit_out [Fpay-1   : 0   ] = (send_hdr)?  hdr_flit_out [Fpay-1 : 0] :
                                      (send_tail)? tail_flit_out :  m_send_dat_i [Fpay-1 : 0];

  assign flit_out [Fw-1 : Fw-2] =   (send_hdr)?  HDR_FLAG : 
                                    (send_tail)?  TAIL_FLAG    : BDY_FLAG;
                                       
    
    
 endmodule
 
 
 
  

 
 
 
 
 
 






/***************
*   header_flit_generator
***************/


module header_flit_generator  #(
    parameter CLASS_HDR_WIDTH     =8,
    parameter ROUTING_HDR_WIDTH   =8,
    parameter DST_ADR_HDR_WIDTH  =8,
    parameter SRC_ADR_HDR_WIDTH   =8,
    parameter TOPOLOGY =    "MESH",//"MESH","TORUS","RING" 
    parameter ROUTE_TYPE   =   "DETERMINISTIC",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter ROUTE_NAME    =   "XY",
    parameter V = 4,    // vc_num_per_port
    parameter P = 5,    // router port num
    parameter NX = 4,   // number of node in x axis
    parameter NY = 4,   // number of node in y axis
    parameter C = 4,    //  number of flit class 
    parameter Fpay = 32     //payload width
)(
    
    flit_out,
   
    x_src_in,
    y_src_in,
    class_in,
    x_dst_in,
    y_dst_in,
    vc_num_in
    
);
// for   flit size >= 32 bits
/* header flit format
31--------------24     23--------16     15--------8            7-----0
message_class_data     routing_info     destination_address    source_address
*/
    
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 
   
    localparam      ADDR_DIMENTION =   (TOPOLOGY ==    "MESH" || TOPOLOGY ==  "TORUS") ? 2 : 1,  // "RING" and FULLY_CONNECT 
                    ALL_DATA_HDR_WIDTH  = CLASS_HDR_WIDTH+ROUTING_HDR_WIDTH+DST_ADR_HDR_WIDTH+SRC_ADR_HDR_WIDTH,
                    P_1         =   P-1 ,
                    Fw          =   2+V+Fpay,//flit width
                    Xw          =   log2(NX),
                    Yw          =   log2(NY),
                    Cw          =  (C>1)? log2(C): 1,
                    HDR_FLAG            =   2'b10;
                    
     
    
    output   [Fw-1       :   0] flit_out;
 
    input    [Cw-1       :   0] class_in;    
    input    [Xw-1       :   0] x_dst_in;
    input    [Yw-1       :   0] y_dst_in;
    input    [Xw-1       :   0] x_src_in;
    input    [Yw-1       :   0] y_src_in;
    input    [V-1        :   0] vc_num_in;
 
   
    
    
    wire    [P_1-1      :   0] destport;
                    
    wire    [CLASS_HDR_WIDTH-1      :   0]  class_hdr;
    wire    [ROUTING_HDR_WIDTH-1    :   0]  routing_hdr;
    wire    [DST_ADR_HDR_WIDTH-1    :   0]  dst_adr_hdr; 
    wire    [SRC_ADR_HDR_WIDTH-1    :   0]  src_adr_hdr;
                  
     
     ni_conventional_routing #(        
        .P(P),
        .NX(NX),
        .NY(NY),
        .ROUTE_TYPE(ROUTE_TYPE),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .LOCATED_IN_NI(1)
    )
    conv_routing
    (
        .current_x (x_src_in),
        .current_y (y_src_in),
        .dest_x    (x_dst_in),
        .dest_y    (y_dst_in),
        .destport  (destport)
    );                      
                    
   
     //x_dst_hdr, y_dst_hdr, x_src_hdr, y_src_hdr       
    generate
        if (ADDR_DIMENTION==1) begin :one_dimen
            assign  dst_adr_hdr       [Xw-1     : 0] = x_dst_in;
            assign  src_adr_hdr       [Xw-1     : 0] = x_src_in;
        end else begin :two_dimen
            assign dst_adr_hdr       [Yw-1     : 0] = y_dst_in;
            assign src_adr_hdr       [Yw-1     : 0] = y_src_in;
            assign dst_adr_hdr       [(DST_ADR_HDR_WIDTH/2)+Xw-1     : DST_ADR_HDR_WIDTH/2] = x_dst_in;
            assign src_adr_hdr       [(SRC_ADR_HDR_WIDTH/2)+Xw-1     : SRC_ADR_HDR_WIDTH/2] = x_src_in;          
        end
    endgenerate

    
     
    assign flit_out [Fpay+V-1    :    Fpay] = vc_num_in;
    assign flit_out [Fw-1        :    Fw-2] = HDR_FLAG;
    assign class_hdr         [Cw-1     :    0] = class_in;
    assign routing_hdr     [P_1-1    :    0] = destport;
    assign flit_out [ALL_DATA_HDR_WIDTH-1      :0] =  {class_hdr,routing_hdr,dst_adr_hdr,src_adr_hdr};  

endmodule




/******************
*   ovc_status
*******************/
 
 module ovc_status #(
    parameter V     =   4,
    parameter B =   16
)
(
    input   [V-1            :0] wr_in,
    input   [V-1            :0] credit_in,
    output  [V-1            :0] full_vc,
    output  [V-1            :0] nearly_full_vc,
    output  [V-1            :0] empty_vc,
    input                       clk,
    input                       reset
);

    
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 
    
    localparam  BUFF_WIDTH  =   log2(B);
    localparam  DEPTH_WIDTH =   BUFF_WIDTH+1;
    localparam  [DEPTH_WIDTH-1          :   0] B_1         =   B-1;
    
    
    reg     [DEPTH_WIDTH-1          :   0]  depth       [V-1    :   0];

    
    genvar i;
    generate
        for(i=0;i<V;i=i+1) begin : vc_loop
            always@(posedge clk or posedge reset)begin
                    if(reset)begin
                        depth[i]<={DEPTH_WIDTH{1'b0}};
                    end else begin
                        if(  wr_in[i]   && ~credit_in[i])   depth[i] <= depth[i]+1'b1;
                        if( ~wr_in[i]   &&  credit_in[i])   depth[i] <= depth[i]-1'b1;
                    end //reset
            end//always

            assign  full_vc[i]       = (depth[i] == B);
            assign  nearly_full_vc[i]= (depth[i] >= B_1);
            assign  empty_vc[i]      = (depth[i] == {DEPTH_WIDTH{1'b0}});
        end//for
    endgenerate
endmodule
 
