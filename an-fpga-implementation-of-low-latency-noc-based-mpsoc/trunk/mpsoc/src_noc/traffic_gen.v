`timescale  1ns/1ps

//`define CHECK_PCKS_CONTENT       // if defined check flit ordering, 
//`define RSV_NOTIFICATION
//`define MONITORE_PATH
/**********************************************************************
**  File:  traffic_gen.v
**  Date:2015-03-05  
**    
**  Copyright (C) 2014-2018  Alireza Monemi
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
**  Inject/sink different syntetic traffic patterns to/from NoC 
**
***************************************/

module  traffic_gen #(
    parameter V = 4,    // VC num per port
    parameter B = 4,    // buffer space :flit per VC 
    parameter T1= 4,    // Topology related parameter #1
    parameter T2= 4,    // Topology related parameter #2
    parameter T3= 4,    // Topology related parameter #3
    parameter Fpay = 32,
    parameter VC_REALLOCATION_TYPE  = "NONATOMIC",// "ATOMIC" , "NONATOMIC"
    parameter TOPOLOGY  = "MESH",
    parameter ROUTE_NAME    = "XY",
    parameter C = 4,    //  number of flit class    
    parameter MAX_PCK_NUM   = 10000,
    parameter MAX_SIM_CLKs  = 100000,
    parameter MAX_PCK_SIZ   = 10,  // max packet size
    parameter TIMSTMP_FIFO_NUM=16,  
    parameter MAX_RATIO= 1000, //   
    //header flit filds' width 
    parameter SWA_ARBITER_TYPE = "RRA", // RRA WRRA
    parameter WEIGHTw = 4, // weight width of WRRA
    parameter MIN_PCK_SIZE=2
)
(
    //input 
    ratio,// real injection ratio  = (MAX_RATIO/100)*ratio
    avg_pck_size_in, 
    pck_size_in,   
    current_r_addr,
    current_e_addr,
    dest_e_addr,
    pck_class_in,        
    start, 
    stop,  
    report,
    init_weight,
      
   //output
    pck_number,
    sent_done, // tail flit has been sent
    hdr_flit_sent,
    update, // update the noc_analayzer
    src_e_addr,
   
    distance,
    pck_class_out,   
    time_stamp_h2h,
    time_stamp_h2t,
   
   //noc port
    flit_out,     
    flit_out_wr,   
    credit_in,
    flit_in,   
    flit_in_wr,   
    credit_out,     
   
    reset,
    clk
);
       
    
       
       
    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
   
    localparam
        RATIOw= log2(MAX_RATIO),
        Vw =  (V==1)? 1 : log2(V);
                 
   
   
    reg [2:0]   ps,ns;
    localparam IDEAL =3'b001, SENT =3'b010, WAIT=3'b100;
   
   
    localparam
        Cw = (C>1)? log2(C) : 1,
        Fw = 2+V+Fpay,
        PCK_CNTw = log2(MAX_PCK_NUM+1),
        CLK_CNTw = log2(MAX_SIM_CLKs+1),
        PCK_SIZw = log2(MAX_PCK_SIZ+1),
        /* verilator lint_off WIDTH */
        DISTw = (TOPOLOGY=="FATTREE" || TOPOLOGY=="TREE" ) ? log2(2*L+1): log2(NR+1), 
        /* verilator lint_on WIDTH */
        W = WEIGHTw;      

    input reset, clk;
    input  [RATIOw-1                :0] ratio;
    input                               start,stop;
    output                              update;
    output [CLK_CNTw-1              :0] time_stamp_h2h,time_stamp_h2t;
    output [DISTw-1                  :0] distance;
    output [Cw-1                    :0] pck_class_out;
   // the connected router address
    input  [RAw-1                   :0] current_r_addr;    
    // the current endpoint address
    input  [EAw-1                   :0] current_e_addr;    
    // the destination endpoint adress
    input  [EAw-1                   :0] dest_e_addr;  
    
    output [PCK_CNTw-1              :0] pck_number;
    input  [PCK_SIZw-1              :0] avg_pck_size_in;
    input  [PCK_SIZw-1              :0] pck_size_in;
    
    output reg sent_done;
    output hdr_flit_sent;
    input  [Cw-1                    :0] pck_class_in;
    input  [W-1                     :0] init_weight;
    // NOC interfaces
    output  [Fw-1                   :0] flit_out;     
    output  reg                         flit_out_wr;   
    input   [V-1                    :0] credit_in;
    
    input   [Fw-1                   :0] flit_in;   
    input                               flit_in_wr;   
    output reg  [V-1                :0] credit_out;     
    input                               report;
    // the recieved packet source endpoint address
    output [EAw-1        :   0]    src_e_addr;
 
    reg                                 inject_en,cand_wr_vc_en,pck_rd;
    reg    [PCK_SIZw-1              :0] pck_size, pck_size_next;    
    reg    [EAw-1                    :0] dest_e_addr_reg;
   
   
      // synopsys  translate_off
    // synthesis translate_off
                                      
     `ifdef MONITORE_PATH
     
   
    reg tt;
    always @(posedge clk) begin
        if(reset)begin 
             tt<=1'b0;               
        end else begin 
            if(flit_out_wr && tt==1'b0 )begin
                $display( "%t: Injector: current_r_addr=%x,current_e_addr=%x,dest_e_addr=%x\n",$time, current_r_addr, current_e_addr, dest_e_addr);
                tt<=1'b1;
            end
        end
    end
    `endif
    
    // synthesis translate_on
    // synopsys  translate_on  
   
   
   
   
   
   
    localparam
        HDR_DATA_w =  (MIN_PCK_SIZE==1)? CLK_CNTw : 0,
        HDR_Dw =  (MIN_PCK_SIZE==1)? CLK_CNTw : 1;
   
    wire [HDR_Dw-1 : 0] hdr_data_in,rd_hdr_data_out;
   
    
    always @ (posedge clk or posedge reset) begin 
        if(reset) begin 
            dest_e_addr_reg<={EAw{1'b0}};           
        end else begin 
            dest_e_addr_reg<=dest_e_addr;       
        end
    end
   
    wire    [DSTPw-1                :   0] destport;   
    wire    [V-1                    :   0] ovc_wr_in;
    wire    [V-1                    :   0] full_vc,empty_vc;
    reg     [V-1                    :   0] wr_vc,wr_vc_next;
    wire    [V-1                    :   0] cand_vc;
    
    
    wire    [CLK_CNTw-1             :   0] wr_timestamp,pck_timestamp;
    wire                                   hdr_flit,tail_flit;
    reg     [PCK_SIZw-1             :   0] flit_counter;
    reg                                    flit_cnt_rst,flit_cnt_inc;
    wire                                   rd_hdr_flg,rd_tail_flg;
    wire    [Cw-1   :   0] rd_class_hdr;
  //  wire    [P_1-1      :   0] rd_destport_hdr;
    wire    [EAw-1      :   0] rd_des_e_addr, rd_src_e_addr;  
    reg     [CLK_CNTw-1             :   0] rsv_counter;
    reg     [CLK_CNTw-1             :   0] clk_counter;
    wire    [Vw-1                   :   0] rd_vc_bin;//,wr_vc_bin;
    reg     [CLK_CNTw-1             :   0] rsv_time_stamp[V-1:0];
    wire    [V-1                    :   0] rd_vc; 
    wire                                   wr_vc_is_full,wr_vc_avb,wr_vc_is_empty;
    reg     [V-1                    :   0] credit_out_next;
    reg     [EAw-1     :   0] rsv_pck_src_e_addr        [V-1:0];
    reg     [Cw-1                   :   0] rsv_pck_class_in     [V-1:0];  
      
    wire [CLK_CNTw-1             :   0] hdr_flit_timestamp;    
    wire pck_wr,buffer_full,pck_ready,valid_dst;    
    wire [CLK_CNTw-1 : 0] rd_timestamp;
   
   
   check_destination_addr #(
   	.TOPOLOGY(TOPOLOGY),
   	.T1(T1),
   	.T2(T2),
   	.T3(T3),   
   	.EAw(EAw)
   )
   check_destination_addr(
   	.dest_e_addr(dest_e_addr),
   	.current_e_addr(current_e_addr),
   	.dest_is_valid(valid_dst)
   );
   
    
    assign hdr_flit_sent=pck_rd;
    
    
    injection_ratio_ctrl #
    (
        .MAX_PCK_SIZ(MAX_PCK_SIZ),
        .MAX_RATIO(MAX_RATIO)
    )
    pck_inject_ratio_ctrl
    (
        .en(inject_en),
        .pck_size(avg_pck_size_in),
        .clk(clk),
        .reset(reset),
        .freez(buffer_full),
        .inject(pck_wr),
        .ratio(ratio)
   );
    
    
    
    output_vc_status #(
        .V  (V),
        .B  (B),
        .CAND_VC_SEL_MODE       (0) // 0: use arbieration between not full vcs, 1: select the vc with most availble free space
    )
    nic_ovc_status
    (
    .wr_in                      (ovc_wr_in),   
    .credit_in                  (credit_in),
    .nearly_full_vc             (full_vc),
    .empty_vc                   (empty_vc),
    .cand_vc                    (cand_vc),
    .cand_wr_vc_en              (cand_wr_vc_en),
    .clk                        (clk),
    .reset                      (reset)
    );
    
       
    
    packet_gen #(
        .P(MAX_P),
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .RAw(RAw),  
        .EAw(EAw),  
        .TOPOLOGY(TOPOLOGY),
        .DSTPw(DSTPw),
        .ROUTE_NAME(ROUTE_NAME),
        .ROUTE_TYPE(ROUTE_TYPE),
        .MAX_PCK_NUM(MAX_PCK_NUM),
        .MAX_SIM_CLKs(MAX_SIM_CLKs),
        .TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)
    )
    packet_buffer
    (
        .reset(reset),
        .clk(clk),
        .pck_wr(pck_wr),
        .pck_rd(pck_rd),
        .current_r_addr(current_r_addr),
        .clk_counter(clk_counter),
        .pck_number(pck_number),
        .dest_e_addr(dest_e_addr_reg),
        .pck_timestamp(pck_timestamp),
        .buffer_full(buffer_full),
        .pck_ready(pck_ready),
        .valid_dst(valid_dst),
        .destport(destport)
    );

    
    assign wr_timestamp    =pck_timestamp; 
    
    assign  update      = flit_in_wr & flit_in[Fw-2];
    assign  hdr_flit    = (flit_counter == 0);
    assign  tail_flit   = (flit_counter ==  pck_size-1'b1);
    
   
    
    assign  time_stamp_h2h  = hdr_flit_timestamp - rd_timestamp;
    assign  time_stamp_h2t  = clk_counter - rd_timestamp;

    wire [Fpay-1    :   0] flit_out_pyload;
    wire [1         :   0] flit_out_hdr;
    

   wire [Fpay-1    :   0] flit_out_header_pyload;
   wire [Fw-1      :   0] hdr_flit_out;
   
   
   
   
   
   assign hdr_data_in = (MIN_PCK_SIZE==1)? wr_timestamp[HDR_Dw-1 : 0]  : {HDR_Dw{1'b0}};
    
    header_flit_generator #(
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .Fpay(Fpay),
        .V(V),
        .EAw(EAw),
        .DSTPw(DSTPw),
        .C(C),
        .WEIGHTw(WEIGHTw),
        .DATA_w(HDR_DATA_w)
    )
    the_header_flit_generator
    (
        .flit_out(hdr_flit_out),
        .vc_num_in(wr_vc),
        .class_in(pck_class_in),
        .dest_e_addr_in(dest_e_addr_reg),
        .src_e_addr_in(current_e_addr),
        .weight_in(init_weight),
        .destport_in(destport),
        .data_in(hdr_data_in)
    );
    
    
   
        assign flit_out_hdr = {hdr_flit,tail_flit};
    
        assign flit_out_header_pyload = hdr_flit_out[Fpay-1 : 0];
        
        
         /* verilator lint_off WIDTH */ 
        assign flit_out_pyload = (hdr_flit)  ?    flit_out_header_pyload :
                                
                                 (tail_flit) ?     wr_timestamp:
                                                  {pck_number,flit_counter};
         /* verilator lint_on WIDTH */
    
       
         
        assign flit_out = {flit_out_hdr, wr_vc, flit_out_pyload };   


//extract header flit info
    
   

     extract_header_flit_info #(
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .V(V),
        .EAw(EAw),
        .DSTPw(DSTPw),
        .C(C),
        .Fpay(Fpay),
        .DATA_w(HDR_DATA_w)
     )
     header_extractor
     (
        .flit_in(flit_in),
        .flit_in_we(flit_in_wr),
        .class_o(rd_class_hdr),
        .destport_o(),
        .dest_e_addr_o(rd_des_e_addr),
        .src_e_addr_o(rd_src_e_addr),
        .vc_num_o(rd_vc),
        .hdr_flit_wr_o( ),
        .hdr_flg_o(rd_hdr_flg),
        .tail_flg_o(rd_tail_flg),
        .weight_o( ),
        .data_o(rd_hdr_data_out)
     );   
   
    
    distance_gen #(
        .TOPOLOGY(TOPOLOGY),
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .EAw(EAw),
        .DISTw(DISTw)
    )
    the_distance_gen
    (
        .src_e_addr(src_e_addr),
        .dest_e_addr(current_e_addr),
        .distance(distance)
    );
    
    
 generate 
    if(MIN_PCK_SIZE == 1) begin : sf_pck
    
        assign src_e_addr            = (rd_hdr_flg & rd_tail_flg)? rd_src_e_addr : rsv_pck_src_e_addr[rd_vc_bin];
        assign pck_class_out     = (rd_hdr_flg & rd_tail_flg)? rd_class_hdr : rsv_pck_class_in[rd_vc_bin];
        assign hdr_flit_timestamp = (rd_hdr_flg & rd_tail_flg)?  clk_counter : rsv_time_stamp[rd_vc_bin];
        assign rd_timestamp =(rd_hdr_flg & rd_tail_flg)? rd_hdr_data_out : flit_in[CLK_CNTw-1             :   0];

    end else begin : no_sf_pck
    
        assign src_e_addr            = rsv_pck_src_e_addr[rd_vc_bin];
        assign pck_class_out    = rsv_pck_class_in[rd_vc_bin];
        assign hdr_flit_timestamp = rsv_time_stamp[rd_vc_bin];
        assign rd_timestamp=flit_in[CLK_CNTw-1 :   0];
        
    end


 if(V==1) begin : v1
    assign rd_vc_bin=1'b0;
   // assign wr_vc_bin=1'b0;
 end else begin :vother  

    one_hot_to_bin #( .ONE_HOT_WIDTH (V)) conv1 
    (
        .one_hot_code   (rd_vc),
        .bin_code       (rd_vc_bin)
    );
    /*
    one_hot_to_bin #( .ONE_HOT_WIDTH (V)) conv2 
    (
        .one_hot_code   (wr_vc),
        .bin_code       (wr_vc_bin)
    );
    */
 end 
 endgenerate
    
    
    assign  ovc_wr_in   = (flit_out_wr ) ?      wr_vc : {V{1'b0}};

    assign  wr_vc_is_full           =   | ( full_vc & wr_vc);
    
    
    
    generate
        /* verilator lint_off WIDTH */ 
        if(VC_REALLOCATION_TYPE ==  "NONATOMIC") begin : nanatom_b
        /* verilator lint_on WIDTH */  
            assign wr_vc_avb    =  ~wr_vc_is_full; 
        end else begin : atomic_b 
        assign wr_vc_is_empty   =  | ( empty_vc & wr_vc);
            assign wr_vc_avb        =  wr_vc_is_empty;      
        end
    endgenerate

reg not_yet_sent_aflit_next,not_yet_sent_aflit;

always @(*)begin
            wr_vc_next          = wr_vc; 
            cand_wr_vc_en       = 1'b0;
            flit_out_wr         = 1'b0;
            flit_cnt_inc        = 1'b0;
            flit_cnt_rst        = 1'b0;
            credit_out_next     = {V{1'd0}};
            sent_done           = 1'b0;
            pck_rd              = 1'b0;
            ns                  = ps;
            pck_rd              =1'b0;
         
            
            not_yet_sent_aflit_next =not_yet_sent_aflit;            
            case (ps) 
                IDEAL: begin                 
                    if(pck_ready ) begin 
                        if(wr_vc_avb && valid_dst)begin
                            pck_rd=1'b1; 
                            flit_out_wr     = 1'b1;//sending header flit
                            not_yet_sent_aflit_next = 1'b0;
                            flit_cnt_inc = 1'b1;                            
                            if (MIN_PCK_SIZE>1 || flit_out_hdr!=2'b11) begin 
                                ns              = SENT;
                            end else begin
                                flit_cnt_rst   = 1'b1;
                                sent_done       =1'b1;
                                cand_wr_vc_en   =1'b1;
                                if(cand_vc>0) begin 
                                    wr_vc_next  = cand_vc;                                  
                                end  else ns = WAIT;                
                            end  //else                         
                        end//wr_vc                        
                end 
                
                end //IDEAL
                SENT: begin  
                  
                    if(!wr_vc_is_full )begin 
                        
                        flit_out_wr     = 1'b1;
                        if(flit_counter  < pck_size-1) begin 
                            flit_cnt_inc = 1'b1;
                        end else begin 
                            flit_cnt_rst   = 1'b1;
                            sent_done       =1'b1;
                            cand_wr_vc_en   =1'b1;
                            if(cand_vc>0) begin 
                                wr_vc_next  = cand_vc;
                                ns          =IDEAL;
                            end     else ns = WAIT; 
                        end//else
                    end // if wr_vc_is_full
                end//SENT
                WAIT:begin
                   
                    cand_wr_vc_en   =1'b1;
                    if(cand_vc>0) begin 
                                wr_vc_next  = cand_vc;
                                ns                  =IDEAL;
                    end  
                end
                default: begin 
                    ns                  =IDEAL;
                end
                endcase
            
        
            // packet sink
            if(flit_in_wr) begin 
                    credit_out_next = rd_vc;
            end else credit_out_next = {V{1'd0}};
        end
 
    always @ (*)begin 
           pck_size_next    = pck_size;
           if((tail_flit & flit_out_wr ) || not_yet_sent_aflit) pck_size_next  = pck_size_in;
    end
    
always @(posedge clk or posedge reset )begin 
        if(reset) begin 
            inject_en       <= 1'b0;
            ps              <= IDEAL;
            wr_vc           <=1; 
            flit_counter    <= {PCK_SIZw{1'b0}};
            credit_out      <= {V{1'd0}};
            rsv_counter     <= 0;
            clk_counter     <=  0;
            pck_size        <= 0;
            not_yet_sent_aflit<=1'b1;          
        
        end else begin 
            //injection
            not_yet_sent_aflit<=not_yet_sent_aflit_next;
            inject_en <=  (start |inject_en) & ~stop;  
            ps             <= ns;
            clk_counter     <= clk_counter+1'b1;
            wr_vc           <=wr_vc_next; 
            if (flit_cnt_rst)      flit_counter    <= {PCK_SIZw{1'b0}};
            else if(flit_cnt_inc)   flit_counter    <= flit_counter + 1'b1;     
            credit_out      <= credit_out_next;
            pck_size  <= pck_size_next;
           
            //sink
            if(flit_in_wr) begin 
                    if (flit_in[Fw-1])begin 
                        rsv_pck_src_e_addr[rd_vc_bin]    <=  rd_src_e_addr;
                        rsv_pck_class_in[rd_vc_bin]    <= rd_class_hdr;
                        rsv_time_stamp[rd_vc_bin]   <= clk_counter;  
                        rsv_counter                 <= rsv_counter+1'b1;
                                            
                        // distance        <= {{(32-8){1'b0}},flit_in[7:0]};
                        `ifdef RSV_NOTIFICATION
                            // synopsys  translate_off
                            // synthesis translate_off
                            // last_pck_time<=$time;
                             $display ("total of %d pcks have been recived in core (%d)", rsv_counter,current_e_addr);
                            // synthesis translate_on
                            // synopsys  translate_on
                        `endif
                    end
            end
        // synopsys  translate_off
        // synthesis translate_off
            if(report) begin 
                 $display ("%t,\t total of %d pcks have been recived in core (%d)",$time ,rsv_counter,current_e_addr);
            end
        // synthesis translate_on
        // synopsys  translate_on
        
         
        
         
        
        end
    end//always
    // synopsys  translate_off
    // synthesis translate_off
    always @(posedge clk) begin     
        if(flit_out_wr && hdr_flit && dest_e_addr_reg  == current_e_addr) $display("%t: Error: The source and destination address of injected packet is the same in endpoint (%h): %m",$time, dest_e_addr );                                                             
        if(flit_in_wr && rd_hdr_flg && (rd_des_e_addr    != current_e_addr )) $display("%t: Error: packet with des(%h) which is sent by source (%h) has been recieved in wrong router (%h).  %m",$time,rd_des_e_addr, rd_src_e_addr, current_e_addr);        
    end
    // synthesis translate_on
    // synopsys  translate_on
    
    
    `ifdef CHECK_PCKS_CONTENT
    // synopsys  translate_off
    // synthesis translate_off
    
    wire     [PCK_SIZw-1             :   0] rsv_flit_counter; 
    reg      [PCK_SIZw-1             :   0] old_flit_counter    [V-1   :   0];
    wire     [PCK_CNTw-1             :   0] rsv_pck_number;
    reg      [PCK_CNTw-1             :   0] old_pck_number  [V-1   :   0];
    
    wire [PCK_CNTw+PCK_SIZw-1 : 0] statistics;
    generate 
        if(PCK_CNTw+PCK_SIZw > Fw) assign statistics = {{(PCK_CNTw+PCK_SIZw-Fw){1'b0}},flit_in};
        else  assign statistics = flit_in[PCK_CNTw+PCK_SIZw-1   :   0];
        assign {rsv_pck_number,rsv_flit_counter}=statistics;
               
    endgenerate   
    
    
    
    integer ii;
    always @(posedge clk or posedge reset )begin 
        if(reset) begin
            for(ii=0;ii<V;ii=ii+1'b1)begin
                old_flit_counter[ii]<=0;            
            end        
        end else begin
            if(flit_in_wr)begin
                if      ( flit_in[Fw-1:Fw-2]==2'b10)  begin
                    old_pck_number[rd_vc_bin]<=0;
                    old_flit_counter[rd_vc_bin]<=0;
                end else if ( flit_in[Fw-1:Fw-2]==2'b00)begin 
                    old_pck_number[rd_vc_bin]<=rsv_pck_number;
                    old_flit_counter[rd_vc_bin]<=rsv_flit_counter;
                end                    
                
            end       
        
        end    
    end
    
    
    always @(posedge clk) begin     
        if(flit_in_wr && (flit_in[Fw-1:Fw-2]==2'b00) && (~reset))begin 
            if( old_flit_counter[rd_vc_bin]!=rsv_flit_counter-1) $display("%t: Error: missmatch flit counter in %m. Expected %d but recieved %d",$time,old_flit_counter[rd_vc_bin]+1,rsv_flit_counter);
            if( old_pck_number[rd_vc_bin]!=rsv_pck_number && old_pck_number[rd_vc_bin]!=0)   $display("%t: Error: missmatch pck number in %m. expected %d but recieved %d",$time,old_pck_number[rd_vc_bin],rsv_pck_number);
                       
        end
   
    end
    // synthesis translate_on
    // synopsys  translate_on
    
    `endif
    
    
    
   
  
    


endmodule





/*****************************

    injection_ratio_ctrl
        
*****************************/

module injection_ratio_ctrl #
(
 parameter MAX_PCK_SIZ=10,
 parameter MAX_RATIO=100
)
(
 en,
 pck_size, // average packet size in flit
 clk,
 reset,
 inject,// inject one packet
 freez,
 ratio // 0~100  flit injection ratio


);


    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 
   
   
   localparam PCK_SIZw= log2(MAX_PCK_SIZ);
   localparam CNTw    =   log2(MAX_RATIO);
   localparam STATE_INIT=   MAX_PCK_SIZ*MAX_RATIO;
   localparam STATEw    =   log2(MAX_PCK_SIZ*2*MAX_RATIO);

    input                       clk,reset,freez,en;
    output  reg                 inject;
    input   [CNTw-1     :   0]  ratio;
    input   [PCK_SIZw-1 :   0]  pck_size;


    wire    [CNTw-1     :   0]  on_clks, off_clks;
    reg     [STATEw-1   :   0]  state,next_state;
    wire                        input_changed;
    reg     [CNTw-1     :   0]  ratio_old;    
    
    always @(posedge clk ) ratio_old<=ratio;
    
    assign input_changed = (ratio_old!=ratio);
    
    
    assign on_clks = ratio; 
    assign off_clks =MAX_RATIO-ratio; 
    
    reg [PCK_SIZw-1 :0] flit_counter,next_flit_counter;
    
    
    reg sent,next_sent,next_inject;
 
 
 
    always @(*) begin 
      next_state        =state;
      next_flit_counter =flit_counter;
      next_sent         =sent;
      if(en && ~freez ) begin
            case(sent)
                1'b1: begin 
                    /* verilator lint_off WIDTH */
                    next_state          = state +  off_clks; 
                    /* verilator lint_on WIDTH */
                    next_flit_counter = (flit_counter >= pck_size-1'b1) ? {PCK_SIZw{1'b0}} : flit_counter +1'b1;
                    next_inject         = (flit_counter=={PCK_SIZw{1'b0}});
                    if (next_flit_counter >= pck_size-1'b1) begin 
                         if( next_state  >= STATE_INIT ) next_sent =1'b0;
                    end
                end
                1'b0:begin 
                    if( next_state  <  STATE_INIT ) next_sent  = 1'b1;
                    next_inject= 1'b0;
                    /* verilator lint_off WIDTH */
                    next_state = state - on_clks;
                    /* verilator lint_on WIDTH */
                end
            endcase     
        end else begin 
             next_inject= 1'b0;
        end
    end     
        
         
 
 
    always @(posedge clk or posedge reset) begin 
        if( reset) begin            
            state       <=  STATE_INIT;
            inject      <=  1'b0; 
            sent        <=  1'b1; 
            flit_counter<= 0;
        end else begin 
            if(input_changed)begin
                state       <=  STATE_INIT;
                inject      <=  1'b0; 
                sent        <=  1'b1; 
                flit_counter<= 0;
            end
        
        
            state       <=  next_state;
           if(ratio!={CNTw{1'b0}}) inject      <=  next_inject; 
            sent        <=  next_sent; 
            flit_counter<=  next_flit_counter;
              
          end
    end     


endmodule



 
 /*************************************
 
        packet_buffer
 
 **************************************/
 
 
 module packet_gen #(   
    parameter P = 5,    
    parameter T1= 4,    
    parameter T2= 4,
    parameter T3= 4,
    parameter RAw = 3,  
    parameter EAw = 3, 
    parameter TOPOLOGY  = "MESH",
    parameter DSTPw = 4,
    parameter ROUTE_NAME = "XY",
    parameter ROUTE_TYPE = "DETERMINISTIC",
    parameter MAX_PCK_NUM   = 10000,
    parameter MAX_SIM_CLKs  = 100000,
    parameter TIMSTMP_FIFO_NUM=16,
    parameter MIN_PCK_SIZE=2
 
 )(
    clk_counter,
    pck_wr,
    pck_rd,
    current_r_addr,
    pck_number,
    dest_e_addr,
    pck_timestamp,
    destport,
    buffer_full,
    pck_ready,
    valid_dst,
    clk,
    reset 
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
        PCK_CNTw    =   log2(MAX_PCK_NUM+1),
        CLK_CNTw    =   log2(MAX_SIM_CLKs+1);     
 
    input  reset,clk, pck_wr, pck_rd;
    input  [RAw-1  :0] current_r_addr;
    input  [CLK_CNTw-1 :0] clk_counter;
     
    output [PCK_CNTw-1 :0] pck_number;
    input  [EAw-1  :0] dest_e_addr;
    output [CLK_CNTw-1 :0] pck_timestamp;   
    output buffer_full,pck_ready;
    input  valid_dst; 
    output [DSTPw-1    :0] destport; 
    reg    [PCK_CNTw-1 :0] packet_counter;  
    wire   buffer_empty; 
 
    assign pck_ready = ~buffer_empty & valid_dst;
    
  
    ni_conventional_routing #(
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .ROUTE_TYPE(ROUTE_TYPE),
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .RAw(RAw),
        .EAw(EAw),
        .DSTPw(DSTPw)
    )
    the_ni_conventional_routing
    (
        .reset(reset),
        .clk(clk),
        .current_r_addr(current_r_addr),
        .dest_e_addr(dest_e_addr),
        .destport(destport)
    );

    wire timestamp_fifo_nearly_full , timestamp_fifo_full;
    assign buffer_full = (MIN_PCK_SIZE==1) ? timestamp_fifo_nearly_full : timestamp_fifo_full;


    wire recieve_more_than_0;
    fwft_fifo #(
        .DATA_WIDTH(CLK_CNTw),
        .MAX_DEPTH(TIMSTMP_FIFO_NUM)        
    )
    timestamp_fifo
    (
        .din(clk_counter),
        .wr_en(pck_wr),
        .rd_en(pck_rd),
        .dout(pck_timestamp),
        .full(timestamp_fifo_full),
        .nearly_full(timestamp_fifo_nearly_full),       
        .recieve_more_than_0(recieve_more_than_0),
        .recieve_more_than_1(),
        .reset(reset),
        .clk(clk)
    );
    
    assign buffer_empty = ~recieve_more_than_0;
    
    /*

    fifo #(
        .Dw(CLK_CNTw),
        .B(TIMSTMP_FIFO_NUM)
    )
    timestamp_fifo
    (
        .din(clk_counter),
        .wr_en(pck_wr),
        .rd_en(pck_rd),
        .dout(pck_timestamp),
        .full(timestamp_fifo_full),
        .nearly_full(timestamp_fifo_nearly_full),
        .empty(buffer_empty),
        .reset(reset),
        .clk(clk)
    );
    */ 
    
    always @ (posedge clk or posedge reset) begin 
        if(reset) begin 
            packet_counter <= {PCK_CNTw{1'b0}};
            
        end else begin 
              if(pck_rd) begin 
                packet_counter <= packet_counter+1'b1;
                
            end
        end
    end
 
    assign pck_number = packet_counter;
   
   
endmodule    
 
 
 
/********************

    distance_gen 
     
********************/

module distance_gen #(
    parameter TOPOLOGY  = "MESH",
    parameter T1=4,
    parameter T2=4,
    parameter T3=4,
    parameter EAw=2,
    parameter DISTw=4

)(
    src_e_addr,
    dest_e_addr,
    distance
);

 input [EAw-1 : 0] src_e_addr;
 input [EAw-1 : 0] dest_e_addr;
 output [DISTw-1 : 0]   distance;

generate 
/* verilator lint_off WIDTH */ 
if (TOPOLOGY ==    "MESH" || TOPOLOGY ==  "TORUS" || TOPOLOGY == "RING" || TOPOLOGY == "LINE")begin : tori_noc 
/* verilator lint_on WIDTH */ 

    mesh_torus_distance_gen #(
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .TOPOLOGY(TOPOLOGY),
        .DISTw(DISTw),
        .EAw(EAw)
    )
    distance_gen
    (
        .src_e_addr(src_e_addr),
        .dest_e_addr(dest_e_addr),
        .distance(distance)
    );
/* verilator lint_off WIDTH */ 
   end else if (TOPOLOGY == "FATTREE" || TOPOLOGY == "TREE") begin : fat 
/* verilator lint_on WIDTH */    
    fattree_distance_gen #(
        .K(T1),
        .L(T2)
    )
    distance_gen
    (
        .src_addr_encoded(src_e_addr),
        .dest_addr_encoded(dest_e_addr),
        .distance(distance)
    );
    end
    endgenerate

  endmodule
