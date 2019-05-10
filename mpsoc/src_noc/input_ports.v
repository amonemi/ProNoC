`timescale    1ns/1ps
//`define MONITORE_PATH

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
    parameter T1= 8,
    parameter T2= 8,
    parameter T3= 8,
    parameter T4= 8,
    parameter RAw = 3,  
    parameter EAw = 3,  
    parameter C = 4,    //    number of flit class 
    parameter Fpay = 32,
    parameter COMBINATION_TYPE= "BASELINE",// "BASELINE", "COMB_SPEC1", "COMB_SPEC2", "COMB_NONSPEC"
    parameter VC_REALLOCATION_TYPE = "ATOMIC",
    parameter TOPOLOGY = "MESH",//"MESH","TORUS"
    parameter ROUTE_NAME="XY",// "XY", "TRANC_XY"
    parameter ROUTE_TYPE="DETERMINISTIC",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter DEBUG_EN = 1,
    parameter AVC_ATOMIC_EN= 0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1: 0] CLASS_SETTING = {CVw{1'b1}}, // shows how each class can use VCs   
    parameter [V-1  : 0] ESCAP_VC_MASK = 4'b1000,  // mask scape vc, valid only for full adaptive
    parameter DSTPw = P-1,
    parameter SSA_EN="YES", // "YES" , "NO" 
    parameter SWA_ARBITER_TYPE ="RRA",// "RRA","WRRA",
    parameter WEIGHTw=4,
    parameter WRRA_CONFIG_INDEX=0,
    parameter PPSw=4,
    parameter MIN_PCK_SIZE=2 //minimum packet size in flits. The minimum value is 1. 
)(
    current_r_addr,
    neighbors_r_addr,
    ivc_num_getting_sw_grant,// for non spec ivc_num_getting_first_sw_grant,
    any_ivc_sw_request_granted_all,
    flit_in_all,
    flit_in_we_all,
    reset_ivc_all,
    flit_is_tail_all,
    ivc_request_all,
    dest_port_encoded_all,
    dest_port_all,
    candidate_ovcs_all,
    flit_out_all,
    assigned_ovc_num_all,
    sel,
    port_pre_sel,
    swap_port_presel,
    nonspec_first_arbiter_granted_ivc_all,
    ssa_ivc_num_getting_sw_grant_all,
    destport_clear_all,
    vc_weight_is_consumed_all,
    iport_weight_is_consumed_all,
    iport_weight_all,
    oports_weight_all,
    granted_dest_port_all,
    refresh_w_counter,
    reset,
    clk
);
    
         
     
    localparam
        PV = V * P,
        VV = V * V,
        PVV = PV * V,    
        P_1 = P-1,
        PP_1 = P * P_1, 
        VP_1 = V * P_1,
        PVP_1 = PV * P_1,
        Fw = 2+V+Fpay,    //flit width;    
        PFw = P*Fw,
        W= WEIGHTw,
        WP= W * P,
        WPP = WP * P,
        PVDSTPw= PV * DSTPw,
        PRAw= P * RAw;
       
        
    input   reset,clk;
    input   [RAw-1 : 0] current_r_addr;
    input   [PRAw-1:  0]  neighbors_r_addr;
    input   [PV-1 : 0] ivc_num_getting_sw_grant;
    input   [P-1 : 0] any_ivc_sw_request_granted_all;
    input   [PFw-1 : 0] flit_in_all;
    input   [P-1 : 0] flit_in_we_all;
    input   [PV-1 : 0] reset_ivc_all;
    output  [PV-1 : 0] flit_is_tail_all;
    output  [PV-1 : 0] ivc_request_all;
    output  [PVDSTPw-1 : 0] dest_port_encoded_all;
    output  [PVP_1-1 : 0] dest_port_all;
    output  [PVV-1 : 0] candidate_ovcs_all;
    output  [PFw-1 : 0] flit_out_all;
    input   [PVV-1 : 0] assigned_ovc_num_all;
    input   [PV-1 : 0] sel;
    input   [PPSw-1 : 0] port_pre_sel;
    input   [PV-1  : 0]  swap_port_presel;
    input   [PV-1 : 0] nonspec_first_arbiter_granted_ivc_all;
    input   [PV-1 : 0] ssa_ivc_num_getting_sw_grant_all;
    input   [PVDSTPw-1 : 0] destport_clear_all;
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
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .T4(T4),
        .RAw(RAw),  
        .EAw(EAw), 
        .C(C),    
        .Fpay(Fpay),    
        .SW_LOC(i),    
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .ROUTE_TYPE(ROUTE_TYPE),
        .DEBUG_EN(DEBUG_EN),
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .DSTPw(DSTPw),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE (SWA_ARBITER_TYPE), 
        .WEIGHTw(WEIGHTw),
        .WRRA_CONFIG_INDEX(WRRA_CONFIG_INDEX),
        .PPSw(PPSw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)    
    )
    the_input_queue_per_port
    (
        .current_r_addr(current_r_addr),    
        .neighbors_r_addr(neighbors_r_addr),
        .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant  [(i+1)*V-1 : i*V]),// for non spec ivc_num_getting_first_sw_grant,
        .any_ivc_sw_request_granted(any_ivc_sw_request_granted_all  [i]),    
        .flit_in(flit_in_all[(i+1)*Fw-1 : i*Fw]),
        .flit_in_we(flit_in_we_all[i]),
        .reset_ivc(reset_ivc_all [(i+1)*V-1 : i*V]),
        .flit_is_tail(flit_is_tail_all  [(i+1)*V-1 : i*V]),
        .ivc_request(ivc_request_all [(i+1)*V-1 : i*V]),    
        .dest_port_encoded(dest_port_encoded_all   [(i+1)*DSTPw*V-1 : i*DSTPw*V]),
        .dest_port(dest_port_all [(i+1)*P_1*V-1 : i*P_1*V]),
        .candidate_ovcs(candidate_ovcs_all [(i+1) * VV -1 : i*VV]),
        .flit_out(flit_out_all [(i+1)*Fw-1 : i*Fw]),
        .assigned_ovc_num(assigned_ovc_num_all [(i+1)*VV-1 : i*VV]),
        .sel(sel [(i+1)*V-1 : i*V]),
        .port_pre_sel(port_pre_sel),
        .swap_port_presel(swap_port_presel[(i+1)*V-1 : i*V]),
        .nonspec_first_arbiter_granted_ivc(nonspec_first_arbiter_granted_ivc_all[(i+1)*V-1 : i*V]),
        .reset(reset),
        .clk(clk),
        .ssa_ivc_num_getting_sw_grant(ssa_ivc_num_getting_sw_grant_all[(i+1)*V-1 : i*V]),
        .destport_clear(destport_clear_all[(i+1)*DSTPw*V-1 : i*DSTPw*V]),
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
    parameter T1= 8,
    parameter T2= 8,
    parameter T3= 8,
    parameter T4= 8,
    parameter RAw = 3,  
    parameter EAw = 3,  
    parameter C = 4,    //    number of flit class 
    parameter Fpay = 32,
    parameter SW_LOC = 0,
    parameter VC_REALLOCATION_TYPE =  "ATOMIC",
    parameter COMBINATION_TYPE= "BASELINE",// "BASELINE", "COMB_SPEC1", "COMB_SPEC2", "COMB_NONSPEC"
    parameter TOPOLOGY =  "MESH",//"MESH","TORUS"
    parameter ROUTE_NAME="XY",// "XY", "TRANC_XY"
    parameter ROUTE_TYPE="DETERMINISTIC",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter DEBUG_EN =1,
    parameter AVC_ATOMIC_EN= 0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1: 0] CLASS_SETTING = {CVw{1'b1}}, // shows how each class can use VCs   
    parameter [V-1  : 0] ESCAP_VC_MASK = 4'b1000,  // mask scape vc, valid only for full adaptive
    parameter DSTPw = P-1,
    parameter SSA_EN="YES", // "YES" , "NO"      
    parameter SWA_ARBITER_TYPE ="RRA",// "RRA","WRRA"
    parameter WEIGHTw=4,
    parameter WRRA_CONFIG_INDEX=0,
    parameter PPSw=4,
    parameter MIN_PCK_SIZE=2 //minimum packet size in flits. The minimum value is 1. 

)(
    current_r_addr,
    neighbors_r_addr,
    ivc_num_getting_sw_grant,// for non spec ivc_num_getting_first_sw_grant,
    any_ivc_sw_request_granted,
    flit_in,
    flit_in_we,
    reset_ivc,
    flit_is_tail,
    ivc_request,
    dest_port_encoded,
    dest_port,
    candidate_ovcs,
    flit_out,
    assigned_ovc_num,
    sel,
    port_pre_sel,
    swap_port_presel,
    reset,
    clk,
    nonspec_first_arbiter_granted_ivc,
    destport_clear,
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
        VDSTPw = V * DSTPw,
        Cw = (C>1)? log2(C): 1,
        Fw = 2+V+Fpay,   //flit width;    
        W = WEIGHTw,
        WP = W * P,
        P_1=P-1,
        VP_1 = V * P_1;    

    localparam
         /* verilator lint_off WIDTH */
         OFFSET = (B%MIN_PCK_SIZE)? 1 :0,
         NON_ATOM_PCKS =  (B>MIN_PCK_SIZE)?  (B/MIN_PCK_SIZE)+ OFFSET : 1,
         MAX_PCK = (VC_REALLOCATION_TYPE== "ATOMIC")?  1 : NON_ATOM_PCKS;// min packet size is two hence the max packet number in buffer is (B/2)
        /* verilator lint_on WIDTH */            

     localparam 
        ELw = log2(T3),
        VELw= V * ELw,
        PRAw= P * RAw;
   
 
    input reset, clk;
    input   [RAw-1 : 0] current_r_addr;
    input   [PRAw-1:  0]  neighbors_r_addr;
    input   [V-1 : 0] ivc_num_getting_sw_grant;
    input                      any_ivc_sw_request_granted;
    input   [Fw-1 : 0] flit_in;
    input                       flit_in_we;
    input   [V-1 : 0] reset_ivc;
    output  [V-1 : 0] flit_is_tail;
    output  [V-1 : 0] ivc_request;
    output  [VDSTPw-1 : 0] dest_port_encoded;
    output  [VP_1-1 : 0] dest_port;
    output  [VV-1 : 0] candidate_ovcs;
    output  [Fw-1 : 0] flit_out;
    input   [VV-1 : 0] assigned_ovc_num;
    input   [V-1 : 0] sel;    
    input   [V-1 : 0] nonspec_first_arbiter_granted_ivc;
    input   [V-1 : 0] ssa_ivc_num_getting_sw_grant;    
    input   [(DSTPw*V)-1 : 0] destport_clear;            
    output reg [WEIGHTw-1 : 0] iport_weight;
    output  [V-1 : 0] vc_weight_is_consumed;
    output  iport_weight_is_consumed;
    input   refresh_w_counter;
    input   [P_1-1 : 0] granted_dest_port; 
    output  [WP-1 : 0] oports_weight;  
    input   [PPSw-1 : 0] port_pre_sel;
    input   [V-1  : 0]  swap_port_presel;
  
            
    
    wire [Cw-1 : 0] class_in;
    wire [DSTPw-1 : 0] destport_in,destport_in_encoded;
    wire [VDSTPw-1 : 0] lk_destination_encoded;
    wire [EAw-1 : 0] dest_e_addr_in;
    wire [EAw-1 : 0] src_e_addr_in;
    wire [V-1 : 0] vc_num_in;
    wire [V-1 : 0] hdr_flit_wr,flit_wr;
    reg  [V-1 : 0] hdr_flit_wr_delayed;
    wire [V-1 : 0] class_rd_fifo,dst_rd_fifo;
    reg  [V-1 : 0] lk_dst_rd_fifo;
    wire [DSTPw-1 : 0] lk_destination_in_encoded;
    wire [WEIGHTw-1  : 0] weight_in;   
    wire [Fw-1 : 0] buffer_out;
    wire hdr_flg_in,tail_flg_in;  
    wire [V-1 : 0] ivc_not_empty;
    wire [Cw-1 : 0] class_out [V-1 : 0];
    wire  [VELw-1 : 0] endp_localp_num;
    wire [ELw-1 : 0] endp_l_in;
           

//extract header flit info
    extract_header_flit_info #(
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .V(V),
        .EAw(EAw),
        .DSTPw(DSTPw),
        .C(C),
        .Fpay(Fpay),
        .DATA_w(0)
     )
     header_extractor
     (
         .flit_in(flit_in),
         .flit_in_we(flit_in_we),         
         .class_o(class_in),
         .destport_o(destport_in),
         .dest_e_addr_o(dest_e_addr_in),
         .src_e_addr_o(src_e_addr_in ),
         .vc_num_o(vc_num_in),
         .hdr_flit_wr_o(hdr_flit_wr),
         .hdr_flg_o(hdr_flg_in),
         .tail_flg_o(tail_flg_in),
         .weight_o(weight_in),
         .data_o( )
     );
     
            
     
     
    // synopsys  translate_off
    // synthesis translate_off                                      
     `ifdef MONITORE_PATH
     
    genvar j;
    reg[V-1 :0] t1;
    generate
    for (j=0;j<V;j=j+1)begin : lp        
    always @(posedge clk) begin
        if(reset)begin 
             t1[j]<=1'b0;               
        end else begin 
            if(flit_in_we >0 && vc_num_in[j] && t1[j]==0)begin 
                $display("%t : Parser: class_in=%x, destport_in=%x, dest_e_addr_in=%x, src_e_addr_in=%x, vc_num_in=%x,hdr_flit_wr=%x, hdr_flg_in=%x,tail_flg_in=%x ",$time,class_in, destport_in, dest_e_addr_in, src_e_addr_in, vc_num_in,hdr_flit_wr, hdr_flg_in,tail_flg_in);
                t1[j]<=1;
            end           
        end
    end
    end
    endgenerate
    `endif
    // synthesis translate_on
    // synopsys  translate_on       
     
     
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
    /* verilator lint_off WIDTH */  
    if (( TOPOLOGY == "RING" || TOPOLOGY == "LINE" || TOPOLOGY == "MESH" || TOPOLOGY == "TORUS") && (T3>1)) begin : multi_local
    /* verilator lint_on WIDTH */  
        mesh_tori_endp_addr_decode #(
            .TOPOLOGY("MESH"),
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .EAw(EAw)
        )
        endp_addr_decode
        (
            .e_addr(dest_e_addr_in),
            .ex( ),
            .ey( ),
            .el(endp_l_in),
            .valid( )
        );
   end

    /* verilator lint_off WIDTH */  
    if(TOPOLOGY=="FATTREE" && ROUTE_NAME == "NCA_STRAIGHT_UP") begin : fat
    /* verilator lint_on WIDTH */  
     
     fattree_destport_up_select #(
         .K(T1),
         .SW_LOC(SW_LOC)
     )
     static_sel
     (
        .destport_in(destport_in),
        .destport_o(destport_in_encoded)
     );
     
    end else begin : other
        assign destport_in_encoded = destport_in;    
    end


      wire odd_column = current_r_addr[0]; 

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
            .din (tail_flg_in),
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
            .DATA_WIDTH(DSTPw),
            .MAX_DEPTH (MAX_PCK)
        )
        lk_dest_fifo
        (
             .din (lk_destination_in_encoded),
             .wr_en (hdr_flit_wr_delayed [i]),   // Write enable
             .rd_en (lk_dst_rd_fifo [i]),   // Read the next word
             .dout (lk_destination_encoded  [(i+1)*DSTPw-1 : i*DSTPw]),    // Data out
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
                 .DATA_WIDTH(DSTPw),
                 .MAX_DEPTH (MAX_PCK)
            )
            dest_fifo
            (
                 .din(destport_in_encoded),
                 .wr_en(hdr_flit_wr[i]),   // Write enable
                 .rd_en(dst_rd_fifo[i]),   // Read the next word
                 .dout(dest_port_encoded[(i+1)*DSTPw-1 : i*DSTPw]),    // Data out
                 .full(),
                 .nearly_full(),
                 .recieve_more_than_0(),
                 .recieve_more_than_1(),
                 .reset(reset),
                 .clk(clk) 
            );               
                         
        end else begin : adptv_dest   

            fwft_fifo_with_output_clear #(
                .DATA_WIDTH(DSTPw),
                .MAX_DEPTH (MAX_PCK)
            )
            dest_fifo
            (
                .din(destport_in_encoded),
                .wr_en(hdr_flit_wr[i]),   // Write enable
                .rd_en(dst_rd_fifo[i]),   // Read the next word
                .dout(dest_port_encoded[(i+1)*DSTPw-1 : i*DSTPw]),    // Data out
                .full(),
                .nearly_full(),
                .recieve_more_than_0(),
                .recieve_more_than_1(),
                .reset(reset),
                .clk(clk),
                .clear(destport_clear[(i+1)*DSTPw-1 : i*DSTPw])   // clear other destination ports once one of them is selected
            );                  
    
                
        end        	
        
                     
                     
        destp_generator #(
            .TOPOLOGY(TOPOLOGY),
            .ROUTE_NAME(ROUTE_NAME),
            .ROUTE_TYPE(ROUTE_TYPE),
            .T1(T1),
            .NL(T3),
            .P(P),
            .DSTPw(DSTPw),
            .ELw(ELw),
            .PPSw(PPSw),
            .SW_LOC(SW_LOC)
        )
        decoder
        (
            .dest_port_encoded(dest_port_encoded[(i+1)*DSTPw-1 : i*DSTPw]),             
            .dest_port_out(dest_port[(i+1)*P_1-1 : i*P_1]),   
            .endp_localp_num(endp_localp_num[(i+1)*ELw-1 : i*ELw]),
            .swap_port_presel(swap_port_presel[i]),
            .port_pre_sel(port_pre_sel),
            .odd_column(odd_column)
        );
         
         
         /* verilator lint_off WIDTH */  
        if (( TOPOLOGY == "RING" || TOPOLOGY == "LINE" || TOPOLOGY == "MESH" || TOPOLOGY == "TORUS") && (T3>1)) begin : multi_local
          /* verilator lint_on WIDTH */  
            // the router has multiple local ports. Save the destination local port 
                  
            
            fwft_fifo #(
                 .DATA_WIDTH(ELw),
                 .MAX_DEPTH (MAX_PCK)
            )
            local_dest_fifo
            (
                 .din(endp_l_in),
                 .wr_en(hdr_flit_wr[i]),   // Write enable
                 .rd_en(dst_rd_fifo[i]),   // Read the next word
                 .dout(endp_localp_num[(i+1)*ELw-1 : i*ELw]),    // Data out
                 .full( ),
                 .nearly_full( ),
                 .recieve_more_than_0(),
                 .recieve_more_than_1(),
                 .reset(reset),
                 .clk(clk) 
            );       
  
        end else begin : slp 
            assign endp_localp_num[(i+1)*ELw-1 : i*ELw] = {ELw{1'bx}}; 
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
    	.T1(T1),
        .T2(T2),
        .T3(T3),
        .T4(T4), 
        .P(P),       
        .RAw(RAw),  
        .EAw(EAw), 
    	.DSTPw(DSTPw),
    	.SW_LOC(SW_LOC),
    	.TOPOLOGY(TOPOLOGY),
    	.ROUTE_NAME(ROUTE_NAME),
    	.ROUTE_TYPE(ROUTE_TYPE)
    )
    lk_routing
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .dest_e_addr(dest_e_addr_in),
        .destport_encoded(destport_in_encoded),
        .lkdestport_encoded(lk_destination_in_encoded),
        .reset(reset),
        .clk(clk)
     );

    header_flit_update_lk_route_ovc #(
        .V(V),
        .P(P),
        .Fpay(Fpay),  
        .TOPOLOGY(TOPOLOGY),     
        .EAw(EAw),
        .DSTPw(DSTPw),
        .SSA_EN(SSA_EN),          
        .ROUTE_TYPE(ROUTE_TYPE)
    
    )
    the_flit_update
    (
        .flit_in (buffer_out),
        .flit_out (flit_out),
        .vc_num_in(ivc_num_getting_sw_grant),
        .lk_dest_all_in (lk_destination_encoded),
        .assigned_ovc_num (assigned_ovc_num),
        .any_ivc_sw_request_granted(any_ivc_sw_request_granted),
        .lk_dest_not_registered(lk_destination_in_encoded),
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
    assign    class_rd_fifo = (C>1)? reset_ivc : {V{1'bx}};
    assign    ivc_request = ivc_not_empty;    

//synthesis translate_off
//synopsys  translate_off
generate 
if(DEBUG_EN) begin :dbg

    debug_IVC_flit_type_order_check #(
    	.V(V)
    )
    IVC_flit_type_check
    (
    	.clk(clk),
    	.reset(reset),
    	.hdr_flg_in(hdr_flg_in),
    	.tail_flg_in(tail_flg_in),
    	.flit_in_we(flit_in_we),
    	.vc_num_in(vc_num_in),
    	.reset_all_errors(1'b0),
    	.active_IVC_hdr_flit_received_err( ),
    	.inactive_IVC_tail_flit_received_err( ),
    	.inactive_IVC_body_flit_received_err( )
    );

     /* verilator lint_off WIDTH */  
     if (( TOPOLOGY == "RING" || TOPOLOGY == "LINE" || TOPOLOGY == "MESH" || TOPOLOGY == "TORUS")) begin : mesh_based
     /* verilator lint_on WIDTH */  

        debug_mesh_tori_route_ckeck #(
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .ROUTE_TYPE(ROUTE_TYPE),
            .V(V),
            .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
            .SW_LOC(SW_LOC),
            .ESCAP_VC_MASK(ESCAP_VC_MASK),
            .TOPOLOGY(TOPOLOGY),
            .DSTPw(DSTPw),
            .RAw(RAw),
            .EAw(EAw)
        )
        route_ckeck
        (
            .reset(reset),
            .clk(clk),
            .hdr_flg_in(hdr_flg_in),
            .flit_in_we(flit_in_we),
            .vc_num_in(vc_num_in),
            .flit_is_tail(flit_is_tail),
            .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant),
            .current_r_addr(current_r_addr),
            .dest_e_addr_in(dest_e_addr_in),
            .src_e_addr_in(src_e_addr_in),
            .destport_in(destport_in)      
        );   
    end//mesh  
end//DEBUG_EN 
endgenerate 
//synopsys  translate_on  
//synthesis translate_on


endmodule





// decode and mask the destintaion port according to routing algorithm and topology
module destp_generator #(
    parameter TOPOLOGY="MESH",
    parameter ROUTE_NAME="XY",
    parameter ROUTE_TYPE="DETERMINISTIC",
    parameter T1=3,
    parameter NL=1,
    parameter P=5,
    parameter DSTPw=4,
    parameter ELw=1,
    parameter PPSw=4,
    parameter SW_LOC=0
    
)
(
    dest_port_encoded,             
    dest_port_out,   
    endp_localp_num,
    swap_port_presel,
    port_pre_sel,
    odd_column
);

    localparam P_1= P-1;
    input [DSTPw-1 : 0]  dest_port_encoded;             
    input [ELw-1 : 0] endp_localp_num;
    output [P_1-1: 0] dest_port_out;    
    input             swap_port_presel;
    input  [PPSw-1 : 0] port_pre_sel;
    input odd_column;
    
    generate
    /* verilator lint_off WIDTH */
    if(TOPOLOGY == "FATTREE" ) begin : fat
    /* verilator lint_on WIDTH */
      fattree_destp_generator #(
      	.K(T1),
      	.P(P),
      	.SW_LOC(SW_LOC),
      	.DSTPw(DSTPw)
      )
      destp_generator
      (
      	.dest_port_in_encoded(dest_port_encoded),
      	.dest_port_out(dest_port_out)
      );
    /* verilator lint_off WIDTH */ 
    end else  if (TOPOLOGY == "TREE") begin :tree
    /* verilator lint_on WIDTH */
        tree_destp_generator #(
            .K(T1),
            .P(P),
            .SW_LOC(SW_LOC),
            .DSTPw(DSTPw)
          )
          destp_generator
          (
            .dest_port_in_encoded(dest_port_encoded),
            .dest_port_out(dest_port_out)
          );    
    
   end else begin : mesh
    
        mesh_torus_destp_generator #(
        	.TOPOLOGY(TOPOLOGY),
        	.ROUTE_NAME(ROUTE_NAME),
        	.ROUTE_TYPE(ROUTE_TYPE),
        	.P(P),
        	.DSTPw(DSTPw),
        	.NL(NL),
        	.ELw(ELw),
        	.PPSw(PPSw),
        	.SW_LOC(SW_LOC)
        )
        destp_generator
        (
        	.dest_port_coded(dest_port_encoded),
        	.endp_localp_num(endp_localp_num),
        	.dest_port_out(dest_port_out),
        	.swap_port_presel(swap_port_presel),
        	.port_pre_sel(port_pre_sel),
        	.odd_column(odd_column)// only needed for od even routing
        );
    
    end
    endgenerate
endmodule
