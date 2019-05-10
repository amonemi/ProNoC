/**************************************
* Module: traffic_gen_verilator
* Date:2015-01-16  
* Author: alireza     
*
* Description: 
***************************************/
module  traffic_gen_verilator (

    ratio,
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

    pck_number,
    sent_done, // tail flit has been sent
    hdr_flit_sent,
    update, // update the noc_analayzer
    src_e_addr,
   
    distance,
    pck_class_out,   
    time_stamp_h2h,
    time_stamp_h2t,

    flit_out,     
    flit_out_wr,   
    credit_in,
    flit_in,   
    flit_in_wr,   
    credit_out,     
   
    reset,
    clk
);


     
    `define   INCLUDE_PARAM    
    `include "parameter.v"
    
    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
    
    
    localparam
       
        Cw          =  (C > 1)? log2(C): 1,
        Fw          =   2+V+Fpay,
        RATIOw      =   log2(MAX_RATIO),
        PCK_CNTw    =   log2(MAX_PCK_NUM+1),
        CLK_CNTw    =   log2(MAX_SIM_CLKs+1),
        PCK_SIZw    =   log2(MAX_PCK_SIZ+1),
       
        /* verilator lint_off WIDTH */
        DISTw = (TOPOLOGY=="FATTREE" || TOPOLOGY == "TREE") ? log2(2*L+1): log2(NR+1), 
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
    
    output sent_done;
    output hdr_flit_sent;
    input  [Cw-1                    :0] pck_class_in;
    input  [W-1                     :0] init_weight;
    // NOC interfaces
    output  [Fw-1                   :0] flit_out;     
    output                           flit_out_wr;   
    input   [V-1                    :0] credit_in;
    
    input   [Fw-1                   :0] flit_in;   
    input                               flit_in_wr;   
    output  [V-1                :0] credit_out;     
    input                               report;
    // the recieved packet source endpoint address
    output [EAw-1        :   0]    src_e_addr;
    

   traffic_gen #(
   	.V(V),
   	.B(B),
   	.T1(T1),
   	.T2(T2),
    .T3(T3),   
   	.Fpay(Fpay),
   	.VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
   	.TOPOLOGY(TOPOLOGY),
   	.ROUTE_NAME(ROUTE_NAME),
   	.C(C),
   	.MAX_PCK_NUM(MAX_PCK_NUM),
   	.MAX_SIM_CLKs(MAX_SIM_CLKs),
   	.MAX_PCK_SIZ(MAX_PCK_SIZ),
   	.TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM),
   	.MAX_RATIO(MAX_RATIO),
   	.SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
   	.WEIGHTw(WEIGHTw),
   	.MIN_PCK_SIZE(MIN_PCK_SIZE)
   )
   the_traffic_gen
   (
   .reset(reset),
    .clk(clk),
    .ratio(ratio),
    .start(start),
    .stop(stop),
    .update(update),
    .time_stamp_h2h(time_stamp_h2h),
    .time_stamp_h2t(time_stamp_h2t),
    .distance(distance),
    .pck_class_out(pck_class_out),
    .current_r_addr(current_r_addr),
    .current_e_addr(current_e_addr),
    .dest_e_addr(dest_e_addr),
    .pck_number(pck_number),
    .avg_pck_size_in(avg_pck_size_in),
    .pck_size_in(pck_size_in),
    .sent_done(sent_done),
    .hdr_flit_sent(hdr_flit_sent),
    .pck_class_in(pck_class_in),
    .init_weight(init_weight),
    .flit_out(flit_out),
    .flit_out_wr(flit_out_wr),
    .credit_in(credit_in),
    .flit_in(flit_in),
    .flit_in_wr(flit_in_wr),
    .credit_out(credit_out),
    .report(report),
    .src_e_addr(src_e_addr)
   );



endmodule

