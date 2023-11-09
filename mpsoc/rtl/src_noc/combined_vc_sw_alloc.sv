`include "pronoc_def.v"
/**********************************************************************
**	File: combined_vc_sw_alloc.v
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
**	combined VC/SW allocator. VC allocation is done in parallel with swich allocator 
**	for header flits which are successfully get sw grant 
*************************************/


module combined_vc_sw_alloc #(
    parameter NOC_ID=0,
    parameter P = 5 //port number
)(
    ivc_info,
    dest_port_all,
    masked_ovc_request_all,
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
    any_ovc_granted_in_outport_all,
    spec_ovc_num_all,
    vc_weight_is_consumed_all, 
    iport_weight_is_consumed_all, 
    granted_dst_is_from_a_single_flit_pck,
    clk,
    reset

);
	`NOC_CONF

    localparam
        PV = V * P,
        PVV = PV * V,    
        P_1 = (SELF_LOOP_EN == "NO")? P-1 : P,
        PP_1 = P_1 * P,
        PVP_1 = PV * P_1;   
        
    input  ivc_info_t ivc_info [P-1 : 0][V-1 : 0];     
    input  [PVP_1-1 : 0] dest_port_all;
    input  [PVV-1 :  0] masked_ovc_request_all;  
   
     
    output [PV-1 : 0] ovc_allocated_all;
    output [PVV-1 : 0] granted_ovc_num_all;
    output [PV-1 : 0] ivc_num_getting_ovc_grant;
    output [PV-1 : 0] ivc_num_getting_sw_grant;
    output [PV-1 : 0] nonspec_first_arbiter_granted_ivc_all;
    output [PV-1 : 0] spec_first_arbiter_granted_ivc_all;
    output [P-1 : 0] any_ivc_sw_request_granted_all;
    output [P-1 :  0] any_ovc_granted_in_outport_all;    
    output [PP_1-1 : 0] granted_dest_port_all;
    output [PP_1-1 : 0] nonspec_granted_dest_port_all;
    output [PP_1-1 : 0] spec_granted_dest_port_all; 
    output [PVV-1 : 0] spec_ovc_num_all;
   
    input  [PV-1 :  0] vc_weight_is_consumed_all;
    input  [P-1 :  0] iport_weight_is_consumed_all;
  
    output [P-1 : 0] granted_dst_is_from_a_single_flit_pck;
    
    input clk,reset;

    wire  [PV-1 : 0] ivc_request_all;
    wire  [PV-1 : 0] assigned_ovc_not_full_all;  
    wire  [PV-1 : 0] ovc_is_assigned_all;
    wire  [PV-1 : 0] pck_is_single_flit_all;
    
    genvar i;
    generate
   	for (i=0; i<PV; i=i+1) begin : vc_loop
    
    		localparam  C_PORT  = i/V;
    	       
    		assign ivc_request_all[i] = ivc_info[C_PORT][i%V].ivc_req;
    		assign assigned_ovc_not_full_all[i] = ivc_info[C_PORT][i%V].assigned_ovc_not_full;
    		assign ovc_is_assigned_all[i] = ivc_info[C_PORT][i%V].ovc_is_assigned;
    		assign pck_is_single_flit_all[i] =ivc_info[C_PORT][i%V].single_flit_pck;
    	
    end//for	
    	
    	
    	
    /* verilator lint_off WIDTH */
    if(COMBINATION_TYPE    ==    "BASELINE") begin : canonical_comb_gen
    /* verilator lint_on WIDTH */
        baseline_allocator #(
            .V(V),    
            .P(P),                        
            .TREE_ARBITER_EN(1),
            .DEBUG_EN(DEBUG_EN),
            .SWA_ARBITER_TYPE (SWA_ARBITER_TYPE),
            .SELF_LOOP_EN(SELF_LOOP_EN)
        )
        the_base_line
        (
            .dest_port_all(dest_port_all), 
            .masked_ovc_request_all(masked_ovc_request_all),
            .ovc_is_assigned_all(ovc_is_assigned_all), 
            .ivc_request_all(ivc_request_all), 
            .assigned_ovc_not_full_all(assigned_ovc_not_full_all), 
            .ovc_allocated_all(ovc_allocated_all), 
            .granted_ovc_num_all(granted_ovc_num_all), 
            .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
            .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
            .spec_first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all), 
            .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
            .granted_dest_port_all(granted_dest_port_all),
            .nonspec_granted_dest_port_all(nonspec_granted_dest_port_all), 
            .spec_granted_dest_port_all(spec_granted_dest_port_all), 
            .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all),
            .spec_ovc_num_all(spec_ovc_num_all),
            .vc_weight_is_consumed_all(vc_weight_is_consumed_all),
            .iport_weight_is_consumed_all(iport_weight_is_consumed_all),
            .clk(clk), 
            .reset(reset)
        
        );
    /* verilator lint_off WIDTH */
    end else if(COMBINATION_TYPE    ==    "COMB_SPEC1") begin : spec1
    /* verilator lint_on WIDTH */
        comb_spec1_allocator #(
            .V(V),    
            .P(P),
            .DEBUG_EN(DEBUG_EN),
            .SWA_ARBITER_TYPE (SWA_ARBITER_TYPE),
            .MIN_PCK_SIZE(MIN_PCK_SIZE),
            .SELF_LOOP_EN(SELF_LOOP_EN)
            
        )
        the_comb_spec1
        (
            .dest_port_all(dest_port_all), 
            .masked_ovc_request_all(masked_ovc_request_all),
            .ovc_is_assigned_all(ovc_is_assigned_all), 
            .ivc_request_all(ivc_request_all), 
            .assigned_ovc_not_full_all(assigned_ovc_not_full_all), 
            .ovc_allocated_all(ovc_allocated_all), 
            .granted_ovc_num_all(granted_ovc_num_all), 
            .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
            .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
            .spec_first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all), 
            .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
            .granted_dest_port_all(granted_dest_port_all), 
            .nonspec_granted_dest_port_all(nonspec_granted_dest_port_all), 
            .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all),
            .vc_weight_is_consumed_all(vc_weight_is_consumed_all),
            .iport_weight_is_consumed_all(iport_weight_is_consumed_all),
            .pck_is_single_flit_all(pck_is_single_flit_all),
            .granted_dst_is_from_a_single_flit_pck(granted_dst_is_from_a_single_flit_pck),  
            .clk(clk), 
            .reset(reset)
        );        
        
        assign spec_granted_dest_port_all = {PP_1{1'bx}};
        assign spec_ovc_num_all = {PVV{1'bx}};
    /* verilator lint_off WIDTH */    
    end else if (COMBINATION_TYPE    == "COMB_SPEC2") begin :spec2
    /* verilator lint_on WIDTH */
            comb_spec2_allocator #(
                .V(V),    
                .P(P),
                .DEBUG_EN(DEBUG_EN),
                .SWA_ARBITER_TYPE (SWA_ARBITER_TYPE),
                .MIN_PCK_SIZE(MIN_PCK_SIZE),
                .SELF_LOOP_EN(SELF_LOOP_EN)
            )
            the_comb_spec2
            (
                .dest_port_all(dest_port_all), 
                .masked_ovc_request_all(masked_ovc_request_all),
                .ovc_is_assigned_all(ovc_is_assigned_all), 
                .ivc_request_all(ivc_request_all), 
                .assigned_ovc_not_full_all(assigned_ovc_not_full_all), 
                .ovc_allocated_all(ovc_allocated_all), 
                .granted_ovc_num_all(granted_ovc_num_all), 
                .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
                .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
                .spec_first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all), 
                .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
                .granted_dest_port_all(granted_dest_port_all), 
                .nonspec_granted_dest_port_all(nonspec_granted_dest_port_all), 
                .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all),
                .vc_weight_is_consumed_all(vc_weight_is_consumed_all),
                .iport_weight_is_consumed_all(iport_weight_is_consumed_all),
                .pck_is_single_flit_all(pck_is_single_flit_all),
                .granted_dst_is_from_a_single_flit_pck(granted_dst_is_from_a_single_flit_pck),  
                .clk(clk), 
                .reset(reset)
            );
            
            assign spec_granted_dest_port_all = {PP_1{1'bx}};
            assign spec_ovc_num_all = {PVV{1'bx}};

    
    end else begin :   nonspec
        if(V>7)begin :cmb_v2
        
             comb_nonspec_v2_allocator #(
                .V(V),    
                .P(P),
                .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
                .SWA_ARBITER_TYPE (SWA_ARBITER_TYPE),
                .MIN_PCK_SIZE(MIN_PCK_SIZE),
                .SELF_LOOP_EN(SELF_LOOP_EN)
            )
            nonspec_comb
            (
                .dest_port_all(dest_port_all), 
                .masked_ovc_request_all(masked_ovc_request_all),
                .ovc_is_assigned_all(ovc_is_assigned_all),
                .ivc_request_all(ivc_request_all), 
                .assigned_ovc_not_full_all(assigned_ovc_not_full_all),
                .ovc_allocated_all(ovc_allocated_all), 
                .granted_ovc_num_all(granted_ovc_num_all), 
                .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
                .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
                .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
                .granted_dest_port_all(granted_dest_port_all), 
                .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all),
                .any_ovc_granted_in_outport_all(any_ovc_granted_in_outport_all),
                .vc_weight_is_consumed_all(vc_weight_is_consumed_all),
                .iport_weight_is_consumed_all(iport_weight_is_consumed_all),
                .pck_is_single_flit_all(pck_is_single_flit_all),
                .granted_dst_is_from_a_single_flit_pck(granted_dst_is_from_a_single_flit_pck),  
                .clk(clk), 
                .reset(reset)
            );
            
        end else begin :cmb_v1
        
            comb_nonspec_allocator #(
                .NOC_ID(NOC_ID),
                .P(P)
            )
            nonspec_comb
            (
            	.ivc_info(ivc_info),
            	.dest_port_all(dest_port_all), 
                .masked_ovc_request_all(masked_ovc_request_all),               
                .ovc_allocated_all(ovc_allocated_all), 
                .granted_ovc_num_all(granted_ovc_num_all), 
                .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
                .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
                .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
                .granted_dest_port_all(granted_dest_port_all), 
                .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all),
                .any_ovc_granted_in_outport_all(any_ovc_granted_in_outport_all),
                .vc_weight_is_consumed_all(vc_weight_is_consumed_all),
                .iport_weight_is_consumed_all(iport_weight_is_consumed_all),
                .pck_is_single_flit_all(pck_is_single_flit_all),
                .granted_dst_is_from_a_single_flit_pck(granted_dst_is_from_a_single_flit_pck),  
                .clk(clk), 
                .reset(reset)
            );
        end
        
        assign nonspec_granted_dest_port_all      = granted_dest_port_all;
        assign spec_granted_dest_port_all         = {PP_1{1'bx}};
        assign spec_ovc_num_all                      = {PVV{1'bx}};
        assign spec_first_arbiter_granted_ivc_all =  nonspec_first_arbiter_granted_ivc_all ;
    end
endgenerate
endmodule
