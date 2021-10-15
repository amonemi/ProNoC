/**********************************************************************
**	File:  ni_vc_wb_slave_regs.v
**	Date:2017-06-11     
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
**	NI internal register bank
**	
**
*******************************************************************/

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on





 
module ni_vc_wb_slave_regs #(
    parameter MAX_TRANSACTION_WIDTH =10,      
    //NoC parameter
    parameter DEBUG_EN=1,
    parameter EAw=4,
    parameter C = 4,    //  number of flit class 
    parameter Fpay=32,
    parameter DSTPw=4,
    parameter WEIGHTw=4, 
    parameter BYTE_EN=0,
    parameter HDw = 8,  
    parameter CTRL_FLGw=14,
    //wishbones  bus  slave  port parameters
    parameter Dw            =   32,
    parameter S_Aw          =   4
 
 )( 
    state_reg_enable,
    send_fsm_is_ideal,
    receive_fsm_is_ideal,
    send_start,
    receive_start,
    receive_done,
    send_done,
    receive_vc_got_packet,
   
  
    send_pointer_addr, 
    be_in,
    receive_pointer_addr,
    receive_start_index,
    receive_start_index_offset,
    send_data_size,
    receive_max_buff_siz,    
    dest_e_addr,
    pck_class,
    weight,  
    hdr_data,
    
    burst_size_err,
    send_data_size_err,
    rcive_buff_ovrflw_err,
    crc_miss_match_err,
    invalid_send_req_err,  
    
    receive_vc_got_hdr_flit_at_head,
    receive_is_busy,
    send_is_busy,
    
    any_err_isr,
    got_packet_isr,
    packet_is_saved_isr,
    packet_is_sent_isr,
    
    irq,  
    ctrl_flags,
    
    s_dat_i,
    s_addr_i,  
    s_stb_i,
    s_cyc_i,
    s_we_i,
//synthesis translate_off
//synopsys  translate_off    
    current_e_addr,
//synopsys  translate_on 
//synthesis translate_on
     
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
    
 
    
  
  
/*
 s_dat_i : 
        [16:0] dest_e_addr,
        [23:16] class,
        [31:24] weight,   
*/
    localparam
        DST_X_LSB  =0,
        CLASS_LSB  =16,
        WEIGHT_LSB =24; 
        
            /*
                1  :   CTRL_FLAGS
                2  :   SEND_DEST_WB_ADDR           // The destination router address
                3  :   SEND_POINTER_WB_ADDR,       // The address of data to be sent in byte 
 Virtual        4  :   SEND_DATA_SIZE_WB_ADDR,     // The size of data to be sent in byte  
 chanel        5  :   SEND_HDR_DATA_WB_ADDR       //  The header data address
 number        
                8  :   RECEIVE_SRC_WB_ADDR       // The source router (the router which is sent this packet).
                9  :   RECEIVE_POINTER_WB_ADDR      // The address pointer of receiver memory in byte
                10 :   RECEIVE_DATA_SIZE_WB_ADDR // The size of received data in byte
                11 :   RECEIVE_MAX_BUFF_SIZ         // The receiver allocated buffer size in bytes. If the packet size is bigger than the buffer size the rest of it will be discarded
                12 :   RECEIVE_START_INDEX_WB_ADDR  // The received data is written on RECEIVE_POINTER_WB_ADDR + RECEIVE_START_INDEX_WB_ADDR. If the write address reach to the end of buffer pointer, it starts at the RECEIVE_POINTER_WB_ADDR.   
                13 :   RECEIVE_CTRL_WB_ADDR      // The NI receiver control register 
                14 :   RECEIVE_PRECAP_DATA_ADDR  // The address to the header flit 
        */
        
    localparam [S_Aw-1  :   0]
        CTRL_FLAGS =1,
        SEND_DEST_WB_ADDR =2,
        SEND_POINTER_WB_ADDR =3,       
        SEND_DATA_SIZE_WB_ADDR =4,  
        SEND_HDR_DATA_WB_ADDR = 5,   
            
        RECEIVE_POINTER_WB_ADDR=9,   
        RECEIVE_MAX_BUFF_SIZ=11,  
        RECEIVE_START_INDEX_WB_ADDR=12,
        RECEIVE_CTRL_WB_ADDR =13;  
       
      
   localparam
        WORLD_SIZE = Dw/8,
        OFFSETw= log2(WORLD_SIZE),        
        Cw =  (C>1)? log2(C): 1,
        BEw = (BYTE_EN)? log2(Fpay/8) : 1; 
       
        
 
    input clk,reset;    
    input state_reg_enable;
    input send_fsm_is_ideal,receive_fsm_is_ideal;
    input receive_vc_got_packet;
    input receive_done;
    input send_done;
    output  reg [Dw-1   :   0] send_pointer_addr; 
    output      [BEw-1 : 0 ] be_in;
   
    output  reg [Dw-1   :   0] receive_pointer_addr;
  
  
    output  [MAX_TRANSACTION_WIDTH-1    :   0] send_data_size;
    output  reg [MAX_TRANSACTION_WIDTH-1    :   0] receive_max_buff_siz;
    output  reg [MAX_TRANSACTION_WIDTH-1    :   0] receive_start_index; 
    output  reg [OFFSETw-1 : 0] receive_start_index_offset;
    output  reg [EAw-1   :   0]  dest_e_addr;
    output  reg [Cw-1   :   0]  pck_class;
    output  reg [WEIGHTw-1 :0]  weight; 
    output  reg send_start, receive_start;
    output  reg [HDw-1 : 0] hdr_data;
    
    input  burst_size_err,  send_data_size_err, rcive_buff_ovrflw_err,crc_miss_match_err,invalid_send_req_err;
    input  receive_vc_got_hdr_flit_at_head;
    input  receive_is_busy,    send_is_busy;
   
    output  any_err_isr ,got_packet_isr , packet_is_saved_isr, packet_is_sent_isr;
   
   
    output  irq;
    output [CTRL_FLGw-1:0] ctrl_flags;

//synthesis translate_off
//synopsys  translate_off    
    input   [EAw-1   :   0]  current_e_addr;
//synopsys  translate_on     
//synthesis translate_on
  
   
//wishbone slave interface signals
    input   [Dw-1       :   0]      s_dat_i;
    input   [S_Aw-1     :   0]      s_addr_i;  
    input                           s_stb_i;
    input                           s_cyc_i;
    input                           s_we_i;
    
    wire  any_err_isr_en ,got_packet_isr_en , packet_is_saved_isr_en, packet_is_sent_isr_en;    
        
    reg  [EAw-1   :   0]  dest_e_addr_next;
    reg  [Cw-1   :   0]  pck_class_next;
    reg  [WEIGHTw-1 : 0] weight_next; 
    reg  [Dw-1   :   0]  send_pointer_addr_next, receive_pointer_addr_next;
    reg  [OFFSETw-1 : 0] send_pointer_addr_byte_offset_next, send_pointer_addr_byte_offset; 
    reg  [OFFSETw-1 : 0] send_data_size_byte_offset_next,send_data_size_byte_offset,receive_start_index_offset_next;
    reg  [MAX_TRANSACTION_WIDTH-1    :   0]  send_data_size_reg,send_data_size_next, receive_max_buff_siz_next,receive_start_index_next;
    reg  send_start_next;
    reg  receive_en,receive_en_next;
  
    
    reg [HDw-1 : 0] hdr_data_next;
   
   
    wire [OFFSETw : 0] add_offsets;
    assign add_offsets =send_pointer_addr_byte_offset +  send_data_size_byte_offset;
    assign be_in = add_offsets [BEw-1 : 0];
   
    generate 
    if(BYTE_EN)begin
         wire [1:0] send_offset= (add_offsets==0)? 2'b00 : (add_offsets<=(1<<OFFSETw))? 2'b01 : 2'b10;    
          /* verilator lint_off WIDTH */ 
         assign send_data_size =  send_data_size_reg+ send_offset;
          /* verilator lint_on WIDTH */ 
    end else begin:nbe
        assign send_data_size = send_data_size_reg;    
    end
    endgenerate
    
    
     // update control registers   
    always @ (*) begin 
        //default values       
        receive_start = 1'b0;                
        if (receive_fsm_is_ideal & receive_vc_got_packet & receive_en ) begin 
            receive_start = 1'b1;
           
        end
    end
    
   
    
    wire  s_dat_invalid_send_req_err_isr,s_dat_burst_size_err_isr, s_dat_send_data_size_err_isr, s_dat_crc_miss_match_isr, s_dat_rcive_buff_ovrflw_err_isr,
          s_dat_got_packet_isr, s_dat_packet_is_saved_isr, s_dat_packet_is_sent_isr,s_dat_got_any_err_int_en,
          s_dat_got_packet_int_en, s_dat_packet_is_saved_int_en, s_dat_packet_is_sent_int_en; 
        
  
   reg    invalid_send_req_err_isr_next,burst_size_err_isr_next, send_data_size_err_isr_next, crc_miss_match_isr_next, rcive_buff_ovrflw_err_isr_next,
          got_packet_isr_next, packet_is_saved_isr_next, packet_is_sent_isr_next,
          got_any_err_int_en_next, got_packet_int_en_next, packet_is_saved_int_en_next, packet_is_sent_int_en_next; 
   
   reg    invalid_send_req_err_isr,burst_size_err_isr, send_data_size_err_isr, crc_miss_match_isr, rcive_buff_ovrflw_err_isr,
          got_packet_isr, packet_is_saved_isr, packet_is_sent_isr,got_any_err_int_en,
          got_packet_int_en, packet_is_saved_int_en, packet_is_sent_int_en; 
   
   
   assign {s_dat_invalid_send_req_err_isr,s_dat_burst_size_err_isr, s_dat_send_data_size_err_isr, s_dat_crc_miss_match_isr, s_dat_rcive_buff_ovrflw_err_isr,
          s_dat_got_packet_isr, s_dat_packet_is_saved_isr, s_dat_packet_is_sent_isr,s_dat_got_any_err_int_en,
          s_dat_got_packet_int_en, s_dat_packet_is_saved_int_en, s_dat_packet_is_sent_int_en}=s_dat_i[CTRL_FLGw-1:2];                 
    
   
    
   
   assign any_err_isr_en = (invalid_send_req_err_isr & got_any_err_int_en) |
        (burst_size_err_isr & got_any_err_int_en) |
        (send_data_size_err_isr & got_any_err_int_en) |
        (crc_miss_match_isr & got_any_err_int_en) |
        (rcive_buff_ovrflw_err_isr & got_any_err_int_en) ;
   
   assign any_err_isr = (invalid_send_req_err_isr  | burst_size_err_isr  | send_data_size_err_isr  | crc_miss_match_isr  | rcive_buff_ovrflw_err_isr ) ;
        
   assign got_packet_isr_en =     (got_packet_isr & got_packet_int_en);   
   assign packet_is_saved_isr_en =(packet_is_saved_isr & packet_is_saved_int_en);
   assign packet_is_sent_isr_en = (packet_is_sent_isr & packet_is_sent_int_en);   
   assign irq =  got_packet_isr_en | packet_is_saved_isr_en | packet_is_sent_isr_en | any_err_isr_en;
                 


   
   assign ctrl_flags = 
          {invalid_send_req_err_isr,burst_size_err_isr, send_data_size_err_isr, crc_miss_match_isr, rcive_buff_ovrflw_err_isr,
          got_packet_isr, packet_is_saved_isr, packet_is_sent_isr,got_any_err_int_en,
          got_packet_int_en, packet_is_saved_int_en, packet_is_sent_int_en,receive_is_busy, send_is_busy};      
    
    always @ (*) begin 
        //default values
        send_pointer_addr_next= send_pointer_addr;
        send_pointer_addr_byte_offset_next=send_pointer_addr_byte_offset;
        receive_pointer_addr_next=receive_pointer_addr;
        send_data_size_next= send_data_size_reg;
        send_data_size_byte_offset_next=send_data_size_byte_offset;
        dest_e_addr_next = dest_e_addr;                                         
        pck_class_next= pck_class;
        weight_next = weight;          
        send_start_next = 1'b0;
        receive_en_next = receive_en;
       
        receive_max_buff_siz_next = receive_max_buff_siz;
        receive_start_index_next=receive_start_index;
        receive_start_index_offset_next=receive_start_index_offset;
        hdr_data_next = hdr_data;
        
        //ctrl flags
        invalid_send_req_err_isr_next = invalid_send_req_err_isr;
        burst_size_err_isr_next = burst_size_err_isr; 
        send_data_size_err_isr_next = send_data_size_err_isr;
        crc_miss_match_isr_next =crc_miss_match_isr;
        rcive_buff_ovrflw_err_isr_next =rcive_buff_ovrflw_err_isr;
       
        got_packet_isr_next =got_packet_isr;
        packet_is_saved_isr_next = packet_is_saved_isr;
        packet_is_sent_isr_next = packet_is_sent_isr;
        got_any_err_int_en_next = got_any_err_int_en;
        got_packet_int_en_next = got_packet_int_en;
        packet_is_saved_int_en_next = packet_is_saved_int_en;
        packet_is_sent_int_en_next = packet_is_sent_int_en;
       
        
       
        if (receive_vc_got_packet & receive_en ) begin 
            receive_en_next = 1'b0;
        end
             
        
        
        if(s_stb_i  &   s_cyc_i &  s_we_i & state_reg_enable)   begin             
                case( s_addr_i)
                    CTRL_FLAGS:begin 
                        got_any_err_int_en_next = s_dat_got_any_err_int_en;
                        got_packet_int_en_next = s_dat_got_packet_int_en;
                        packet_is_saved_int_en_next = s_dat_packet_is_saved_int_en;
                        packet_is_sent_int_en_next = s_dat_packet_is_sent_int_en;
                        
                        //reset isr flag when writting 1 
                        if(s_dat_invalid_send_req_err_isr)  invalid_send_req_err_isr_next = 1'b0;
                        if(s_dat_burst_size_err_isr)        burst_size_err_isr_next = 1'b0;
                        if(s_dat_send_data_size_err_isr)    send_data_size_err_isr_next = 1'b0;
                        if(s_dat_crc_miss_match_isr)        crc_miss_match_isr_next = 1'b0;
                        if(s_dat_rcive_buff_ovrflw_err_isr) rcive_buff_ovrflw_err_isr_next = 1'b0;
                        if(s_dat_got_packet_isr)            got_packet_isr_next = 1'b0;
                        if(s_dat_packet_is_saved_isr)       packet_is_saved_isr_next = 1'b0;
                        if(s_dat_packet_is_sent_isr)        packet_is_sent_isr_next = 1'b0;
                           
                    
                    end//CTRL_FLAGS
                
                
                
                
                    SEND_POINTER_WB_ADDR: begin                    
                         if (send_fsm_is_ideal) begin 
                            send_pointer_addr_next={{OFFSETw{1'b0}},s_dat_i [Dw-1    : OFFSETw]};
                            send_pointer_addr_byte_offset_next = s_dat_i[OFFSETw-1: 0];
                         end                              
                         
                    end //SEND_POINTER_WB_ADDR
                    SEND_DATA_SIZE_WB_ADDR: begin 
                        if (send_fsm_is_ideal) begin 
                            send_data_size_next=s_dat_i [MAX_TRANSACTION_WIDTH + OFFSETw -1 :    OFFSETw];
                            send_data_size_byte_offset_next = s_dat_i[OFFSETw-1: 0];
                        end   
               
                    end //DATA_SIZE_WB_ADDR
                    SEND_DEST_WB_ADDR: begin 
                        if (send_fsm_is_ideal) begin 
                            dest_e_addr_next = s_dat_i [EAw+ DST_X_LSB-1    :    DST_X_LSB];   
                           
//synthesis translate_off
//synopsys  translate_off
			if(DEBUG_EN)begin
				if(s_dat_i [EAw+ DST_X_LSB-1    :    DST_X_LSB] == current_e_addr )begin
					$display("%t: err: source destination address are identical in: %m",$time);
				end
			end
//synopsys  translate_on 
//synthesis translate_on
                                       
                            pck_class_next= s_dat_i[CLASS_LSB+Cw-1      :  CLASS_LSB];
                            weight_next = s_dat_i[ WEIGHT_LSB+WEIGHTw-1 :  WEIGHT_LSB]; 
                            send_start_next = 1'b1;
                           end    
                             
                    end //SEND_DEST_WB_ADDR
                    
                    SEND_HDR_DATA_WB_ADDR: begin
                        if (send_fsm_is_ideal) hdr_data_next = s_dat_i [HDw-1 : 0];
                        
                    end
                    RECEIVE_MAX_BUFF_SIZ: begin 
                        if (receive_fsm_is_ideal) receive_max_buff_siz_next = s_dat_i [MAX_TRANSACTION_WIDTH+ OFFSETw -1 :    OFFSETw]; 
                    end                    
                    
                    RECEIVE_POINTER_WB_ADDR: begin 
                        if (receive_fsm_is_ideal) receive_pointer_addr_next= {{OFFSETw{1'b0}},s_dat_i [Dw-1 :   OFFSETw]};
                    end //RECEIVE_POINTER_WB_ADDR
                    
                    RECEIVE_START_INDEX_WB_ADDR:begin 
                        if (receive_fsm_is_ideal) begin 
                            receive_start_index_next= s_dat_i [MAX_TRANSACTION_WIDTH+ OFFSETw -1 :    OFFSETw];
                            receive_start_index_offset_next= s_dat_i [OFFSETw-1 : 0];
                        end                        
                    end
                    
                    
                    
                    RECEIVE_CTRL_WB_ADDR: begin
                        if (receive_fsm_is_ideal) begin 
                       	 	receive_en_next=1'b1;                         
                        end 
                    end                 
                    
                    default :begin 
                          
                    end                         
                 endcase//wb_receive_send_addr
            end//if
            
            //isr setting flags
            if(invalid_send_req_err) invalid_send_req_err_isr_next = 1'b1;
            if(burst_size_err)      burst_size_err_isr_next = 1'b1;
            if(send_data_size_err)  send_data_size_err_isr_next = 1'b1;
            if(crc_miss_match_err)  crc_miss_match_isr_next = 1'b1;
            if(rcive_buff_ovrflw_err) rcive_buff_ovrflw_err_isr_next = 1'b1;
            if(receive_vc_got_hdr_flit_at_head)            got_packet_isr_next = 1'b1;
            if(receive_done)       packet_is_saved_isr_next = 1'b1;
            if(send_done)        packet_is_sent_isr_next = 1'b1;
            
            
        
    end// always
    
       
    //synthesis translate_off
    //synopsys  translate_off    
    always @(posedge clk) begin 
        if(s_stb_i  &   s_cyc_i &  s_we_i & state_reg_enable & ~receive_fsm_is_ideal ) begin 
            case(s_addr_i)
            SEND_DEST_WB_ADDR, SEND_POINTER_WB_ADDR,       
            SEND_DATA_SIZE_WB_ADDR,SEND_HDR_DATA_WB_ADDR:
                if(~send_fsm_is_ideal) $display("%t: Warning: write on NI sent register %d was not accepted as fsm was not in ideal state. %m!",$time,s_addr_i);
            RECEIVE_POINTER_WB_ADDR,  RECEIVE_MAX_BUFF_SIZ,  
            RECEIVE_START_INDEX_WB_ADDR, RECEIVE_CTRL_WB_ADDR:  
                if(~receive_fsm_is_ideal) $display("%t: Warning: write on NI receive register %d was not accepted as fsm was not in ideal state. %m!",$time,s_addr_i);
            default : begin
            
            end            
            endcase    
        end       
    end
    //synopsys  translate_on     
    //synthesis translate_on
    
    
    
   
    localparam [WEIGHTw-1 : 0] INIT_WEIGHT = 1;
 
 
     //registers assigmnet    
`ifdef SYNC_RESET_MODE 
    always @ (posedge clk )begin 
`else 
    always @ (posedge clk or posedge reset)begin 
`endif   
        if(reset) begin        
            send_pointer_addr   <= {Dw{1'b0}};
            send_pointer_addr_byte_offset<={OFFSETw{1'b0}};
            receive_pointer_addr   <= {Dw{1'b0}};
            send_data_size_reg    <= {MAX_TRANSACTION_WIDTH{1'b0}};
            send_data_size_byte_offset<={OFFSETw{1'b0}};
            receive_max_buff_siz <= {MAX_TRANSACTION_WIDTH{1'b0}}; 
            receive_start_index <= {MAX_TRANSACTION_WIDTH{1'b0}};
            receive_start_index_offset<={OFFSETw{1'b0}};
            dest_e_addr     <= {EAw{1'b0}};                                        
            pck_class  <= {Cw{1'b0}};
            weight <= INIT_WEIGHT;
            receive_en <= 1'b0;
           
            
            send_start <=1'b0;
            hdr_data <= {HDw{1'b0}}; 
          
            //ctrl flags
            invalid_send_req_err_isr<=1'b0;
            burst_size_err_isr<=1'b0;
            send_data_size_err_isr<=1'b0;
            crc_miss_match_isr<=1'b0;
            rcive_buff_ovrflw_err_isr<=1'b0;
            got_packet_isr<=1'b0;
            packet_is_saved_isr<=1'b0;
            packet_is_sent_isr<=1'b0;
            got_any_err_int_en<=1'b0;
            got_packet_int_en<=1'b0;
            packet_is_saved_int_en<=1'b0;
            packet_is_sent_int_en<=1'b0;
            
            
        end else begin 
            send_pointer_addr <= send_pointer_addr_next;
            send_pointer_addr_byte_offset<=send_pointer_addr_byte_offset_next;
            receive_pointer_addr <= receive_pointer_addr_next;
            send_data_size_reg <= send_data_size_next; 
            send_data_size_byte_offset <= send_data_size_byte_offset_next;            
            receive_max_buff_siz <= receive_max_buff_siz_next;
            dest_e_addr     <= dest_e_addr_next;   
            receive_start_index<=receive_start_index_next; 
            receive_start_index_offset<=receive_start_index_offset_next;
            pck_class  <= pck_class_next;
            weight <= weight_next;
            receive_en <=receive_en_next;
           
            send_start <= send_start_next;
            hdr_data <= hdr_data_next;
            
            //ctrl_flags
            invalid_send_req_err_isr        <=invalid_send_req_err_isr_next;
            burst_size_err_isr              <=burst_size_err_isr_next;
            send_data_size_err_isr          <=send_data_size_err_isr_next;
            crc_miss_match_isr              <=crc_miss_match_isr_next;
            rcive_buff_ovrflw_err_isr       <=rcive_buff_ovrflw_err_isr_next;
            got_packet_isr                  <=got_packet_isr_next;
            packet_is_saved_isr             <=packet_is_saved_isr_next;
            packet_is_sent_isr              <=packet_is_sent_isr_next;
            got_any_err_int_en              <=got_any_err_int_en_next;
            got_packet_int_en               <=got_packet_int_en_next;
            packet_is_saved_int_en          <=packet_is_saved_int_en_next;
            packet_is_sent_int_en           <=packet_is_sent_int_en_next;
            
        end 
    end 
  
 endmodule
