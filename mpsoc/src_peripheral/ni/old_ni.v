/**************************************
* Module: ni
* Date:2015-03-30  
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
        1- Read packet register: contain the pointer and maximum size of the pointer 
                                         which has been dedicated by cpu to store the received 
                                         packet 
        2- write packet register: contain the pointer and maximum size of the pointer 
                                          of the packet which must be sent. The destination address 
                                         must be updated by cpu in the first word of the packet 
        3-status register: provide information about the current status of the router 
    
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



module old_ni #(

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
  
    parameter NI_PTR_WIDTH=19,
    parameter NI_PCK_SIZE_WIDTH= 13,
    
    //wishbone port parameters
    parameter RAM_WIDTH_IN_WORD     =   13,
    parameter Dw            =   32,
    parameter S_Aw          =   3,
    parameter M_Aw          =   RAM_WIDTH_IN_WORD,
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
   
    localparam  P_1    =    P-1 ,
                Fw     =    2+V+Fpay, //flit width
                Xw =   log2(NX),
                Yw =   log2(NY); 
                   
                    
                    
 localparam     NI_BUSY_LOC=            0,  
                NI_WR_DONE_LOC=         1,
                NI_RD_DONE_LOC=         2,
                NI_RD_OVR_ERR_LOC=      3,
                NI_RD_NPCK_ERR_LOC=     4,
                NI_HAS_PCK_LOC=         5,
                NI_ALL_VCS_FULL_LOC=    6,
                NI_WR_DONE_INT_EN_LOC=  7,
                NI_RD_DONE_INT_EN_LOC=  8,
                NI_RSV_PCK_INT_EN_LOC=  9,
                NI_WR_DONE_ISR_LOC=     10,
                NI_RD_DONE_ISR_LOC=     11,
                NI_RSV_PCK_ISR_LOC=     12;  
                
                
localparam  CLASS_IN_HDR_WIDTH      =8,
            DEST_IN_HDR_WIDTH       =8,
            X_Y_IN_HDR_WIDTH        =4,
            HDR_ROUTING_INFO_WIDTH  =   CLASS_IN_HDR_WIDTH+DEST_IN_HDR_WIDTH+ 4* X_Y_IN_HDR_WIDTH;
            
localparam  NUMBER_OF_STATUS    =   7,
            IDEAL               =   1,
            READ_MEM_PCK_HDR    =   2,
            ASSIGN_PORT_VC      =   4,
            SEND_HDR            =   8,
            WR_ON_FIFO          =   16,
            WR_ON_RAM           =   32,
            AUTO_WR             =   64;
                
            
   
    localparam  COUNTER_WIDTH       =   M_Aw-1;
    localparam  PTR_WIDTH           =   NI_PTR_WIDTH-2;
    localparam  PCK_SIZE_WIDTH      =   NI_PCK_SIZE_WIDTH;
    localparam  HDR_FLIT            =   2'b10;
    localparam  BDY_FLIT            =   2'b00;
    localparam  TAIL_FLIT           =   2'b01;
    localparam  SLAVE_RD_PCK_ADDR   =   0;
    localparam  SLAVE_WR_PCK_ADDR   =   1;
    localparam  SLAVE_STATUS_ADDR   =   2;
    
  
    
    
    input reset;
    input clk;
    
    
    // NOC interfaces
    input   [Xw-1   :   0]  current_x;
    input   [Yw-1   :   0]  current_y;
    output  [Fw-1   :   0]  flit_out;     
    output  reg             flit_out_wr;   
    input   [V-1    :   0]  credit_in;
    input   [Fw-1   :   0]  flit_in; 
    input                   flit_in_wr;   
    output reg  [V-1:   0]  credit_out;     
    
    

    //wishbone slave interface signals
    input   [Dw-1       :   0]      s_dat_i;
    input   [SELw-1     :   0]      s_sel_i;
    input   [S_Aw-1     :   0]      s_addr_i;  
    input   [TAGw-1     :   0]      s_tag_i;
    input                           s_stb_i;
    input                           s_cyc_i;
    input                           s_we_i;
    
    output      [Dw-1       :   0]  s_dat_o;
    output  reg                     s_ack_o;
    output                          s_err_o;
    output                          s_rty_o;
    
    
    //wishbone master interface signals
    output  [SELw-1          :   0] m_sel_o;
    output  [Dw-1            :   0] m_dat_o;
    output  [M_Aw-1          :   0] m_addr_o;
    output  [TAGw-1          :   0] m_tag_o;
    output                          m_stb_o;
    output                          m_cyc_o;
    output                          m_we_o;
    input   [Dw-1           :  0]   m_dat_i;
    input                           m_ack_i;    
    input                           m_err_i;
    input                           m_rty_i;
    //intruupt interface
    output                          irq;
    
  
    assign  s_err_o=1'b0;
    assign  s_rty_o=1'b0;

    
    
    wire    [P_1-1              :   0]  destport_next;
    reg     [P_1-1              :   0]  destport;
    wire    [Xw-1               :   0]  dest_x_addr;
    wire    [Yw-1               :   0]  dest_y_addr;
    wire    [Fpay-1             :   0]  flit_out_hdr_pyd;
    
    
    wire                                m_waitrequest, m_read;
    wire                                s_ack_o_next;
    reg                                 last_rw;
    reg                                 m_ack_i_delayed;  
   
   
    reg                                     rsv_pck_isr, rd_done_isr,wr_done_isr,rsv_pck_int_en, rd_done_int_en,wr_done_int_en;
    reg                                     rsv_pck_isr_next, rd_done_isr_next,wr_done_isr_next,rsv_pck_int_en_next, rd_done_int_en_next,wr_done_int_en_next;
    
        
    reg     [NUMBER_OF_STATUS-1     :   0]  ps,ns;
    reg     [COUNTER_WIDTH-1        :   0]  counter,counter_next;
    reg                                     counter_reset,   counter_increase;
    
    // memory mapped registers
    wire    [Fpay-1                 :   0]  status_reg;
    wire    [Fpay-1                 :   0]  m_pyld;
    
    reg     [PTR_WIDTH-1            :   0]  memory_ptr,memory_ptr_next;
    reg     [PCK_SIZE_WIDTH-1       :   0]  pck_size,pck_size_next;
    wire                                    pck_eq_counter;

    reg                                     wr_done_next, wr_done;
    reg                                     rd_done_next, rd_done;
    reg                                     rd_no_pck_err_next, rd_no_pck_err;
    reg                                     rd_ovr_size_err_next, rd_ovr_size_err;
    reg                                     wr_mem_en, rd_mem_en;
    
    
    
    reg                                     cand_wr_vc_en;
    wire                                    cand_wr_vc_full;
    reg     [V-1                    :   0]  cand_rd_vc,cand_rd_vc_next;
    wire                                    no_rd_vc_is_cand;
    reg                                     cand_rd_vc_en,cand_rd_vc_rst;
    wire                                    cand_rd_vc_not_empty;
    reg                                     any_vc_has_data;
    
        
    
    wire    [V-1                    :   0]  rd_vc_arbiter_in ,rd_vc_arbiter_out; 
    reg                                     ififo_rd_en; 
    
        
    wire                                     all_vcs_full;
    reg     [1                      :   0]   wr_flit_type;
     
    wire    [Fw-1                   :   0]  ififo_dout;   
    wire    [V-1                    :   0]  ififo_vc_not_empty;
    wire                                    ififo_hdr_flg, ififo_tail_flg;
   
    
    reg                                     destport_ld;
    reg                                     AUTO_mode_en,AUTO_mode_en_delay;
    wire                                    AUTO_mode_en_next;
    
    reg                                     hdr_write;
    reg                                     read_burst;
    
    
    wire    [V-1  :0] full_vc;
    wire    [V-1  :0] cand_wr_vc;
    wire                 noc_busy;
    
    
    assign  m_sel_o         =   4'b1111;
    assign  m_waitrequest   =   ~m_ack_i_delayed ; //in busrt mode  the ack is regisered inside the ni insted of ram to avoid combinational loop
    assign  m_cyc_o         =   m_we_o | m_read;
    assign  s_ack_o_next    =   s_stb_i & (~s_ack_o);
    assign  m_tag_o         =   (m_stb_o)   ?   ((last_rw)? 3'b111 :    3'b010) : 3'b000;
    
    assign  irq             = (rsv_pck_isr & rsv_pck_int_en) | (rd_done_isr & rd_done_int_en) | (wr_done_isr & wr_done_int_en);
        
    assign  all_vcs_full    =   & full_vc;
    assign  cand_wr_vc_full =   | ( full_vc & cand_wr_vc);
         
    
    assign  no_rd_vc_is_cand            =   ~(| cand_rd_vc);
    assign  rd_vc_arbiter_in            =   (cand_rd_vc_en)?  ififo_vc_not_empty : {V{1'b0}} ;
    assign  cand_rd_vc_not_empty        =   |(ififo_vc_not_empty & cand_rd_vc) ;
    
    
    
    assign  m_stb_o         =   wr_mem_en | rd_mem_en;
    assign  m_we_o          =   wr_mem_en;
    assign  m_read          =   rd_mem_en;
    
    assign  m_dat_o         =   {ififo_dout[Fpay-1  :   0]};
    
    assign  flit_out        =   {wr_flit_type,cand_wr_vc,m_pyld};
    
    
    wire    [CLASS_IN_HDR_WIDTH-1   :   0]  flit_in_class_hdr;
    wire    [DEST_IN_HDR_WIDTH-1    :   0]  flit_in_destport_hdr;
    wire    [X_Y_IN_HDR_WIDTH-1     :   0]  flit_in_x_src_hdr, flit_in_y_src_hdr, flit_in_x_dst_hdr, flit_in_y_dst_hdr;
    wire    [V-1                    :   0]  flit_in_vc_num;
    wire    [1                      :   0]  flit_in_flg_hdr;


    //extract header flit info
    assign {flit_in_class_hdr,flit_in_destport_hdr, flit_in_x_dst_hdr, flit_in_y_dst_hdr, flit_in_x_src_hdr, flit_in_y_src_hdr}= flit_in [HDR_ROUTING_INFO_WIDTH-1      :0];
    assign flit_in_vc_num = flit_in [Fpay+V-1    :   Fpay];
    assign flit_in_flg_hdr= flit_in [Fw-1    :   Fw-2];    
    assign AUTO_mode_en_next    =   flit_in_flg_hdr[1] & (flit_in_class_hdr == {CLASS_IN_HDR_WIDTH{1'b1}});    



    wire    [CLASS_IN_HDR_WIDTH-1   :   0]  flit_out_class_hdr;
    wire    [DEST_IN_HDR_WIDTH-1    :   0]  flit_out_destport_hdr;
    wire    [X_Y_IN_HDR_WIDTH-1     :   0]  flit_out_x_src_hdr, flit_out_y_src_hdr, flit_out_x_dst_hdr, flit_out_y_dst_hdr;



generate 
    if(X_Y_IN_HDR_WIDTH== Xw)   assign flit_out_x_src_hdr = current_x;
    else                        assign flit_out_x_src_hdr = {{(X_Y_IN_HDR_WIDTH-Xw){1'b0}},current_x};
    if(X_Y_IN_HDR_WIDTH== Yw)   assign flit_out_y_src_hdr = current_y;
    else                        assign flit_out_y_src_hdr = {{(X_Y_IN_HDR_WIDTH-Yw){1'b0}},current_y}; 
    if(DEST_IN_HDR_WIDTH==P_1)  assign flit_out_destport_hdr=destport;
    else                        assign flit_out_destport_hdr={{(DEST_IN_HDR_WIDTH-P_1){1'b0}},destport};
endgenerate

    assign {flit_out_x_dst_hdr, flit_out_y_dst_hdr} = m_dat_i[4*X_Y_IN_HDR_WIDTH-1           : 2*X_Y_IN_HDR_WIDTH];
    assign flit_out_class_hdr                       = m_dat_i[4*X_Y_IN_HDR_WIDTH+DEST_IN_HDR_WIDTH+CLASS_IN_HDR_WIDTH-1   : 4*X_Y_IN_HDR_WIDTH+DEST_IN_HDR_WIDTH];
    assign  dest_x_addr     =   flit_out_x_dst_hdr[Xw-1 :   0];
    assign  dest_y_addr     =   flit_out_y_dst_hdr[Yw-1 :   0];
    assign flit_out_hdr_pyd = {flit_out_class_hdr,flit_out_destport_hdr, flit_out_x_dst_hdr, flit_out_y_dst_hdr, flit_out_x_src_hdr, flit_out_y_src_hdr} ;

    
    assign  m_pyld                      =   (hdr_write)? flit_out_hdr_pyd :   m_dat_i;
    
    assign ififo_hdr_flg            =   ififo_dout  [Fw-1 ];
    assign ififo_tail_flg           =   ififo_dout  [Fw-2 ];
   
      
    //status register
     assign  noc_busy                   =   ps!=IDEAL;
    assign  status_reg                  =   {rsv_pck_isr, rd_done_isr,wr_done_isr,rsv_pck_int_en, rd_done_int_en,wr_done_int_en,all_vcs_full,any_vc_has_data,rd_no_pck_err,rd_ovr_size_err,rd_done,wr_done,noc_busy};
    assign  s_dat_o                  =   status_reg;
   
    
    generate 
        if(M_Aw        >    PTR_WIDTH)         assign  m_addr_o    = (~m_waitrequest & read_burst)?   memory_ptr+counter+1'b1: memory_ptr+counter;
        else                                            assign  m_addr_o    = (~m_waitrequest & read_burst)?   memory_ptr[M_Aw-1  :0 ] + counter + 1'b1: memory_ptr[M_Aw-1  :0 ] + counter;
    
        if(COUNTER_WIDTH    >   PCK_SIZE_WIDTH )  assign    pck_eq_counter              = ( counter[PCK_SIZE_WIDTH-1:   0] == pck_size);
        else                                                assign  pck_eq_counter              = ( counter == (pck_size[COUNTER_WIDTH-1    :0]));
        
    endgenerate                                                                                 
    
       
    
    
    always@(posedge clk or posedge reset)begin
        if(reset)begin
            destport            <= {P_1{1'b0}};
            ps                  <=  IDEAL;
            memory_ptr          <=  {PTR_WIDTH{1'b0}};
            pck_size            <=  {PCK_SIZE_WIDTH{1'b0}};
            counter             <=  {COUNTER_WIDTH{1'b0}};
            cand_rd_vc          <=  {V{1'b0}};
            wr_done             <=  1'b0;
            rd_done             <=  1'b0;
            rd_no_pck_err       <=  1'b0;
            rd_ovr_size_err     <= 1'b0;
            any_vc_has_data     <= 1'b0;
            AUTO_mode_en        <= 1'b0;
            AUTO_mode_en_delay  <= 1'b0;
            m_ack_i_delayed     <=  1'b0;
            s_ack_o             <= 1'b0;
            rsv_pck_int_en      <= 1'b0;
            rd_done_int_en      <= 1'b0;
            wr_done_int_en      <= 1'b0;
            rsv_pck_isr         <= 1'b0;
            rd_done_isr         <= 1'b0;
            wr_done_isr         <= 1'b0;
            
        end else begin //if reset
            if(destport_ld)destport <= destport_next; 
            ps                      <=  ns;
            memory_ptr          <=  memory_ptr_next;
            pck_size            <=  pck_size_next;
            counter             <=  counter_next;
            cand_rd_vc          <=  cand_rd_vc_next;
            wr_done             <=  wr_done_next;
            rd_done             <=  rd_done_next;
            rd_no_pck_err       <=  rd_no_pck_err_next;
            rd_ovr_size_err     <= rd_ovr_size_err_next;
            any_vc_has_data     <= | ififo_vc_not_empty;
            AUTO_mode_en        <= AUTO_mode_en_next;
            AUTO_mode_en_delay  <= AUTO_mode_en;
            m_ack_i_delayed     <=  m_ack_i;
            s_ack_o             <= s_ack_o_next;
            rsv_pck_int_en      <= rsv_pck_int_en_next;
            rd_done_int_en      <= rd_done_int_en_next;
            wr_done_int_en      <= wr_done_int_en_next;
            rsv_pck_isr         <= rsv_pck_isr_next;            
            rd_done_isr         <= rd_done_isr_next;
            wr_done_isr         <= wr_done_isr_next;
        end//els reset
    end//always
    
    
    always@(*)begin
        counter_next        = counter;  
        cand_rd_vc_next = cand_rd_vc;
        if      (counter_reset)             counter_next    =   {COUNTER_WIDTH{1'b0}};
        else if (counter_increase)          counter_next    =  counter +1'b1;
        if  (cand_rd_vc_rst)            cand_rd_vc_next =   {V{1'b0}};
        else if(cand_rd_vc_en)      cand_rd_vc_next =   rd_vc_arbiter_out;
     end//always
    
    reg wr_done_trg,rd_done_trg;
    
    always@(*) begin
        ns                      = ps;
        counter_reset           = 1'b0;
        counter_increase        = 1'b0;
        cand_rd_vc_rst          = 1'b0;
        cand_rd_vc_en           = 1'b0;
        cand_rd_vc_rst          = 1'b0;
        ififo_rd_en             = 1'b0;  
        wr_mem_en               = 1'b0;
        credit_out              = {V{1'b0}};
        rd_mem_en               = 1'b0;
        flit_out_wr             = 1'b0;
        cand_wr_vc_en           = 1'b0;
        destport_ld             = 1'b0;
        wr_done_next            = wr_done;
        rd_done_next            = rd_done;
        rd_no_pck_err_next  = rd_no_pck_err;
        rd_ovr_size_err_next    = rd_ovr_size_err;
        memory_ptr_next     = memory_ptr;
        pck_size_next           = pck_size;
        wr_flit_type            = BDY_FLIT; 
        hdr_write               = 1'b0;
        last_rw                 = 1'b0;
        read_burst              = 1'b0;
        wr_done_trg             = 1'b0;
        rd_done_trg             = 1'b0;
        case(ps)
            
            IDEAL:   begin 
                counter_reset =1;
                cand_rd_vc_en   =   (no_rd_vc_is_cand)? 1'b1    :   1'b0;
                if  (AUTO_mode_en_delay)    begin
                    ns                      =   AUTO_WR;
                   
                    ififo_rd_en         =   1'b1;
                    credit_out          =   cand_rd_vc;
                end
                if(s_stb_i &    s_we_i )   begin 
                    {pck_size_next,memory_ptr_next} = s_dat_i[31:2];
                    case (s_addr_i) 
                        SLAVE_RD_PCK_ADDR:  begin   
                            rd_done_next        = 1'b0;
                            rd_ovr_size_err_next=1'b0;
                                if(any_vc_has_data) begin 
                                    //synthesis translate_off
                                        $display ("%t,\t   core (%d,%d) has recived a packet",$time,current_x,current_y);
                                    //synthesis translate_on
                                                                
                                    ns  = WR_ON_RAM;
                                    rd_no_pck_err_next= 1'b0;
                                    ififo_rd_en         = 1'b1; 
                                    credit_out          =   cand_rd_vc;
                                end else    begin
                                    ns= IDEAL;
                                    rd_no_pck_err_next= 1'b1;
                                end
                    end   //SLAVE_RD_PCK_ADDR:
                    SLAVE_WR_PCK_ADDR:  begin           
                            ns                  = READ_MEM_PCK_HDR;
                            wr_done_next    =1'b0;
                                                        
                    end //SLAVE_WR_PCK_ADDR
                    default:                        ns= IDEAL;
                    endcase
                end
            end
            
            READ_MEM_PCK_HDR:   begin
                if(~all_vcs_full)   begin
                        ns  =   ASSIGN_PORT_VC;
                        rd_mem_en  =   1'b1;
                        
                end 
                
            end //READ_MEM_PCK_HDR:
            ASSIGN_PORT_VC  : begin
                if(~m_waitrequest) begin 
                        ns                  =   SEND_HDR;
                        rd_mem_en           =   1'b1;
                        counter_increase    =   1'b1;
                        cand_wr_vc_en       =   1'b1;
                        destport_ld         =   1'b1;
                end else rd_mem_en          =  1'b1;
            end
            SEND_HDR: begin 
                        ns                  =   WR_ON_FIFO;
                        wr_flit_type        =   HDR_FLIT;
                        hdr_write           =   1'b1;
                        flit_out_wr         =   1'b1;
            end             
            WR_ON_FIFO: begin 
                    read_burst          =   1'b1;
                    if(!m_waitrequest) begin 
                        if(pck_eq_counter) begin
                            flit_out_wr     =   1'b1;
                            ns                  =   IDEAL;
                            wr_done_next    =   1'b1;
                            wr_done_trg     =  1'b1;
                            wr_flit_type    = TAIL_FLIT;    
                            last_rw         =   1'b1;
                        end else if(!cand_wr_vc_full) begin 
                            flit_out_wr         =1'b1;
                            counter_increase    = 1'b1;
                            rd_mem_en           = 1'b1;
                        end 
                    end else if(!cand_wr_vc_full)   rd_mem_en           = 1'b1; 
                //end
            end//WR_ON_FIFO
            
            
            WR_ON_RAM:  begin
                rd_no_pck_err_next= 1'b0;
                if(ififo_tail_flg) begin
                    if(~m_waitrequest) begin 
                            ns                          =   IDEAL;
                            last_rw                 =   1'b1;
                            rd_done_next            =   1'b1;
                            rd_done_trg             =  1'b1;
                            cand_rd_vc_rst          =   1'b1;
                            wr_mem_en               =   1'b1;
                    end else  wr_mem_en         =   1'b1;
                end //ififo_tail_flg
                else if(~m_waitrequest) begin 
                        if(cand_rd_vc_not_empty ) begin
                            ififo_rd_en             = 1'b1; 
                            credit_out              =   cand_rd_vc;
                            counter_increase        = 1'b1;
                            if( pck_eq_counter )    rd_ovr_size_err_next    =   1'b1;
                            else                        wr_mem_en   =   1'b1;
                        end// cand_rd_vc_not_empty
                end //m_waitrequest
                else    if(cand_rd_vc_not_empty ) wr_mem_en =   1'b1;
            end //WR_ON_RAM
            
            AUTO_WR :   begin
                    memory_ptr_next =   ififo_dout [PTR_WIDTH-1            :   0];
                    pck_size_next={PCK_SIZE_WIDTH{1'b1}};
                    if(cand_rd_vc_not_empty ) begin
                            ififo_rd_en             = 1'b1; 
                            credit_out              = cand_rd_vc;
                            if(! ififo_hdr_flg)   ns=   WR_ON_RAM;
                           
                    end// if(cand_AUTO_vc_not_empty )
                
            end//AUTO_WR
                
            
            default : ns=IDEAL;
        
        endcase
    end
    
    
    //isr_register handeling
    always @(*) begin
            rsv_pck_int_en_next     = rsv_pck_int_en;
            rd_done_int_en_next     = rd_done_int_en;
            wr_done_int_en_next     = wr_done_int_en;
            rsv_pck_isr_next            = rsv_pck_isr;          
            rd_done_isr_next            = rd_done_isr;
            wr_done_isr_next            = wr_done_isr;
        
        if(any_vc_has_data) rsv_pck_isr_next  = 1'b1;
        if(rd_done_trg  )     rd_done_isr_next  = 1'b1;
        if(wr_done_trg  )     wr_done_isr_next  = 1'b1;
        
        
        if(s_stb_i &   s_we_i & (s_addr_i == SLAVE_STATUS_ADDR [S_Aw-1    :0]) ) begin 
            rsv_pck_int_en_next     = s_dat_i[NI_RSV_PCK_INT_EN_LOC];
            rd_done_int_en_next     = s_dat_i[NI_RD_DONE_INT_EN_LOC];
            wr_done_int_en_next     = s_dat_i[NI_WR_DONE_INT_EN_LOC];
    
            if (s_dat_i[NI_RSV_PCK_ISR_LOC]) rsv_pck_isr_next = 1'b0;
            if (s_dat_i[NI_RD_DONE_ISR_LOC]) rd_done_isr_next = 1'b0;
            if (s_dat_i[NI_WR_DONE_ISR_LOC]) wr_done_isr_next = 1'b0;
        end
    end

// input buffer
    
 flit_buffer #(
    .V(V),
    .P(P),
    .B(B),
    .Fpay(Fpay),
    .DEBUG_EN(DEBUG_EN)
 )
 the_ififo
 (
    .din(flit_in),     // Data in
    .vc_num_wr(flit_in_vc_num),//write vertual channel    
    .wr_en(flit_in_wr),   // Write enable
    .vc_num_rd(cand_rd_vc),//read vertual channel     
    .rd_en(ififo_rd_en),   // Read the next word
    .dout(ififo_dout),    // Data out
    .vc_not_empty(ififo_vc_not_empty),
    .reset(reset),
    .clk(clk)
    
    
 );
 
 

    
    
arbiter #(
    .ARBITER_WIDTH (V)
)
rd_vc_arbiter
(   
    .clk        (clk), 
   .reset       (reset), 
   .request     (rd_vc_arbiter_in), 
   .grant       (rd_vc_arbiter_out), 
   .anyGrant    ()
);



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
        .current_x (current_x),
        .current_y (current_y),
        .dest_x    (dest_x_addr),
        .dest_y    (dest_y_addr),
        .destport  (destport_next)
    );





 
    
    wire [V-1         :0]     ovc_wr_in;
    assign ovc_wr_in    = (flit_out_wr ) ?  cand_wr_vc : {V{1'b0}};
    
    output_vc_status #(
        .V  (V),
        .B  (B),
        .CAND_VC_SEL_MODE       (0)  // 0: use arbieration between not full vcs, 1: select the vc with most availble free space
    )
    nic_ovc_status
    (
    .wr_in (ovc_wr_in),   
    .credit_in (credit_in),
    .full_vc (full_vc),
    .cand_vc  (cand_wr_vc),
    .empty_vc (),
    .cand_wr_vc_en (cand_wr_vc_en),
    .clk  (clk),
    .reset (reset)
    );
    
    

    //synthesis translate_off
always @(posedge clk) begin
    if(flit_in_wr && (flit_in_vc_num=={V{1'b0}})) $display ("%d,\t   Error: a packet has been recived by x[%d] , y[%d] with no assigned VC",$time,current_x,current_y);
end


//synthesis translate_on

endmodule


