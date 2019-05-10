`timescale     1ns/1ps

/**********************************************************************
**	File: inout_ports.v
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
**	NoC router Input/output module 
**
**************************************************************/

module inout_ports #(
    parameter V = 4,   
    parameter P = 5,   
    parameter B = 4,   
    parameter T1= 8,
    parameter T2= 8,
    parameter T3= 8,
    parameter T4= 8,
    parameter RAw = 3,  
    parameter EAw = 3,  
    parameter C = 4,   
    parameter Fpay = 32,   
    parameter VC_REALLOCATION_TYPE=  "NONATOMIC",
    parameter COMBINATION_TYPE= "COMB_NONSPEC",
    parameter TOPOLOGY=    "MESH",
    parameter ROUTE_NAME="XY",
    parameter ROUTE_TYPE="DETERMINISTIC",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter CONGESTION_INDEX =   2,//"CREDIT","VC"
    parameter DEBUG_EN = 1,
    parameter AVC_ATOMIC_EN = 1,
    parameter CONGw = 2,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1: 0] CLASS_SETTING = {CVw{1'b1}}, // shows how each class can use VCs   
    parameter [V-1 : 0] ESCAP_VC_MASK = 4'b1000,  
    parameter DSTPw=P-1,
    parameter SSA_EN="YES", 
    parameter SWA_ARBITER_TYPE="RRA",
    parameter WEIGHTw=4,
    parameter WRRA_CONFIG_INDEX=0,
    parameter PPSw=4,
    parameter MIN_PCK_SIZE=2 //minimum packet size in flits. The minimum value is 1. 
)
(
    current_r_addr,
    neighbors_r_addr,
       
    // to/from neighboring router
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    credit_in_all,
    congestion_in_all,
    congestion_out_all,
    
    // from vc/sw allocator
    ovc_allocated_all,
    granted_ovc_num_all,
    ivc_num_getting_sw_grant,
    ivc_num_getting_ovc_grant,
    spec_ovc_num_all,
    nonspec_first_arbiter_granted_ivc_all,
    spec_first_arbiter_granted_ivc_all,
    nonspec_granted_dest_port_all,
    spec_granted_dest_port_all,
    granted_dest_port_all,
    any_ivc_sw_request_granted_all,
    any_ovc_granted_in_outport_all,
    granted_dst_is_from_a_single_flit_pck,
    
    // to vc/sw allocator
    dest_port_all,
    ovc_is_assigned_all,
    ivc_request_all,
    assigned_ovc_not_full_all,
    masked_ovc_request_all,
    pck_is_single_flit_all,
    vc_weight_is_consumed_all, 
    iport_weight_is_consumed_all,    
        
    // to crossbar
    flit_out_all,
    ssa_flit_wr_all,
    iport_weight_all,
    oports_weight_all,
    refresh_w_counter,
    clk,reset
    
);

   
    localparam
        PV = V * P,
        PVV = PV * V,    
        P_1 = P-1,
        PP_1 = P_1 * P,
        PVP_1 = PV * P_1,
        Fw = 2+V+Fpay,//flit width
        PFw = P * Fw,
        CONG_ALw = CONGw*P,    //  congestion width per router 
        W = WEIGHTw,
        WP = W * P,
        WPP = WP * P,
        PVDSTPw= PV * DSTPw,
        PRAw= P * RAw;
       
   
   


    input   [RAw-1 : 0] current_r_addr;
    input   [PRAw-1:  0]  neighbors_r_addr;
           
                    
    input [PFw-1 : 0] flit_in_all;
    input [P-1 : 0] flit_in_we_all;
    output reg[PV-1 : 0] credit_out_all;
    input [PV-1 : 0] credit_in_all;
    input [PV-1 : 0] ovc_allocated_all;
    input [PVV-1 : 0] granted_ovc_num_all;
    input [PV-1 : 0] ivc_num_getting_sw_grant;
    input [PV-1 : 0] ivc_num_getting_ovc_grant;
    input [PVV-1 : 0] spec_ovc_num_all;
    input [PV-1 : 0] nonspec_first_arbiter_granted_ivc_all;
    input [PV-1 : 0] spec_first_arbiter_granted_ivc_all;
    input [PP_1-1 : 0] nonspec_granted_dest_port_all;
    input [PP_1-1 : 0] spec_granted_dest_port_all;    
    input [PP_1-1 : 0] granted_dest_port_all;
    input [P-1 : 0] any_ivc_sw_request_granted_all;
    input [P-1 : 0] any_ovc_granted_in_outport_all;   
   
    input [CONG_ALw-1 : 0] congestion_in_all;
    output[CONG_ALw-1 : 0] congestion_out_all;
    output[PV-1 : 0] vc_weight_is_consumed_all;
    output[P-1 : 0] iport_weight_is_consumed_all;  
    input [P-1 : 0] granted_dst_is_from_a_single_flit_pck;  
    
    
    // to vc/sw allocator
    output [PVP_1-1 : 0] dest_port_all;
    output [PV-1 : 0] ovc_is_assigned_all;
    output [PV-1 : 0] pck_is_single_flit_all;   
    output [PV-1 : 0] ivc_request_all;
    output [PV-1 : 0] assigned_ovc_not_full_all;
    output [PVV-1 : 0] masked_ovc_request_all;

    // to crossbar
    output [PFw-1 : 0] flit_out_all;
    output [P-1 : 0] ssa_flit_wr_all;
    output [WP-1: 0] iport_weight_all;
    output [WPP-1:0] oports_weight_all;
    input refresh_w_counter;

    input clk,reset;

  
    wire [PVV-1 : 0] candidate_ovc_all;
    wire [PVDSTPw-1 : 0] dest_port_encoded_all;
  //  wire [PVDSTPw-1 : 0] lk_destination_encoded_all;

    wire [PPSw-1 : 0] port_pre_sel;
    wire [PV-1 :  0]  swap_port_presel;
    wire [PV-1 : 0] reset_ivc_all;    
    wire [PV-1 : 0] flit_is_tail_all;
    reg  [PV-1 : 0] ovc_is_assigned_all,ovc_is_assigned_all_next;
  //  wire [PV-1 : 0] port_pre_sel_ld_all;
    reg  [PVV-1 : 0] assigned_ovc_num_all,assigned_ovc_num_all_next;
    
    wire [PV-1 : 0] sel; 
    wire [PV-1 : 0] ovc_avalable_all; 
    
    wire [PVDSTPw-1 : 0] destport_clear_all;// clear unprefrable ports in adaptive routing     
  
    // ssa
    wire [PV-1 : 0] ssa_ovc_allocated_all;
    wire [PV-1 : 0] ssa_ovc_released_all; 
    wire [PVV-1 : 0] ssa_granted_ovc_num_all;
    wire [PV-1 : 0] ssa_ivc_num_getting_sw_grant_all;
    wire [PV-1 : 0] ssa_ivc_num_getting_ovc_grant_all;    
    wire [PV-1 : 0] ssa_ivc_reset_all;  
    wire [PV-1 : 0] ssa_decreased_credit_in_ss_ovc_all;  
    
    

generate
if(MIN_PCK_SIZE == 1) begin :single_flit_supported 
    assign pck_is_single_flit_all = flit_is_tail_all & ~ovc_is_assigned_all; 
end else begin : single_flit_notsupported
    assign pck_is_single_flit_all = {PV{1'b0}}; 
end

/* verilator lint_off WIDTH */
 if( SSA_EN =="YES" ) begin : predict 
/* verilator lint_on WIDTH */
       ss_allocator #(
            .TOPOLOGY(TOPOLOGY),
            .V(V),
            .P(P),
            .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
            .WEIGHTw(WEIGHTw),
            .EAw(EAw),
            .DSTPw(DSTPw),
            .C(C),                
            .Fpay(Fpay), //payload width
            .ROUTE_TYPE(ROUTE_TYPE),                   
            .DEBUG_EN(DEBUG_EN),
            .ESCAP_VC_MASK(ESCAP_VC_MASK)     
        )
        the_ssa
        (
            .flit_in_we_all(flit_in_we_all),
            .flit_in_all(flit_in_all),
            .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all),
            .any_ovc_granted_in_outport_all(any_ovc_granted_in_outport_all),
            .ovc_avalable_all(ovc_avalable_all),
            .ivc_request_all(ivc_request_all),
            .assigned_ovc_not_full_all(assigned_ovc_not_full_all),
            .dest_port_encoded_all(dest_port_encoded_all),
            .assigned_ovc_num_all(assigned_ovc_num_all),
            .ovc_is_assigned_all(ovc_is_assigned_all),
            .clk(clk),
            .reset(reset),
         
            .ovc_allocated_all(ssa_ovc_allocated_all),
            .ovc_released_all(ssa_ovc_released_all),
            .granted_ovc_num_all(ssa_granted_ovc_num_all),
            .ivc_num_getting_sw_grant_all(ssa_ivc_num_getting_sw_grant_all),
            .ivc_num_getting_ovc_grant_all(ssa_ivc_num_getting_ovc_grant_all),
            .ivc_reset_all(ssa_ivc_reset_all),
            .decreased_credit_in_ss_ovc_all(ssa_decreased_credit_in_ss_ovc_all),
            .ssa_flit_wr_all(ssa_flit_wr_all)

    
        );

    end else begin :non_predict
        assign  ssa_ovc_allocated_all=  {PV{1'b0}};
        assign  ssa_ovc_released_all=  {PV{1'b0}};
        assign  ssa_granted_ovc_num_all= {PVV{1'b0}};
        assign  ssa_ivc_num_getting_sw_grant_all= {PV{1'b0}};
        assign  ssa_ivc_num_getting_ovc_grant_all= {PV{1'b0}};
        assign  ssa_ivc_reset_all=  {PV{1'b0}};
        assign  ssa_flit_wr_all= {P{1'b0}}; 
        assign  ssa_decreased_credit_in_ss_ovc_all = {PV{1'b0}};

    end
    endgenerate

    wire [PVV-1 : 0] granted_ovc_num_all_or_ssa;
    wire [PV-1 : 0] ivc_num_getting_sw_grant_all_or_ssa; 
    
    assign granted_ovc_num_all_or_ssa = granted_ovc_num_all | ssa_granted_ovc_num_all;
    assign ivc_num_getting_sw_grant_all_or_ssa = ivc_num_getting_sw_grant | ssa_ivc_num_getting_sw_grant_all;
    assign reset_ivc_all    =    (flit_is_tail_all & ivc_num_getting_sw_grant) | ssa_ivc_reset_all;


    

//synthesis translate_off
//synopsys  translate_off
generate
    if(DEBUG_EN)begin :dbg2   // The SSA must not have conflict with the main VC/Sw allocator
        localparam VV = V*V;
        genvar g;
        for(g=0; g< P; g=g+1 ) begin: p_loop
            always @ (posedge clk) begin
                if( (|granted_ovc_num_all[(g+1)*VV-1 : g*VV]) &  (|ssa_granted_ovc_num_all[(g+1)*VV-1 : g*VV])) $display("%t: ERROR: VSA/SSA conflict: granted_ovc_num %m",$time);
                if( (|ivc_num_getting_sw_grant [(g+1)*V-1 : g*V]) & (|ssa_ivc_num_getting_sw_grant_all[(g+1)*V-1 : g*V]) ) $display("%t: ERROR: VSA/SSA conflict: ivc_num_getting_sw_grant %m",$time);     
                 if((|(flit_is_tail_all[(g+1)*V-1 : g*V] & ivc_num_getting_sw_grant[(g+1)*V-1 : g*V])) & (|ssa_ivc_reset_all[(g+1)*V-1 : g*V])) $display("%t: ERROR: VSA/SSA conflict: reset_ivc_all %m",$time);   
            end//always
        end
    end //dbg
endgenerate
//synopsys  translate_on
//synthesis translate_on


//assign port_pre_sel_ld_all= ~ovc_is_assigned_all_next;




genvar k;
generate
    for(k=0; k< PV; k=k+1 ) begin: PV_loop
        always @ (*) begin
            //default values
            ovc_is_assigned_all_next[k] = ovc_is_assigned_all[k];
            assigned_ovc_num_all_next[(k+1)*V-1 : k*V] = assigned_ovc_num_all[(k+1)*V-1 : k*V] ;
            if(reset_ivc_all[k]) begin 
                ovc_is_assigned_all_next[k] = 1'b0;
                //assigned_ovc_num_all_next[(k+1)*V-1 : k*V] = {V{1'b0}};
            end
            else if(ivc_num_getting_ovc_grant[k] | ssa_ivc_num_getting_ovc_grant_all[k]) begin 
                ovc_is_assigned_all_next[k] = 1'b1;
                
            end
	    if((ivc_num_getting_ovc_grant[k] | ssa_ivc_num_getting_ovc_grant_all[k]) ) begin 
		assigned_ovc_num_all_next[(k+1)*V-1 : k*V] = granted_ovc_num_all_or_ssa[(k+1)*V-1 : k*V];
	    end
        end//always
        //synthesis translate_off
        //synopsys  translate_off
        if(DEBUG_EN)begin :dbg
          always @ (posedge clk) begin
            if((ivc_num_getting_ovc_grant[k] | ssa_ivc_num_getting_ovc_grant_all[k]) && granted_ovc_num_all_or_ssa[(k+1)*V-1 : k*V]== {V{1'b0}}) begin 
                    $display("%t: ERROR: granted OVC num is NULL: %m",$time);
                    
            end
          end//always
        end
        //synopsys  translate_on
        //synthesis translate_on
        
        
    end//for
endgenerate



always @ (posedge clk or posedge reset) begin
    if (reset)    begin
        ovc_is_assigned_all   <=  {PV{1'b0}};
        assigned_ovc_num_all  <=  {PVV{1'b0}};
        credit_out_all        <=  {PV{1'b0}};
    end else begin
        ovc_is_assigned_all   <= ovc_is_assigned_all_next;
        assigned_ovc_num_all  <= assigned_ovc_num_all_next;
        credit_out_all        <= ivc_num_getting_sw_grant_all_or_ssa;         
    end
end

 	

generate 
    //synthesis translate_off 
    //synopsys  translate_off
    if(DEBUG_EN && MIN_PCK_SIZE >1 )begin :dbg
        integer kk;
        always @(posedge clk ) begin
            for(kk=0; kk< PV; kk=kk+1'b1 ) if(reset_ivc_all[kk] & (ivc_num_getting_ovc_grant[kk] | ssa_ivc_num_getting_ovc_grant_all[kk]))   $display("%t: ERROR: the ovc %d released and allocat signal is asserted in the same clock cycle : %m",$time,kk);
        end
    end
    //synopsys  translate_on
    //synthesis translate_on
            
    if( COMBINATION_TYPE==  "BASELINE") begin : canonical
        
        canonical_credit_counter #(
            .V   (V),
            .P   (P),
            .B   (B),
            .VC_REALLOCATION_TYPE   (VC_REALLOCATION_TYPE),
            .ROUTE_TYPE             (ROUTE_TYPE),
            .CONGESTION_INDEX       (CONGESTION_INDEX),
            .ESCAP_VC_MASK          (ESCAP_VC_MASK),
            .CONGw                  (CONGw),
            .AVC_ATOMIC_EN          (AVC_ATOMIC_EN),
            .PPSw(PPSw),
            .DEBUG_EN               (DEBUG_EN)
                        
        )
        the_credit_counter
        (
            .non_ss_ovc_allocated_all                (ovc_allocated_all),
            .flit_is_tail_all                        (flit_is_tail_all),
            .assigned_ovc_num_all                    (assigned_ovc_num_all),
            .spec_ovc_num_all                        (spec_ovc_num_all),
            .dest_port_all                           (dest_port_all),
            .nonspec_granted_dest_port_all           (nonspec_granted_dest_port_all),
            .spec_granted_dest_port_all              (spec_granted_dest_port_all),
            .credit_in_all                           (credit_in_all),
            .nonspec_first_arbiter_granted_ivc_all   (nonspec_first_arbiter_granted_ivc_all),
            .spec_first_arbiter_granted_ivc_all      (spec_first_arbiter_granted_ivc_all),
            .ivc_num_getting_sw_grant                (ivc_num_getting_sw_grant_all_or_ssa ),
            .ovc_avalable_all                        (ovc_avalable_all),
            .assigned_ovc_not_full_all               (assigned_ovc_not_full_all),
            .port_pre_sel                            (port_pre_sel),//only valid for adaptive routing
            .congestion_in_all                       (congestion_in_all),//only valid for adaptive routing
            .ssa_ovc_released_all                     (ssa_ovc_released_all),
            .ssa_ovc_allocated_all                   (ssa_ovc_allocated_all),
            .ssa_decreased_credit_in_ss_ovc_all      (ssa_decreased_credit_in_ss_ovc_all),
            .reset                                   (reset),
            .clk                                     (clk)
        );
        
        end //canonical
        else begin : noncanonical
            
            credit_counter #(
                .V                        (V),
                .P                        (P),
                .B                      (B),
                .PPSw(PPSw),
                .VC_REALLOCATION_TYPE   (VC_REALLOCATION_TYPE),
                .ROUTE_TYPE             (ROUTE_TYPE),
                .CONGESTION_INDEX       (CONGESTION_INDEX),
                .ESCAP_VC_MASK          (ESCAP_VC_MASK),
                .AVC_ATOMIC_EN          (AVC_ATOMIC_EN),
                .CONGw                  (CONGw),
                .DEBUG_EN               (DEBUG_EN),
                .MIN_PCK_SIZE           (MIN_PCK_SIZE)  
            )
            the_credit_counter
            (
                .non_ss_ovc_allocated_all                   (ovc_allocated_all),
                .flit_is_tail_all                           (flit_is_tail_all),
                .assigned_ovc_num_all                       (assigned_ovc_num_all),
                .ovc_is_assigned_all                        (ovc_is_assigned_all),
                .dest_port_all                              (dest_port_all),
                .nonspec_granted_dest_port_all              (nonspec_granted_dest_port_all),
                .credit_in_all                              (credit_in_all),
                .nonspec_first_arbiter_granted_ivc_all      (nonspec_first_arbiter_granted_ivc_all),
                .ivc_num_getting_sw_grant                   (ivc_num_getting_sw_grant_all_or_ssa ),
                .ovc_avalable_all                           (ovc_avalable_all),
                .assigned_ovc_not_full_all                  (assigned_ovc_not_full_all),
                .port_pre_sel                               (port_pre_sel),//only valid for adaptive routing
                .congestion_in_all                          (congestion_in_all),//only valid for adaptive routing
                .ssa_ovc_released_all                       (ssa_ovc_released_all),
                .ssa_ovc_allocated_all                      (ssa_ovc_allocated_all),
                .ssa_decreased_credit_in_ss_ovc_all         (ssa_decreased_credit_in_ss_ovc_all),
                .granted_dst_is_from_a_single_flit_pck      (granted_dst_is_from_a_single_flit_pck),
                .reset                                      (reset),
                .clk                                        (clk)
            );
    
        end//noncanonical
        
endgenerate

  

    vc_alloc_request_gen #(
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
    	.ROUTE_TYPE(ROUTE_TYPE),
    	.P(P),
    	.DSTPw(DSTPw),
    	.PPSw(PPSw),
      	.V(V),
    	.ESCAP_VC_MASK(ESCAP_VC_MASK),
    	.SSA_EN(SSA_EN)
    )
    vc_alloc_req_gen
    (
    	.ovc_avalable_all(ovc_avalable_all),
    	.dest_port_encoded_all(dest_port_encoded_all),
    	.ivc_request_all(ivc_request_all),
    	.ovc_is_assigned_all(ovc_is_assigned_all),
    	.dest_port_decoded_all(dest_port_all),
    	.masked_ovc_request_all(masked_ovc_request_all),
    	.candidate_ovc_all(candidate_ovc_all),
    	.port_pre_sel(port_pre_sel),
    	.swap_port_presel(swap_port_presel),
    	.sel(sel),
    	.reset(reset),
    	.clk(clk),
    	.destport_clear_all(destport_clear_all),
    	.ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant),
    	.ssa_ivc_num_getting_ovc_grant_all(ssa_ivc_num_getting_ovc_grant_all)
    );

   


    congestion_out_gen #(
        .P(P),
        .V(V),
        .ROUTE_TYPE(ROUTE_TYPE),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw)
   )
   congestion_out
   (
        .ovc_avalable_all(ovc_avalable_all),
        .ivc_request_all(ivc_request_all),
        .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant_all_or_ssa ),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)
   );       


     input_ports
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
        .DSTPw(DSTPw), 
        .C(C),    
        .Fpay(Fpay),    
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .ROUTE_TYPE(ROUTE_TYPE),
        .DEBUG_EN(DEBUG_EN),
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .WRRA_CONFIG_INDEX(WRRA_CONFIG_INDEX),
        .PPSw(PPSw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)  
        
    )
        the_input_port
    (
        .current_r_addr (current_r_addr),    
        .neighbors_r_addr(neighbors_r_addr),
        .ivc_num_getting_sw_grant (ivc_num_getting_sw_grant_all_or_ssa ),
        .any_ivc_sw_request_granted_all (any_ivc_sw_request_granted_all),    
        .flit_in_all (flit_in_all),
        .flit_in_we_all (flit_in_we_all),
        .reset_ivc_all (reset_ivc_all),
        .flit_is_tail_all (flit_is_tail_all),
        .ivc_request_all (ivc_request_all),    
        .dest_port_encoded_all (dest_port_encoded_all),
        .dest_port_all(dest_port_all),
        .candidate_ovcs_all (candidate_ovc_all),
        .flit_out_all (flit_out_all),
        .assigned_ovc_num_all (assigned_ovc_num_all),
        .sel (sel),
        .port_pre_sel(port_pre_sel),
        .swap_port_presel(swap_port_presel),
       // .lk_destination_encoded_all (lk_destination_encoded_all),
        .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all),
        .ssa_ivc_num_getting_sw_grant_all (ssa_ivc_num_getting_sw_grant_all),
        .destport_clear_all (destport_clear_all),
        .vc_weight_is_consumed_all (vc_weight_is_consumed_all),
        .iport_weight_is_consumed_all (iport_weight_is_consumed_all),
        .iport_weight_all(iport_weight_all),
        .oports_weight_all(oports_weight_all),
        .granted_dest_port_all(granted_dest_port_all),
        .refresh_w_counter(refresh_w_counter),
        .reset (reset),
        .clk (clk)
    );               

endmodule





 /******************
 
    output_vc_status
 
 ******************/
 
 module output_vc_status #(
    parameter V     =   4,
    parameter B =   16,
    parameter CAND_VC_SEL_MODE      =   0   // 0: use arbieration between not full vcs, 1: select the vc with most availble free space

)

(
    input    [V-1 :0] wr_in,
    input   [V-1 :0] credit_in,
    output  [V-1 :0] nearly_full_vc,
    output  [V-1 :0] empty_vc,
    output reg [V-1 :0] cand_vc,
    input                                               cand_wr_vc_en,
    input                                                   clk,
    input                                                   reset
);

    
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
    
    localparam  BUFF_WIDTH  =   log2(B);
    localparam  DEPTH_WIDTH =   BUFF_WIDTH+1;
    localparam  [DEPTH_WIDTH-1 : 0] B_1         =   B-1;
    localparam  [DEPTH_WIDTH-1 : 0] B_2         =   B-2;
    
    
    reg  [DEPTH_WIDTH-1 : 0] depth    [V-1 : 0];
    wire  [V-1 : 0] cand_vc_next;
    wire  [V-1 : 0] full_vc;
    
    genvar i;
    generate
        for(i=0;i<V;i=i+1) begin : vc_loop
            always@(posedge clk or posedge reset)begin
                    if(reset)begin
                        depth[i]<={DEPTH_WIDTH{1'b0}};
                    end else begin
                        if(  wr_in[i]  && ~credit_in[i])   depth[i] <= depth[i]+1'b1;
                        if( ~wr_in[i]  &&  credit_in[i])   depth[i] <= depth[i]-1'b1;
                    end //reset
            end//always

            assign  full_vc[i]   = (depth[i] == B);
            assign  nearly_full_vc[i]= (depth[i] >= B_1);
            assign  empty_vc[i]  = (depth[i] == {DEPTH_WIDTH{1'b0}});


        end//for
        if(CAND_VC_SEL_MODE==0) begin : nic_arbiter
            wire  [V-1 :0] request;
            for(i=0;i<V;i=i+1) begin :req_loop
                assign  request[i]   = ~ nearly_full_vc[i] & cand_wr_vc_en;
            end //for


            arbiter #(
                .ARBITER_WIDTH      (V)
                )
                the_nic_arbiter
                (
                    .clk                (clk),
                    .reset          (reset),
                    .request            (request),
                    .grant          (cand_vc_next),
                    .any_grant       ()
                );

        end else begin : min_depth_select

        wire [(V*DEPTH_WIDTH)-1 : 0] depth_array;
        for(i=0;i<V;i=i+1) begin :depth_loop
            assign depth_array[((i+1)*(DEPTH_WIDTH))-1  : i*DEPTH_WIDTH]=depth[i];
        end //for

        fast_minimum_number#(
            .NUM_OF_INPUTS (V),
            .DATA_WIDTH (DEPTH_WIDTH)

        )
        the_min_depth
        (
            .in_array (depth_array),
            .min_out (cand_vc_next)
        );

        end //else

        always @(posedge clk or posedge reset)begin
            if          (reset)          cand_vc    <= {V{1'b0}};
            else    if(cand_wr_vc_en)    cand_vc    <=  cand_vc_next;
        end

    endgenerate




endmodule


/*************************
    vc_alloc_request_gen

************************/


module  vc_alloc_request_gen #(
    parameter TOPOLOGY="MESH",
    parameter ROUTE_NAME        =   "XY",
    parameter ROUTE_TYPE = "DETERMINISTIC",
    parameter P = 5,
    parameter DSTPw=4,  
    parameter PPSw=4,
    parameter V = 4,
    parameter [V-1  :   0] ESCAP_VC_MASK = 4'b1000,   // mask scape vc, valid only for full adaptive       
    parameter SSA_EN="YES"
)(
    ovc_avalable_all,
    dest_port_encoded_all,
    candidate_ovc_all,
    ivc_request_all,
    ovc_is_assigned_all,
    dest_port_decoded_all,
    masked_ovc_request_all,    
    port_pre_sel,
    swap_port_presel,
    sel,
    reset,
    clk,    
    destport_clear_all,
    ivc_num_getting_ovc_grant, 
    ssa_ivc_num_getting_ovc_grant_all      
);

    localparam  P_1     =   P-1,
                PV      =   V       *   P,
                PVV     =   PV      *  V,
                PVP_1   =   PV      *   P_1,
                PVDSTPw= PV * DSTPw;


    input   [PV-1       :   0]  ovc_avalable_all;
    input   [PVDSTPw-1  :   0]  dest_port_encoded_all;
    input   [PV-1       :   0]  ivc_request_all;
    input   [PV-1       :   0]  ovc_is_assigned_all;
    input   [PVP_1-1    :   0]  dest_port_decoded_all;
    output  [PVV-1      :   0]  masked_ovc_request_all;
    input   [PVV-1      :   0]  candidate_ovc_all;
    
    input  [PPSw-1 : 0] port_pre_sel;
    output [PV-1  : 0] sel;
    output    [PV-1       :   0]  swap_port_presel;
    input  reset,clk;
    output [PVDSTPw-1 : 0] destport_clear_all;
    input [PV-1 : 0] ivc_num_getting_ovc_grant; 
    input [PV-1 : 0] ssa_ivc_num_getting_ovc_grant_all;       
    
        
    generate   
    
    /* verilator lint_off WIDTH */
    if(ROUTE_TYPE == "DETERMINISTIC") begin : dtrmn
    /* verilator lint_on WIDTH */          
                          
        vc_alloc_request_gen_determinstic #(
        	.P(P),
        	.V(V)
        )
        vc_request_gen
        (
        	.ovc_avalable_all(ovc_avalable_all),
        	.ivc_request_all(ivc_request_all),
        	.ovc_is_assigned_all(ovc_is_assigned_all),
        	.dest_port_in_all(dest_port_decoded_all),
        	.masked_ovc_request_all(masked_ovc_request_all),
        	.candidate_ovc_all(candidate_ovc_all)
        );
        
        assign swap_port_presel = {PV{1'bx}};
        assign destport_clear_all={PVDSTPw{1'bx}};
        assign sel = {PV{1'bx}};
    
    end else begin: adptv     
      
      if(P==5)begin:sl_mesh // combine portsel and available VC mux as proposed in ProNoC paper
      
      mesh_torus_vc_alloc_request_gen_adaptive #(
       	.ROUTE_TYPE(ROUTE_TYPE),
      	.V(V),
      	.DSTPw(DSTPw),
      	.SSA_EN(SSA_EN),
      	.ESCAP_VC_MASK(ESCAP_VC_MASK),
      	.PPSw(PPSw)
      )
      vc_alloc_request_gen
      (
      	.ovc_avalable_all(ovc_avalable_all),
      	.dest_port_coded_all(dest_port_encoded_all),
      	.ivc_request_all(ivc_request_all),
      	.ovc_is_assigned_all(ovc_is_assigned_all),
      	.masked_ovc_request_all(masked_ovc_request_all),
      	.candidate_ovc_all(candidate_ovc_all),
      	.port_pre_sel(port_pre_sel),
      	.swap_port_presel(swap_port_presel),
      	.sel(sel),
      	.destport_clear_all(destport_clear_all),
      	.ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant),
      	.ssa_ivc_num_getting_ovc_grant_all(ssa_ivc_num_getting_ovc_grant_all),
      	.reset(reset),
      	.clk(clk)
      ); 
      
      end else begin :ml_mesh // there are several local ports connected to one router. 
      //select the port first then select the available vc
        
                
        
         mesh_torus_dynamic_portsel_control #(
         	.P(P),
         	.ROUTE_TYPE(ROUTE_TYPE),
         	.V(V),
         	.DSTPw(DSTPw),
         	.SSA_EN(SSA_EN),
         	.PPSw(PPSw),
         	.ESCAP_VC_MASK(ESCAP_VC_MASK)
         )
         dynamic_portsel_control
         (
         	.dest_port_coded_all(dest_port_encoded_all),
         	.ivc_request_all(ivc_request_all),
         	.ovc_is_assigned_all(ovc_is_assigned_all),
         	.port_pre_sel(port_pre_sel),
         	.swap_port_presel(swap_port_presel),
         	.masked_ovc_request_all(masked_ovc_request_all),
         	.sel(sel),
         	.destport_clear_all(destport_clear_all),
         	.ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant),
         	.ssa_ivc_num_getting_ovc_grant_all(ssa_ivc_num_getting_ovc_grant_all),
         	.reset(reset),
         	.clk(clk)
         );
         
        vc_alloc_request_gen_determinstic #(
            .P(P),
            .V(V)
        )
        vc_request_gen
        (
            .ovc_avalable_all(ovc_avalable_all),
            .ivc_request_all(ivc_request_all),
            .ovc_is_assigned_all(ovc_is_assigned_all),
            .dest_port_in_all(dest_port_decoded_all),
            .masked_ovc_request_all(masked_ovc_request_all),
            .candidate_ovc_all(candidate_ovc_all)
        );
                 
      
      end      
    
    end
    endgenerate

endmodule


module  vc_alloc_request_gen_determinstic #(    
    parameter P = 5,
    parameter V = 4
)(
    ovc_avalable_all,
    candidate_ovc_all,
    ivc_request_all,
    ovc_is_assigned_all,
    dest_port_in_all,
    masked_ovc_request_all
);

    localparam  P_1     =   P-1,
                PV      =   V       *   P,
                PVV     =   PV      *  V,
                PVP_1   =   PV      *   P_1,
                VP_1    =   V       *   P_1;             

    input   [PV-1       :   0]  ovc_avalable_all;
    input   [PV-1       :   0]  ivc_request_all;
    input   [PV-1       :   0]  ovc_is_assigned_all;
    input   [PVP_1-1    :   0]  dest_port_in_all;
    output  [PVV-1      :   0]  masked_ovc_request_all;
    input   [PVV-1      :   0]  candidate_ovc_all;
    
    wire    [PV-1       :   0]  non_assigned_ovc_request_all; 
    wire    [VP_1-1     :   0]  ovc_avalable_perport        [P-1    :   0];
    wire    [VP_1-1     :   0]  ovc_avalable_ivc            [PV-1   :   0];
    wire    [P_1-1      :   0]  dest_port_ivc               [PV-1   :   0];
    wire    [V-1        :   0]  ovc_avb_muxed               [PV-1   :   0];  
    wire    [V-1        :   0]  ovc_request_ivc             [PV-1   :   0];
 
    assign non_assigned_ovc_request_all =   ivc_request_all & ~ovc_is_assigned_all;
   
    
  genvar i;

generate
    //remove avalable ovc of reciver port 
    for(i=0;i< P;i=i+1) begin :port_loop
        if(i==0) begin : first assign ovc_avalable_perport[i]=ovc_avalable_all [PV-1              :   V]; end
        else if(i==(P-1)) begin : last assign ovc_avalable_perport[i]=ovc_avalable_all [PV-V-1               :   0]; end
        else  begin : midle  assign ovc_avalable_perport[i]={ovc_avalable_all [PV-1  :   (i+1)*V],ovc_avalable_all [(i*V)-1  :   0]}; end
    end
        
    // IVC loop
    for(i=0;i< PV;i=i+1) begin :total_vc_loop
        //seprate input/output
        assign ovc_avalable_ivc[i]  =   ovc_avalable_perport[(i/V)];
        assign dest_port_ivc   [i]  =   dest_port_in_all [(i+1)*P_1-1  :   i*P_1   ];
        assign ovc_request_ivc [i]  = (non_assigned_ovc_request_all[i])? candidate_ovc_all  [(i+1)*V-1  :   i*V ]: {V{1'b0}};          
       
        //available ovc multiplexer
        one_hot_mux #(
            .IN_WIDTH       (VP_1   ),
            .SEL_WIDTH      (P_1)
        )
        multiplexer
        (
            .mux_in     (ovc_avalable_ivc   [i]),
            .mux_out    (ovc_avb_muxed      [i]),
            .sel        (dest_port_ivc      [i])

        );  
        
        // mask unavailable ovc from requests
        assign masked_ovc_request_all  [(i+1)*V-1   :   i*V ]     =   ovc_avb_muxed[i] & ovc_request_ivc [i];
        
    end
   endgenerate
endmodule


 
