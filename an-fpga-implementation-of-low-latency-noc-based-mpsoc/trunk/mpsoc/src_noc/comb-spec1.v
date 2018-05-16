`timescale    1ns/1ps

/**********************************************************************
**	File: comb_spec1.v
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
**	VC allocator combined with speculative switch allo-
**	cator where free VC availability is checked at the end
**	of switch allocation (comb-spec1).
**
***********************************************************************/    
    
module comb_spec1_allocator #(
    parameter V = 4,// Virtual channel num per port
    parameter P = 5,
    parameter DEBUG_EN = 1,
    parameter SWA_ARBITER_TYPE = "WRRA"
)(    
        dest_port_all,
        masked_ovc_request_all,
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
        any_ivc_sw_request_granted_all,
        vc_weight_is_consumed_all,
        iport_weight_is_consumed_all,
        clk,reset

);

    localparam 
        PV = V * P,
        VV = V * V,
        PVV = PV * V,   
        P_1 = P-1,
        VP_1 = V * P_1,                
        PP_1 = P_1 * P,
        PVP_1 = PV * P_1;
                    
                    
    input  [PVP_1-1 : 0] dest_port_all; 
    input  [PVV-1 : 0] masked_ovc_request_all; 
    input  [PV-1 : 0] ovc_is_assigned_all;
    input  [PV-1 : 0] ivc_request_all;
    input  [PV-1 : 0] assigned_ovc_not_full_all;
    input  [PV-1 : 0] vc_weight_is_consumed_all;
    input  [P-1 : 0] iport_weight_is_consumed_all;
    
    output [PV-1 : 0] ovc_allocated_all;
    output [PVV-1 : 0] granted_ovc_num_all;
    output [PV-1 : 0] ivc_num_getting_ovc_grant;
    output [PV-1 : 0] ivc_num_getting_sw_grant;
    output [PV-1 : 0] nonspec_first_arbiter_granted_ivc_all;
    output [PV-1 : 0] spec_first_arbiter_granted_ivc_all;
        
    output [PP_1-1 : 0]  granted_dest_port_all;
    output [PP_1-1 : 0]  nonspec_granted_dest_port_all; 
    output [P-1 : 0] any_ivc_sw_request_granted_all;
    
    input clk,reset;

    
    
    

    //internal wires switch allocator
    
    wire    [PV-1 : 0]  spec_first_arbiter_granted_ivc_all;
    wire    [PP_1-1 : 0]  spec_granted_dest_port_all;
    wire    [P-1 : 0] spec_any_ivc_grant_valid;
    wire    [P-1 : 0]  valid_speculation;
   
    
    
    //speculative switch allocator 
    spec_sw_alloc #(
        .V(V),
        .P(P),
        .DEBUG_EN(DEBUG_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE)
    )
    speculative_sw_allocator
    (

        .ivc_granted_all(ivc_num_getting_sw_grant),
        .ivc_request_all(ivc_request_all),
        .ovc_is_assigned_all(ovc_is_assigned_all),
        .assigned_ovc_not_full_all(assigned_ovc_not_full_all),
        .dest_port_all(dest_port_all),
        .granted_dest_port_all(granted_dest_port_all),
        .nonspec_granted_dest_port_all(nonspec_granted_dest_port_all),
        .valid_speculation(valid_speculation),
        .spec_first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all),
        .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all),
        .spec_granted_dest_port_all(spec_granted_dest_port_all),
        .spec_any_ivc_grant_valid(spec_any_ivc_grant_valid),
        .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all),
        .vc_weight_is_consumed_all(vc_weight_is_consumed_all),
        .iport_weight_is_consumed_all(iport_weight_is_consumed_all),
        .clk(clk),
        .reset(reset)
    
    );
      
    wire    [V-1 : 0]  masked_non_assigned_request [PV-1 : 0]  ;   
    wire    [VV-1 : 0]  masked_candidate_ovc_per_port   [P-1 : 0]  ;
    wire    [V-1 : 0]  spec_first_arbiter_granted_ivc_per_port[P-1 : 0]  ;
    wire    [V-1 : 0]  spec_first_arbiter_ovc_request  [P-1 : 0]  ;
    wire    [V-1 : 0]  spec_first_arbiter_ovc_granted  [P-1 : 0]  ;
    wire    [P_1-1 : 0]  spec_granted_dest_port_per_port [P-1 : 0];
    wire    [VP_1-1 : 0] cand_ovc_granted                     [P-1 : 0];
    wire    [P_1-1 : 0]  ovc_allocated_all_gen               [PV-1 : 0];
    wire    [V-1 : 0]  granted_ovc_local_num_per_port  [P-1 : 0];
    wire    [V-1 : 0]  ivc_local_num_getting_ovc_grant [P-1 : 0];
     
    genvar i,j;
    generate 
 
    
    // IVC loop
    for(i=0;i< PV;i=i+1) begin :total_vc_loop
        //seprate input/output
        assign masked_non_assigned_request    [i]     =   masked_ovc_request_all [(i+1)*V-1 : i*V ];
            
    end//for
    
    
    for(i=0;i< P;i=i+1) begin :port_loop3
            for(j=0;j< V;j=j+1) begin :vc_loop
                //merge masked_candidate_ovc in each port
                assign masked_candidate_ovc_per_port[i][(j+1)*V-1 : j*V]    =   masked_non_assigned_request [i*V+j];
            end//for j
            
            assign spec_first_arbiter_granted_ivc_per_port[i]   =spec_first_arbiter_granted_ivc_all[(i+1)*V-1 : i*V];
            assign spec_granted_dest_port_per_port[i]               =spec_granted_dest_port_all[(i+1)*P_1-1 : i*P_1];
            // multiplex candidate OVC of first level switch allocatore winner
            
        one_hot_mux #(
            .IN_WIDTH       (VV),
            .SEL_WIDTH      (V)
        )
        multiplexer2
        (
            .mux_in         (masked_candidate_ovc_per_port  [i]),
            .mux_out            (spec_first_arbiter_ovc_request [i]),
            .sel                (spec_first_arbiter_granted_ivc_per_port        [i])

        );
            
        //first level arbiter to candidate only one OVC 
        arbiter #(
            .ARBITER_WIDTH  (V)            
        )
        second_arbiter
        (   
            .clk            (clk), 
            .reset      (reset), 
            .request        (spec_first_arbiter_ovc_request[i]), 
            .grant      (spec_first_arbiter_ovc_granted[i]),
            .any_grant   (valid_speculation[i])
        );
    
        
        //demultiplexer
        
        one_hot_demux   #(
            .IN_WIDTH   (V),
            .SEL_WIDTH  (P_1)
        )demux1
        (
            .demux_sel  (spec_granted_dest_port_per_port [i]),//selectore
            .demux_in   (spec_first_arbiter_ovc_granted[i]),//repeated
            .demux_out  (cand_ovc_granted[i])
        );
    
        
        assign granted_ovc_local_num_per_port[i]=(spec_any_ivc_grant_valid[i])?  spec_first_arbiter_ovc_granted[i] : {V{1'b0}};
        assign ivc_local_num_getting_ovc_grant[i]= (spec_any_ivc_grant_valid[i] & valid_speculation[i])?spec_first_arbiter_granted_ivc_per_port [i] : {V{1'b0}};
        assign ivc_num_getting_ovc_grant[(i+1)*V-1 : i*V] = ivc_local_num_getting_ovc_grant[i];
        for(j=0;j<V;    j=j+1)begin: assign_loop3
            assign granted_ovc_num_all[(i*VV)+((j+1)*V)-1 : (i*VV)+(j*V)]=granted_ovc_local_num_per_port[i];
        end//j
    end//i
    

    wire [PV-1 : 0]  result;
    for(i=0;i< PV;i=i+1) begin :total_vc_loop2
        for(j=0;j<P;    j=j+1)begin: assign_loop2
            if((i/V)<j )begin: jj
                assign ovc_allocated_all_gen[i][j-1]    = cand_ovc_granted[j][i];
            end else if((i/V)>j) begin: hh
                assign ovc_allocated_all_gen[i][j]  = cand_ovc_granted[j][i-V];
                
            end
        end//j
        
        assign ovc_allocated_all [i] = |ovc_allocated_all_gen[i];
        
    //synthesis translate_off
    //synopsys  translate_off
    if(DEBUG_EN)begin :dbg
    
        check_single_bit_assertation #(
            .IN_WIDTH(P_1)
        )
        check_ovc_allocated
        (
            .in(ovc_allocated_all_gen[i]),
            .result(result[i])
    
        );
    
        always @(posedge clk ) begin 
            if(~result[i]) $display("%t,Error: An OVC is assigned to more than one IVC %m",$time);
        end
    end //DEBUG_EN
    //synopsys  translate_on
    //synthesis translate_on

    end//i   
    
    endgenerate
    
endmodule 



/******************************
*
*    speculative switch allocator
*
******************************/

        
    
module spec_sw_alloc #(
    parameter V = 4,
    parameter P = 5,
    parameter DEBUG_EN = 1,
    parameter SWA_ARBITER_TYPE="RRA"   

)(

    ivc_granted_all,
    ivc_request_all,
    ovc_is_assigned_all,
    assigned_ovc_not_full_all,
    dest_port_all,
    nonspec_granted_dest_port_all,
    granted_dest_port_all,
    valid_speculation,
    spec_first_arbiter_granted_ivc_all,
    nonspec_first_arbiter_granted_ivc_all,
    spec_granted_dest_port_all,
    spec_any_ivc_grant_valid,
    any_ivc_sw_request_granted_all,
    vc_weight_is_consumed_all, 
    iport_weight_is_consumed_all,   
    clk,
    reset
    
);


    localparam  
        P_1 = P-1,//assumed that no port request for itself!
        PV = V * P,
        VP_1 = V * P_1,                
        PVP_1 = P * VP_1,   
        PP_1 = P_1 * P;

    output  [PV-1 : 0]  ivc_granted_all;
    input   [PV-1 : 0] ivc_request_all;
    input   [PV-1 : 0] ovc_is_assigned_all;
    input   [PV-1 : 0] assigned_ovc_not_full_all;
    input   [PVP_1-1 : 0]  dest_port_all;
    output  [PP_1-1 : 0]  granted_dest_port_all;
    output  [PP_1-1 : 0]  nonspec_granted_dest_port_all;
    input   [P-1 : 0]  valid_speculation;
    output  [PV-1 : 0]  spec_first_arbiter_granted_ivc_all;
    output  [PV-1 : 0]  nonspec_first_arbiter_granted_ivc_all;
    output  [PP_1-1 : 0]  spec_granted_dest_port_all;
    output  [P-1 : 0]  spec_any_ivc_grant_valid;
    output  [P-1 : 0]  any_ivc_sw_request_granted_all;
    input   [PV-1 :   0] vc_weight_is_consumed_all;
    input   [P-1 : 0] iport_weight_is_consumed_all;
    input   clk, reset;
    
    

    //internal wire 
    wire    [PV-1 : 0]  spec_ivc_granted_all,nonspec_ivc_granted_all;
    wire    [PV-1 : 0] spec_ivc_request_all,nonspec_ivc_request_all;
    wire    [PV-1 : 0] spec_assigned_ovc_not_full_all,nonspec_assigned_ovc_not_full_all;
    wire    [PVP_1-1 : 0]  spec_dest_port_all,nonspec_dest_port_all;
    wire    [PP_1-1 : 0]  spec_granted_dest_port_all,spec_granted_dest_port_all_accepted;
    wire    [P-1 : 0]  nonspec_inport_granted_all,nonspec_outport_granted_all;
    wire    [PP_1-1 : 0]  spec_granted_dest_port_all_pre;
    
    wire    [P_1-1 : 0]  nonspec_portsel_granted [P-1 : 0];
    wire    [PP_1-1 : 0]  spec_request_acceptable;
    wire    [P_1-1 : 0]  spec_request_accepted [P-1 : 0];
    wire    [P-1 : 0]  any_spec_request_accepted;
    wire    [PV-1 : 0]  spec_ivc_granted_all_accepted;
    wire    [P-1 : 0]  spec_any_ivc_grant,nonspec_any_ivc_grant;
    
    
    sw_alloc_sub#(
        .V(V),
        .P(P),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE)
            
    )
    speculative_alloc
    (
        .ivc_granted_all(spec_ivc_granted_all),
        .ivc_request_all(spec_ivc_request_all),
        .assigned_ovc_not_full_all(spec_assigned_ovc_not_full_all),
        .dest_port_all(spec_dest_port_all),
        .granted_dest_port_all(spec_granted_dest_port_all_pre),
        .first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all),
        .first_arbiter_granted_port_all( ),
        .any_ivc_grant (spec_any_ivc_grant),
        .vc_weight_is_consumed_all(vc_weight_is_consumed_all),
        .iport_weight_is_consumed_all(iport_weight_is_consumed_all),
        .inport_granted_all ( ),
        .outport_granted_all( ),
        .clk (clk),
        .reset (reset) 
    );


    sw_alloc_sub#(
        .V(V),
        .P(P),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE) 
    )
    nonspeculative_alloc
    (
        .ivc_granted_all (nonspec_ivc_granted_all),
        .ivc_request_all (nonspec_ivc_request_all),
        .assigned_ovc_not_full_all (nonspec_assigned_ovc_not_full_all),
        .dest_port_all (nonspec_dest_port_all),
        .granted_dest_port_all (nonspec_granted_dest_port_all),
        .inport_granted_all (nonspec_inport_granted_all),
        .outport_granted_all (nonspec_outport_granted_all),
        .first_arbiter_granted_ivc_all (nonspec_first_arbiter_granted_ivc_all),
        .first_arbiter_granted_port_all ( ),
        .any_ivc_grant (nonspec_any_ivc_grant),
        .vc_weight_is_consumed_all (vc_weight_is_consumed_all),
        .iport_weight_is_consumed_all(iport_weight_is_consumed_all),
        .clk (clk),
        .reset (reset)   
    );
    
    assign nonspec_ivc_request_all      = ivc_request_all &  ovc_is_assigned_all;
    assign spec_ivc_request_all         = ivc_request_all &  ~ovc_is_assigned_all;
    assign spec_assigned_ovc_not_full_all           = {PV{1'b1}};
    assign nonspec_assigned_ovc_not_full_all        = assigned_ovc_not_full_all;    
    assign spec_dest_port_all               = dest_port_all;
    assign nonspec_dest_port_all            = dest_port_all;
    
   
    
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
        assign spec_request_acceptable[(i+1)*P_1-1 : i*P_1] = (nonspec_inport_granted_all[i])? {P_1{1'b0}} : ~nonspec_portsel_granted[i];
        assign spec_request_accepted  [i]= spec_request_acceptable[(i+1)*P_1-1 : i*P_1] & spec_granted_dest_port_all_pre[(i+1)*P_1-1 : i*P_1];
        assign any_spec_request_accepted [i] = |spec_request_accepted  [i];
        assign spec_ivc_granted_all_accepted[(i+1)*V-1 : i*V] = (any_spec_request_accepted [i] & valid_speculation[i])? spec_ivc_granted_all[(i+1)*V-1 : i*V]: {V{1'b0}};
        assign spec_granted_dest_port_all_accepted[(i+1)*P_1-1 : i*P_1]=(valid_speculation[i])? spec_request_accepted  [i]: {P_1{1'b0}};
    
    //synthesis translate_off
    //synopsys  translate_off
        if(DEBUG_EN)begin :dbg
            wire [P_1-1 : 0]  nonspec_check [P-1:0];
            wire [P_1-1 : 0]  spec_check [P-1:0];
            assign nonspec_check[i] = nonspec_granted_dest_port_all[(i+1)*P_1-1 : i*P_1];
            assign spec_check[i]= spec_granted_dest_port_all_accepted[(i+1)*P_1-1 : i*P_1];
            always @(posedge clk) begin 
                if(nonspec_granted_dest_port_all[(i+1)*P_1-1 : i*P_1] >0 && spec_granted_dest_port_all_accepted[(i+1)*P_1-1 : i*P_1]>0 ) $display("%t: Error: Both speculative and nonspeculative is granted for one port",$time);
                if(nonspec_ivc_granted_all [(i+1)*V-1 : i*V] >0 && spec_ivc_granted_all_accepted[(i+1)*V-1 : i*V]>0 ) $display("%t: Error: Both speculative and nonspeculative is granted for one port",$time);
            end
        end //DEBUG
    //synthesis translate_on
    //synopsys  translate_on
    
    
    end//i
    endgenerate
    
    assign spec_any_ivc_grant_valid = any_spec_request_accepted & valid_speculation & spec_any_ivc_grant;
    assign any_ivc_sw_request_granted_all = nonspec_any_ivc_grant | spec_any_ivc_grant_valid;    
    
    assign granted_dest_port_all = nonspec_granted_dest_port_all | spec_granted_dest_port_all_accepted;
    assign ivc_granted_all = nonspec_ivc_granted_all | spec_ivc_granted_all_accepted;
    assign spec_granted_dest_port_all = spec_granted_dest_port_all_accepted;    
    
endmodule

/**********************************
*
*    canonical switch allocator
*
**********************************/

    
module sw_alloc_sub#(
    parameter V = 4,
    parameter P = 5,
    parameter SWA_ARBITER_TYPE="RRA"      

)(
    ivc_granted_all,
    ivc_request_all,
    assigned_ovc_not_full_all,
    dest_port_all,
    granted_dest_port_all,
    inport_granted_all,
    outport_granted_all,
    first_arbiter_granted_ivc_all,
    first_arbiter_granted_port_all,
    vc_weight_is_consumed_all, 
    iport_weight_is_consumed_all,
    any_ivc_grant,
    clk,
    reset    
);


    localparam  
        P_1 = P-1,//assumed that no port request for itself!
        PV = V * P,
        VP_1 = V * P_1,                
        PVP_1 = P * VP_1,   
        PP_1 = P_1 * P;
                    

    output [PV-1 : 0]  ivc_granted_all;
    input  [PV-1 : 0] ivc_request_all;
    input  [PV-1 : 0] assigned_ovc_not_full_all;
    input  [PVP_1-1 : 0]  dest_port_all;
    output [PP_1-1 : 0]  granted_dest_port_all;
    output [P-1 : 0]  inport_granted_all;
    output [P-1 : 0]  outport_granted_all;
    output [PV-1 : 0]  first_arbiter_granted_ivc_all;
    output [PP_1-1 : 0]  first_arbiter_granted_port_all;
    output [P-1 : 0]  any_ivc_grant;
    input  [PV-1 : 0 ] vc_weight_is_consumed_all;
    input  [P-1:0] iport_weight_is_consumed_all;
    input  clk;
    input  reset;
    
    //separte input per port
    wire [V-1 : 0]  ivc_granted [P-1 : 0];
    wire [V-1 : 0]  ivc_request [P-1 : 0];
    wire [V-1 : 0]  ivc_not_full [P-1 : 0];
    wire [VP_1-1 : 0] dest_port_ivc [P-1 : 0];
    wire [P_1-1 : 0]  granted_dest_port [P-1 : 0];
    
    // internal wires
    wire [V-1 : 0] ivc_masked [P-1 : 0];//output of mask and             
    wire [V-1 : 0] first_arbiter_grant [P-1 : 0];//output of first arbiter            
    wire [P_1-1 : 0] dest_port [P-1 : 0];//output of multiplexer
    wire [P_1-1 : 0] second_arbiter_request [P-1 : 0]; 
    wire [P_1-1 : 0] second_arbiter_grant [P-1 : 0];             
    wire [P_1-1 : 0] second_arbiter_weight_consumed [P-1 : 0]; 
    wire [V-1 : 0] vc_weight_is_consumed [P-1 : 0]; 
    wire [P-1 : 0] winner_weight_consumed;     
    
        
    genvar i,j;
    generate
    
    for(i=0;i< P;i=i+1) begin :port_loop
        //assign in/out to the port based wires
        //output
        assign ivc_granted_all          [(i+1)*V-1 : i*V]    =   ivc_granted [i];
        assign granted_dest_port_all    [(i+1)*P_1-1 : i*P_1]      =   granted_dest_port[i];
        assign first_arbiter_granted_ivc_all[(i+1)*V-1 : i*V]=           first_arbiter_grant[i];
        //input 
        assign ivc_request[i]       = ivc_request_all [(i+1)*V-1 : i*V];
        assign ivc_not_full[i]      = assigned_ovc_not_full_all[(i+1)*V-1 : i*V];
        assign dest_port_ivc[i]     = dest_port_all [(i+1)*VP_1-1 : i*VP_1];
        assign vc_weight_is_consumed[i]  =  vc_weight_is_consumed_all [(i+1)*V-1 : i*V];
        
        //mask
        assign ivc_masked[i]    = ivc_request[i] & ivc_not_full[i];
        
        //first level arbiter        
        swa_input_port_arbiter #(
         	.ARBITER_WIDTH(V),
         	.EXT_P_EN(0),
         	.ARBITER_TYPE(SWA_ARBITER_TYPE)
        )
        input_arbiter
        (
         	.ext_pr_en_i(1'b1),// not used here anyway
         	.request(ivc_masked [i]),
         	.grant(first_arbiter_grant[i]),
         	.any_grant( ),
         	.clk(clk),
         	.reset(reset),
         	.vc_weight_is_consumed(vc_weight_is_consumed[i]),
            .winner_weight_consumed(winner_weight_consumed[i])
        );
       
        //destination port multiplexer
        one_hot_mux #(
            .IN_WIDTH(VP_1),
            .SEL_WIDTH(V)
        )
        multiplexer
        (
            .mux_in (dest_port_ivc  [i]),
            .mux_out(dest_port      [i]),
            .sel(first_arbiter_grant[i])    
        );
        
        assign first_arbiter_granted_port_all[(i+1)*P_1-1 : i*P_1]  = dest_port     [i];
    //second arbiter input/output generate


    for(j=0;j<P;    j=j+1)begin: assign_loop
            if(i<j)begin: jj
                assign second_arbiter_request[i][j-1]   = dest_port[j][i]   ;
                //assign second_arbiter_weight_consumed[i][j-1]  =winner_weight_consumed[j] ;
                assign second_arbiter_weight_consumed[i][j-1]  =iport_weight_is_consumed_all[j];
                assign granted_dest_port[j][i]  = second_arbiter_grant  [i][j-1]    ;
            end else if(i>j)begin: hh
                assign second_arbiter_request[i][j] = dest_port [j][i-1];
                //assign second_arbiter_weight_consumed[i][j]  =winner_weight_consumed[j];
                assign second_arbiter_weight_consumed[i][j]  =iport_weight_is_consumed_all[j];
                assign granted_dest_port[j][i-1]    = second_arbiter_grant  [i][j];
            end
            //if(i==j) wires are left disconnected  
        
        end
    
        
       
        //second level arbiter 
        swa_output_port_arbiter #(
            .ARBITER_WIDTH(P_1),
            .ARBITER_TYPE(SWA_ARBITER_TYPE) // RRA, WRRA
        )
        output_arbiter        
        (
           .weight_consumed(second_arbiter_weight_consumed[i]),  // only used for WRRA
           .clk(clk), 
           .reset(reset), 
           .request(second_arbiter_request [i]), 
           .grant(second_arbiter_grant [i]),
           .any_grant(outport_granted_all [i])  
        );
        
        
        
        //any ivc 
        assign  any_ivc_grant[i] = | granted_dest_port[i];
        
        assign  ivc_granted[i] =  (any_ivc_grant[i]) ? first_arbiter_grant[i] : {V{1'b0}};
                
        assign      inport_granted_all[i]   =any_ivc_grant[i];
    end//for
    endgenerate 
        
    
endmodule
  

