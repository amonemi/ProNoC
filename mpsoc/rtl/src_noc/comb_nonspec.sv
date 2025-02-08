`include "pronoc_def.v"

/**********************************************************************
**    File: comb-nonspec.v
**    
**    Copyright (C) 2014-2017  Alireza Monemi
**    
**    This file is part of ProNoC 
**
**    ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**    you can redistribute it and/or modify it under the terms of the GNU
**    Lesser General Public License as published by the Free Software Foundation,
**    either version 2 of the License, or (at your option) any later version.
**
**     ProNoC is distributed in the hope that it will be useful, but WITHOUT
**     ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
**     or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
**     Public License for more details.
**
**     You should have received a copy of the GNU Lesser General Public
**     License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
**
**
**    Description: 
**    VC allocator combined with non-speculative switch
**    allocator where the free VC availability is checked at
**    the beginning of switch allocation (comb-nonspec).        
**
***********************************************************************/    

module comb_nonspec_allocator # (
    parameter NOC_ID = 0,
    parameter P = 5 //port number
)(
    //VC allocator
    //input 
    dest_port_all,         // from input port
    masked_ovc_request_all,
    pck_is_single_flit_all,    
    
    //output 
    ovc_allocated_all,//to the output port
    granted_ovc_num_all, // to the input port
    ivc_num_getting_ovc_grant,
    
    //switch_alloc
    ivc_info,   
    vc_weight_is_consumed_all,
    iport_weight_is_consumed_all,
    
    //output
    granted_dest_port_all,
    ivc_num_getting_sw_grant,
    nonspec_first_arbiter_granted_ivc_all,
    any_ivc_sw_request_granted_all,
    any_ovc_granted_in_outport_all,
    granted_dst_is_from_a_single_flit_pck,
    
    // global
    clk,
    reset
);
    
    `NOC_CONF
    
    localparam
        P_1 = (SELF_LOOP_EN == "NO")? P-1 : P,
        PV = V * P,
        VV = V * V,
        VP_1 = V * P_1,                
        PP_1 = P_1 * P,
        PVV = PV * V,
        PVP_1 = PV * P_1;            
    input  ivc_info_t ivc_info [P-1 : 0][V-1 : 0]; 
    input  [PVV-1 : 0] masked_ovc_request_all;
    input  [PVP_1-1 : 0] dest_port_all;
    input  [PV-1 : 0] pck_is_single_flit_all;
    output [PV-1 : 0] ovc_allocated_all;
    output [PVV-1 : 0] granted_ovc_num_all;
    output [PV-1 : 0] ivc_num_getting_ovc_grant;
    output [PP_1-1 : 0] granted_dest_port_all;
    output [PV-1 : 0] ivc_num_getting_sw_grant;
    output [P-1 : 0] any_ivc_sw_request_granted_all;
    output [P-1 : 0] any_ovc_granted_in_outport_all;
    output [PV-1 : 0] nonspec_first_arbiter_granted_ivc_all;
    input  clk,reset;
    input  [PV-1 : 0] vc_weight_is_consumed_all;
    input  [P-1 : 0] iport_weight_is_consumed_all;
    output [P-1 : 0] granted_dst_is_from_a_single_flit_pck;
    
    //internal wires switch allocator
    wire  [PV-1 : 0] first_arbiter_granted_ivc_all;
    wire  [PV-1 : 0] ivc_request_masked_all;
    wire  [P-1 : 0] any_cand_ovc_exsit;    
    wire  [PV-1 : 0] ivc_request_all;
    wire  [PV-1 : 0] ovc_is_assigned_all;
    wire  [PV-1 : 0] assigned_ovc_not_full_all;    
    
    assign nonspec_first_arbiter_granted_ivc_all = first_arbiter_granted_ivc_all;
    
    //nonspeculative switch allocator 
    nonspec_sw_alloc #(
        .V(V),
        .P(P),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .SWA_ARBITER_TYPE (SWA_ARBITER_TYPE),
        .MIN_PCK_SIZE(MIN_PCK_SIZE),
        .SELF_LOOP_EN(SELF_LOOP_EN)
    ) nonspeculative_sw_allocator (
        .ivc_granted_all (ivc_num_getting_sw_grant),
        .ivc_request_masked_all (ivc_request_masked_all),
        .pck_is_single_flit_all(pck_is_single_flit_all),
        .granted_dst_is_from_a_single_flit_pck(granted_dst_is_from_a_single_flit_pck),
        .dest_port_all (dest_port_all),
        .granted_dest_port_all (granted_dest_port_all),
        .first_arbiter_granted_ivc_all (first_arbiter_granted_ivc_all),
        .any_ivc_granted_all (any_ivc_sw_request_granted_all),
        .any_ovc_granted_all (any_ovc_granted_in_outport_all),
        .vc_weight_is_consumed_all(vc_weight_is_consumed_all),
        .iport_weight_is_consumed_all(iport_weight_is_consumed_all),
        .clk (clk),
        .reset (reset)    
    );
    
    wire   [PVV-1 : 0] masked_ovc_request_all;
    wire   [V-1 : 0] masked_non_assigned_request [PV-1 : 0] ;    
    wire   [PV-1 : 0] masked_assigned_request;
    wire   [PV-1 : 0] assigned_ovc_request_all ;
    wire   [VV-1 : 0] masked_candidate_ovc_per_port [P-1 : 0] ;
    wire   [V-1 : 0] first_arbiter_granted_ivc_per_port[P-1 : 0] ;
    wire   [V-1 : 0] candidate_ovc_local_num [P-1 : 0] ;
    wire   [V-1 : 0] first_arbiter_ovc_granted [PV-1 : 0];
    wire   [P_1-1 : 0] granted_dest_port_per_port [P-1 : 0];
    wire   [VP_1-1 : 0] cand_ovc_granted [P-1 : 0];
    wire   [P_1-1 : 0] ovc_allocated_all_gen  [PV-1 : 0];
    wire   [V-1 : 0] granted_ovc_local_num_per_port [P-1 : 0];
    wire   [V-1 : 0] ivc_local_num_getting_ovc_grant[P-1 : 0];
    wire   [V : 0] summ_in [PV-1 : 0];
    wire   [V-1 : 0]  vc_pririty [PV-1 : 0] ;
    
    assign assigned_ovc_request_all =   ivc_request_all &   ovc_is_assigned_all;
        
    genvar i,j;    
    generate 
    // IVC loop
    for(i=0;i< PV;i=i+1) begin :PV_      
        // mask unavailable ovc from requests
        assign masked_non_assigned_request [i] = masked_ovc_request_all [(i+1)*V-1 : i*V ];
        assign masked_assigned_request [i] = assigned_ovc_not_full_all [i] & assigned_ovc_request_all [i]; 
        // summing assigned and non-assigned VC requests
        assign summ_in[i] ={masked_non_assigned_request [i], masked_assigned_request [i]};
        assign ivc_request_masked_all[i] = | summ_in[i];        
        //first level arbiter to candidate only one OVC 
        //if(VC_ARBITER_TYPE=="RRA")begin :round_robin
        arbiter #(
            .ARBITER_WIDTH(V)
        ) ovc_arbiter (    
            .clk (clk), 
            .reset (reset), 
            .request (masked_non_assigned_request    [i]), 
            .grant (first_arbiter_ovc_granted[i]),
            .any_grant()
        );
    end//for
    
    wire [P-1 : 0] ovc_assigned_local;
    
    for(i=0;i< P;i=i+1) begin :P_
        for(j=0;j< V;j=j+1) begin :V_
            //merge masked_candidate_ovc in each port
            assign ivc_request_all[i*V+j] = ivc_info[i][j].ivc_req;
            assign ovc_is_assigned_all[i*V+j] = ivc_info[i][j].ovc_is_assigned;  
            assign assigned_ovc_not_full_all[i*V+j] =ivc_info[i][j].assigned_ovc_not_full;           
            assign masked_candidate_ovc_per_port[i][(j+1)*V-1 : j*V] = first_arbiter_ovc_granted [i*V+j];
            assign granted_ovc_num_all[(i*VV)+((j+1)*V)-1 : (i*VV)+(j*V)]=granted_ovc_local_num_per_port[i];
        end//for j
        
        assign first_arbiter_granted_ivc_per_port[i]=first_arbiter_granted_ivc_all[(i+1)*V-1 : i*V];
        assign granted_dest_port_per_port[i]=granted_dest_port_all[(i+1)*P_1-1 : i*P_1];
        
        // multiplex candidate OVC of first level switch allocatore winner    
        onehot_mux_1D #(
            .W(V),
            .N(V)
        ) mux2 (
            .in(masked_candidate_ovc_per_port[i]),
            .out(candidate_ovc_local_num[i]),
            .sel(first_arbiter_granted_ivc_per_port[i])
        );
        
        onehot_mux_1D #(
            .W (1),
            .N (V)
        ) mux2_1 (
            .in  (ovc_is_assigned_all[(i+1)*V-1 : i*V]),
            .out (ovc_assigned_local[i]),
            .sel (first_arbiter_granted_ivc_per_port [i])            
        );
        
        //demultiplexer        
        one_hot_demux #(
            .IN_WIDTH(V),
            .SEL_WIDTH(P_1)
        )demux1 (
            .demux_sel(granted_dest_port_per_port [i]),//selectore
            .demux_in(candidate_ovc_local_num[i]),//repeated
            .demux_out(cand_ovc_granted [i])
        );
        
        assign granted_ovc_local_num_per_port[i] = (any_ivc_sw_request_granted_all[i] )?  candidate_ovc_local_num[i] : {V{1'b0}};
        assign ivc_local_num_getting_ovc_grant [i] = (any_ivc_sw_request_granted_all[i] & ~ovc_assigned_local[i])?     first_arbiter_granted_ivc_per_port [i] : {V{1'b0}};
        assign ivc_num_getting_ovc_grant   [(i+1)*V-1 : i*V] = ivc_local_num_getting_ovc_grant[i];
        
    end//i
    
    for(i=0;i< PV;i=i+1) begin :_PV
        for(j=0;j<P;    j=j+1)begin: P_
            if(SELF_LOOP_EN == "NO") begin 
                if((i/V)<j )begin
                    assign ovc_allocated_all_gen[i][j-1] = cand_ovc_granted[j][i];
                end else if((i/V)>j) begin
                    assign ovc_allocated_all_gen[i][j] = cand_ovc_granted[j][i-V];
                end
            end else begin
                assign ovc_allocated_all_gen[i][j] = cand_ovc_granted[j][i];            
            end
        end//j
        assign ovc_allocated_all [i] = |ovc_allocated_all_gen[i];
    end//i
    endgenerate  
endmodule    

/**************************************************************
*             comb_nonspec_v2
* first arbiter has been shifted after first multiplexer            
*
*********************************************************/
module  comb_nonspec_v2_allocator #(
    parameter V = 4,
    parameter P = 5,
    parameter FIRST_ARBITER_EXT_P_EN = 1,
    parameter SWA_ARBITER_TYPE = "WRRA",
    parameter MIN_PCK_SIZE=2, //minimum packet size in flits. The minimum value is 1.
    parameter SELF_LOOP_EN= "NO"
)(
    //VC allocator
    //input    
    dest_port_all,      // from input port
    ovc_is_assigned_all,    // 
    masked_ovc_request_all,
    pck_is_single_flit_all,
    
    //output 
    ovc_allocated_all,//to the output port
    granted_ovc_num_all, // to the input port
    ivc_num_getting_ovc_grant,
    
    //switch_alloc
    ivc_request_all,
    assigned_ovc_not_full_all,
    vc_weight_is_consumed_all,
    iport_weight_is_consumed_all,
    
    //output
    granted_dest_port_all,
    ivc_num_getting_sw_grant,
    nonspec_first_arbiter_granted_ivc_all,
    any_ivc_sw_request_granted_all,
    any_ovc_granted_in_outport_all,
    granted_dst_is_from_a_single_flit_pck,
    
    // global
    clk,
    reset
);
    localparam
        P_1 = (SELF_LOOP_EN == "NO") ?  P-1 :P,
        PV = V * P,
        VV = V * V,
        VP_1 = V * P_1,                
        PP_1 = P_1 * P,
        PVV = PV * V,
        PVP_1 = PV * P_1;    
        
    input   [PVV-1 : 0] masked_ovc_request_all;
    input   [PVP_1-1 : 0] dest_port_all;
    input   [PV-1 : 0] ovc_is_assigned_all;
    input   [PV-1 : 0] pck_is_single_flit_all;
    output  [PV-1 : 0] ovc_allocated_all;
    output  [PVV-1 : 0] granted_ovc_num_all;
    output  [PV-1 : 0] ivc_num_getting_ovc_grant;
    input   [PV-1 : 0] ivc_request_all;
    input   [PV-1 : 0] assigned_ovc_not_full_all;
    output  [PP_1-1 : 0] granted_dest_port_all;
    output  [PV-1 : 0] ivc_num_getting_sw_grant;
    output  [P-1 : 0] any_ivc_sw_request_granted_all;
    output  [P-1 : 0] any_ovc_granted_in_outport_all;
    output  [PV-1 : 0] nonspec_first_arbiter_granted_ivc_all;
    input   clk,reset;
    input   [PV-1 : 0] vc_weight_is_consumed_all;
    input   [P-1 : 0] iport_weight_is_consumed_all;
    output  [P-1 : 0] granted_dst_is_from_a_single_flit_pck;
    //internal wires switch allocator
    wire    [PV-1 : 0] first_arbiter_granted_ivc_all;
    wire    [PV-1 : 0] ivc_request_masked_all;
    wire    [P-1 : 0] any_cand_ovc_exsit;
    
    assign nonspec_first_arbiter_granted_ivc_all = first_arbiter_granted_ivc_all;
    
    //nonspeculative switch allocator    
    nonspec_sw_alloc #(
        .V(V),
        .P(P),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .MIN_PCK_SIZE(MIN_PCK_SIZE) 
    ) nonspeculative_sw_allocator (
        .ivc_granted_all (ivc_num_getting_sw_grant),
        .ivc_request_masked_all (ivc_request_masked_all),
        .pck_is_single_flit_all(pck_is_single_flit_all),
        .granted_dst_is_from_a_single_flit_pck(granted_dst_is_from_a_single_flit_pck),
        .dest_port_all  (dest_port_all),
        .granted_dest_port_all (granted_dest_port_all),
        .first_arbiter_granted_ivc_all (first_arbiter_granted_ivc_all),
        //.first_arbiter_granted_port_all   (first_arbiter_granted_port_all),
        .any_ivc_granted_all (any_ivc_sw_request_granted_all),
        .any_ovc_granted_all (any_ovc_granted_in_outport_all),
        .vc_weight_is_consumed_all(vc_weight_is_consumed_all),
        .iport_weight_is_consumed_all(iport_weight_is_consumed_all),
        .clk  (clk),
        .reset (reset)
    );
    
    wire    [V-1 : 0] masked_non_assigned_request [PV-1 : 0] ;   
    wire    [PV-1 : 0] masked_assigned_request;
    wire    [PV-1 : 0] assigned_ovc_request_all;
    wire    [VV-1 : 0] masked_non_assigned_request_per_port [P-1 : 0] ;
    wire    [V-1 : 0] first_arbiter_granted_ivc_per_port[P-1 : 0] ;
    wire    [V-1 : 0] candidate_ovc_local_num     [P-1 : 0] ;
    wire    [V-1 : 0] first_arbiter_ovc_granted [P-1:0];
    wire    [P_1-1 : 0] granted_dest_port_per_port  [P-1 : 0];
    wire    [VP_1-1 : 0] cand_ovc_granted    [P-1 : 0];
    wire    [P_1-1 : 0] ovc_allocated_all_gen   [PV-1 : 0];
    wire    [V-1 : 0] granted_ovc_local_num_per_port [P-1 : 0];
    wire    [V-1 : 0] ivc_local_num_getting_ovc_grant[P-1 : 0];
    wire    [V : 0] summ_in   [PV-1 : 0];
    
    assign assigned_ovc_request_all =   ivc_request_all &   ovc_is_assigned_all;
    genvar i,j;
    generate 
    // IVC loop
    for(i=0;i< PV;i=i+1) begin :PV_
        // mask unavailable ovc from requests
        assign masked_non_assigned_request  [i]  =   masked_ovc_request_all [(i+1)*V-1 : i*V ];
        assign masked_assigned_request      [i]  =   assigned_ovc_not_full_all[i] & assigned_ovc_request_all[i]; 
        // summing assigned and non-assigned VC requests
        assign summ_in[i]  ={masked_non_assigned_request   [i],masked_assigned_request     [i]};
        assign ivc_request_masked_all[i] = | summ_in[i];
    end//for
    
    for(i=0;i< P;i=i+1) begin : P_
        for(j=0;j< V;j=j+1) begin : V_
            //merge masked_candidate_ovc in each port
            assign masked_non_assigned_request_per_port[i][(j+1)*V-1 : j*V] =           masked_non_assigned_request [i*V+j];
            assign granted_ovc_num_all[(i*VV)+((j+1)*V)-1 : (i*VV)+(j*V)]=granted_ovc_local_num_per_port[i];
        end//for j
        assign first_arbiter_granted_ivc_per_port[i]=first_arbiter_granted_ivc_all[(i+1)*V-1 : i*V];
        assign granted_dest_port_per_port[i]=granted_dest_port_all[(i+1)*P_1-1 : i*P_1];
        
        onehot_mux_1D #(
            .W(V),
            .N(V)
        ) mux2 (
            .in (masked_non_assigned_request_per_port [i]),
            .out (candidate_ovc_local_num [i]),
            .sel (first_arbiter_granted_ivc_per_port [i])
        );
        
        assign any_cand_ovc_exsit[i] = | candidate_ovc_local_num    [i];
        //first level arbiter to candidate only one OVC 
        arbiter #(
            .ARBITER_WIDTH (V)
        ) arbiter1 (   
            .clk (clk), 
            .reset (reset), 
            .request (candidate_ovc_local_num[i]), 
            .grant (first_arbiter_ovc_granted[i]),
            .any_grant ( )
        );
        
        //demultiplexer
        one_hot_demux   #(
            .IN_WIDTH (V),
            .SEL_WIDTH (P_1)
        ) demux1 (
            .demux_sel (granted_dest_port_per_port [i]),//selectore
            .demux_in (first_arbiter_ovc_granted[i]),//repeated
            .demux_out (cand_ovc_granted [i])
        );  
        
        assign granted_ovc_local_num_per_port   [i]=(any_ivc_sw_request_granted_all[i] )?  first_arbiter_ovc_granted[i] : {V{1'b0}};
        assign ivc_local_num_getting_ovc_grant  [i]= (any_ivc_sw_request_granted_all[i] & any_cand_ovc_exsit[i])?   first_arbiter_granted_ivc_per_port [i] : {V{1'b0}};
        assign ivc_num_getting_ovc_grant   [(i+1)*V-1 : i*V] = ivc_local_num_getting_ovc_grant[i];
        
    end//i  
    
    for(i=0;i< PV;i=i+1) begin :total_vc_loop2
        for(j=0;j<P;    j=j+1)begin: assign_loop2
            if((i/V)<j )begin: jj
                assign ovc_allocated_all_gen[i][j-1] = cand_ovc_granted[j][i];
            end else if((i/V)>j) begin: hh
                assign ovc_allocated_all_gen[i][j] = cand_ovc_granted[j][i-V];
            end
        end//j
        assign ovc_allocated_all [i] = |ovc_allocated_all_gen[i];
    end//i
    endgenerate
    
endmodule   

/********************************************
*
*    nonspeculative switch allocator
*
******************************************/
module nonspec_sw_alloc #(
    parameter V = 4,
    parameter P = 5,
    parameter FIRST_ARBITER_EXT_P_EN = 1, 
    parameter SWA_ARBITER_TYPE = "WRRA",
    parameter MIN_PCK_SIZE=2, //minimum packet size in flits. The minimum value is 1.
    parameter SELF_LOOP_EN="NO"
)(
    ivc_granted_all,
    ivc_request_masked_all,
    pck_is_single_flit_all,
    granted_dst_is_from_a_single_flit_pck,
    dest_port_all,
    granted_dest_port_all,
    first_arbiter_granted_ivc_all,
    //first_arbiter_granted_port_all,
    any_ivc_granted_all,
    any_ovc_granted_all,
    vc_weight_is_consumed_all,
    iport_weight_is_consumed_all,
    clk,
    reset
);
    
    localparam
        P_1 = (SELF_LOOP_EN== "NO") ? P-1 : P,
        PV = V * P,
        VP_1 = V * P_1,                
        PP_1 = P_1 * P,
        PVP_1 = PV * P_1,
        PP = P*P;  
    
    output [PV-1 : 0] ivc_granted_all;
    output [P-1 : 0] granted_dst_is_from_a_single_flit_pck;
    input  [PV-1 : 0] ivc_request_masked_all;
    input  [PV-1 : 0] pck_is_single_flit_all;
    input  [PVP_1-1 : 0] dest_port_all;
    output [PP_1-1 : 0] granted_dest_port_all;
    output [PV-1 : 0] first_arbiter_granted_ivc_all;
    //output [PP_1-1 : 0] first_arbiter_granted_port_all;
    output [P-1 : 0] any_ivc_granted_all; //any ivc is granted in input  port [i]
    output [P-1 : 0] any_ovc_granted_all; //any ovc is granted in output port [i]
    input  clk, reset;
    input [PV-1 : 0] vc_weight_is_consumed_all;
    input [P-1: 0] iport_weight_is_consumed_all;
    
    //separte input per port
    wire [V-1 : 0] ivc_granted        [P-1 : 0];
    wire [V-1 : 0] pck_is_single_flit [P-1 : 0];  
    wire [VP_1-1 : 0] dest_port_ivc       [P-1 : 0];
    wire [P_1-1 : 0] granted_dest_port  [P-1 : 0];
    wire [P_1-1 : 0] single_flit_granted_dst [P-1 : 0];
    wire [PP-1 : 0] single_flit_granted_dst_all;
    
    // internal wires
    wire    [V-1 : 0] ivc_masked     [P-1 : 0];//output of mask and             
    wire    [V-1 : 0] first_arbiter_grant     [P-1 : 0];//output of first arbiter 
    wire    [P-1 : 0] single_flit_pck_local_grant;           
    wire    [P_1-1 : 0] dest_port      [P-1 : 0];//output of multiplexer
    wire    [P_1-1 : 0] second_arbiter_request  [P-1 : 0]; 
    wire    [P_1-1 : 0] second_arbiter_grant    [P-1 : 0]; 
    wire    [P_1-1 : 0] second_arbiter_weight_consumed [P-1 : 0]; 
    wire    [V-1 : 0] vc_weight_is_consumed [P-1 : 0]; 
    wire    [P-1    :0] winner_weight_consumed;            
    
    genvar i,j;
    generate
    
    for(i=0;i< P;i=i+1) begin : P_
        //assign in/out to the port based wires
        //output
        assign ivc_granted_all [(i+1)*V-1 : i*V] =   ivc_granted [i];
        assign granted_dest_port_all    [(i+1)*P_1-1 : i*P_1]   =   granted_dest_port[i];
        assign first_arbiter_granted_ivc_all[(i+1)*V-1 : i*V]=           first_arbiter_grant[i];
        //input 
        assign ivc_masked[i]  = ivc_request_masked_all [(i+1)*V-1 : i*V];
        assign dest_port_ivc[i]  = dest_port_all [(i+1)*VP_1-1 : i*VP_1];
        assign vc_weight_is_consumed[i]  =  vc_weight_is_consumed_all [(i+1)*V-1 : i*V];
        
        //first level arbiter
        swa_input_port_arbiter #(
            .ARBITER_WIDTH(V),
            .EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
            .ARBITER_TYPE(SWA_ARBITER_TYPE)
        ) input_arbiter (
            .ext_pr_en_i(any_ivc_granted_all[i]),
            .request(ivc_masked [i]),
            .grant(first_arbiter_grant[i]),
            .any_grant( ),
            .clk(clk),
            .reset(reset),
            .vc_weight_is_consumed(vc_weight_is_consumed[i]),
            .winner_weight_consumed(winner_weight_consumed[i])
        );
        //destination port multiplexer
        onehot_mux_1D #(
            .W (P_1),
            .N (V)
        ) mux (
            .in (dest_port_ivc [i]),
            .out (dest_port[i]),
            .sel(first_arbiter_grant[i])    
        );
        
        if(MIN_PCK_SIZE == 1) begin       
            //single_flit req multiplexer
            assign pck_is_single_flit[i] = pck_is_single_flit_all [(i+1)*V-1 : i*V];
            onehot_mux_1D #(
                .W (1),
                .N (V)
            ) mux2 (
                .in (pck_is_single_flit  [i]),
                .out (single_flit_pck_local_grant[i]),
                .sel (first_arbiter_grant[i])
            );   
            
            assign  single_flit_granted_dst[i] = (single_flit_pck_local_grant[i])?  granted_dest_port[i] : {P_1{1'b0}};
            
            if (SELF_LOOP_EN == "NO") begin 
                add_sw_loc_one_hot #(
                    .P(P),
                    .SW_LOC(i)
                ) add_sw_loc (
                    .destport_in(single_flit_granted_dst[i]),
                    .destport_out(single_flit_granted_dst_all[(i+1)*P-1 : i*P])
                );
            end else begin 
                assign single_flit_granted_dst_all[(i+1)*P-1 : i*P] = single_flit_granted_dst[i];
            end
            
        end else begin 
            assign single_flit_pck_local_grant[i] = 1'bx;
            assign single_flit_granted_dst[i] = {P_1{1'bx}};
            assign single_flit_granted_dst_all[(i+1)*P-1 : i*P]={P{1'b0}};
        end
        //second arbiter input/output generate
        for(j=0;j<P;    j=j+1)begin: P_
            if (SELF_LOOP_EN == "NO") begin 
                if(i<j) begin
                    assign second_arbiter_request[i][j-1]  = dest_port[j][i];
                    //assign second_arbiter_weight_consumed[i][j-1]  =winner_weight_consumed[j] ;
                    assign second_arbiter_weight_consumed[i][j-1]  =iport_weight_is_consumed_all[j] ;
                    assign granted_dest_port[j][i] = second_arbiter_grant  [i][j-1] ;
                end else if(i>j)begin
                    assign second_arbiter_request[i][j] = dest_port [j][i-1] ;
                    //assign second_arbiter_weight_consumed[i][j]  =winner_weight_consumed[j];
                    assign second_arbiter_weight_consumed[i][j]  =iport_weight_is_consumed_all[j];
                    assign granted_dest_port[j][i-1] = second_arbiter_grant  [i][j] ;
                end
                //if(i==j) wires are left disconnected 
            end else begin 
                assign second_arbiter_request[i][j]  = dest_port[j][i];
                assign second_arbiter_weight_consumed[i][j]  =iport_weight_is_consumed_all[j] ;
                assign granted_dest_port[j][i] = second_arbiter_grant  [i][j] ;        
            end
        end //P_
        //second level arbiter 
        swa_output_port_arbiter #(
            .ARBITER_WIDTH(P_1),
            .ARBITER_TYPE(SWA_ARBITER_TYPE) // RRA, WRRA
        ) output_arbiter (
            .weight_consumed(second_arbiter_weight_consumed[i]),  // only used for WRRA
            .clk(clk), 
            .reset(reset), 
            .request(second_arbiter_request [i]), 
            .grant(second_arbiter_grant [i]),
            .any_grant(any_ovc_granted_all [i])  
        );
        //any ivc 
        assign  any_ivc_granted_all[i] = | granted_dest_port[i];
        assign  ivc_granted[i] =  (any_ivc_granted_all[i]) ? first_arbiter_grant[i] : {V{1'b0}};
        
    end//for P_
    endgenerate 
    
    custom_or #(
            .IN_NUM(P),
            .OUT_WIDTH(P)
    ) or_dst (
        .or_in(single_flit_granted_dst_all),
        .or_out(granted_dst_is_from_a_single_flit_pck)
    );
endmodule


/*******************
*    swa_input_port_arbiter
*
********************/
module swa_input_port_arbiter #(
    parameter ARBITER_WIDTH =4,
    parameter EXT_P_EN = 1,
    parameter ARBITER_TYPE = "WRRA"// RRA, WRRA
)(
    ext_pr_en_i,  // it is used only if the EXT_P_EN is 1
    clk, 
    reset, 
    request, 
    grant,
    any_grant,
    vc_weight_is_consumed, // only for WRRA
    winner_weight_consumed // only for WRRA
);
    input ext_pr_en_i;
    input [ARBITER_WIDTH-1 : 0] request;
    output[ARBITER_WIDTH-1 : 0] grant;
    output any_grant;
    input  clk;
    input  reset;
    input  [ARBITER_WIDTH-1 : 0] vc_weight_is_consumed;
    output winner_weight_consumed;
    
    generate 
    /* verilator lint_off WIDTH */
    if(ARBITER_TYPE != "RRA") begin: wrra_
    /* verilator lint_on WIDTH */
        // one hot mux    
        onehot_mux_1D #(
            .W(1),
            .N(ARBITER_WIDTH)            
        ) mux (
            .in(vc_weight_is_consumed),
            .out(winner_weight_consumed),
            .sel(grant)
        );
        
        wire priority_en = (EXT_P_EN == 1) ? ext_pr_en_i & winner_weight_consumed : winner_weight_consumed;
        
        //round robin arbiter with external priority
        arbiter_priority_en #(
            .ARBITER_WIDTH(ARBITER_WIDTH)
        ) rra (
            .request(request),
            .grant(grant),
            .any_grant(any_grant),
            .clk(clk),
            .reset(reset),
            .priority_en(priority_en)
        );
    end else begin : rra_m //RRA
        assign winner_weight_consumed = 1'bx;
        if(EXT_P_EN==1) begin : arbiter_ext_en
            
            arbiter_priority_en #(
                .ARBITER_WIDTH (ARBITER_WIDTH)
            )
            arb
            (   
                .clk (clk), 
                .reset (reset), 
                .request (request), 
                .grant (grant),
                .any_grant (any_grant ),
                .priority_en (ext_pr_en_i)        
            );
        end else  begin: first_lvl_arbiter_internal_en
            arbiter #(
                .ARBITER_WIDTH (ARBITER_WIDTH)
            ) arb(   
                .clk (clk), 
                .reset (reset), 
                .request (request), 
                .grant (grant),
                .any_grant (any_grant )
            );
            
        end//else
    end
    endgenerate
endmodule

/*******************
*    swa_output_port_arbiter
*
********************/
module swa_output_port_arbiter #(
    parameter ARBITER_WIDTH =4,
    parameter ARBITER_TYPE = "WRRA" // RRA, WRRA
)(
    weight_consumed,  // only used for WRRA
    clk, 
    reset, 
    request, 
    grant,
    any_grant  
);
    
    input     [ARBITER_WIDTH-1  :    0]    request;
    output    [ARBITER_WIDTH-1  :    0]    grant;
    output                                 any_grant;
    input                                  clk;
    input                                  reset;
    input    [ARBITER_WIDTH-1  :    0]     weight_consumed;
    
    generate 
    /* verilator lint_off WIDTH */
    if(ARBITER_TYPE == "WRRA") begin : wrra_mine
    /* verilator lint_on WIDTH */
        // second level wrra priority is only changed if the granted request weight is consumed 
        wire pr_en;
        
        onehot_mux_1D #(
            .W(1),
            .N(ARBITER_WIDTH)
        ) mux (
            .in(weight_consumed),
            .out(pr_en),
            .sel(grant)
        );
        
        arbiter_priority_en #(
            .ARBITER_WIDTH (ARBITER_WIDTH)
        ) arb  (   
            .clk (clk), 
            .reset (reset), 
            .request (request), 
            .grant (grant),
            .any_grant (any_grant ),
            .priority_en (pr_en)        
        );
        
     /* verilator lint_off WIDTH */
    end else if(ARBITER_TYPE == "WRRA_CLASSIC") begin : wrra_classic 
    /* verilator lint_on WIDTH */
        // use classic WRRA. only for compasrion with propsoed wrra 
        
        wire  [ARBITER_WIDTH-1  :    0] masked_req=       request & ~weight_consumed;
        wire sel = |masked_req;
        wire  [ARBITER_WIDTH-1  :    0] mux_req = (sel==1'b1)? masked_req : request;
        
        arbiter #(
            .ARBITER_WIDTH  (ARBITER_WIDTH )
        ) arb  (   
            .clk (clk), 
            .reset (reset), 
            .request (mux_req), 
            .grant (grant),
            .any_grant (any_grant )
        );
    end else begin : rra_m   
        
        arbiter #(
            .ARBITER_WIDTH  (ARBITER_WIDTH )
        ) arb  (   
            .clk (clk), 
            .reset (reset), 
            .request (request), 
            .grant (grant),
            .any_grant (any_grant )
        );
        
    end
    endgenerate
endmodule