
/**********************************************************************
**	File:  ni_vc_dma.v
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
**	NI send-/receive-DMA
**	
**
*******************************************************************/







 `timescale  1ns/1ps
 
 
module ni_vc_dma #(
   
    parameter MAX_TRANSACTION_WIDTH=10, // MAximum transaction size will be 2 power of MAX_DMA_TRANSACTION_WIDTH words 
    parameter CRC_EN= "NO",// "YES","NO" if CRC is enable then the CRC32 of all packet data is calculated and sent via tail flit. 
    
    //wishbone port parameters
    parameter Dw            =   32,
    parameter M_Aw          =   32,
    parameter TAGw          =   3,
    parameter SELw          =   4


)
(
     // 
    reset,
    clk,
    
    //ctrl signals
    send_enable,
    receive_enable,
    send_is_busy,
    receive_is_busy,
    send_is_active,
    receive_is_active,
    last_burst,
    send_hdr,
    send_tail,
    status,
    save_hdr_info,
    send_done,
    receive_done,    
    
  
    send_fsm_is_ideal,
    receive_fsm_is_ideal,
    received_flit_is_tail,
    send_start_addr, 
    receive_start_addr,
    
    send_data_size,
    max_receive_buff_siz,
    send_start, 
    receive_start,
    receive_counter,
    
    
    //fifo signals
        
    send_fifo_wr, 
    send_fifo_full,
    send_fifo_nearly_full,
    send_fifo_rd,    
    receive_fifo_rd,  
    receive_fifo_empty,
    
    //busrdt counter control signals
    burst_counter_ld,
    burst_counter_dec,
    burst_size_is_set,
    

   
    //wishbone master rd interface signals
    m_send_sel_o,
    m_send_addr_o,
    m_send_cti_o,
    m_send_stb_o,
    m_send_cyc_o,
    m_send_we_o,
  //  m_send_dat_i,
    m_send_ack_i,    


     //wishbone master wr interface signals
     
    m_receive_sel_o,
   // m_receive_dat_o,
    m_receive_addr_o,
    m_receive_cti_o,
    m_receive_stb_o,
    m_receive_cyc_o,
    m_receive_we_o,
    m_receive_ack_i  
     
  
    

);


           
        
    //state machine registers/parameters
    localparam
        SEND_ST_NUM=5,
        RECEIVE_ST_NUM=4;
    localparam [SEND_ST_NUM-1 :   0]
        SEND_IDEAL = 1,
        SEND_HDR=2,
        SEND_BODY =4,
        SEND_CRC=8,
        SEND_WAIT=16;    
        
        
    localparam [RECEIVE_ST_NUM-1:0]
        RECEIVE_IDEAL = 1,
        RECEIVE_READ_FIFO=2,
        RECEIVE_ACTIVE =4,
        RECEIVE_RELEASE_WB=8;  
    
    localparam [2 : 0]
        CLASSIC = 3'b000,
        CONST_ADDR_BURST = 3'b010,
        INCREMENT_BURST = 3'b011,
        END_OF_BURST = 3'b111;
        
        
      //control Registers/ parameters 
    
   

    localparam STATUSw=SEND_ST_NUM+RECEIVE_ST_NUM;
   
    output  [STATUSw-1  :0] status;  


    input reset,clk,send_enable,receive_enable;
    output reg send_is_busy, receive_is_busy;
    output reg burst_counter_ld,    burst_counter_dec;
    input burst_size_is_set;
    input last_burst;
    output reg  send_hdr;
    output reg  send_done,receive_done;    
    
    output send_tail;
    output reg send_is_active, receive_is_active;
    input received_flit_is_tail;
    output reg  [MAX_TRANSACTION_WIDTH-1    :   0] receive_counter;
    output reg save_hdr_info;
   
    output send_fsm_is_ideal,receive_fsm_is_ideal;
    input  [Dw-1   :   0] send_start_addr; 
    input  [Dw-1   :   0] receive_start_addr;
    
    input  [MAX_TRANSACTION_WIDTH-1    :   0] send_data_size;
    input  [MAX_TRANSACTION_WIDTH-1    :   0] max_receive_buff_siz;
    input  send_start, receive_start;
    
    //fifo
    output reg  send_fifo_wr, receive_fifo_rd;
    input       send_fifo_full, send_fifo_nearly_full,send_fifo_rd, receive_fifo_empty;
    
    
  

  
    
    
    //wishbone read master interface signals
    output  [SELw-1          :   0] m_send_sel_o;
    output  [M_Aw-1          :   0] m_send_addr_o;
    output reg [TAGw-1       :   0] m_send_cti_o;
    output                          m_send_stb_o;
    output   reg                    m_send_cyc_o;
    output                          m_send_we_o;
   // input   [Dw-1           :  0]   m_send_dat_i;
    input                           m_send_ack_i;    
     
     //wishbone write master interface signals
    output  [SELw-1          :   0] m_receive_sel_o;
  //  output  [Dw-1            :   0] m_receive_dat_o;
    output  [M_Aw-1          :   0] m_receive_addr_o;
    output  reg [TAGw-1      :   0] m_receive_cti_o;
    output                          m_receive_stb_o;
    output  reg                     m_receive_cyc_o;
    output                          m_receive_we_o;
    input                           m_receive_ack_i;   
    
    
    reg [MAX_TRANSACTION_WIDTH-1    :   0] send_counter, send_counter_next;
    reg [MAX_TRANSACTION_WIDTH-1    :   0] receive_counter_next;
  
       
        
    
    wire last_data = (send_counter == send_data_size-1'b1);
   
    wire receive_overflow= (send_counter == max_receive_buff_siz);    
    
    reg [SEND_ST_NUM-1    :0] send_ps,send_ns; // read  peresent state, read next sate 
    reg [RECEIVE_ST_NUM-1    :0] receive_ps,receive_ns; // read  peresent state, read next sate
    
    reg receive_is_busy_next, send_is_busy_next;
   
   
    assign status= {receive_ps,send_ps};
   // assign s_dat_o={{(Dw-STATUSw){1'b0}}, status};
   
    reg  send_crc; 
    assign send_tail =  ( CRC_EN == "NO") ?  last_data : send_crc; 
     
    
    
    assign send_fsm_is_ideal = (send_ps== SEND_IDEAL);
    assign receive_fsm_is_ideal = (receive_ps== RECEIVE_IDEAL);
    assign m_send_addr_o =  send_start_addr + send_counter;
    assign m_receive_addr_o =  receive_start_addr + receive_counter;
    assign m_send_stb_o =  m_send_cyc_o;
    assign m_receive_stb_o =  m_receive_cyc_o;
    assign m_receive_we_o = 1'b1;
    assign m_send_we_o = 1'b0;
    assign m_receive_sel_o = 4'b1111;
    assign m_send_sel_o = 4'b1111;
    
 
    reg [1:0] active_st,active_st_next;
     //send state machine
    always @ (*) begin 
        // default values 
        send_ns = send_ps;
        send_counter_next=send_counter;
        burst_counter_ld=1'b0;
        burst_counter_dec=1'b0;
        m_send_cti_o =  CONST_ADDR_BURST;
        m_send_cyc_o=1'b0;
        send_fifo_wr=1'b0;
        send_done = 1'b0;
        send_is_active =1'b0;
        send_hdr = 1'b0;
        send_crc = 1'b0; 
        active_st_next = active_st;
        case(send_ps)
            SEND_IDEAL: begin 
                if(send_start) begin 
                    if (burst_size_is_set && (send_data_size>0)) begin 
                        send_counter_next= {MAX_TRANSACTION_WIDTH{1'b0}};
                        burst_counter_ld=1'b1;
                        send_ns = SEND_HDR;
                    end else begin // set error reg
                    end
                end
            end // SEND_IDEAL
            SEND_HDR: begin 
                    active_st_next =2'd1;
                    send_is_active =1'b1; // this signal sends request to the send_arbiter, the granted signal is send_enable
                    if(send_enable) begin 
                        send_hdr = 1'b1;                                             
                        if(send_fifo_nearly_full & !send_fifo_rd)  begin
                            send_ns =  SEND_WAIT; 
                        end else begin 
                            send_fifo_wr=1'b1;
                            send_ns =  SEND_BODY;
                                                     
                        end
                    end
                         
            end // SEND_ACTIVE
            
            
            
               
            SEND_BODY: begin 
                    active_st_next =2'd2;
                    send_is_active =1'b1; // this signal sends request to the send_arbiter, the granted signal is send_enable
                    if(send_enable) begin 
                        m_send_cyc_o=1'b1; 
                        
                        if(last_data |  last_burst | (send_fifo_nearly_full & !send_fifo_rd))  m_send_cti_o= END_OF_BURST;  
                        if(send_fifo_nearly_full & !send_fifo_rd)  send_ns =  SEND_WAIT;
                               
                                
                        if (m_send_ack_i) begin 
                                send_fifo_wr=1'b1;
                                send_counter_next=send_counter +1'b1;
                                burst_counter_dec=1'b1;
                                                                    
                                if(last_data) begin 
                                    send_ns = ( CRC_EN == "NO") ? SEND_IDEAL : SEND_CRC;
                                  send_done = 1'b1;
                                  
                                end else if (last_burst | (send_fifo_nearly_full & !send_fifo_rd)) begin 
                                  send_ns = SEND_WAIT;
                                 
                                end 
                        end 
                    end
                         
            end // SEND_BODY
            
          SEND_CRC: begin 
                    active_st_next =2'd3;
                    send_is_active =1'b1; // this signal sends request to the send_arbiter, the granted signal is send_enable
                    if(send_enable) begin 
                        send_crc = 1'b1;                                             
                        if(send_fifo_nearly_full & !send_fifo_rd)  begin
                                send_ns =  SEND_WAIT;  
                        end else begin 
                                send_fifo_wr=1'b1;
                                send_ns =  SEND_IDEAL;
                                                      
                        end
                    end
                         
            end // SEND_ACTIVE
            
            
            
            
            
             SEND_WAIT: begin 
                    //burst_counter_next = burst_size;
                     
                burst_counter_ld=1'b1;
                if(!send_fifo_full) begin 
                        send_ns = ( active_st ==2'd1) ? SEND_HDR :
                                  ( active_st ==2'd2) ? SEND_BODY : SEND_CRC;
                end
                
            end //SEND_RELEASE_WB
            default: begin
                    
                    
            end
       endcase      
    end//alays
    
    
 
            
           
       
    
 
    reg hdr_flit_is_received,hdr_flit_is_received_next;
 
 //receive state machine    
    always @ (*) begin 
        // default values 
        receive_ns = receive_ps;
        receive_counter_next=receive_counter;
        m_receive_cyc_o=1'b0;
        m_receive_cti_o= CONST_ADDR_BURST;
        receive_fifo_rd=1'b0;
        receive_done=1'b0;
        receive_is_active =1'b0;
        hdr_flit_is_received_next=hdr_flit_is_received;
        save_hdr_info=1'b0;
       
            case(receive_ps)
                RECEIVE_IDEAL: begin 
                    
                    hdr_flit_is_received_next =1'b0;                
                    if(receive_start )begin 
                        receive_counter_next = {MAX_TRANSACTION_WIDTH{1'b0}};  
                        receive_ns = RECEIVE_READ_FIFO;                         
                    end 
                    
                end // RECEIVE_IDEAL
                RECEIVE_READ_FIFO: begin 
                     receive_is_active =1'b1; // this signal sends request to the receive_arbiter, the granted signal is receive_enable
                     if(receive_enable) begin 
                          receive_ns = RECEIVE_ACTIVE; 
                          receive_fifo_rd=1'b1;
                    end
                end
                
                
                RECEIVE_ACTIVE: begin 
                     receive_is_active =1'b1; // this signal sends request to the receive_arbiter, the granted signal is receive_enable
                     if(receive_enable) begin 
                            if(CRC_EN == "YES")begin 
                                if(received_flit_is_tail)begin 
                                    m_receive_cyc_o = 1'b0;// make sre do not save crc on data memory
                                    receive_ns = RECEIVE_IDEAL;
                                    m_receive_cti_o= END_OF_BURST;
                                    receive_done=1'b1;  
                                end else begin 
                                    m_receive_cyc_o=1'b1; 
                                end
                            end else  m_receive_cyc_o=1'b1; //CRC_EN == "NO"
                            if (receive_fifo_empty) begin 
                                m_receive_cti_o= END_OF_BURST;                             
                            end
                            if (m_receive_ack_i) begin 
                                hdr_flit_is_received_next=1'b1;
                                if(! hdr_flit_is_received) save_hdr_info=1'b1;
                                if(! receive_overflow && hdr_flit_is_received) receive_counter_next=receive_counter +1'b1; //Donot save hedaer flit in memory
                                if (received_flit_is_tail) begin 
                                    receive_ns = RECEIVE_IDEAL;
                                    m_receive_cti_o= END_OF_BURST; 
                                    receive_done=1'b1; 
                                end
                                else if (receive_fifo_empty) begin 
                                    receive_ns = RECEIVE_RELEASE_WB; 
                                   
                                end else begin 
                                    receive_fifo_rd=1'b1;
                                end                 
                            end 
                     end               
                end // RECEIVE_ACTIVE
               RECEIVE_RELEASE_WB: begin 
                    if (! receive_fifo_empty) begin 
                                    receive_ns = RECEIVE_READ_FIFO;                                    
                    end                
                end //RELEASE_WB                
                default: begin
                    
                    
                    end
            endcase
       
    end//alays
    
          
    always @(*)begin 
        send_is_busy_next= send_is_busy;
        if(send_start) send_is_busy_next =1'b1;
        else if(send_done) send_is_busy_next=1'b0;
    end
    
    
     always @(*)begin 
        receive_is_busy_next= receive_is_busy;
        if(receive_done) receive_is_busy_next =1'b0;
        else if(receive_start) receive_is_busy_next=1'b1;
    end
    
   
    
    
    //registers assigmnet
    
    always @ (posedge clk or posedge reset)begin 
        if(reset) begin 
            send_ps <= SEND_IDEAL;
            receive_ps <= RECEIVE_IDEAL;
            send_counter <=  {MAX_TRANSACTION_WIDTH{1'b0}};
            receive_counter <=   {MAX_TRANSACTION_WIDTH{1'b0}}; 
            send_is_busy<= 1'b0;
            receive_is_busy<= 1'b0;
            hdr_flit_is_received<=1'b0;
            active_st <= 2'd0;
           
          
        end else begin 
            send_ps <= send_ns;
            receive_ps <= receive_ns;
            send_counter <=  send_counter_next;
            receive_counter <=  receive_counter_next; 
            send_is_busy <=send_is_busy_next;
            receive_is_busy <=receive_is_busy_next;
            hdr_flit_is_received<=hdr_flit_is_received_next;
            active_st <= active_st_next;
           
        end 
    end 
    
    
    
/*
    dma_fifo  #(
         .Dw(Dw),//data_width
         .B(B) // buffer num
    ) 
    the_fifo
    (
         .din(m_send_dat_i),   
         .receive_en(send_fifo_wr), 
         .send_en(fifo_rd), 
         .dout(m_receive_dat_o),  
         .full(send_fifo_full),
         .nearly_full(send_fifo_nearly_full),
         .empty(receive_fifo_empty),
         .reset(reset),
         .clk(clk)
    );
*/
 





endmodule
