`timescale    1ns/1ps

/**********************************************************************
**	File: input_ports.v
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
**	NoC router input Port. It consists of input buffer, control FIFO 
**	and request masking/generation control modules
**
**************************************************************/


module input_ports
 #(
    parameter V = 4,     // vc_num_per_port
    parameter P = 5,     // router port num
    parameter B = 4,     // buffer space :flit per VC 
    parameter NX= 4,    // number of node in x axis
    parameter NY= 4,    // number of node in y axis
    parameter C = 4,    //    number of flit class 
    parameter Fpay = 32,
    parameter COMBINATION_TYPE= "BASELINE",// "BASELINE", "COMB_SPEC1", "COMB_SPEC2", "COMB_NONSPEC"
    parameter VC_REALLOCATION_TYPE = "ATOMIC",
    parameter TOPOLOGY = "MESH",//"MESH","TORUS"
    parameter ROUTE_NAME="XY",// "XY", "TRANC_XY"
    parameter ROUTE_TYPE="DETERMINISTIC",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter DEBUG_EN = 1,
    parameter ROUTE_SUBFUNC= "XY",
    parameter AVC_ATOMIC_EN= 0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1: 0] CLASS_SETTING = {CVw{1'b1}}, // shows how each class can use VCs   
    parameter [V-1  : 0] ESCAP_VC_MASK = 4'b1000,  // mask scape vc, valid only for full adaptive
    parameter CLASS_HDR_WIDTH =8,
    parameter ROUTING_HDR_WIDTH =8,
    parameter DST_ADR_HDR_WIDTH =8,
    parameter SRC_ADR_HDR_WIDTH =8,     
    parameter SSA_EN="YES", // "YES" , "NO" 
    parameter SWA_ARBITER_TYPE ="RRA",// "RRA","WRRA",
    parameter WEIGHTw=4,
    parameter WRRA_CONFIG_INDEX=0     
)(
    current_x,
    current_y,
    ivc_num_getting_sw_grant,// for non spec ivc_num_getting_first_sw_grant,
    any_ivc_sw_request_granted_all,
    flit_in_all,
    flit_in_we_all,
    reset_ivc_all,
    flit_is_tail_all,
    ivc_request_all,
    dest_port_all,
    candidate_ovcs_all,
    flit_out_all,
    assigned_ovc_num_all,
    lk_destination_all,
    sel,
    x_diff_is_one_all,
    nonspec_first_arbiter_granted_ivc_all,
    ssa_ivc_num_getting_sw_grant_all,
    destport_ab_clear_all,
    vc_weight_is_consumed_all,
    iport_weight_is_consumed_all,
    iport_weight_all,
    oports_weight_all,
    granted_dest_port_all,
    refresh_w_counter,
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
    
    localparam
        PV = V * P,
        VV = V * V,
        PVV = PV * V,    
        P_1 = P-1,
        PP_1 = P * P_1, 
        VP_1 = V * P_1,
        PVP_1 = PV * P_1,
        Xw = log2(NX),    // number of node in x axis
        Yw = log2(NY),    // number of node in y axis
        Fw = 2+V+Fpay,    //flit width;    
        PFw = P*Fw,
        W= WEIGHTw,
        WP= W * P,
        WPP = WP * P;


    input   [Xw-1 : 0] current_x;
    input   [Yw-1 : 0] current_y;    
    input   [PV-1 : 0] ivc_num_getting_sw_grant;
    input   [P-1 : 0] any_ivc_sw_request_granted_all;
    input   [PFw-1 : 0] flit_in_all;
    input   [P-1 : 0] flit_in_we_all;
    input   [PV-1 : 0] reset_ivc_all;
    output  [PV-1 : 0] flit_is_tail_all;
    output  [PV-1 : 0] ivc_request_all;
    output  [PVP_1-1 : 0] dest_port_all;
    output  [PVV-1 : 0] candidate_ovcs_all;
    output  [PFw-1 : 0] flit_out_all;
    input   [PVV-1 : 0] assigned_ovc_num_all;
    input   [PV-1 : 0] sel;
    output  [PV-1 : 0] x_diff_is_one_all;
    input   reset,clk;
    output  [PVP_1-1 : 0] lk_destination_all;
    input   [PV-1 : 0] nonspec_first_arbiter_granted_ivc_all;
    input   [PV-1 : 0] ssa_ivc_num_getting_sw_grant_all;
    input   [2*PV-1 : 0] destport_ab_clear_all;
    output  [WP-1 : 0] iport_weight_all;
    output  [PV-1 : 0] vc_weight_is_consumed_all;
    output  [P-1 : 0] iport_weight_is_consumed_all;
    input   [PP_1-1 : 0] granted_dest_port_all;
    output  [WPP-1 : 0] oports_weight_all;
    input refresh_w_counter;

genvar i;
generate 
    for(i=0;i<P;i=i+1)begin : port_loop
    
    
    input_queue_per_port 
    #(
        .V(V),
        .P(P),
        .B(B), 
        .NX(NX),
        .NY(NY),
        .C(C),    
        .Fpay(Fpay),    
        .SW_LOC(i),    
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .ROUTE_TYPE(ROUTE_TYPE),
        .DEBUG_EN(DEBUG_EN),
        .ROUTE_SUBFUNC(ROUTE_SUBFUNC),
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .CLASS_HDR_WIDTH(CLASS_HDR_WIDTH),
        .ROUTING_HDR_WIDTH(ROUTING_HDR_WIDTH),
        .DST_ADR_HDR_WIDTH(DST_ADR_HDR_WIDTH),
        .SRC_ADR_HDR_WIDTH(SRC_ADR_HDR_WIDTH),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE (SWA_ARBITER_TYPE), 
        .WEIGHTw(WEIGHTw),
        .WRRA_CONFIG_INDEX(WRRA_CONFIG_INDEX)
    
    )
    the_input_queue_per_port
    (
        .current_x(current_x),    
        .current_y(current_y),    
        .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant  [(i+1)*V-1 : i*V]),// for non spec ivc_num_getting_first_sw_grant,
        .any_ivc_sw_request_granted(any_ivc_sw_request_granted_all  [i]),    
        .flit_in(flit_in_all[(i+1)*Fw-1 : i*Fw]),
        .flit_in_we(flit_in_we_all[i]),
        .reset_ivc(reset_ivc_all [(i+1)*V-1 : i*V]),
        .flit_is_tail(flit_is_tail_all  [(i+1)*V-1 : i*V]),
        .ivc_request(ivc_request_all [(i+1)*V-1 : i*V]),    
        .dest_port(dest_port_all   [(i+1)*VP_1-1 : i*VP_1]),
        .candidate_ovcs(candidate_ovcs_all [(i+1) * VV -1 : i*VV]),
        .flit_out(flit_out_all [(i+1)*Fw-1 : i*Fw]),
        .assigned_ovc_num(assigned_ovc_num_all [(i+1)*VV-1 : i*VV]),
        .sel(sel [(i+1)*V-1 : i*V]),
        .x_diff_is_one(x_diff_is_one_all[(i+1)*V-1 : i*V]),
        .nonspec_first_arbiter_granted_ivc(nonspec_first_arbiter_granted_ivc_all[(i+1)*V-1 : i*V]),
        .reset(reset),
        .clk(clk),
        .lk_destination(lk_destination_all[(i+1)*VP_1-1 : i*VP_1]),
        .ssa_ivc_num_getting_sw_grant(ssa_ivc_num_getting_sw_grant_all[(i+1)*V-1 : i*V]),
        .destport_ab_clear(destport_ab_clear_all[(i+1)*2*V-1 : i*2*V]),
        .iport_weight(iport_weight_all[(i+1)*W-1 : i*W]),
        .oports_weight(oports_weight_all[(i+1)*WP-1 : i*WP]),
        .vc_weight_is_consumed(vc_weight_is_consumed_all [(i+1)*V-1 : i*V]),
        .iport_weight_is_consumed(iport_weight_is_consumed_all[i]),
        .refresh_w_counter(refresh_w_counter),
        .granted_dest_port(granted_dest_port_all[(i+1)*P_1-1 : i*P_1])
    );
    
    end//for
    

       
    
    
endgenerate






endmodule 


/**************************

    input_queue_per_port

**************************/



module input_queue_per_port  #(
    parameter V = 4,     // vc_num_per_port
    parameter P = 5,     // router port num
    parameter B = 4,     // buffer space :flit per VC 
    parameter NX = 4,    // number of node in x axis
    parameter NY = 4,    // number of node in y axis
    parameter C = 4,    //    number of flit class 
    parameter Fpay = 32,
    parameter SW_LOC = 0,
    parameter VC_REALLOCATION_TYPE =  "ATOMIC",
    parameter COMBINATION_TYPE= "BASELINE",// "BASELINE", "COMB_SPEC1", "COMB_SPEC2", "COMB_NONSPEC"
    parameter TOPOLOGY =  "MESH",//"MESH","TORUS"
    parameter ROUTE_NAME="XY",// "XY", "TRANC_XY"
    parameter ROUTE_TYPE="DETERMINISTIC",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter DEBUG_EN =1,
    parameter ROUTE_SUBFUNC= "XY",
    parameter AVC_ATOMIC_EN= 0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1: 0] CLASS_SETTING = {CVw{1'b1}}, // shows how each class can use VCs   
    parameter [V-1  : 0] ESCAP_VC_MASK = 4'b1000,  // mask scape vc, valid only for full adaptive
    parameter CLASS_HDR_WIDTH =8,
    parameter ROUTING_HDR_WIDTH =8,
    parameter DST_ADR_HDR_WIDTH =8,
    parameter SRC_ADR_HDR_WIDTH =8,     
    parameter SSA_EN="YES", // "YES" , "NO"      
    parameter SWA_ARBITER_TYPE ="RRA",// "RRA","WRRA"
    parameter WEIGHTw=4,
    parameter WRRA_CONFIG_INDEX=0
)(
    current_x,
    current_y,
    ivc_num_getting_sw_grant,// for non spec ivc_num_getting_first_sw_grant,
    any_ivc_sw_request_granted,
    flit_in,
    flit_in_we,
    reset_ivc,
    flit_is_tail,
    ivc_request,
    dest_port,
    candidate_ovcs,
    flit_out,
    assigned_ovc_num,
    sel,
    reset,
    clk,
    x_diff_is_one,
    lk_destination,
    nonspec_first_arbiter_granted_ivc,
    destport_ab_clear,
    ssa_ivc_num_getting_sw_grant,
    iport_weight,
    oports_weight,  
    vc_weight_is_consumed,
    iport_weight_is_consumed,
    refresh_w_counter,
    granted_dest_port
    
    
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
        VV = V * V,
        P_1 = P-1,
        VP_1 = V * P_1,
        Xw = log2(NX),    // number of node in x axis
        Yw = log2(NY),    // number of node in y axis
        Cw = (C>1)? log2(C): 1,
        Fw = 2+V+Fpay,   //flit width;    
        W = WEIGHTw,
        WP = W * P;    

    localparam
        HDR_FLG =1,
        TAIL_FLG =0,
        /* verilator lint_off WIDTH */
        MAX_PCK = (VC_REALLOCATION_TYPE== "ATOMIC")?  1 : (B/2)+(B%2);// min packet size is two hence the max packet number in buffer is (B/2)
        /* verilator lint_on WIDTH */            

    

    input   [Xw-1 : 0] current_x;
    input   [Yw-1 : 0] current_y;                    
    input   [V-1 : 0] ivc_num_getting_sw_grant;
    input                      any_ivc_sw_request_granted;
    input   [Fw-1 : 0] flit_in;
    input                       flit_in_we;
    input   [V-1 : 0] reset_ivc;
    output  [V-1 : 0] flit_is_tail;
    output  [V-1 : 0] ivc_request;
    output  [VP_1-1 : 0] dest_port;
    output  [VV-1 : 0] candidate_ovcs;
    output  [Fw-1 : 0] flit_out;
    input   [VV-1 : 0] assigned_ovc_num;
    input   [V-1 : 0] sel;
    input                        reset,clk;
    output  [VP_1-1 : 0] lk_destination;
    output  [V-1 : 0] x_diff_is_one;
    input   [V-1 : 0] nonspec_first_arbiter_granted_ivc;
    input   [V-1 : 0] ssa_ivc_num_getting_sw_grant;    
    input   [2*V-1 : 0] destport_ab_clear;            
    output reg [WEIGHTw-1 : 0] iport_weight;
    output  [V-1 : 0] vc_weight_is_consumed;
    output  iport_weight_is_consumed;
    input   refresh_w_counter;
    input   [P_1-1 : 0] granted_dest_port; 
    output  [WP-1 : 0] oports_weight;  
    
    wire [Cw-1 : 0] class_in;
    wire [P_1-1 : 0] destport_in;
    wire [Xw-1 : 0] x_dst_in;
    wire [Yw-1 : 0] y_dst_in;
    wire [Xw-1 : 0] x_src_in;
    wire [Yw-1 : 0] y_src_in;
    wire [V-1 : 0] vc_num_in;
    wire [V-1 : 0] hdr_flit_wr,flit_wr;
    reg  [V-1 : 0] hdr_flit_wr_delayed;
    wire [V-1 : 0] class_rd_fifo,dst_rd_fifo;
    reg  [V-1 : 0] lk_dst_rd_fifo;
    wire [P_1-1 : 0] lk_destination_in;
    wire [WEIGHTw-1  : 0] weight_in;
   
    wire [Fw-1 : 0] buffer_out;
    wire [1 : 0] flg_hdr_in;  
    wire [V-1 : 0] ivc_not_empty;
    wire [Cw-1 : 0] class_out [V-1 : 0];


//extract header flit info

     extract_header_flit_info #(
         .CLASS_HDR_WIDTH(CLASS_HDR_WIDTH),
         .ROUTING_HDR_WIDTH(ROUTING_HDR_WIDTH),
         .DST_ADR_HDR_WIDTH(DST_ADR_HDR_WIDTH),
         .SRC_ADR_HDR_WIDTH(SRC_ADR_HDR_WIDTH),
         .TOPOLOGY(TOPOLOGY),
         .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
         .WEIGHTw(WEIGHTw),
         .V(V),
         .P(P),
         .NX(NX),
         .NY(NY),
         .C(C),
         .Fpay(Fpay)
     )
     header_extractor
     (
         .flit_in(flit_in),
         .flit_in_we(flit_in_we),
         
         .class_o(class_in),
         .destport_o(destport_in),
         .x_dst_o(x_dst_in),
         .y_dst_o(y_dst_in),
         .x_src_o(x_src_in ),
         .y_src_o(y_src_in ),
         .vc_num_o(vc_num_in),
         .hdr_flit_wr_o(hdr_flit_wr),
         .flg_hdr_o(flg_hdr_in),
         .weight_o(weight_in)
     );
always @ (posedge clk or posedge reset) begin 
    if(reset) begin 
          iport_weight <= 1;
    end else begin 
          if(hdr_flit_wr != {V{1'b0}})  iport_weight <= (weight_in=={WEIGHTw{1'b0}})? 1 : weight_in; // the minimum weight is 1
    end
end


// genrate write enable for lk_routing result with one clock cycle latency after reciveing the flit
always @(posedge clk or posedge reset) begin 
    if(reset) begin 
        hdr_flit_wr_delayed <= {V{1'b0}};
        //lk_dst_rd_fifo          <= {V{1'b0}};
    end else begin 
        hdr_flit_wr_delayed <= hdr_flit_wr;
    //    lk_dst_rd_fifo          <= dst_rd_fifo;
    end
end 


genvar i;
generate
    for (i=0;i<V; i=i+1) begin: V_loop
        
        class_ovc_table #(
            .CVw(CVw),
            .CLASS_SETTING(CLASS_SETTING),   
            .C(C),
            .V(V)
        )
        class_table
        (
            .class_in(class_out[i]),
            .candidate_ovcs(candidate_ovcs [(i+1)*V-1 : i*V])
        );
    
        
        //tail fifo
        fwft_fifo #(
            .DATA_WIDTH(1),
            .MAX_DEPTH (B),
            .IGNORE_SAME_LOC_RD_WR_WARNING(SSA_EN)
        )
        tail_fifo
        (
            .din (flg_hdr_in [TAIL_FLG]),
            .wr_en (flit_wr[i]),   // Write enable
            .rd_en (ivc_num_getting_sw_grant[i]),   // Read the next word
            .dout (flit_is_tail[i]),    // Data out
            .full ( ),
            .nearly_full ( ),
            .recieve_more_than_0 ( ),
            .recieve_more_than_1 ( ),
            .reset (reset),
            .clk (clk)            
        );
    
        //class_fifo
        if(C>1)begin :cb1
            fwft_fifo #(
                .DATA_WIDTH(Cw),
                .MAX_DEPTH (MAX_PCK)
            )
            class_fifo
            (
                .din (class_in),
                .wr_en (hdr_flit_wr[i]),   // Write enable
                .rd_en (class_rd_fifo[i]),   // Read the next word
                .dout (class_out[i]),    // Data out
                .full ( ),
                .nearly_full ( ),
                .recieve_more_than_0 ( ),
                .recieve_more_than_1 ( ),
                .reset (reset),
                .clk (clk)
            
            );
       end else begin :c_num_1
           assign class_out[i] = 1'b0;
       end
       
       //lk_dst_fifo
        fwft_fifo #(
            .DATA_WIDTH(P_1),
            .MAX_DEPTH (MAX_PCK)
        )
        lk_dest_fifo
        (
             .din (lk_destination_in),
             .wr_en (hdr_flit_wr_delayed [i]),   // Write enable
             .rd_en (lk_dst_rd_fifo [i]),   // Read the next word
             .dout (lk_destination  [(i+1)*P_1-1 : i*P_1]),    // Data out
             .full (),
             .nearly_full (),
             .recieve_more_than_0 (),
             .recieve_more_than_1 (),
             .reset (reset),
             .clk (clk)
             
        );
        /* verilator lint_off WIDTH */    
        if( ROUTE_TYPE=="DETERMINISTIC") begin : dtrmn_dest
        /* verilator lint_on WIDTH */
            //destport_fifo
            fwft_fifo #(
                 .DATA_WIDTH(P_1),
                 .MAX_DEPTH (MAX_PCK)
            )
            dest_fifo
            (
                 .din(destport_in),
                 .wr_en(hdr_flit_wr[i]),   // Write enable
                 .rd_en(dst_rd_fifo[i]),   // Read the next word
                 .dout(dest_port[(i+1)*P_1-1 : i*P_1]),    // Data out
                 .full(),
                 .nearly_full(),
                 .recieve_more_than_0(),
                 .recieve_more_than_1(),
                 .reset(reset),
                 .clk(clk) 
            );               
                         
        end else begin : adptv_dest   

            fwft_fifo_with_output_clear #(
                .DATA_WIDTH(P_1),
                .MAX_DEPTH (MAX_PCK)
            )
            dest_fifo
            (
                .din(destport_in),
                .wr_en(hdr_flit_wr[i]),   // Write enable
                .rd_en(dst_rd_fifo[i]),   // Read the next word
                .dout(dest_port[(i+1)*P_1-1 : i*P_1]),    // Data out
                .full(),
                .nearly_full(),
                .recieve_more_than_0(),
                .recieve_more_than_1(),
                .reset(reset),
                .clk(clk),
                .clear({2'b00,destport_ab_clear[((i+1)*2)-1 : i*2]})   // dest_port_in ={x,y,a,b}
            );                  
    
                
        end 
        /* verilator lint_off WIDTH */          
        if( ROUTE_TYPE=="FULL_ADAPTIVE" && ROUTE_SUBFUNC=="ODD_EVEN") begin :odd
        /* verilator lint_on WIDTH */
                wire x_diff_is_one_in;
                assign x_diff_is_one_in =(current_x==(NX-1'b1))? 1'b0 : (x_dst_in == (current_x + 1'b1)); 
            
            
                fwft_fifo #(
                    .DATA_WIDTH(1),
                    .MAX_DEPTH (MAX_PCK)
                )
                xdiff_fifo
                (
                    .din(x_diff_is_one_in),
                    .wr_en(hdr_flit_wr[i]),   // Write enable
                    .rd_en(dst_rd_fifo[i]),   // Read the next word
                    .dout(x_diff_is_one[i]), // Data out
                    .full(),
                    .nearly_full(),
                    .recieve_more_than_0(),
                    .recieve_more_than_1(),
                    .reset(reset),
                    .clk(clk)
            
                );
                        
        end else begin : no_odd            
                assign x_diff_is_one={V{1'bX}};        
        end  
            
        /* verilator lint_off WIDTH */    
        if(SWA_ARBITER_TYPE != "RRA")begin  : wrra
        /* verilator lint_on WIDTH */
               /*
                weight_control #(
                    .WEIGHTw(WEIGHTw)
                )
                wctrl_per_vc
                (   
                    .sw_is_granted(ivc_num_getting_sw_grant[i]),
                    .flit_is_tail(flit_is_tail[i]),               
                    .weight_is_consumed_o(vc_weight_is_consumed[i]),    
                    .iport_weight(1),  //(iport_weight),               
                    .clk(clk),
                    .reset(reset)           
                );
                */     
            assign vc_weight_is_consumed[i] = 1'b1;
        end else begin :now_rra
            assign vc_weight_is_consumed[i] = 1'bX;        
        end              
                
            
    end//for i
    

    /* verilator lint_off WIDTH */    
    if(SWA_ARBITER_TYPE != "RRA")begin  : wrra
    /* verilator lint_on WIDTH */
        wire granted_flit_is_tail;
        
        one_hot_mux #(
        	.IN_WIDTH(V),
        	.SEL_WIDTH(V)
        )
        one_hot_mux(
        	.mux_in(flit_is_tail),
        	.mux_out(granted_flit_is_tail),
        	.sel(ivc_num_getting_sw_grant)
        );
    
        weight_control#(
            .ARBITER_TYPE(SWA_ARBITER_TYPE),
            .SW_LOC(SW_LOC),
            .WEIGHTw(WEIGHTw),
            .WRRA_CONFIG_INDEX(WRRA_CONFIG_INDEX),
            .P(P)
        )
        wctrl_iport
        (   
            .sw_is_granted(any_ivc_sw_request_granted),
            .flit_is_tail(granted_flit_is_tail),               
            .weight_is_consumed_o(iport_weight_is_consumed),    
            .iport_weight(iport_weight),
            .oports_weight(oports_weight),
            .granted_dest_port(granted_dest_port), 
            .refresh_w_counter(refresh_w_counter),              
            .clk(clk),
            .reset(reset)           
        );     
  
        end else begin :now_rra
            assign iport_weight_is_consumed=1'bX;
            assign oports_weight = {WP{1'bX}};          
        end              
        


    /* verilator lint_off WIDTH */
    if(COMBINATION_TYPE == "COMB_NONSPEC") begin  : nonspec  
    /* verilator lint_on WIDTH */ 
           
        flit_buffer #(
            .V(V),
            .B(B),   // buffer space :flit per VC 
            .Fpay(Fpay),
            .DEBUG_EN(DEBUG_EN),
            .SSA_EN(SSA_EN)
        )
        the_flit_buffer
        (
            .din(flit_in),     // Data in
            .vc_num_wr(vc_num_in),//write vertual channel   
            .vc_num_rd(nonspec_first_arbiter_granted_ivc),//read vertual channel     
            .wr_en(flit_in_we),   // Write enable
            .rd_en(any_ivc_sw_request_granted),     // Read the next word
            .dout(buffer_out),    // Data out
            .vc_not_empty(ivc_not_empty),
            .reset(reset),
            .clk(clk),
            .ssa_rd(ssa_ivc_num_getting_sw_grant)
        );
   
    end else begin :spec//not nonspec comb
 

        flit_buffer #(
            .V(V),
            .B(B),   // buffer space :flit per VC 
            .Fpay(Fpay),
            .DEBUG_EN(DEBUG_EN),
            .SSA_EN(SSA_EN)
        )
        the_flit_buffer
        (
            .din(flit_in),     // Data in
            .vc_num_wr(vc_num_in),//write vertual channel   
            .vc_num_rd(ivc_num_getting_sw_grant),//read vertual channel     
            .wr_en(flit_in_we),   // Write enable
            .rd_en(any_ivc_sw_request_granted),     // Read the next word
            .dout(buffer_out),    // Data out
            .vc_not_empty(ivc_not_empty),
            .reset(reset),
            .clk(clk),
            .ssa_rd(ssa_ivc_num_getting_sw_grant)
        );  
  
    end   
    
endgenerate    




     look_ahead_routing #(
        .P(P),
        .NX(NX),
        .NY(NY),
        .SW_LOC(SW_LOC),
        .TOPOLOGY (TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .ROUTE_TYPE(ROUTE_TYPE)
    )
    lk_routing
    (
        .current_x(current_x),
        .current_y(current_y),
        .dest_x(x_dst_in),
        .dest_y(y_dst_in),
        .destport(destport_in),
        .lkdestport(lk_destination_in),
        .reset(reset),
        .clk(clk)
     );
 
    


    flit_update #(
        .V(V),
        .P(P),
        .Fpay(Fpay),
        .DST_ADR_HDR_WIDTH(DST_ADR_HDR_WIDTH),
        .SRC_ADR_HDR_WIDTH(SRC_ADR_HDR_WIDTH),
        .ROUTE_TYPE(ROUTE_TYPE),
        .SSA_EN(SSA_EN)

    )
    the_flit_update
    (
        .flit_in (buffer_out),
        .flit_out (flit_out),
        .vc_num_in(ivc_num_getting_sw_grant),
        .lk_dest_all_in (lk_destination),
        .assigned_ovc_num (assigned_ovc_num),
        .any_ivc_sw_request_granted(any_ivc_sw_request_granted),
        .lk_dest_not_registered(lk_destination_in),
        .sel (sel),
        .reset (reset),
        .clk (clk)
    );
    
    assign flit_wr =(flit_in_we )? vc_num_in : {V{1'b0}};
        
    always @(posedge clk or posedge reset) begin 
        if(reset) begin 
                lk_dst_rd_fifo          <= {V{1'b0}};
        end else begin 
                lk_dst_rd_fifo          <= dst_rd_fifo;
            end
    end//always 
      
    
    assign    dst_rd_fifo = reset_ivc;
    assign    class_rd_fifo = reset_ivc;
    assign    ivc_request = ivc_not_empty;
    

//synthesis translate_off
//synopsys  translate_off

generate 
if(DEBUG_EN) begin :dbg

    wire [V-1 : 0] vc_num_hdr_wr, vc_num_tail_wr,vc_num_bdy_wr ;
    reg  [V-1 : 0] hdr_passed, hdr_passed_next;
    
    assign     vc_num_hdr_wr =(flg_hdr_in[HDR_FLG] && flit_in_we)?    vc_num_in : 0;
    assign     vc_num_tail_wr =(flg_hdr_in[TAIL_FLG]&& flit_in_we)?    vc_num_in : 0;
    assign    vc_num_bdy_wr =(flg_hdr_in == 2'b00 && flit_in_we)?    vc_num_in : 0;
    always @(*)begin
        hdr_passed_next = (hdr_passed | vc_num_hdr_wr) & ~vc_num_tail_wr; 
    end
    
    always @ (posedge clk or posedge reset) begin 
        if(reset)  hdr_passed <= 0;
        else          begin 
            hdr_passed     <= hdr_passed_next;
            if(( hdr_passed & vc_num_hdr_wr)>0  ) $display("%t :Error: a header flit received in  an active IVC %m",$time);    
            if((~hdr_passed & vc_num_tail_wr)>0 ) $display("%t :Error: a tail flit received in an inactive IVC %m",$time);    
            if ((~hdr_passed & vc_num_bdy_wr    )>0) $display("%t :Error: a body  flit received in an inactive IVC %m",$time);    
        end
    end

localparam      LOCAL =  0, 
    //            EAST =  1, 
                NORTH =  2,  
     //           WEST =  3,  
                SOUTH =  4; 


/* verilator lint_off WIDTH */
if(ROUTE_TYPE== "FULL_ADAPTIVE")begin :full_adpt
/* verilator lint_on WIDTH */    
       // wire a,b;
        reg [V-1 : 0] not_empty;
        //assign {a,b} = destport_in[1:0];
        always@( posedge clk or posedge reset) begin
            if(reset) begin
               not_empty <=0;
            end else begin 
               if(flg_hdr_in[HDR_FLG] & flit_in_we) begin
                    not_empty <= not_empty | vc_num_in;
                    if( ((AVC_ATOMIC_EN==1)&& (SW_LOC!= LOCAL)) || (SW_LOC== NORTH) || (SW_LOC== SOUTH) )begin   
                        if((vc_num_in  & ~ESCAP_VC_MASK)>0) begin // adaptive VCs
                            if( (not_empty & vc_num_in)>0) $display("%t  :Error AVC allocated nonatomicly in %d port %m",$time,SW_LOC);
                        end
                    end//( AVC_ATOMIC_EN || SW_LOC== NORTH || SW_LOC== SOUTH )
                    if( ROUTE_SUBFUNC== "XY") begin 
                        if((vc_num_in  & ESCAP_VC_MASK)>0 && (SW_LOC== SOUTH || SW_LOC== NORTH) )  begin // escape vc
                            // if (a & b) $display("%t  :Error EVC allocation violate subfunction routing rules %m",$time);
                            if ((current_x- x_dst_in) !=0 && (current_y- y_dst_in) !=0) $display("%t  :Error EVC allocation violate subfunction routing rules src_x=%d src_y=%d dst_x%d   dst_y=%d %m",$time,x_src_in, y_src_in, x_dst_in,y_dst_in);
                        end
                     end else begin //NORTH LAST
                        if((vc_num_in  & ESCAP_VC_MASK)>0 && (SW_LOC== SOUTH ) )  begin // escape vc
                            // if (a & b) $display("%t  :Error EVC allocation violate subfunction routing rules %m",$time);
                            if ((current_x- x_dst_in) !=0 && (current_y- y_dst_in) !=0) $display("%t  :Error EVC allocation violate subfunction routing rules src_x=%d src_y=%d dst_x%d   dst_y=%d %m",$time,x_src_in, y_src_in, x_dst_in,y_dst_in);
                        end
                      end
                end//hdr_wr_in
                if((flit_is_tail & ivc_num_getting_sw_grant)>0)begin
                    not_empty <= not_empty & ~ivc_num_getting_sw_grant;
                end//tail wr out
            end//reset
        end//always
    end //SW_LOC


    /* verilator lint_off WIDTH */ 
    if(TOPOLOGY=="MESH")begin :mesh
    /* verilator lint_on WIDTH */
        wire  [Xw-1 : 0] low_x,high_x;
        wire  [Yw-1 : 0] low_y,high_y;    
        
           
        
        assign low_x = (x_src_in < x_dst_in)?  x_src_in : x_dst_in;
        assign low_y = (y_src_in < y_dst_in)?  y_src_in : y_dst_in;
        assign high_x = (x_src_in < x_dst_in)?  x_dst_in : x_src_in;
        assign high_y = (y_src_in < y_dst_in)?  y_dst_in : y_src_in;
        
          
        always@( posedge clk)begin 
               if((current_x <low_x) | (current_x > high_x) | (current_y <low_y) | (current_y > high_y) )  
                    if(flit_in_we & flg_hdr_in[HDR_FLG] )$display ( "%t\t  Error: non_minimal routing %m",$time );
        end
               
    
    
    end// mesh  
  
 
  
  end//DEBUG_EN 
endgenerate 

//synopsys  translate_on  
//synthesis translate_on


endmodule



/***********************************
    
    flit_update

**********************************/
module flit_update #(
    parameter V = 4,
    parameter P = 5,
    parameter Fpay = 32,
    parameter DST_ADR_HDR_WIDTH =8,
    parameter SRC_ADR_HDR_WIDTH =8,
    parameter ROUTE_TYPE = "DETERMINISTIC",
    parameter SSA_EN ="YES"
)(
    flit_in ,
    flit_out,
    vc_num_in,
    lk_dest_all_in,
    assigned_ovc_num,
    any_ivc_sw_request_granted,
    lk_dest_not_registered,
    sel,
    reset,
    clk
);

    localparam  Fw = 2+V+Fpay,
                P_1 = P-1,
                VP_1 = V       *   P_1,
                VV = V       *   V;
                    
     

    input   [Fw-1 : 0]  flit_in;
    output  [Fw-1 : 0]  flit_out;
    input   [V-1 : 0]  vc_num_in;
    input   [VP_1-1 : 0]  lk_dest_all_in;
    input                       reset,clk;
    input   [VV-1 : 0]  assigned_ovc_num;
    input   [V-1 : 0]  sel;
    input                        any_ivc_sw_request_granted;
    input   [P_1-1 : 0]  lk_dest_not_registered;

    generate 
    /* verilator lint_off WIDTH */
    if(ROUTE_TYPE == "DETERMINISTIC") begin :dtrmn
    /* verilator lint_on WIDTH */
        flit_update_dtrmn #(
            .V(V),
            .P(P),
            .Fpay(Fpay),
            .DST_ADR_HDR_WIDTH(DST_ADR_HDR_WIDTH),
            .SRC_ADR_HDR_WIDTH(SRC_ADR_HDR_WIDTH),
            .SSA_EN(SSA_EN)
        )        
        the_flit_update
        (
            .flit_in(flit_in),
            .flit_out(flit_out),
            .vc_num_in(vc_num_in),
            .lk_dest_all_in(lk_dest_all_in),
            .assigned_ovc_num(assigned_ovc_num),
            .any_ivc_sw_request_granted(any_ivc_sw_request_granted),
            .lk_dest_not_registered(lk_dest_not_registered),
            .reset(reset),
            .clk(clk)            
        );
    
    
    end else begin :adaptive
        flit_update_adaptive #(
            .V(V),
            .P(P),
            .Fpay(Fpay),
            .DST_ADR_HDR_WIDTH(DST_ADR_HDR_WIDTH),
            .SRC_ADR_HDR_WIDTH(SRC_ADR_HDR_WIDTH),
            .SSA_EN(SSA_EN)
        )        
        the_flit_update
        (
            .flit_in(flit_in),
            .flit_out(flit_out),
            .vc_num_in(vc_num_in),
            .lk_dest_all_in(lk_dest_all_in),
            .assigned_ovc_num(assigned_ovc_num),
            .any_ivc_sw_request_granted(any_ivc_sw_request_granted),
            .lk_dest_not_registered(lk_dest_not_registered),
            .sel(sel),
            .reset(reset),
            .clk(clk)           
        );
     
    end
    endgenerate

endmodule

/*****************
*
*   flit_update_dtrmn
*
******************/

module flit_update_dtrmn #(
    parameter V = 4,
    parameter P = 5,
    parameter Fpay = 32,
    parameter DST_ADR_HDR_WIDTH =8,
    parameter SRC_ADR_HDR_WIDTH =8,
    parameter SSA_EN ="YES"


)(
    flit_in    ,
    flit_out,
    vc_num_in,
    lk_dest_all_in,
    assigned_ovc_num,
    any_ivc_sw_request_granted,
    lk_dest_not_registered,
    reset,
    clk
);

    localparam     Fw =  2+V+Fpay,
                    P_1 =  P-1,
                    VP_1 =  V        *     P_1,
                    VV =  V        *    V;
                    
    localparam    DEST_LOC_LSB =  SRC_ADR_HDR_WIDTH+DST_ADR_HDR_WIDTH,
                    DEST_LOC_HSB =  DEST_LOC_LSB+P_1-1;
    

    input [Fw-1 : 0]    flit_in;
    output reg [Fw-1 : 0]    flit_out;
    input [V-1 : 0]    vc_num_in;
    input [VP_1-1 : 0]    lk_dest_all_in;
    input                             reset,clk;
    input [VV-1 : 0]    assigned_ovc_num;
    input                    any_ivc_sw_request_granted;
    input [P_1-1 : 0]    lk_dest_not_registered;
    
    wire                         hdr_flag;
    reg [V-1 : 0]    vc_num_delayed;
    wire [V-1 : 0]    ovc_num; 
    //reg [VV-1 : 0]    assigned_ovc_num_delayed;
    wire [P_1-1 : 0]    lk_mux_out;    
    wire [P_1-1 : 0]    lk_dest;
    
    always @(posedge clk or posedge reset) begin 
        if(reset) begin 
            vc_num_delayed                    <= {V{1'b0}};
            //assigned_ovc_num_delayed    <=  {VV{1'b0}};
        end else begin
            vc_num_delayed<= vc_num_in;
            //assigned_ovc_num_delayed    <=assigned_ovc_num;
        end
    end
    
    assign hdr_flag = flit_in[Fw-1];
    
    one_hot_mux #(
        .IN_WIDTH(VP_1),
        .SEL_WIDTH(V) 
    )
    lkdest_mux
    (
        .mux_in(lk_dest_all_in),
        .mux_out(lk_mux_out),
        .sel(vc_num_delayed)
    );
    
    one_hot_mux #(
        .IN_WIDTH(VV),
        .SEL_WIDTH(V) 
    )
    ovc_num_mux
    (
        .mux_in(assigned_ovc_num),
        .mux_out(ovc_num),
        .sel(vc_num_delayed)
    );

    generate 
    /* verilator lint_off WIDTH */
    if( SSA_EN == "YES" ) begin : predict // bypass the lk fifo when no ivc is granted
    /* verilator lint_on WIDTH */
        reg ivc_any_delayed;
        always @(posedge clk or posedge reset) begin 
            if(reset) begin 
                ivc_any_delayed <= 1'b0;
            end else begin
                ivc_any_delayed <= any_ivc_sw_request_granted;
            end
        end
        
        assign lk_dest = (ivc_any_delayed == 1'b0)? lk_dest_not_registered : lk_mux_out;

    end else begin : no_predict
        assign lk_dest =lk_mux_out;
    end 
    endgenerate

    
    always @(*)begin 
        flit_out =  {flit_in[Fw-1 : Fw-2],ovc_num,flit_in[Fpay-1 :0]};
        if(hdr_flag) flit_out[DEST_LOC_HSB : DEST_LOC_LSB]= lk_dest;
    end
endmodule



module flit_update_adaptive #(
    parameter V = 4,
    parameter P = 5,
    parameter Fpay = 32,
    parameter DST_ADR_HDR_WIDTH = 8,
    parameter SRC_ADR_HDR_WIDTH = 8,
    parameter SSA_EN ="YES"
)(
    flit_in ,
    flit_out,
    vc_num_in,
    lk_dest_all_in,
    assigned_ovc_num,
    any_ivc_sw_request_granted,
    lk_dest_not_registered,
    sel,
    reset,
    clk
);

    localparam  Fw = 2+V+Fpay,
                P_1 = P-1,
                VP_1 = V       *   P_1,
                VV = V       *   V;
                    
    localparam  DEST_LOC_LSB = SRC_ADR_HDR_WIDTH+DST_ADR_HDR_WIDTH,
                DEST_LOC_HSB = DEST_LOC_LSB+P_1-1;
    

    input [Fw-1 : 0]  flit_in;
    output reg  [Fw-1 : 0]  flit_out;
    input [V-1 : 0]  vc_num_in;
    input [VP_1-1 : 0]  lk_dest_all_in;
    input                           reset,clk;
    input [VV-1 : 0]  assigned_ovc_num;
    input [V-1 : 0]  sel;
    input                    any_ivc_sw_request_granted;
    input [P_1-1 : 0]  lk_dest_not_registered;
    
    wire hdr_flag;
    reg  [V-1 : 0]  vc_num_delayed;
    wire [V-1 : 0]  ovc_num; 
    wire [P_1-1 : 0]  lk_dest;
    wire [P_1-1 : 0]  lk_mux_out;
    wire [1 : 0]  ab,xy;
    wire                        sel_muxed;
    
    always @(posedge clk or posedge reset) begin 
        if(reset) begin 
            vc_num_delayed                  <= {V{1'b0}};
            //assigned_ovc_num_delayed  <=  {VV{1'b0}};
        end else begin
            vc_num_delayed<= vc_num_in;
            //assigned_ovc_num_delayed  <=assigned_ovc_num;
        end
    end
    
    assign hdr_flag = flit_in[Fw-1];
    
    one_hot_mux #(
        .IN_WIDTH(VP_1),
        .SEL_WIDTH(V) 
    )
    lkdest_mux
(
        .mux_in(lk_dest_all_in),
        .mux_out(lk_mux_out),
        .sel(vc_num_delayed)
    );
   

    generate 
    /* verilator lint_off WIDTH */
    if( SSA_EN == "YES" ) begin : predict // bypass the lk fifo when no ivc is granted
    /* verilator lint_on WIDTH */
        reg ivc_any_delayed;
        always @(posedge clk or posedge reset) begin 
            if(reset) begin 
                ivc_any_delayed <= 1'b0;
            end else begin
                ivc_any_delayed <= any_ivc_sw_request_granted;
            end
        end
        
        assign lk_dest = (ivc_any_delayed == 1'b0)? lk_dest_not_registered : lk_mux_out;

    end else begin : no_predict
        assign lk_dest =lk_mux_out;
    end 
    endgenerate


 
    one_hot_mux #(
        .IN_WIDTH(VV),
        .SEL_WIDTH(V) 
    )
    ovc_num_mux
    (
        .mux_in(assigned_ovc_num),
        .mux_out(ovc_num),
        .sel(vc_num_delayed)
    );
    
    one_hot_mux #(
        .IN_WIDTH(V),
        .SEL_WIDTH(V) 
    )
    sel_mux
    (
        .mux_in(sel),
        .mux_out(sel_muxed),
        .sel(vc_num_delayed)
    );
    
    
    //lkdestport = {lkdestport_x[1:0],lkdestport_y[1:0]};
    // sel: 0: xdir     1: ydir
    assign ab = (sel_muxed)? lk_dest[1:0] : lk_dest[3:2];
    //if ab==00 change x and y direction
    assign xy = (ab>0)? flit_in[DEST_LOC_HSB  : DEST_LOC_LSB+2] : ~flit_in[DEST_LOC_HSB  : DEST_LOC_LSB+2] ;
    
    always @(*)begin 
        flit_out = {flit_in[Fw-1 : Fw-2],ovc_num,flit_in[Fpay-1 :0]};
        if(hdr_flag) flit_out[DEST_LOC_HSB  : DEST_LOC_LSB]= {xy,ab};
    end

endmodule





/***************************
*
*    extract header flit info
*
****************************/

module extract_header_flit_info #(
    parameter CLASS_HDR_WIDTH =8,
    parameter ROUTING_HDR_WIDTH =8,
    parameter DST_ADR_HDR_WIDTH =8,
    parameter SRC_ADR_HDR_WIDTH =8,
    parameter TOPOLOGY =  "MESH",//"MESH","TORUS","RING" 
    parameter SWA_ARBITER_TYPE= "RRA",// "RRA", "WRRA",
    parameter WEIGHTw = 4, // WRRA weight width
    parameter V = 4,    // vc_num_per_port
    parameter P = 5,    // router port num
    parameter NX = 4,   // number of node in x axis
    parameter NY = 4,   // number of node in y axis
    parameter C = 4,    //  number of flit class 
    parameter Fpay = 32     //payload width
)(
    
    flit_in,
    flit_in_we,
    //outputs
    class_o,
    destport_o,
    x_dst_o,
    y_dst_o,
    x_src_o,
    y_src_o,
    vc_num_o,
    hdr_flit_wr_o,
    flg_hdr_o,
    weight_o 
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
   
    localparam
        /* verilator lint_off WIDTH */   
        ADDR_DIMENTION = (TOPOLOGY ==  "MESH" || TOPOLOGY ==  "TORUS") ? 2 : 1,  // "RING" and FULLY_CONNECT 
        /* verilator lint_on WIDTH */
        ALL_DATA_HDR_WIDTH = CLASS_HDR_WIDTH+ROUTING_HDR_WIDTH+DST_ADR_HDR_WIDTH+SRC_ADR_HDR_WIDTH,
        HDR_FLG = 1,
        P_1 = P-1,
        Fw = 2+V+Fpay,//flit width
        Xw = log2(NX),
        Yw = log2(NY),
        Cw = (C>1)? log2(C): 1;
                    
     
    
    input [Fw-1 : 0] flit_in;
    input                        flit_in_we;
    output [Cw-1 : 0] class_o;
    output [P_1-1 : 0] destport_o;
    output [Xw-1 : 0] x_dst_o;
    output [Yw-1 : 0] y_dst_o;
    output [Xw-1 : 0] x_src_o;
    output [Yw-1 : 0] y_src_o;
    //output [Yw-1 : 0] Z_dst_in;
    output [V-1 : 0] vc_num_o;
    output [V-1 : 0] hdr_flit_wr_o;
    output [1 : 0] flg_hdr_o; 
    output [WEIGHTw-1  : 0] weight_o; 
    
                    
    wire [CLASS_HDR_WIDTH-1 : 0]  class_hdr;
    wire [ROUTING_HDR_WIDTH-1 : 0]  routing_hdr;
    wire [DST_ADR_HDR_WIDTH-1 : 0]  dst_adr_hdr; 
    wire [SRC_ADR_HDR_WIDTH-1 : 0]  src_adr_hdr;
                  
                    
                    
    assign {class_hdr,routing_hdr,dst_adr_hdr,src_adr_hdr}= flit_in [ALL_DATA_HDR_WIDTH-1 :0];                
                    
   
     //x_dst_hdr, y_dst_hdr, x_src_hdr, y_src_hdr       
    generate
        if (ADDR_DIMENTION==1) begin :one_dimen
            assign x_dst_o = dst_adr_hdr [Xw-1 : 0];
            assign x_src_o = src_adr_hdr [Xw-1 : 0];
            assign y_dst_o = 1'b0; 
            assign y_src_o = 1'b0;                   
        end else begin :two_dimen
            assign y_dst_o =  dst_adr_hdr [Yw-1 : 0];
            assign y_src_o =  src_adr_hdr [Yw-1 : 0];
            assign x_dst_o =  dst_adr_hdr [(DST_ADR_HDR_WIDTH/2)+Xw-1 : DST_ADR_HDR_WIDTH/2];
            assign x_src_o =  src_adr_hdr [(SRC_ADR_HDR_WIDTH/2)+Xw-1 : SRC_ADR_HDR_WIDTH/2];          
        end
        
        /* verilator lint_off WIDTH */
        if(SWA_ARBITER_TYPE != "RRA")begin  : wrra_b
        /* verilator lint_on WIDTH */
            assign weight_o =  class_hdr   [Cw+WEIGHTw-1 : Cw];        
        end else begin : rra_b
            assign weight_o = {WEIGHTw{1'bX}};        
        end       
        
    endgenerate
    
     
    assign vc_num_o = flit_in [Fpay+V-1 : Fpay];
    assign flg_hdr_o= flit_in [Fw-1 : Fw-2];
    assign class_o =   class_hdr   [Cw-1 : 0];
    
    assign destport_o=  routing_hdr [P_1-1 : 0];
    assign hdr_flit_wr_o= (flit_in_we & flg_hdr_o[HDR_FLG] )? vc_num_o : {V{1'b0}};

endmodule




