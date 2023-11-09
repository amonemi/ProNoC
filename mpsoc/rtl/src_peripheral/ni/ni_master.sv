//`define MONITOR_HDR_FLITS 
//`define MONITOR_DAT_FLITS 

/**********************************************************************
**	File:  ni.sv 
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
**	Description: multi-chanel DMA-based network interface for 
**  handling packetizing/depacketizing data to/form NoC. 
**  Can support CRC32 
**	
**
*******************************************************************/

`include "pronoc_def.v"


module  ni_master 
	#(    
    parameter NOC_ID=0,
    parameter MAX_TRANSACTION_WIDTH=10, // Maximum transaction size will be 2 power of MAX_DMA_TRANSACTION_WIDTH words 
    parameter MAX_BURST_SIZE =256, // in words
    parameter CRC_EN= "NO",// "YES","NO" if CRC is enable then the CRC32 of all packet data is calculated and sent via tail flit. 
    parameter HDATA_PRECAPw=0,  
    // The header Data pre capture width. It Will be enabled when it is larger than zero. The header data can optionally carry a short width Data. This data can be pre-captured (completely/partially) 
    // by the NI before saving the packet in a memory buffer. This can give some hints to the software regarding the incoming 
    // packet such as its type, or source port so the software can store the packet in its appropriate buffer.
        
    //wishbone port parameters
    parameter Dw            =   32,
    parameter S_Aw          =   7,
    parameter M_Aw          =   32,
    parameter TAGw          =   3,
    parameter SELw          =   4
)
(
    //general 
    reset,
    clk,  
      
    //noc interface  
    current_r_addr,
    current_e_addr,
    chan_in,
    chan_out,  
     
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
    
    //interrupt interface
    irq    

);

   `NOC_CONF

   
 
    input reset,clk;   


     // NOC interfaces
    input   [RAw-1   :   0]  current_r_addr;
    input   [EAw-1   :   0]  current_e_addr;
    
    input   smartflit_chanel_t 	chan_in;
    output  smartflit_chanel_t 	chan_out;    
    
    
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
    
    
    
    
    logic  [Fw-1   :   0]  flit_out;     
    logic                  flit_out_wr;   
    logic   [V-1    :   0]  credit_in;
    logic   [Fw-1   :   0]  flit_in; 
    logic                   flit_in_wr;   
    logic  [V-1    :   0]  credit_out;     
    
    
    assign 	chan_out.flit_chanel.flit = flit_out; 
    assign  chan_out.flit_chanel.flit_wr = flit_out_wr;
    assign  chan_out.flit_chanel.credit = credit_out;
		
		
    assign flit_in   =  chan_in.flit_chanel.flit;   
    assign flit_in_wr=  chan_in.flit_chanel.flit_wr; 
    assign credit_in =  chan_in.flit_chanel.credit;  
    
    //old ni.v file    
    
    localparam 
        CTRL_FLGw=14,
        CHw=log2(V),
        BURST_SIZE_w= log2(MAX_BURST_SIZE+1),
        STATUS1w=  2 * CHw + 4;
    
/*   Wishbone bus slave address :
 
 VC specific registers       
       address bits       
 [4+Vw:4]      [3:0]                     
                1  :   CTRL_FLAGS    :  {invalid_send_req_err,burst_size_err_isr,send_data_size_err_isr,crc_miss_match_isr,rcive_buff_ovrflw_err_isr,got_packet_isr, packet_is_saved_isr, packet_is_sent_isr,got_any_errorint_en,got_packet_int_en, packet_is_saved_int_en, packet_is_sent_int_en,receive_is_busy, send_is_busy}; 
        
                2  :   SEND_DEST_WB_ADDR        // The destination router address
                3  :   SEND_POINTER_WB_ADDR,    // The address of data to be sent in byte 
 Virtual        4  :   SEND_DATA_SIZE,          // The size of data to be sent in byte  
 chanel        5  :   SEND_HDR_DATA            // The short width data that can be sent by header flit  
 number        
                8  :   RECEIVE_SRC_WB_ADDR       // The source router (the router which is sent this packet).
                9  :   RECEIVE_POINTER_WB_ADDR   // The address pointer of receiver memory in byte
                10 :   RECEIVE_DATA_SIZE_WB_ADDR // The size of received data in byte
                11 :   RECEIVE_MAX_BUFF_SIZ      // The receiver allocated buffer size in words. If the packet size is bigger than the buffer size the rest of it will be discarded
                12 :   RECEIVE_START_INDEX_WB_ADDR  // The received data is written on RECEIVE_POINTER_WB_ADDR + RECEIVE_START_INDEX_WB_ADDR. If the write address reach to the end of buffer pointer, it starts at the RECEIVE_POINTER_WB_ADDR.   
                13 :   RECEIVE_CTRL_WB_ADDR      // The NI receiver control register 
                14 :   RECEIVE_PRECAP_DATA_ADDR  // The port address to the header flit data which can be pre-captured before buffering the actual data. 
 
 Shared registers for all VCs
    address bits       
      [5:0]   
       0:    STATUS_WB_ADDR     // status1:  {send_vc_enable_binary, receive_vc_enable_binary, any_err_isr_en,any_got_packet_isr_en,any_packet_is_saved_isr_en,any_packet_is_sent_isr_en}  
       16:   BURST_SIZE_WB_ADDR  // The burst size in words        
       32: reserved 
      
*/
    localparam 
        chanel_ADDRw= 4,
        chanel_REGw = 4,
        GENRL_ADRw=2;
    
    wire [CHw-1 :   0] vc_addr = s_addr_i [chanel_REGw+CHw-1	:	chanel_REGw];
    wire [GENRL_ADRw-1 :   0] genrl_reg_addr = s_addr_i [chanel_REGw+GENRL_ADRw-1  :   chanel_REGw];
    wire [chanel_ADDRw-1     :   0] vc_s_addr_i = s_addr_i [chanel_ADDRw-1: 0];

//general registers     
    localparam [GENRL_ADRw-1  :   0]
        STATUS1_WB_ADDR  =   0,          // status1 
      //  STATUS2_WB_ADDR  =   1,          // status2 
     //   STATUS3_WB_ADDR  =   3,          // status3
        BURST_SIZE_WB_ADDR = 1;      
    
 //Readonly registers per VC
    localparam [chanel_ADDRw-1  :   0]
        GENERAL_REGS_WB_ADDR=0,
        CTRL_FLAGS_WB_ADDR=1,
        RECEIVE_SRC_WB_ADDR =8,         // The source router (the router which is sent this packet).
        RECEIVE_DATA_SIZE_WB_ADDR = 10,  // The size of received data in byte  
        RECEIVE_PRECAP_DATA_ADDR=14;
  
    
    localparam 
        WORLD_SIZE = Dw/8,
        OFFSETw= log2(WORLD_SIZE),        
        HDw = Fpay - (2*EAw) -  DSTPw - WEIGHTw,
        PRE_Dw = (HDATA_PRECAPw>0)? HDATA_PRECAPw : 1,
        MAX_PCK_SIZE_IN_BYTE = MAX_TRANSACTION_WIDTH + log2(Fpay/8);
      
        
 
    reg [BURST_SIZE_w-1  :   0] burst_size, burst_size_next,burst_counter,burst_counter_next;      
    wire [V-1 :   0] receive_vc_is_busy, send_vc_is_busy;
    wire [V-1 :   0] receive_vc_enable,send_vc_enable,vc_state_reg_enable;
    wire [V-1 :   0] vc_burst_counter_ld, vc_burst_counter_dec;
    wire [V-1 :   0] vc_fifo_wr, vc_fifo_rd;
    wire [V-1 :   0] vc_fifo_full, vc_fifo_nearly_full, vc_fifo_empty;
    wire [V-1 :   0] send_vc_is_active,receive_vc_is_active;
    wire [CHw-1:  0] send_vc_enable_binary,receive_vc_enable_binary;          
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
    wire  [MAX_PCK_SIZE_IN_BYTE-1    :   0] receive_dat_size_in_byte [V-1 :   0];            
    wire  [V-1    :   0] send_vc_fsm_is_ideal,receive_vc_fsm_is_ideal;
    wire  [Dw-1   :   0] send_vc_pointer_addr [V-1   :  0];
    wire  [Dw-1   :   0] receive_vc_pointer_addr [V-1   :  0];
    wire  [V-1    :   0] receive_vc_got_packet,receive_vc_got_hdr_flit_at_head;    
    wire [MAX_TRANSACTION_WIDTH-1    :   0] send_vc_data_size [V-1   :  0];
    wire [MAX_TRANSACTION_WIDTH-1    :   0] receive_vc_max_buff_siz [V-1   :  0];
    wire [MAX_TRANSACTION_WIDTH-1    :   0] receive_vc_start_index  [V-1   :  0];
    wire [OFFSETw-1 : 0] receive_vc_start_index_offset [V-1   :  0];
    
    
    
    wire [V-1   :  0]   send_vc_start, receive_vc_start; 
    wire  received_flit_is_tail,received_flit_is_hdr;    
    wire [EAw-1  :   0]  vc_dest_e_addr [V-1   :  0];
    wire [Cw-1   :   0]  vc_pck_class [V-1   :  0]; 
    wire [WEIGHTw-1 : 0] vc_weight [V-1:0];  
    wire [BEw-1 : 0 ] vc_be_in  [V-1    :   0];   
    wire [HDw-1 : 0] vc_hdr_data [V-1:0];
    wire [V-1    :   0]  send_vc_send_hdr,send_vc_send_tail;
    wire [V-1    :   0]  send_vc_done,receive_vc_done;    
  
    wire [EAw-1   :   0]  dest_e_addr;
    wire [Cw-1   :   0]  pck_class;
    wire [BEw-1 : 0 ] be_in;
    wire send_hdr, send_tail;
    wire [Fw-1   :   0] hdr_flit_out;         
    wire burst_counter_ld = | vc_burst_counter_ld; 
    wire burst_counter_dec= | vc_burst_counter_dec;
    wire fifo_wr = | vc_fifo_wr; 
    wire fifo_rd = | vc_fifo_rd;
    
    
    
   
    
    wire last_burst = (burst_counter == 1);
    wire burst_is_set =  (burst_size>0);    
    wire [Cw-1   :   0] received_class_next;
    wire [EAw-1   :   0] received_src_e_addr_next;
    wire [BEw-1 : 0 ] received_be_next;
    wire [HDw-1 : 0 ] received_hdr_dat_next;
    wire [Fpay-1    :   0] tail_flit_out;   
    reg [Cw-1  : 0] class_in [V-1    :   0];
    reg [EAw-1 : 0] src_e_addr [V-1    :   0];
    reg [HDw-1 : 0] rsv_hdr_dat [V-1 : 0];
    reg [BEw-1 : 0] receive_vc_be [V-1 : 0];
    wire [CTRL_FLGw-1 : 0] vc_ctrl_flags [V-1 : 0];
    reg [V-1    :   0] crc_miss_match;    
    
    wire [V-1    :   0] burst_size_err,send_data_size_err,rcive_buff_ovrflw_err;
    wire [V-1    :   0] invalid_send_req_err;           
     
    wire [V-1 : 0] vc_irq;
   
  
            
    wire  [STATUS1w-1  :0] status1;
   // wire  [STATUS2w-1  :0] status2; 
  //  wire  [STATUS3w-1  :0] status3;
    
 
    wire [DSTPw-1 : 0] destport;
    wire [WEIGHTw-1 : 0] weight;  
    wire [HDw-1 : 0 ] hdr_data; 
   
    wire [V-1 :0] vc_any_err_isr        ;
    wire [V-1 :0] vc_got_packet_isr     ;
    wire [V-1 :0] vc_packet_is_saved_isr; 
    wire [V-1 :0] vc_packet_is_sent_isr ;   
    wire [PRE_Dw-1 : 0 ] recive_vc_precap_data [V-1 : 0];    
    wire any_err_isr,any_got_packet_isr,any_packet_is_saved_isr,any_packet_is_sent_isr;
    
    assign any_err_isr = |  vc_any_err_isr         ;
    assign any_got_packet_isr = |  vc_got_packet_isr      ;
    assign any_packet_is_saved_isr = |  vc_packet_is_saved_isr;
    assign any_packet_is_sent_isr  = |  vc_packet_is_sent_isr;
  //  assign status1= {vc_got_error_isr, receive_vc_got_packet_isr, receive_vc_packet_is_saved_isr, send_vc_packet_is_sent_isr};    
 //   assign status2= {vc_got_error_int_en, receive_vc_got_packet_int_en, receive_vc_packet_is_saved_int_en, send_vc_packet_is_sent_int_en};
    assign status1= {send_vc_enable_binary, receive_vc_enable_binary, any_err_isr,any_got_packet_isr,any_packet_is_saved_isr,any_packet_is_sent_isr};
      
    
    assign  irq =|vc_irq;
    
    wire [7: 0] temp;
    generate
    if (HDw >= 8) assign temp = rsv_hdr_dat [vc_addr][7:0];
    else assign temp = {{(8-HDw){1'b0}},rsv_hdr_dat [vc_addr]};
    endgenerate
                                
                   
    //read wb registers                
    always @(*)begin 
        s_dat_o ={Dw{1'b0}};
        case(vc_s_addr_i)
        GENERAL_REGS_WB_ADDR:begin // This is a general address. check the general address filed
            case(genrl_reg_addr)
            STATUS1_WB_ADDR: begin 
                s_dat_o = {{(Dw-STATUS1w){1'b0}}, status1};
            end 
            BURST_SIZE_WB_ADDR:begin
                s_dat_o = {{(Dw-BURST_SIZE_w){1'b0}}, burst_size};  
            end 
            default: begin 
            	s_dat_o ={Dw{1'b0}};
            end
            endcase
        end//0
                
        CTRL_FLAGS_WB_ADDR: begin 
             s_dat_o[CTRL_FLGw-1     : 0] = vc_ctrl_flags[vc_addr];           
        end  
      
        RECEIVE_SRC_WB_ADDR: begin 
            
            s_dat_o[EAw-1: 0]   =   src_e_addr[vc_addr];   // first&second bytes
            s_dat_o[Cw+15: 16]  =   class_in[vc_addr];  //third byte  
            s_dat_o[31: 24] =       temp;   // 4th byte
        end 
        
        RECEIVE_DATA_SIZE_WB_ADDR: begin        
            s_dat_o   [MAX_PCK_SIZE_IN_BYTE-1    :   0] = receive_dat_size_in_byte[vc_addr];
        end        
        
        RECEIVE_PRECAP_DATA_ADDR: begin 
        	s_dat_o[PRE_Dw-1 : 0 ] =  (HDATA_PRECAPw>0)? recive_vc_precap_data[vc_addr][PRE_Dw-1 : 0 ]: {{PRE_Dw{1'b0}}};        
        end
        default: begin 
             s_dat_o ={Dw{1'b0}};
        end       
        endcase      
    end      
     
   
   
    
    //write wb registers
    always @ (*)begin 
        burst_counter_next=burst_counter;
        burst_size_next= burst_size;
        if(burst_counter_ld)    burst_counter_next = burst_size;
        if(burst_counter_dec)   burst_counter_next= burst_counter- 1'b1;
         
        if((s_stb_i  &    s_we_i) && (vc_s_addr_i == GENERAL_REGS_WB_ADDR)) begin // This is a general address. check the general address filed
            case(genrl_reg_addr)
            BURST_SIZE_WB_ADDR: begin 
                if (send_vc_is_busy == {V{1'b0}}) burst_size_next=s_dat_i [BURST_SIZE_w-1 : 0];    
            end //BURST_SIZE_WB_ADDR
                                 
		    default begin

		    end                   
            endcase
        end//  if(s_stb_i  &    s_we_i)   
           
    end 
    
   
    
    
`ifdef SYNC_RESET_MODE 
    always @ (posedge clk )begin 
`else 
    always @ (posedge clk or posedge reset)begin 
`endif 
    
    
   
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
    
     wire [V-1 : 0 ] precap_hdr_flit_wr;
     wire [HDATA_PRECAPw-1 : 0 ] precap_din;
     wire [V-1 : 0] precap_hdr_flit_rd = (fifo_rd & received_flit_is_hdr) ?  receive_vc_enable : {V{1'b0}};
     wire [HDATA_PRECAPw-1 : 0 ] precap_dout  [V-1 : 0] ;    
     wire [V-1 : 0 ] precap_valid;
    
        
    //capture data before saving the actual flit in memory
    if(HDATA_PRECAPw > 0 ) begin : precap      
      
        wire [EAw-1 : 0] src_endp_addr;
        
        extract_header_flit_info #(
            .NOC_ID(NOC_ID),
            .DATA_w(HDATA_PRECAPw)           
        )
        data_extractor
        (
            .flit_in(flit_in),
            .flit_in_wr(flit_in_wr),
            .src_e_addr_o(src_endp_addr ),
            .dest_e_addr_o( ),
            .destport_o( ),
            .class_o( ),
            .weight_o( ),
            .tail_flg_o( ),
            .hdr_flg_o( ),
            .vc_num_o( ),
            .be_o( ),
            .hdr_flit_wr_o(precap_hdr_flit_wr),
            .data_o(precap_din)
        ); 
        
        
//synthesis translate_off
//synopsys  translate_off    
`ifdef MONITOR_HDR_FLITS 
always @(posedge clk) begin
    
    if(precap_hdr_flit_wr)begin 
        $display("%t: endp %d got a packet with port address %d from endp %d",$time,current_e_addr,precap_din,src_endp_addr);
    end
    
    if(send_hdr & flit_out_wr)begin 
        $display("%t: endp %d sends a packet with port address %d to endp %d",$time,current_e_addr,hdr_data,dest_e_addr);
    end
    
    
end
`endif

`ifdef MONITOR_DAT_FLITS 
    always @(posedge clk) begin
        if(flit_out_wr & ~send_hdr) begin 
            $display("%t: endp %u V %u sends %h",$time,current_e_addr,  flit_out [Fpay+V-1 : Fpay],  flit_out [Fpay-1 : 0 ]);    
        end
    end
`endif

//synopsys  translate_on 
//synthesis translate_on
        
        
        
       for (i=0;i<V; i=i+1) begin : vc__          
          
          fwft_fifo #(
            .DATA_WIDTH(HDATA_PRECAPw),
            .MAX_DEPTH(LB/MIN_PCK_SIZE),//maximum packet number which can be stored in buffer 
            .IGNORE_SAME_LOC_RD_WR_WARNING("YES")
          )
          precap_data_fifo
          (
            .din(precap_din),
            .wr_en(precap_hdr_flit_wr[i]),
            .rd_en(precap_hdr_flit_rd[i]),
            .dout(precap_dout[i]),
            .full( ),
            .nearly_full( ),
            .recieve_more_than_0(precap_valid[i] ),
            .recieve_more_than_1( ),
            .reset(reset),
            .clk(clk)
          );
      
          assign recive_vc_precap_data[i] = precap_dout[i]; 
      
        //synthesis translate_off
        //synopsys  translate_off  
        always @(posedge clk)begin 
             if(s_stb_i  &  ~s_we_i &  (vc_addr==i) & (vc_s_addr_i == RECEIVE_PRECAP_DATA_ADDR) )begin
                    if( precap_valid[i] == 1'b0) $display( "Warning: Reading invalid precap-data %m");    
             end           
        end     
        //synopsys  translate_on   
        //synthesis translate_on 
     
      
        end
           
    end    
    
      
    
    assign chan_out.ctrl_chanel.endp_port =1'b1;
    
    
    
    for (i=0;i<V; i=i+1) begin : vc_    
    
    	
		assign chan_out.ctrl_chanel.credit_init_val[i]= LB;
    
       
       
       
        ni_vc_wb_slave_regs #(
            .MAX_TRANSACTION_WIDTH(MAX_TRANSACTION_WIDTH),
            .DEBUG_EN(DEBUG_EN),
            .EAw(EAw),
            .Fpay(Fpay),
            .DSTPw(DSTPw),
            .HDw(HDw),
            .CTRL_FLGw(CTRL_FLGw),
            .C(C),
            .Dw(Dw),
            .S_Aw(chanel_REGw),
            .WEIGHTw(WEIGHTw),
            .BYTE_EN(BYTE_EN)
            
        )        
        wb_slave_registers
        (
//synthesis translate_off
//synopsys  translate_off    
            .current_e_addr(current_e_addr),
//synopsys  translate_on   
//synthesis translate_on
            .clk(clk),
            .reset(reset),
            .state_reg_enable(vc_state_reg_enable[i]),
            .send_fsm_is_ideal(send_vc_fsm_is_ideal[i]),
            .receive_fsm_is_ideal(receive_vc_fsm_is_ideal[i]),
            .send_pointer_addr(send_vc_pointer_addr[i]),
            .be_in(vc_be_in[i]),
            .receive_pointer_addr(receive_vc_pointer_addr[i]),
            .receive_start_index(receive_vc_start_index[i]),
            .receive_start_index_offset(receive_vc_start_index_offset[i]),
            .receive_done(receive_vc_done[i]),
            .send_done(send_vc_done[i]),
           
            .send_data_size(send_vc_data_size[i]),
            .receive_max_buff_siz(receive_vc_max_buff_siz[i]),
            .dest_e_addr(vc_dest_e_addr[i]),
            .pck_class(vc_pck_class[i]),
            .weight(vc_weight[i]), 
            .hdr_data(vc_hdr_data[i]),
            .send_start(send_vc_start[i]),
            .receive_start(receive_vc_start[i]),
            .receive_vc_got_packet(receive_vc_got_packet[i]),
                   
	        .burst_size_err(burst_size_err[i]),
            .send_data_size_err(send_data_size_err[i]),
            .rcive_buff_ovrflw_err(rcive_buff_ovrflw_err[i]),
	        .crc_miss_match_err( crc_miss_match[i]),
	        .invalid_send_req_err(invalid_send_req_err[i]),  
	        
	        .receive_vc_got_hdr_flit_at_head(receive_vc_got_hdr_flit_at_head[i]),
	        .receive_is_busy(receive_vc_is_busy[i]),
	        .send_is_busy(send_vc_is_busy[i]),	        
	        .ctrl_flags(vc_ctrl_flags[i]),
	                                                         
	        .any_err_isr          (vc_any_err_isr        [i]),
	        .got_packet_isr       (vc_got_packet_isr     [i]),
	        .packet_is_saved_isr  (vc_packet_is_saved_isr[i]),
	        .packet_is_sent_isr   (vc_packet_is_sent_isr [i]),
	        
	        
	        .irq(vc_irq[i]),
	        
	        .s_dat_i(s_dat_i),
            .s_addr_i(s_addr_i[chanel_REGw-1:0]),
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
            .SELw(SELw),
            .Fpay(Fpay),
            .BYTE_EN(BYTE_EN)
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
            .receive_dat_size_in_byte(receive_dat_size_in_byte[i]),
            .receive_be(receive_vc_be[i]),
            .save_hdr_info(save_hdr_info[i]),
            .send_done(send_vc_done[i]),
            .receive_done(receive_vc_done[i]),                       
            .send_fsm_is_ideal(send_vc_fsm_is_ideal[i]),
            .receive_fsm_is_ideal(receive_vc_fsm_is_ideal[i]),
            .send_pointer_addr(send_vc_pointer_addr[i]),           
            .receive_pointer_addr(receive_vc_pointer_addr[i]),
            .receive_start_index(receive_vc_start_index[i]),
            .receive_start_index_offset(receive_vc_start_index_offset[i]),
            .send_data_size(send_vc_data_size[i]),
            .receive_max_buff_siz(receive_vc_max_buff_siz[i]),
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
         
            //errors
            .burst_size_err(burst_size_err[i]),
            .send_data_size_err(send_data_size_err[i]),
            .rcive_buff_ovrflw_err(rcive_buff_ovrflw_err[i]),
            .invalid_send_req_err(invalid_send_req_err[i]),                         
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
     
`ifdef SYNC_RESET_MODE 
    always @ (posedge clk )begin 
`else 
    always @ (posedge clk or posedge reset)begin 
`endif         
             
            if(reset) begin 
                class_in[i]<= {Cw{1'b0}};
                src_e_addr[i]<= {EAw{1'b0}};
                rsv_hdr_dat[i]<={HDw{1'b0}};
                receive_vc_be[i] <= {BEw{1'b0}};
            end else if(save_hdr_info[i])begin 
                class_in[i]<= received_class_next;
                src_e_addr[i]<= received_src_e_addr_next;
                rsv_hdr_dat[i]<=received_hdr_dat_next;
                receive_vc_be[i]<= received_be_next;
            end
        end//always
   
    end  // for loop vc_
    
/* verilator lint_off WIDTH */ 
    if(  CRC_EN == "YES") begin :crc_blk
/* verilator lint_on WIDTH */
   
      reg fifo_rd_delayed;
`ifdef SYNC_RESET_MODE 
    always @ (posedge clk )begin 
`else 
    always @ (posedge clk or posedge reset)begin 
`endif   
        if(reset) fifo_rd_delayed <=1'b0;
        else fifo_rd_delayed <= fifo_rd;
      end
  
      wire send_crc_enable =  flit_out_wr & ~send_hdr &   ~send_tail;
      wire receive_crc_enable =  fifo_rd_delayed & ~ received_flit_is_tail & ~received_flit_is_hdr;
      wire [31:0]  send_crc_out,receive_crc_out;
                                        
        crc_32_multi_chanel #(
            .chanel(V)
        )
        send_crc
        (
            .reset(reset),
            .clk(clk),
            .crc_reset(send_hdr),
            .crc_enable(send_crc_enable),
            .chanel_in(send_vc_enable_binary),
            .data_in(m_send_dat_i [Fpay-1 : 0]),
            .crc_out(send_crc_out)
        );        
        
        crc_32_multi_chanel #(
        	.chanel(V)
        )
         receive_crc
         (
        	.reset(reset),
        	.clk(clk),
        	.crc_reset(received_flit_is_hdr),
        	.crc_enable(receive_crc_enable),
        	.chanel_in(receive_vc_enable_binary),
        	.data_in(m_receive_dat_o[Fpay-1 : 0]),
        	.crc_out(receive_crc_out)
        );
        
        for (i=0;i<V;i=i+1) begin: crc_v
        
`ifdef SYNC_RESET_MODE 
            always @ (posedge clk )begin 
`else 
            always @ (posedge clk or posedge reset)begin 
`endif 
                  
                if(reset) begin 
                    crc_miss_match[i] <= 1'b0;
                end else begin 
                    if(receive_vc_enable_binary==i && received_flit_is_tail && m_receive_stb_o ) begin 
                        crc_miss_match[i] <= receive_crc_out[31:0] != m_receive_dat_o[31 : 0];
                    end                
                end
            
            end
        end//for
        
        assign tail_flit_out[31 : 0]  =  send_crc_out;
    end   else begin : no_crc 
        assign tail_flit_out   =  m_send_dat_i [Fpay-1 : 0];
        //always @(*) crc_miss_match = {V{1'b0}};
	always @(posedge clk) crc_miss_match <= {V{1'b0}};
    end
      
  
    if(V> 1) begin : multi_chanel
    
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
            .bin_code(send_vc_enable_binary)
        );
        
        
         one_hot_to_bin #(
            .ONE_HOT_WIDTH(V),
            .BIN_WIDTH(CHw)
        )
        receive_en_conv
        (
            .one_hot_code(receive_vc_enable),
            .bin_code(receive_vc_enable_binary)
        );
        
        
    end else begin : single_chanel // if we have just one chanel there is no need for arbitration
        assign receive_vc_enable =  receive_vc_is_active;
        assign send_vc_enable =  send_vc_is_active;
        assign send_vc_enable_binary = 1'b0;
        assign receive_vc_enable_binary = 1'b0;
    end
    endgenerate  
  
   
  
    conventional_routing #(
        .NOC_ID(NOC_ID),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .ROUTE_TYPE(ROUTE_TYPE),  
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .RAw(RAw),
        .EAw(EAw),
        .DSTPw(DSTPw),
        .LOCATED_IN_NI(1)
    ) route_compute (
        .reset(reset),
        .clk(clk),
        .current_r_addr(current_r_addr),
        .src_e_addr(current_e_addr),
        .dest_e_addr(dest_e_addr),
        .destport(destport)
    );
  
        
    header_flit_generator #(
        .NOC_ID(NOC_ID),
        .DATA_w(HDw)       
    ) hdr_flit_gen (
        .flit_out(hdr_flit_out),
        .class_in(pck_class),
        .dest_e_addr_in(dest_e_addr),
        .src_e_addr_in(current_e_addr),
        .destport_in(destport),
        .vc_num_in(send_vc_enable),
        .weight_in(weight),
        .be_in(be_in),
        .data_in(hdr_data)        
    );
    
  wire [V-1    :   0] wr_vc_send =  (fifo_wr) ? send_vc_enable : {V{1'b0}};  
  
  
  ovc_status #(
    .V(V),
    .B(LB),
    .CRDTw(CRDTw)    
  )
  the_ovc_status
  (
    .credit_init_val_in ( chan_in.ctrl_chanel.credit_init_val),
  	.wr_in(wr_vc_send),
    .credit_in(credit_in),
    .full_vc(vc_fifo_full),
    .nearly_full_vc(vc_fifo_nearly_full),
    .empty_vc( ),
    .clk(clk),
    .reset(reset)
  );   
    
    // header info mux    
    assign dest_e_addr = vc_dest_e_addr[send_vc_enable_binary];
    assign pck_class  = vc_pck_class[send_vc_enable_binary];
    assign weight =   vc_weight[send_vc_enable_binary];  
    assign hdr_data = vc_hdr_data [send_vc_enable_binary]; 
    assign send_hdr = send_vc_send_hdr[send_vc_enable_binary]; 
    assign send_tail = send_vc_send_tail[send_vc_enable_binary]; 
    assign be_in = vc_be_in[send_vc_enable_binary];
    
    //wb multiplexors    
    assign m_send_sel_o  = vc_m_send_sel_o[send_vc_enable_binary];
    assign m_send_addr_o = vc_m_send_addr_o[send_vc_enable_binary];
    assign m_send_cti_o  = vc_m_send_cti_o[send_vc_enable_binary];
    assign m_send_stb_o  = vc_m_send_stb_o[send_vc_enable_binary];
    assign m_send_cyc_o  = vc_m_send_cyc_o[send_vc_enable_binary];
    assign m_send_we_o   = vc_m_send_we_o[send_vc_enable_binary];       
                        
    assign m_receive_sel_o = vc_m_receive_sel_o[receive_vc_enable_binary];
    assign m_receive_addr_o= vc_m_receive_addr_o[receive_vc_enable_binary];
    assign m_receive_cti_o = vc_m_receive_cti_o[receive_vc_enable_binary];
    assign m_receive_stb_o = vc_m_receive_stb_o[receive_vc_enable_binary];
    assign m_receive_cyc_o = vc_m_receive_cyc_o[receive_vc_enable_binary];
    assign m_receive_we_o  = vc_m_receive_we_o[receive_vc_enable_binary];    
          
    wire [V-1    :   0]  flit_in_vc_num = flit_in [Fpay+V-1    :   Fpay]; 
    wire [V-1    :   0]  ififo_vc_not_empty; 
    assign vc_fifo_empty = ~ ififo_vc_not_empty;
    assign receive_vc_got_packet = ififo_vc_not_empty;
    assign receive_vc_got_hdr_flit_at_head=  ififo_vc_not_empty & receive_vc_fsm_is_ideal;
        
    
    
    
    wire [Fw-1  :   0] fifo_dout;
    
    localparam LBw = log2(LB);
    
    flit_buffer #(
        .V(V),
        .B(LB),
        .SSA_EN("NO"),
        .Fw(Fw),
		.PCK_TYPE(PCK_TYPE),
		.CAST_TYPE(CAST_TYPE),
		.DEBUG_EN(DEBUG_EN)
     )
     the_ififo
     (
        .din(flit_in),     // Data in
        .vc_num_wr(flit_in_vc_num),//write virtual chanel    
        .wr_en(flit_in_wr),   // Write enable
        .vc_num_rd(receive_vc_enable),//read virtual chanel     
        .rd_en(fifo_rd),   // Read the next word
        .dout(fifo_dout),    // Data out
        .vc_not_empty(ififo_vc_not_empty),
        .reset(reset),
        .clk(clk),
        .ssa_rd({V{1'b0}}),
        .multiple_dest(),
        .sub_rd_ptr_ld()  
    ); 
    
   extract_header_flit_info #(
        .NOC_ID(NOC_ID),
        .DATA_w (HDw)      
    )
    extractor
    (
        .flit_in(fifo_dout),
        .flit_in_wr(),
        .class_o(received_class_next),
        .destport_o(),
        .dest_e_addr_o(),
        .src_e_addr_o(received_src_e_addr_next),
        .vc_num_o(),
        .hdr_flit_wr_o( ),
        .hdr_flg_o( ),
        .tail_flg_o( ),
        .weight_o(),
        .be_o(received_be_next),
        .data_o(received_hdr_dat_next)
    );  
  
  
 
  assign m_receive_dat_o = fifo_dout[Dw-1   :   0];
  assign received_flit_is_tail = fifo_dout[Fw-2];
  assign received_flit_is_hdr  = fifo_dout[Fw-1];  
//  assign any_vc_got_pck = |receive_vc_got_packet;

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
 
 
  
/******************
*   ovc_status
*******************/
 
 module ovc_status #(
    parameter V     =   4,
    parameter B =   16,
    parameter CRDTw =4
)
(
   
	input   [V-1 : 0] [CRDTw-1 : 0 ] credit_init_val_in,
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
    
  
 	localparam  DEPTH_WIDTH =   log2(B+1);
 
    
	 reg  [DEPTH_WIDTH-1 : 0] credit    [V-1 : 0];
	 wire  [V-1 : 0] cand_vc_next;
	
    
	 genvar i;
	 generate
	 	for(i=0;i<V;i=i+1) begin : vc_loop
	 	`ifdef SYNC_RESET_MODE 
	 		always @ (posedge clk )begin 
	 	`else 
	 		always @ (posedge clk or posedge reset)begin 
	 	`endif  
	 	if(reset)begin
	 	credit[i]<= credit_init_val_in[i][DEPTH_WIDTH-1:0];
	    end else begin
	    	if(  wr_in[i]  && ~credit_in[i])   credit[i] <= credit[i]-1'b1;
	    	if( ~wr_in[i]  &&  credit_in[i])   credit[i] <= credit[i]+1'b1;
	    end //reset
	    end//always

	    assign  full_vc[i]   = (credit[i] == {DEPTH_WIDTH{1'b0}});
	    assign  nearly_full_vc[i]=  (credit[i] == 1) |  full_vc[i];
	    assign  empty_vc[i]  = (credit[i] == credit_init_val_in[i][DEPTH_WIDTH-1:0]);
      end//for
    endgenerate
endmodule
 
 
