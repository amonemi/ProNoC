/**********************************************************************
    File: sub_ni_wr.v 
    
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
    wishbone slave adderess :
    
        [2:0]  
            // ni status register
            0 : STATUS_ADDR 
            // update memory pinter, packet size and send packet read command. If memory pointer and packet size width are smaller than COMB_MEM_PTR_W and COMB_PCK_SIZE_W respectively.
            1 : MEM_PCKSIZ_ADDR       
            //update packet size  
            2: PCK_SIZE_ADDR        
            //update the memory pointer address and send read command. The packet size must be updated before setting this register. use it when memory pointer width is larger than COMB_MEM_PTR_W
            3: MEM_ADDR  
           
        
        
        [3] 
            // rd/wr flag. If ni is in ideal state then 
            0:    RD_CMD  update rd packet register
            1:    WR_CMD  updare wr packet register
        [4+Vw:4]
            // candidate read/write V binarry number. Only write in IDEAL state  
            V_NUM  : rd/wr VC num 
    
    
    
    
        status_reg  
            bit_loc         flag_name
            [14+V : 14+2V-1]rd_vc_not_empty       
            [14 : 14+V-1]   wr_vc_not_empty       
            13              rsv_pck_isr
            12              rd_done_isr
            11              wr_done_isr
            10              rsv_pck_int_en
            9               rd_done_int_en
            8               wr_done_int_en
            7               all_wr_vcs_full
            6               any_rd_vc_has_data
            5               rd_no_pck_err
            4               rd_ovr_size_err
            3               rd_done
            2               wr_done
            1               rd_busy
            0               wr_busy
            
        
        
        RD/WR registers ={pck_size_next,memory_ptr_next}
    
    Info: monemi@fkegraduate.utm.my
    *************************************************************************/


`timescale 1ns/1ps



module sub_ni_wr #(

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
    parameter S_Aw          =   7,
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
    


   
    //wishbone master interface signals
    m_sel_o,
    m_addr_o,
    m_cti_o,
    m_stb_o,
    m_cyc_o,
    m_we_o,
    m_dat_i,
    m_ack_i,    
   
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
                Yw =   log2(NY),
					 Vw =   (V>1) ? log2(V) : 1;  
                   
  
    //wishbone slave addresses
    localparam  
    // ni status register
    STATUS_ADDR       =   3'd0,
    // update memory pinter, packet size and send packet read command. If memory pointer and packet size width are smaller than COMB_MEM_PTR_W and COMB_PCK_SIZE_W respectively.
    MEM_PCKSIZ_ADDR   =   3'd1,  
    //update packet size  
    PCK_SIZE_ADDR     =   3'd2,
    //update the memory pointer address and send read command. The packet size must be updated before setting this register. use it when memory pointer width is larger than COMB_MEM_PTR_W
    MEM_ADDR          =   3'd3,
    //If ni is in ideal state then  update RD/WR packet registers
    RD_CMD            =   1'b0,   
    WR_CMD            =   1'b1;
     
   
    
    
   
    //status register bit                    
 localparam     NI_RD_BUSY_LOC=         0,
                NI_WR_BUSY_LOC=         1,  
                NI_WR_DONE_LOC=         2,
                NI_RD_DONE_LOC=         3,
                NI_RD_OVR_ERR_LOC=      4,
                NI_RD_NPCK_ERR_LOC=     5,
                NI_HAS_PCK_LOC=         6,
                NI_ALL_VCS_FULL_LOC=    7,
                NI_WR_DONE_INT_EN_LOC=  8,
                NI_RD_DONE_INT_EN_LOC=  9,
                NI_RSV_PCK_INT_EN_LOC=  10,
                NI_WR_DONE_ISR_LOC=     11,
                NI_RD_DONE_ISR_LOC=     12,
                NI_RSV_PCK_ISR_LOC=     13;  
                
                
localparam  CLASS_IN_HDR_WIDTH      =8,
            DEST_IN_HDR_WIDTH       =8,
            X_Y_IN_HDR_WIDTH        =4,
            HDR_ROUTING_INFO_WIDTH  =   CLASS_IN_HDR_WIDTH+DEST_IN_HDR_WIDTH+ 4* X_Y_IN_HDR_WIDTH;
            
localparam  NUMBER_OF_STATUS    =   5,
            IDEAL               =   1,
            READ_MEM_PCK_HDR    =   2,
            ASSIGN_PORT_VC      =   4,
            SEND_HDR            =   8,
            WR_ON_FIFO          =   16;
            
                
            
   
    localparam  COUNTER_W       =   M_Aw-2;
    localparam  MEM_PTR_W           =   M_Aw-2;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    localparam  HDR_FLIT            =   2'b10;
    localparam  BDY_FLIT            =   2'b00;
    localparam  TAIL_FLIT           =   2'b01;
    
    
  
    
    
    input reset;
    input clk;
    
    
    // NOC interfaces
    input   [Xw-1   :   0]  current_x;
    input   [Yw-1   :   0]  current_y;
    output  [Fw-1   :   0]  flit_out;     
    output  reg             flit_out_wr;   
    input   [V-1    :   0]  credit_in;
    
    
    

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
  
    
    
    //wishbone master interface signals
    output  [SELw-1          :   0] m_sel_o;
    output  [M_Aw-1          :   0] m_addr_o;
    output  [TAGw-1          :   0] m_cti_o;
    output                          m_stb_o;
    output                          m_cyc_o;
    output                          m_we_o;
    input   [Dw-1           :  0]   m_dat_i;
    input                           m_ack_i;    
    
    //intruupt interface
    output                          irq;
    
  
   

    
    
    wire    [P_1-1              :   0]  destport_next;
    reg     [P_1-1              :   0]  destport;
    wire    [Xw-1               :   0]  dest_x_addr;
    wire    [Yw-1               :   0]  dest_y_addr;
    wire    [Fpay-1             :   0]  flit_out_hdr_pyd;
    
    
    wire                                m_waitrequest, m_read;
    wire                                s_ack_o_next;
    
    reg                                 m_ack_i_delayed;  
   
   
    reg                                     wr_done_isr,wr_done_int_en;
    reg                                     wr_done_isr_next,wr_done_int_en_next;
    
        
    reg     [NUMBER_OF_STATUS-1     :   0]  ps,ns;
    reg     [COUNTER_W-1        :   0]  counter,counter_next;
    reg                                     counter_reset,   counter_increase;
    
    // memory mapped registers
    wire    [Fpay-1                 :   0]  status_reg;
    wire    [Fpay-1                 :   0]  m_pyld;
    
    reg     [MEM_PTR_W-1            :   0]  memory_ptr,memory_ptr_next;
    reg     [COUNTER_W-1            :   0]  pck_size,pck_size_next;
    wire                                    pck_eq_counter;

    reg                                     wr_done_next, wr_done;
    reg                                     wr_mem_en, rd_mem_en;
    
    
    
    wire                                    cand_wr_vc_full;
   
   
    
    
        
    
   
    
        
    wire                                     all_vcs_full;
    reg     [1                      :   0]   wr_flit_type;
     
    
   
    
    reg                                     destport_ld;
   
    
    reg                                     hdr_write;
    reg                                     read_burst;
    
    
    wire    [V-1  :0] full_vc;
    wire              wr_busy;
    wire    [V-1  :0] wr_vc_not_empty;
    //wishbone slave register address 
    wire [2:0] wb_general_reg_addr;
    wire       wb_wr_rd_addr;
    wire [Vw-1   :   0] wb_v_addr_binary;
   
    
    reg  [Vw-1  :0] cand_wr_vc_binary,cand_rd_vc_binary;
    wire [V-1  :0] cand_wr_vc_onehot,cand_rd_vc_onehot;
    
    assign {wb_v_addr_binary, wb_wr_rd_addr, wb_general_reg_addr} = s_addr_i[3+Vw      :0];
   
    
    
    assign  m_sel_o         =   4'b1111;
    assign  m_waitrequest   =   ~m_ack_i_delayed ; //in busrt mode  the ack is regisered inside the ni insted of ram to avoid combinational loop
    assign  m_cyc_o         =   m_we_o | m_read;
    assign  s_ack_o_next    =   s_stb_i & (~s_ack_o);
   // assign  m_cti_o         =   (m_stb_o)   ?   ((last_rw)? 3'b111 :    3'b100) : 3'b000;
    assign  m_cti_o         =   (m_stb_o)   ?      3'b100 : 3'b000;
    
    assign  irq             =  (wr_done_isr & wr_done_int_en);
        
    assign  all_vcs_full    =   & full_vc;
    assign  cand_wr_vc_full =   full_vc[cand_wr_vc_binary];
         
    
   
   
    
    
    assign  m_stb_o         =   wr_mem_en | rd_mem_en;
    assign  m_we_o          =   wr_mem_en;
    assign  m_read          =   rd_mem_en;
    
   
    
    assign  flit_out        =   {wr_flit_type,cand_wr_vc_onehot,m_pyld};
    
    
    


   



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
    
  
   
      
    //status register
    assign  wr_busy            =   ps!=IDEAL;
    assign  status_reg          =   {/*rd_vc_not_empty*/{Vw{1'b0}}, wr_vc_not_empty,/*rsv_pck_isr*/1'b0, /*rd_done_isr*/1'b0, wr_done_isr,/*rsv_pck_int_en*/1'b0,/*rd_done_int_en*/1'b0,wr_done_int_en,all_vcs_full,/*any_vc_has_data*/1'b0,/*rd_no_pck_err*/1'b0,/*rd_ovr_size_err*/1'b0,/*rd_done*/1'b0,wr_done,/*rd_busy*/1'b0,wr_busy};
    assign  s_dat_o             =   status_reg;
   
    reg  [M_Aw-1          :   0] m_addr;
	 
	 always @ ( posedge clk or posedge reset)begin 
		if(reset)begin 
			m_addr<= {M_Aw{1'b0}};
		end else begin  
			m_addr<= memory_ptr_next+counter_next;
		end
	 end
	 
	 
	
 
    assign  m_addr_o    = (~m_waitrequest & read_burst)?   m_addr+1'b1: m_addr;
        
    assign  pck_eq_counter = ( counter == pck_size);
        
                                                                       
    
       
    
    
    always@(posedge clk or posedge reset)begin
        if(reset)begin
            destport            <=  {P_1{1'b0}};
            ps                  <=  IDEAL;
            memory_ptr          <=  {MEM_PTR_W{1'b0}};
            pck_size            <=  {COUNTER_W{1'b0}};
            counter             <=  {COUNTER_W{1'b0}};
           
            wr_done             <=  1'b0;
            m_ack_i_delayed     <=  1'b0;
            s_ack_o             <=  1'b0;
            wr_done_int_en      <=  1'b0;
            wr_done_isr         <=  1'b0;
            
        end else begin //if reset
            if(destport_ld)destport <= destport_next; 
            ps                  <=  ns;
            memory_ptr          <=  memory_ptr_next;
            pck_size            <=  pck_size_next;
            counter             <=  counter_next;
            
            wr_done             <=  wr_done_next;
            m_ack_i_delayed     <=  m_ack_i;
            s_ack_o             <=  s_ack_o_next;           
            wr_done_int_en      <=  wr_done_int_en_next;           
            wr_done_isr         <=  wr_done_isr_next;
        end//els reset
    end//always
    
    
    // flit counter & candidate read VC
    always@(*)begin
        counter_next        = counter;  
      
        if      (counter_reset)             counter_next    =   {COUNTER_W{1'b0}};
        else if (counter_increase)          counter_next    =   counter +1'b1;
      
     end//always
    
    reg wr_done_trg;
    
    
    
    //update the read\write memory pointer and packet size in flits
     always@(*) begin
        memory_ptr_next     = memory_ptr;
        pck_size_next       = pck_size;
        case(ps)
        IDEAL:   begin
            if(s_stb_i &    s_we_i )   begin 
                case (wb_general_reg_addr)
                MEM_PCKSIZ_ADDR : begin 
                    memory_ptr_next = {{(MEM_PTR_W+2-COMB_MEM_PTR_W){1'b0}},s_dat_i[COMB_MEM_PTR_W-1:2]};  
                    pck_size_next   = {{(COMB_MEM_PTR_W-2){1'b0}},s_dat_i[M_Aw-1:COMB_MEM_PTR_W]};                  
                end
                PCK_SIZE_ADDR :begin
                    pck_size_next   = s_dat_i[COUNTER_W-1  :0];   
                end
                MEM_ADDR :begin
                    memory_ptr_next = s_dat_i[MEM_PTR_W+1:2];          
                end
                default:begin 
                    memory_ptr_next     = memory_ptr;
                    pck_size_next       = pck_size;
                end 
                endcase
            end//if  
        end
        
        default : begin
            memory_ptr_next     = memory_ptr;
            pck_size_next       = pck_size;
        end
        endcase
     end
   //update the cand read\write VC
     always@(posedge clk or posedge reset) begin
        if(reset)begin 
              cand_wr_vc_binary<= {Vw{1'b0}};
        end else begin 
             if( s_stb_i &  s_we_i & (wb_general_reg_addr != STATUS_ADDR) & (ps == IDEAL ) ) begin            
                if(wb_wr_rd_addr == WR_CMD)  cand_wr_vc_binary <= wb_v_addr_binary;       
            end
        end
     end
     
     
     
     bin_to_one_hot #(
        .BIN_WIDTH(Vw)   
    )
    conv_wr_vc
    (
        .bin_code(cand_wr_vc_binary),
        .one_hot_code(cand_wr_vc_onehot)
    ); 
     
  
  
  
    
    always@(*) begin
        ns                      = ps;
        counter_reset           = 1'b0;
        counter_increase        = 1'b0;
        wr_mem_en               = 1'b0;
        rd_mem_en               = 1'b0;
        flit_out_wr             = 1'b0;
        destport_ld             = 1'b0;
        wr_done_next            = wr_done;
        wr_flit_type            = BDY_FLIT; 
        hdr_write               = 1'b0;
        read_burst              = 1'b0;
        wr_done_trg             = 1'b0;
        
        case(ps)
        IDEAL:   begin 
            counter_reset =1;
            
            
            if(s_stb_i &    s_we_i )   begin 
		if ((wb_general_reg_addr ==  MEM_PCKSIZ_ADDR) || (wb_general_reg_addr == MEM_ADDR))  begin   
			if(wb_wr_rd_addr ==  WR_CMD) begin
                            ns              =   READ_MEM_PCK_HDR;
                            wr_done_next    =   1'b0;
                        end //WR_CMD                                  
		end//if
	     end//if	 

        end//IDEAL
        
        READ_MEM_PCK_HDR:   begin
            if(!cand_wr_vc_full)   begin
                ns  =   ASSIGN_PORT_VC;
                rd_mem_en  =   1'b1;                        
            end                
        end //READ_MEM_PCK_HDR:
        
        ASSIGN_PORT_VC  : begin
            if(~m_waitrequest) begin 
                ns                  =   SEND_HDR;
                rd_mem_en           =   1'b1;
                counter_increase    =   1'b1;
                destport_ld         =   1'b1;
            end else rd_mem_en          =  1'b1;
        end//ASSIGN_PORT_VC
        
        SEND_HDR: begin 
            ns                  =   WR_ON_FIFO;
            wr_flit_type        =   HDR_FLIT;
            hdr_write           =   1'b1;
            flit_out_wr         =   1'b1;
        end // SEND_HDR 
          
        WR_ON_FIFO: begin 
            read_burst          =   1'b1;
            if(!m_waitrequest) begin 
                if(pck_eq_counter) begin
                    flit_out_wr     =   1'b1;
                    ns                  =   IDEAL;
                    wr_done_next    =   1'b1;
                    wr_done_trg     =  1'b1;
                    wr_flit_type    = TAIL_FLIT;    
                 
                end else if(!cand_wr_vc_full) begin 
                    flit_out_wr         =1'b1;
                    counter_increase    = 1'b1;
                    rd_mem_en           = 1'b1;
                end//pck_eq_counter 
            end else if(!cand_wr_vc_full)   rd_mem_en           = 1'b1; 
                //end
        end//WR_ON_FIFO
             
            
        default : ns=IDEAL;
        
        endcase
    end
    
    
    //isr_register handeling
    always @(*) begin
              
            wr_done_int_en_next     = wr_done_int_en;
            wr_done_isr_next            = wr_done_isr;
              
        
        if(wr_done_trg  )     wr_done_isr_next  = 1'b1;
        
        
        if(s_stb_i &   s_we_i & (wb_general_reg_addr == STATUS_ADDR) ) begin 
            wr_done_int_en_next     = s_dat_i[NI_WR_DONE_INT_EN_LOC];
               
            if (s_dat_i[NI_WR_DONE_ISR_LOC]) wr_done_isr_next = 1'b0;
        end
    end


   



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





 
    
    wire [V-1         :0]     ovc_wr_in,wr_vc_empty;
    assign ovc_wr_in    = (flit_out_wr ) ?  cand_wr_vc_onehot : {V{1'b0}};
    
    output_vc_status #(
        .V  (V),
        .B  (B),
        .CAND_VC_SEL_MODE       (0)  // 0: use arbieration between not full vcs, 1: select the vc with most availble free space
    )
    nic_ovc_status
    (
    .wr_in (ovc_wr_in),   
    .credit_in (credit_in),
    .nearly_full_vc (full_vc),
    .cand_vc  (),
    .empty_vc (wr_vc_empty),
    .cand_wr_vc_en (1'b0),
    .clk  (clk),
    .reset (reset)
    );
    
    assign wr_vc_not_empty = ~ wr_vc_empty;              
    


endmodule






