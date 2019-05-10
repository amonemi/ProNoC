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
    parameter WEIGHTw=4,     
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
    receive_vc_got_packet,
    receive_packet_is_saved,
    all_save_done_reg_rst,   
    send_start_addr, 
    receive_start_addr,
    send_data_size,
    max_receive_buff_siz,    
    dest_e_addr,
    pck_class,
    weight,  
    s_dat_i,
    s_addr_i,  
    s_stb_i,
    s_cyc_i,
    s_we_i,
//synthesis translate_off
//synopsys  translate_off    
    current_e_addr,
//synthesis translate_on
//synopsys  translate_on      
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
            
    localparam [S_Aw-1  :   0]
        SEND_DATA_SIZE_WB_ADDR =3,  // The transfer data size in byte  
        SEND_STRT_WB_ADDR =4,  // The source start address in byte       
        SEND_DEST_WB_ADDR =5,
        SEND_CTRL_WB_ADDR = 6,        
        RECEIVE_STRT_WB_ADDR=8,   // The destination start address in byte
        RECEIVE_CTRL_WB_ADDR =10,  
        RECEIVE_MAX_BUFF_SIZ=11;   // The reciver buffer size in words. If the packet size is bigger tha the buffer size the rest of will be discarred

   localparam
        WORLD_SIZE = Dw/8,
        OFFSET_w= log2(WORLD_SIZE),        
        Cw =  (C>1)? log2(C): 1;  
 
    input clk,reset;    
    input state_reg_enable;
    input send_fsm_is_ideal,receive_fsm_is_ideal;
    input receive_vc_got_packet;
    input receive_done;
    output  reg [Dw-1   :   0] send_start_addr; 
    output  reg [Dw-1   :   0] receive_start_addr;
    output  reg receive_packet_is_saved;
    input   all_save_done_reg_rst;    
    output  reg [MAX_TRANSACTION_WIDTH-1    :   0] send_data_size;
    output  reg [MAX_TRANSACTION_WIDTH-1    :   0] max_receive_buff_siz;
    output  reg [EAw-1   :   0]  dest_e_addr;
    output  reg [Cw-1   :   0]  pck_class;
    output  reg [WEIGHTw-1 :0]  weight; 
    output  reg send_start, receive_start;

//synthesis translate_off
//synopsys  translate_off    
    input   [EAw-1   :   0]  current_e_addr;
//synthesis translate_on
//synopsys  translate_on   
   
 //wishbone slave interface signals
    input   [Dw-1       :   0]      s_dat_i;
    input   [S_Aw-1     :   0]      s_addr_i;  
    input                           s_stb_i;
    input                           s_cyc_i;
    input                           s_we_i;
        
    reg  [EAw-1   :   0]  dest_e_addr_next;
    reg  [Cw-1   :   0]  pck_class_next;
    reg  [WEIGHTw-1 : 0] weight_next; 
    reg  [Dw-1   :   0]  send_start_addr_next, receive_start_addr_next;
    reg  [MAX_TRANSACTION_WIDTH-1    :   0] send_data_size_next, max_receive_buff_siz_next;
    reg  send_start_next;
    reg  receive_en,receive_en_next;
    reg  receive_packet_is_saved_next;
   
     // update control registers   
    always @ (*) begin 
        //default values       
        receive_start = 1'b0;                
        if (receive_fsm_is_ideal & receive_vc_got_packet & receive_en ) begin 
            receive_start = 1'b1;
           
        end
    end 
     
    always @ (*) begin 
        //default values
        send_start_addr_next= send_start_addr;
        receive_start_addr_next=receive_start_addr;
        send_data_size_next= send_data_size;
        dest_e_addr_next = dest_e_addr;                                         
        pck_class_next= pck_class;
        weight_next = weight;          
        send_start_next = 1'b0;
        receive_en_next = receive_en;
        receive_packet_is_saved_next = receive_packet_is_saved;
        max_receive_buff_siz_next = max_receive_buff_siz;
        
        if(all_save_done_reg_rst) receive_packet_is_saved_next=1'b0;
        if (receive_vc_got_packet & receive_en ) begin 
            receive_en_next = 1'b0;
        end
        if(receive_done) begin 
            receive_packet_is_saved_next = 1'b1;
        end
        if(s_stb_i  &   s_cyc_i &  s_we_i & state_reg_enable)   begin             
                case( s_addr_i)
                    SEND_STRT_WB_ADDR: begin                    
                         if (send_fsm_is_ideal) send_start_addr_next={{OFFSET_w{1'b0}},s_dat_i [Dw-1    : OFFSET_w]};
                    end //SEND_STRT_WB_ADDR
                    SEND_DATA_SIZE_WB_ADDR: begin 
                        if (send_fsm_is_ideal) send_data_size_next=s_dat_i [MAX_TRANSACTION_WIDTH-1 :   0]; 
                    end //DATA_SIZE_WB_ADDR
                    SEND_DEST_WB_ADDR: begin 
                        if (send_fsm_is_ideal) begin 
                            dest_e_addr_next = s_dat_i [EAw+ DST_X_LSB-1    :    DST_X_LSB];   
                           
//synthesis translate_off
//synopsys  translate_off
			if(DEBUG_EN)begin
				if(s_dat_i [EAw+ DST_X_LSB-1    :    DST_X_LSB] == current_e_addr )begin
					$display("%t: ERROR: source destination address are identical in: %m",$time);
				end
			end
//synthesis translate_on
//synopsys  translate_on                                        
                            pck_class_next= s_dat_i[CLASS_LSB+Cw-1      :  CLASS_LSB];
                            weight_next = s_dat_i[ WEIGHT_LSB+WEIGHTw-1 :  WEIGHT_LSB]; 
                            send_start_next = 1'b1;
                           end
                    end //SEND_DEST_WB_ADDR
                    SEND_CTRL_WB_ADDR: begin
                        if (send_fsm_is_ideal) begin 

                        end                    
                    end    // SEND_CTRL_WB_ADDR               
                    RECEIVE_MAX_BUFF_SIZ: begin 
                        if (receive_fsm_is_ideal) max_receive_buff_siz_next = s_dat_i [MAX_TRANSACTION_WIDTH-1 :   0]; 
                    
                    end                    
                    RECEIVE_STRT_WB_ADDR: begin 
                        if (receive_fsm_is_ideal) receive_start_addr_next= {{OFFSET_w{1'b0}},s_dat_i [Dw-1 :   OFFSET_w]};
                       
                    end //RECEIVE_STRT_WB_ADDR
                    RECEIVE_CTRL_WB_ADDR: begin
                        if (receive_fsm_is_ideal) begin 
                       	 	receive_en_next=1'b1;
                            receive_packet_is_saved_next=1'b0;   
                        end                 
                    end                 
                    
                    default :begin 
                          
                    end                         
                 endcase//wb_receive_send_addr
            end//if
        
    end// always
   
    localparam [WEIGHTw-1 : 0] INIT_WEIGHT = 1;
 
 
     //registers assigmnet    
    always @ (posedge clk or posedge reset)begin 
        if(reset) begin        
            send_start_addr   <= {Dw{1'b0}};
            receive_start_addr   <= {Dw{1'b0}};
            send_data_size    <= {MAX_TRANSACTION_WIDTH{1'b0}};
            max_receive_buff_siz <= {MAX_TRANSACTION_WIDTH{1'b0}}; 
            dest_e_addr     <= {EAw{1'b0}};                                        
            pck_class  <= {Cw{1'b0}};
            weight <= INIT_WEIGHT;
            receive_en <= 1'b0;
            receive_packet_is_saved <= 1'b0;
            send_start <=1'b0;
        end else begin 
            send_start_addr <= send_start_addr_next;
            receive_start_addr <= receive_start_addr_next;
            send_data_size <= send_data_size_next;           
            max_receive_buff_siz <= max_receive_buff_siz_next;
            dest_e_addr     <= dest_e_addr_next;                                        
            pck_class  <= pck_class_next;
            weight <= weight_next;
            receive_en <=receive_en_next;
            receive_packet_is_saved<=receive_packet_is_saved_next;
            send_start <= send_start_next;
        end 
    end 
  
 endmodule
