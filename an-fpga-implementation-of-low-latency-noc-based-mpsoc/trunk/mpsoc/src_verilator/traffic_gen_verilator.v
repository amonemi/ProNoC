/**************************************
* Module: traffic_gen_verilator
* Date:2015-01-16  
* Author: alireza     
*
* Description: 
***************************************/
module  traffic_gen_verilator (
    //input 
    ratio,
    avg_pck_size_in,
    pck_size_in,       
    current_x,
    current_y,
    dest_x,
    dest_y, 
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
    distance,
    src_x,
    src_y,
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


    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 

    function integer CORE_NUM;
        input integer x,y;
        begin
            CORE_NUM = ((y * NX) +  x);
        end
    endfunction
    
    `define   INCLUDE_PARAM
    
    `include "parameter.v"
    
    
    
    localparam
        Xw          =   log2(NX),   // number of node in x axis
        Yw          =  log2(NY),    // number of node in y axis
        Cw          =  (C > 1)? log2(C): 1,
        Fw          =   2+V+Fpay,
        RATIOw      =   log2(MAX_RATIO),
        PCK_CNTw    =   log2(MAX_PCK_NUM+1),
        CLK_CNTw    =   log2(MAX_SIM_CLKs+1),
        PCK_SIZw    =   log2(MAX_PCK_SIZ+1),
         /* verilator lint_off WIDTH */
        NC = (TOPOLOGY=="RING" || TOPOLOGY=="LINE")? NX : NX*NY,    //number of cores
        /* verilator lint_on WIDTH */
        DSTw = log2(NC+1),     
        W = WEIGHTw;

       
    
    
    input                               reset, clk;     
    input  [RATIOw-1                :0] ratio;
    input                               start,stop;
    output                              update;
    output [CLK_CNTw-1              :0] time_stamp_h2h,time_stamp_h2t;
    output [DSTw-1                  :0] distance;
    output [Xw-1        :   0]    src_x;
    output [Yw-1        :   0]    src_y;

    output [Cw-1                    :0] pck_class_out;
    input  [Xw-1                    :0] current_x;
    input  [Yw-1                    :0] current_y;
    input  [Xw-1                    :0] dest_x;
    input  [Yw-1                    :0] dest_y;
    output [PCK_CNTw-1              :0] pck_number;
    input  [PCK_SIZw-1              :0] pck_size_in;
    input  [PCK_SIZw-1              :0] avg_pck_size_in;
    output                              sent_done;
    output                              hdr_flit_sent;
    input  [Cw-1                    :0] pck_class_in;
    input  [W-1                     :0] init_weight;
    
    
    // NOC interfaces
    output  [Fw-1                   :0] flit_out;     
    output                              flit_out_wr;   
    input   [V-1                    :0] credit_in;    
    input   [Fw-1                   :0] flit_in;   
    input                               flit_in_wr;   
    output  [V-1                    :0] credit_out;   
    input                               report;
    
    

    traffic_gen #(
        .V(V),
        .B(B),
        .NX(NX),
        .NY(NY),
        .Fpay(Fpay),
        .C(C),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .MAX_PCK_NUM(MAX_PCK_NUM),
        .MAX_SIM_CLKs(MAX_SIM_CLKs),
        .MAX_PCK_SIZ(MAX_PCK_SIZ),
        .TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM),
        .MAX_RATIO(MAX_RATIO),
        .WEIGHTw(WEIGHTw)
    )
    the_traffic_gen
    (
        //input 
        .ratio (ratio),
        .avg_pck_size_in(avg_pck_size_in),
        .pck_size_in(pck_size_in), 
        .current_x(current_x),
        .current_y(current_y),
        .dest_x(dest_x),
        .dest_y(dest_y), 
        .pck_class_in(pck_class_in),        
        .start(start),
        .stop(stop),
        .report (report),
        .init_weight(init_weight),
        //output
        .pck_number(pck_number),
        .sent_done(sent_done), // tail flit has been sent
        .hdr_flit_sent(hdr_flit_sent),
        .update(update), // update the noc_analayzer
        .distance(distance),
        .src_x(src_x),
    	.src_y(src_y),
        .pck_class_out(pck_class_out),   
        .time_stamp_h2h(time_stamp_h2h),
        .time_stamp_h2t(time_stamp_h2t),
         //noc
        .flit_out(flit_out),  
        .flit_out_wr(flit_out_wr),  
        .credit_in(credit_in), 
        .flit_in(flit_in),  
        .flit_in_wr(flit_in_wr),  
        .credit_out(credit_out),      
                     
        .reset(reset),
        .clk(clk)
               
            );
        
      //  always @(posedge start ) begin 
	//	 $display(" (%d,%d) start at %t",current_x, current_y,$time);
	//end 

endmodule

