`timescale     1ns/1ps
 /**********************************************************************
**	File: baseline.v
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
**
**	Description: 
**	baseline allocators:
**	Canonical VC allocator and speculative switch allocator  
**  Not recommended to use
*************************************/

    
module baseline_allocator #(
    parameter V = 4,// Virtual channel num per port
    parameter P = 5,//port number
    parameter TREE_ARBITER_EN = 0,
    parameter DEBUG_EN = 1,
    parameter SWA_ARBITER_TYPE = "WRRA"
)
(
    dest_port_all,
    ovc_is_assigned_all,
    ivc_request_all,
    assigned_ovc_not_full_all,
    ovc_allocated_all,
    granted_ovc_num_all,
    ivc_num_getting_ovc_grant,
    ivc_num_getting_sw_grant,
    spec_first_arbiter_granted_ivc_all,
    nonspec_first_arbiter_granted_ivc_all,
    granted_dest_port_all,
    nonspec_granted_dest_port_all,
    spec_granted_dest_port_all,
    any_ivc_sw_request_granted_all,
    spec_ovc_num_all,
    masked_ovc_request_all,
    vc_weight_is_consumed_all,
    iport_weight_is_consumed_all,
    clk,reset
);

    localparam 
        PV = V * P,
        PVV = PV * V,   
        P_1 = P-1,
        PP_1 = P_1 * P,
        PVP_1 = PV * P_1;                   
                    
    input  [PVP_1-1:   0]    dest_port_all;    
    input  [PV-1:   0]    ovc_is_assigned_all;
    input  [PV-1:   0]  ivc_request_all;
    input  [PV-1:   0]  assigned_ovc_not_full_all;
    input  [PV-1 : 0] vc_weight_is_consumed_all;
    input  [P-1 : 0] iport_weight_is_consumed_all;
    
    output [PV-1:   0] ovc_allocated_all;
    output [PVV-1:   0] granted_ovc_num_all;
    output [PV-1:   0] ivc_num_getting_ovc_grant;
    output [PV-1:   0] ivc_num_getting_sw_grant;
    output [PV-1:   0] nonspec_first_arbiter_granted_ivc_all;
    output [PV-1:   0] spec_first_arbiter_granted_ivc_all;
        
    output [PP_1-1:   0] granted_dest_port_all;
    output [PP_1-1:   0] nonspec_granted_dest_port_all;
    output [PP_1-1:   0] spec_granted_dest_port_all;
    output [P-1:   0] any_ivc_sw_request_granted_all;
    output [PVV-1:   0] spec_ovc_num_all;
    input  [PVV-1:  0] masked_ovc_request_all;
    input  clk,reset;

    
    wire [V-1:   0] spec_first_arbiter_granted_ivc    [P-1:   0];
    wire [V-1:   0] ivc_local_num_getting_ovc_grant  [P-1:   0];
    wire [P-1:   0] valid_speculation;
     
       
    
    
    // canonical VC allocator
    canonical_vc_alloc #(
        .TREE_ARBITER_EN(TREE_ARBITER_EN),
        .V(V),
        .P(P)
    )
    the_canonical_VC_allocator
    (
        .granted_ovc_num_all(granted_ovc_num_all),
        .ovc_allocated_all  (ovc_allocated_all),
        .ivc_num_getting_ovc_grant (ivc_num_getting_ovc_grant),
        .masked_ovc_request_all (masked_ovc_request_all),
        .dest_port_all (dest_port_all),
        .spec_ovc_num_all (spec_ovc_num_all),
        .clk (clk),
        .reset (reset)
    );
            
    //speculative switch allocator 
    spec_sw_alloc_can #(
        .V(V),
        .P(P),
        .DEBUG_EN (DEBUG_EN),
        .SWA_ARBITER_TYPE (SWA_ARBITER_TYPE)
    )
    speculative_sw_allocator
    (
        .ivc_granted_all (ivc_num_getting_sw_grant),
        .ivc_request_all (ivc_request_all),
        .ovc_is_assigned_all (ovc_is_assigned_all),
        .assigned_ovc_not_full_all (assigned_ovc_not_full_all),
        .dest_port_all (dest_port_all),
        .granted_dest_port_all (granted_dest_port_all),
        .nonspec_granted_dest_port_all (nonspec_granted_dest_port_all),
        .spec_granted_dest_port_all (spec_granted_dest_port_all),
        .valid_speculation (valid_speculation),
        .spec_first_arbiter_granted_ivc_all (spec_first_arbiter_granted_ivc_all),
        .nonspec_first_arbiter_granted_ivc_all (nonspec_first_arbiter_granted_ivc_all),
        .any_ivc_sw_request_granted_all (any_ivc_sw_request_granted_all),
        .vc_weight_is_consumed_all(vc_weight_is_consumed_all),
        .iport_weight_is_consumed_all(iport_weight_is_consumed_all),
        .clk (clk),
        .reset (reset)    
    );
    
    // check valid speculation
    genvar i;
    generate 
    for(i=0;i<P; i=i+1) begin :valid_chek_lp    
    
        assign spec_first_arbiter_granted_ivc[i] = spec_first_arbiter_granted_ivc_all[(i+1)*V-1:   i*V];
        assign ivc_local_num_getting_ovc_grant[i] = ivc_num_getting_ovc_grant [(i+1)*V-1:   i*V];
        
        //speculative VC request multiplexer
        one_hot_mux #(
            .IN_WIDTH (V),
            .SEL_WIDTH (V)
        )
        multiplexer
        (
            .mux_in (ivc_local_num_getting_ovc_grant [i]),
            .mux_out (valid_speculation [i]),
            .sel (spec_first_arbiter_granted_ivc [i])
        );      
    
    end//for
    endgenerate


endmodule



/***********************************
*
*
*    canonical VC allocator
*
*
************************************/



module canonical_vc_alloc #(
    parameter TREE_ARBITER_EN = 1,
    parameter V = 4,
    parameter P = 5
)
(
    granted_ovc_num_all,
    ivc_num_getting_ovc_grant,
    ovc_allocated_all,
    dest_port_all,
    masked_ovc_request_all,
    spec_ovc_num_all,
    clk,
    reset    
);


    localparam  
        P_1 = P-1,//assumed that no port request for itself!
        PV  = V * P,
        PVV = PV * V,
        PVP_1 = PV * P_1,
        VP_1 = V * P_1;
        
    //input/output
    output [PVV-1:  0]  granted_ovc_num_all;
    output [PV-1:  0]  ovc_allocated_all;
    output [PV-1:  0] ivc_num_getting_ovc_grant;
    input  [PVV-1:  0]  masked_ovc_request_all;
    input  [PVP_1-1:  0]  dest_port_all;
    output [PVV-1:  0]  spec_ovc_num_all;
    input  clk,reset;
    
    wire    [V-1:  0]  ovc_granted_ivc [PV-1:  0]  ;
    wire    [P_1-1: 0]  dest_port_ivc  [PV-1:  0]  ;
    wire    [V-1:  0]  masked_ovc_request [PV-1:  0]  ;
    wire    [V-1:  0] first_arbiter_grant [PV-1:  0]  ;
    wire    [VP_1-1 : 0]  ovc_demuxed  [PV-1:  0]  ;
    wire    [VP_1-1 : 0]  second_arbiter_request  [PV-1:  0]  ;
    wire    [VP_1-1 : 0]  second_arbiter_grant [PV-1:  0]  ;
    wire    [VP_1-1 : 0]  granted_ovc_array [PV-1:  0]  ;
    genvar i,j;
        
    
    generate
    
       
    // IVC loop
    for(i=0;i< PV;i=i+1) begin :total_vc_loop
       //seprate input/output
       assign granted_ovc_num_all    [(i+1)*V-1:  i*V ] = ovc_granted_ivc[i] ;
       assign masked_ovc_request     [i]  = masked_ovc_request_all[(i+1)*V-1:  i*V ];
       assign dest_port_ivc   [i]    =   dest_port_all [(i+1)*P_1-1:  i*P_1   ];
       
       //first level arbiter
       arbiter #(
        .ARBITER_WIDTH  (V)
       )first_arbiter
       (    
        .clk        (clk), 
        .reset       (reset), 
        .request       (masked_ovc_request  [i]), 
        .grant       (first_arbiter_grant[i]),
        .any_grant   ()
       );
       
       assign spec_ovc_num_all[(i+1)*V-1 :i*V]   = first_arbiter_grant[i];
       //demultiplexer
       
       one_hot_demux    #(
        .IN_WIDTH   (V),
        .SEL_WIDTH  (P_1)
       )demux
       (
        .demux_sel  (dest_port_ivc [i]),//selectore
        .demux_in   (first_arbiter_grant[i]),//repeated
        .demux_out  (ovc_demuxed[i])
       );
       
       //second arbiter input/output generate
       

       for(j=0;j<PV;    j=j+1)begin: assign_loop2
        if((i/V)<(j/V))begin: jj
              assign second_arbiter_request[i][j-V] = ovc_demuxed[j][i] ;
              assign granted_ovc_array[j][i]    = second_arbiter_grant  [i][j-V]    ;
        end else if((i/V)>(j/V)) begin: hh
              assign second_arbiter_request[i][j]   = ovc_demuxed[j][i-V]   ;
              assign granted_ovc_array[j][i-V]  = second_arbiter_grant  [i][j]  ;
        end
        //if(i==j)  s are left disconnected  
       
       end
    
       
       //second level arbiter 
       if(TREE_ARBITER_EN) begin :tree 
        tree_arbiter #(
              .GROUP_NUM (P_1),
              .ARBITER_WIDTH (VP_1)
        )
        second_arbiter
        (   
              .clk (clk), 
              .reset (reset), 
              .request (second_arbiter_request[i]), 
              .grant (second_arbiter_grant  [i]),
              .any_grant (ovc_allocated_all[i])
        );
       end else begin :arb
        arbiter #(
              .ARBITER_WIDTH    (VP_1)
        )
        second_arbiter
        (   
              .clk (clk), 
              .reset (reset), 
              .request (second_arbiter_request[i]), 
              .grant (second_arbiter_grant  [i]),
              .any_grant (ovc_allocated_all[i])
        );
       end
       
       custom_or #(
        .IN_NUM (P_1),
        .OUT_WIDTH (V)
        
       )
       or_gate
       (
        .or_in  (granted_ovc_array[i]),
        .or_out (ovc_granted_ivc[i])
       );
       
       assign ivc_num_getting_ovc_grant[i]  =   |ovc_granted_ivc[i];
       
    end//for
    endgenerate
    
endmodule  


 /*************************************
 
            spec_sw_alloc_can
    speculative switch allocator for baseline             
 
 *************************************/   
    
    
    
module spec_sw_alloc_can #(
    parameter V = 4,
    parameter P = 5,
    parameter DEBUG_EN = 1,
    parameter SWA_ARBITER_TYPE = "WRRA"
)(
    ivc_granted_all,
    ivc_request_all,
    ovc_is_assigned_all,
    assigned_ovc_not_full_all,
    dest_port_all,
    granted_dest_port_all,
    nonspec_granted_dest_port_all,
    spec_granted_dest_port_all,
    valid_speculation,
    spec_first_arbiter_granted_ivc_all,
    nonspec_first_arbiter_granted_ivc_all,
    any_ivc_sw_request_granted_all,
    vc_weight_is_consumed_all,
    iport_weight_is_consumed_all,
    clk,
    reset    
);


    localparam  
        P_1 = P-1,//assumed that no port request for itself!
        PV  = V * P,
        VP_1 = V * P_1,                
        PVP_1 = P * VP_1,   
        PP_1 = P_1* P;
                    
    output [PV-1:  0]  ivc_granted_all;
    input  [PV-1:  0] ivc_request_all;
    input  [PV-1:  0] ovc_is_assigned_all;
    input  [PV-1:  0] assigned_ovc_not_full_all;
    input  [PVP_1-1:  0]  dest_port_all;
    output [PP_1-1:  0]  granted_dest_port_all;
    output [PP_1-1:  0]  nonspec_granted_dest_port_all;
    output [PP_1-1:  0]  spec_granted_dest_port_all;
    input  [P-1:  0]  valid_speculation;
    output [PV-1:  0]  spec_first_arbiter_granted_ivc_all;
    output [PV-1:  0]  nonspec_first_arbiter_granted_ivc_all;
    output [P-1:  0] any_ivc_sw_request_granted_all;
    input  [PV-1 : 0 ] vc_weight_is_consumed_all;
    input  [P-1:0] iport_weight_is_consumed_all;
    input clk, reset;  
    

    //internal wire 
    wire  [PV-1:  0]  spec_ivc_granted_all,nonspec_ivc_granted_all;
    wire  [PV-1:  0] spec_ivc_request_all,nonspec_ivc_request_all;
    wire  [PV-1:  0] spec_assigned_ovc_not_full_all,nonspec_assigned_ovc_not_full_all;
    wire  [PVP_1-1:  0]  spec_dest_port_all,nonspec_dest_port_all;
    wire  [PP_1-1:  0]  spec_granted_dest_port_all_pre;
    wire  [PP_1-1:  0] nonspec_granted_dest_port_all_pre;
    wire  [PP_1-1:  0] spec_granted_dest_port_all_accepted;
    wire  [P-1:  0]  nonspec_inport_granted_all,nonspec_outport_granted_all;
    
    
    wire    [P_1-1:  0]  nonspec_portsel_granted [P-1:  0];
    wire    [PP_1-1:  0]  spec_request_acceptable;
    wire  [P_1-1:  0]  spec_request_accepted [P-1:  0];
    wire  [P-1:  0]  any_spec_request_accepted;
    wire    [PV-1:  0]  spec_ivc_granted_all_accepted;
    wire    [P-1:  0] nonspec_any_ivc_grant,spec_any_ivc_grant;
    wire    [P-1:  0] spec_any_ivc_grant_valid;
    
        
    
    sw_alloc_sub#(
        .V(V),
        .P(P),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE)     
    )
    speculative_alloc
    (
        .ivc_granted_all (spec_ivc_granted_all),
        .ivc_request_all (spec_ivc_request_all),
        .assigned_ovc_not_full_all (spec_assigned_ovc_not_full_all),
        .dest_port_all (spec_dest_port_all),
        .granted_dest_port_all (spec_granted_dest_port_all_pre),
        .inport_granted_all  ( ),
        .outport_granted_all ( ),
        .first_arbiter_granted_ivc_all  (spec_first_arbiter_granted_ivc_all),
        .first_arbiter_granted_port_all ( ),
        .any_ivc_grant (spec_any_ivc_grant),
        .vc_weight_is_consumed_all (vc_weight_is_consumed_all),
        .iport_weight_is_consumed_all(iport_weight_is_consumed_all),
        .clk (clk),
        .reset (reset) 
    );

    

    sw_alloc_sub#(
        .V (V),
        .P (P),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE)
    )
    nonspeculative_alloc
    (

        .ivc_granted_all(nonspec_ivc_granted_all),
        .ivc_request_all(nonspec_ivc_request_all),
        .assigned_ovc_not_full_all(nonspec_assigned_ovc_not_full_all),
        .dest_port_all(nonspec_dest_port_all),
        .granted_dest_port_all(nonspec_granted_dest_port_all_pre),
        .inport_granted_all(nonspec_inport_granted_all),
        .outport_granted_all(nonspec_outport_granted_all),
        .first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all),
        .first_arbiter_granted_port_all(),
        .any_ivc_grant(nonspec_any_ivc_grant),
        .vc_weight_is_consumed_all (vc_weight_is_consumed_all),
        .iport_weight_is_consumed_all(iport_weight_is_consumed_all),
        .clk (clk),
        .reset(reset)
    
    );
        
    assign nonspec_ivc_request_all              = ivc_request_all &  ovc_is_assigned_all;
    assign spec_ivc_request_all                 = ivc_request_all &  ~ovc_is_assigned_all;
    assign spec_assigned_ovc_not_full_all       = {PV{1'b1}};
    assign nonspec_assigned_ovc_not_full_all    = assigned_ovc_not_full_all;    
    assign spec_dest_port_all                       = dest_port_all;
    assign nonspec_dest_port_all                    = dest_port_all;
    
    genvar i,j;
    generate 
    for(i=0;i<P; i=i+1) begin :port_lp
        //remove non-spec inport from the nonspec_outport_granted_all
        for(j=0;j<P;    j=j+1)begin: port_loop2
            if(i<j)begin: jj
                assign nonspec_portsel_granted[i][j-1]  = nonspec_outport_granted_all[j];
            end else if(i>j)begin: hh
                assign nonspec_portsel_granted[i][j]        = nonspec_outport_granted_all [j];
            end
            //if(i==j) wires are left disconnected  
        end//j
        // an speculative grant is acceptable if the non-speculative request is not granted for both inport request and outport grant
        assign spec_request_acceptable  [(i+1)*P_1-1:  i*P_1] = (nonspec_inport_granted_all[i])? {P_1{1'b0}} : ~nonspec_portsel_granted[i];
        assign spec_request_accepted    [i]= spec_request_acceptable[(i+1)*P_1-1:  i*P_1] & spec_granted_dest_port_all_pre[(i+1)*P_1-1:  i*P_1];
        assign any_spec_request_accepted [i] = |spec_request_accepted  [i];
        assign spec_ivc_granted_all_accepted[(i+1)*V-1:  i*V] = (any_spec_request_accepted [i] & valid_speculation[i])? spec_ivc_granted_all[(i+1)*V-1:  i*V]: {V{1'b0}};
        assign spec_granted_dest_port_all_accepted[(i+1)*P_1-1:  i*P_1]=valid_speculation[i]? (spec_request_acceptable[(i+1)*P_1-1:  i*P_1] & spec_granted_dest_port_all_pre[(i+1)*P_1-1:  i*P_1]): {P_1{1'b0}};
        
    //synthesis translate_off
    //synopsys  translate_off

        if(DEBUG_EN)begin :dbg
            always @(posedge clk) begin 
                if(nonspec_granted_dest_port_all[(i+1)*P_1-1:  i*P_1] >0 && spec_granted_dest_port_all_accepted[(i+1)*P_1-1:  i*P_1]>0 ) $display("%t: Error: Both speculative and nonspeculative is granted for one port",$time);
                if(nonspec_ivc_granted_all [(i+1)*V-1:  i*V] >0 && spec_ivc_granted_all_accepted[(i+1)*V-1:  i*V]>0 ) $display("%t: Error: Both speculative and nonspeculative is granted for one port",$time);
            end
        end
    //synopsys  translate_on
    //synthesis translate_on
    
    
    end//i
    endgenerate
    
    assign spec_any_ivc_grant_valid  = any_spec_request_accepted & valid_speculation & spec_any_ivc_grant;
    assign any_ivc_sw_request_granted_all = nonspec_any_ivc_grant | spec_any_ivc_grant_valid;
    assign granted_dest_port_all = nonspec_granted_dest_port_all_pre | spec_granted_dest_port_all_accepted;
    assign ivc_granted_all = nonspec_ivc_granted_all  | spec_ivc_granted_all_accepted;    
    assign nonspec_granted_dest_port_all = nonspec_granted_dest_port_all_pre;
    assign spec_granted_dest_port_all = spec_granted_dest_port_all_accepted;
    
endmodule
 
    

