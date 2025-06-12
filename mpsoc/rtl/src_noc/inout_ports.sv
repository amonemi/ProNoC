`include "pronoc_def.v"
/**********************************************************************
**    File: inout_ports.v
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
**    NoC router Input/output module 
**
**************************************************************/

module inout_ports #(
    parameter ROUTER_ID=0,
    parameter P=5    
)(
    clk,
    reset,
    router_info,
    
    // to/from neighboring router
    flit_in_all,
    flit_in_wr_all,
    credit_out_all,
    credit_in_all,
    congestion_in_all,
    congestion_out_all,
    credit_init_val_in,
    credit_init_val_out,
    ctrl_in,
    
    // from vsa: local vc/sw allocator
    vsa_ovc_allocated_all,
    granted_ovc_num_all,
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
    vc_weight_is_consumed_all, 
    iport_weight_is_consumed_all, 
    flit_is_tail_all,
    
    // to crossbar
    flit_out_all,
    ssa_flit_wr_all,
    iport_weight_all,
    oports_weight_all,
    refresh_w_counter,
    crossbar_flit_out_wr_all,
    
    // status
    vsa_credit_decreased_all,
    vsa_ovc_released_all,
    ivc_info, 
    ovc_info,
    oport_info,
    vsa_ctrl_in,
    smart_ctrl_in    
);
    
    import pronoc_pkg::*;
    
    localparam
        PV = V * P,
        PVV = PV * V,    
        P_1 = (SELF_LOOP_EN )?  P : P-1,
        PP_1 = P_1 * P,
        PVP_1 = PV * P_1,
        PFw = P * Fw,
        CONG_ALw = CONGw*P,    //  congestion width per router 
        W = WEIGHTw,
        WP = W * P,
        WPP = WP * P,
        PVDSTPw= PV * DSTPw,
        PRAw= P * RAw;
    
    input router_info_t router_info;
    input [PFw-1 : 0] flit_in_all;
    input [P-1 : 0] flit_in_wr_all;
    output[PV-1 : 0] credit_out_all;
    input [PV-1 : 0] credit_in_all;
    input [PV-1 : 0] vsa_ovc_allocated_all;
    input [PVV-1 : 0] granted_ovc_num_all;
    input ctrl_chanel_t ctrl_in  [P-1 : 0];
    
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
    output [PV-1 : 0] ivc_request_all;
    output [PV-1 : 0] assigned_ovc_not_full_all;
    output [PVV-1: 0] masked_ovc_request_all;
    output [PV-1 : 0] flit_is_tail_all;
    
    // to crossbar
    output [PFw-1 : 0] flit_out_all;
    output [P-1 : 0] ssa_flit_wr_all;
    output [WP-1: 0] iport_weight_all;
    output [WPP-1:0] oports_weight_all;
    input refresh_w_counter;
    input [P-1 : 0] crossbar_flit_out_wr_all;
    
    input clk,reset;
    
    output  [PV-1 : 0] vsa_ovc_released_all;
    output  [PV-1 : 0] vsa_credit_decreased_all;
    output  ivc_info_t ivc_info    [P-1 : 0][V-1 : 0];
    output  ovc_info_t ovc_info    [P-1 : 0][V-1 : 0];
    
    output  oport_info_t oport_info  [P-1 : 0]; 
    input   smart_ctrl_t   smart_ctrl_in [P-1 : 0];
    input   vsa_ctrl_t   vsa_ctrl_in [P-1 : 0];
    input   [CRDTw-1 : 0 ] credit_init_val_in  [P-1 : 0][V-1 : 0];
    output  [CRDTw-1 : 0 ] credit_init_val_out [P-1 : 0][V-1 : 0];
    
    wire [PPSw-1 : 0] port_pre_sel;
    wire [PV-1 :  0]  swap_port_presel;
    wire [PV-1 : 0] reset_ivc_all;     
    wire [PV-1 : 0] sel; 
    wire [PV-1 : 0] ovc_avalable_all; 
    
    wire [DSTPw-1 : 0] destport_clear [P-1 : 0][V-1 : 0];   // clear non preferable ports in adaptive routing     
    wire [PV-1 : 0] ivc_num_getting_sw_grant; 
    
    ssa_ctrl_t ssa_ctrl [P-1 : 0];   
    
    input_ports #(
        .ROUTER_ID(ROUTER_ID),
        .P(P)
    ) the_input_port (
        .router_info(router_info),
        .ivc_num_getting_sw_grant (ivc_num_getting_sw_grant ),
        .any_ivc_sw_request_granted_all (any_ivc_sw_request_granted_all),    
        .flit_in_all (flit_in_all),
        .flit_in_wr_all (flit_in_wr_all),
        .reset_ivc_all (reset_ivc_all),
        .flit_is_tail_all (flit_is_tail_all),
        .ivc_request_all (ivc_request_all),    
        .dest_port_all(dest_port_all),
        .flit_out_all (flit_out_all),
        .assigned_ovc_not_full_all(assigned_ovc_not_full_all),
        .ovc_is_assigned_all(ovc_is_assigned_all),
        .sel (sel),
        .port_pre_sel(port_pre_sel),
        .swap_port_presel(swap_port_presel),
        .credit_out_all(credit_out_all),
        // .lk_destination_encoded_all (lk_destination_encoded_all),
        .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all),
        .destport_clear (destport_clear),
        .vc_weight_is_consumed_all (vc_weight_is_consumed_all),
        .iport_weight_is_consumed_all (iport_weight_is_consumed_all),
        .iport_weight_all(iport_weight_all),
        .oports_weight_all(oports_weight_all),
        .granted_dest_port_all(granted_dest_port_all),
        .refresh_w_counter(refresh_w_counter),
        .ivc_info(ivc_info),
        .smart_ctrl_in(smart_ctrl_in),
        .vsa_ctrl_in(vsa_ctrl_in),
        .ssa_ctrl_in(ssa_ctrl),
        .credit_init_val_out(credit_init_val_out),
        .ctrl_in(ctrl_in),
        .reset (reset),
        .clk (clk)
    );   
    
    output_ports #(
        .P (P)               
    ) output_ports (        
        .vsa_ovc_allocated_all                      (vsa_ovc_allocated_all),
        .flit_is_tail_all                           (flit_is_tail_all),
        .dest_port_all                              (dest_port_all),
        .nonspec_granted_dest_port_all              (nonspec_granted_dest_port_all),
        .credit_in_all                              (credit_in_all),
        .nonspec_first_arbiter_granted_ivc_all      (nonspec_first_arbiter_granted_ivc_all),
        .ivc_num_getting_sw_grant                   (ivc_num_getting_sw_grant ),
        .ovc_avalable_all                           (ovc_avalable_all),
        .assigned_ovc_not_full_all                  (assigned_ovc_not_full_all),
        .port_pre_sel                               (port_pre_sel),//only valid for adaptive routing
        .congestion_in_all                          (congestion_in_all),//only valid for adaptive routing
        .granted_ovc_num_all                         (granted_ovc_num_all),                  
        
        .granted_dst_is_from_a_single_flit_pck      (granted_dst_is_from_a_single_flit_pck),
        .reset                                      (reset),
        .clk                                        (clk),
        .crossbar_flit_out_wr_all                    (crossbar_flit_out_wr_all),
        .any_ovc_granted_in_outport_all ( any_ovc_granted_in_outport_all),  
        .vsa_ovc_released_all (vsa_ovc_released_all),
        .vsa_credit_decreased_all(vsa_credit_decreased_all),
        .oport_info (oport_info),
        .ivc_info(ivc_info),
        .ovc_info (ovc_info),
        .smart_ctrl_in(smart_ctrl_in),
        .vsa_ctrl_in(vsa_ctrl_in),
        .ssa_ctrl_in(ssa_ctrl),
        .credit_init_val_in(credit_init_val_in)
    );    
    
    vc_alloc_request_gen #(
        .P(P)        
    ) vc_alloc_req_gen (
        .ivc_info(ivc_info),
        .ovc_avalable_all(ovc_avalable_all),        
        .dest_port_decoded_all(dest_port_all),
        .masked_ovc_request_all(masked_ovc_request_all),
        .ctrl_in(ctrl_in),   
        .port_pre_sel(port_pre_sel),
        .swap_port_presel(swap_port_presel),
        .sel(sel),
        .reset(reset),
        .clk(clk),
        .destport_clear(destport_clear),
        .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant),
        //.ssa_ivc_num_getting_ovc_grant_all(nla_ivc_num_getting_ovc_grant_all),
        .smart_ctrl_in (smart_ctrl_in),
        .ssa_ctrl_in (ssa_ctrl)
    );    
    
    congestion_out_gen #(
        .P(P),
        .V(V),
        .ROUTE_TYPE(ROUTE_TYPE),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw)
    ) congestion_out (
        .ovc_avalable_all(ovc_avalable_all),
        .ivc_request_all(ivc_request_all),
        .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant ),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)
    );   
    
    genvar i;
    generate  

    if( SSA_EN == 1 ) begin : ssa
        ss_allocator #(
            .P(P)
        ) the_ssa (
            .ivc_info(ivc_info),
            .ovc_info(ovc_info),
            .flit_in_wr_all(flit_in_wr_all),
            .flit_in_all(flit_in_all),
            .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all),
            .any_ovc_granted_in_outport_all(any_ovc_granted_in_outport_all),
            .ovc_avalable_all(ovc_avalable_all),
            .clk(clk),
            .reset(reset),
            .ssa_ctrl_o(ssa_ctrl)
        );
        
    end else begin :non_ssa
        for(i=0;i< P;i=i+1) begin :p_
            assign  ssa_ctrl[i] = {SSA_CTRL_w{1'b0}};
        end
    end //ssa   
    
    for(i=0;i< P;i=i+1) begin :p_
        assign ssa_flit_wr_all [i] = ssa_ctrl[i].ssa_flit_wr;
    end//for    
    
    `ifdef SIMULATION     
    if(DEBUG_EN && MIN_PCK_SIZE >1 )begin :dbg  
        wire [PV-1 : 0] non_vsa_ivc_num_getting_ovc_grant_all;
        integer kk;
        for(i=0;i< P;i=i+1) begin :p_
            assign non_vsa_ivc_num_getting_ovc_grant_all [(i+1)*V-1 : i*V] = ssa_ctrl[i].ivc_num_getting_ovc_grant | smart_ctrl_in[i].ivc_num_getting_ovc_grant;                
        end//for 
        always @(posedge clk ) begin
            for(kk=0; kk< PV; kk=kk+1'b1 ) if(reset_ivc_all[kk] & (ivc_num_getting_ovc_grant[kk] | non_vsa_ivc_num_getting_ovc_grant_all[kk])) begin 
                $display("%t: ERROR: the ovc %d released and allocat signal is asserted in the same clock cycle : %m",$time,kk);
                $finish;    
            end
            end
    end  
    `endif// SIMULATION   
    endgenerate            
endmodule

/******************
    output_vc_status
******************/
module output_vc_status #(
    parameter V =  4,
    parameter B =  16,
    parameter CAND_VC_SEL_MODE = 0,   // 0: use arbiteration between not full vcs, 1: select the vc with most availble free space
    parameter CRDTw = 4,
    parameter HETERO_VC=0
)(
    credit_init_val_in,
    ovc_presence,
    wr_in,
    credit_in,
    nearly_full_vc,
    full_vc,
    empty_vc,
    cand_vc,
    cand_wr_vc_en,
    clk,
    reset
);
    
    input   [V-1 : 0] [CRDTw-1 : 0 ] credit_init_val_in ;
    input   [V-1 : 0] ovc_presence;
    input   [V-1 : 0] wr_in;
    input   [V-1 : 0] credit_in;
    output  [V-1 : 0] nearly_full_vc;
    output  [V-1 : 0] full_vc;
    output  [V-1 : 0] empty_vc;
    output  [V-1 : 0] cand_vc;
    input   cand_wr_vc_en;
    input   clk;
    input   reset;
    
    function integer log2;
    input integer number; begin
        log2=(number <=1) ? 1: 0;
        while(2**log2<number) begin
            log2=log2+1;
        end
    end
    endfunction // log2 
    
    localparam  DEPTH_WIDTH =   log2(B+1);
    
    logic  [DEPTH_WIDTH-1 : 0] credit    [V-1 : 0];
    logic  [DEPTH_WIDTH-1 : 0] credit_next    [V-1 : 0];
    wire  [V-1 : 0] cand_vc_next;
    wire  [V-1 :0] request;
    
    genvar i;
    generate
    for(i=0;i<V;i=i+1) begin : vc_loop
        
        pronoc_register_reset_init #(
            .W(DEPTH_WIDTH)
        )reg1( 
            .D_in(credit_next[i]),
            .reset(reset),
            .clk(clk),
            .Q_out(credit[i]),
            .reset_to(credit_init_val_in[i][DEPTH_WIDTH-1:0])
        );
        
        always_comb begin 
            credit_next[i] = credit [i];
            if(  wr_in[i]  && ~credit_in[i])   credit_next[i] = credit[i]-1'b1;
            if( ~wr_in[i]  &&  credit_in[i])   credit_next[i] = credit[i]+1'b1;
        end//always
        
        assign  full_vc[i]   = (credit[i] == {DEPTH_WIDTH{1'b0}});
        assign  nearly_full_vc[i]=  (credit[i] == 1) |  full_vc[i];
        assign  empty_vc[i]  = (credit[i] == credit_init_val_in[i][DEPTH_WIDTH-1:0]);
        assign  request[i]   = (HETERO_VC>0)?
                    ~ nearly_full_vc[i] & cand_wr_vc_en & ovc_presence[i]:
                    ~ nearly_full_vc[i] & cand_wr_vc_en;
    end//for
    endgenerate
    
    arbiter #(
        .ARBITER_WIDTH (V)
    ) the_nic_arbiter (
        .clk (clk),
        .reset (reset),
        .request (request),
        .grant (cand_vc_next),
        .any_grant()
    );
    
    logic [V-1 : 0] cand_vc_ld_next;  
    pronoc_register #(.W(V)) reg2 (.D_in(cand_vc_ld_next ), .Q_out(cand_vc), .reset(reset), .clk(clk));

    always_comb begin 
        cand_vc_ld_next = cand_vc;
        if(cand_wr_vc_en)    cand_vc_ld_next  =  cand_vc_next;
    end
endmodule


/*************************
    vc_alloc_request_gen
************************/
module  vc_alloc_request_gen #(
    parameter P=5
) (
    ivc_info,
    ovc_avalable_all,
    dest_port_decoded_all,
    masked_ovc_request_all,    
    port_pre_sel,
    swap_port_presel,
    sel,
    reset,
    clk,    
    destport_clear,
    ivc_num_getting_ovc_grant, 
    smart_ctrl_in,
    ssa_ctrl_in,
    ctrl_in
);
    
    import pronoc_pkg::*;
    
    localparam  
        P_1 = (SELF_LOOP_EN )?  P : P-1,
        PV      =   V       *   P,
        PVV     =   PV      *  V,
        PVP_1   =   PV      *   P_1,
        PVDSTPw= PV * DSTPw;
    
    input   [PV-1       :   0]  ovc_avalable_all;
    input   [PVP_1-1    :   0]  dest_port_decoded_all;   
    output  [PVV-1      :   0]  masked_ovc_request_all;
    
    input   [PPSw-1 : 0] port_pre_sel;
    output  [PV-1   : 0] sel;
    output  [PV-1   : 0] swap_port_presel;
    input   reset;
    input   clk;
    output  [DSTPw-1 : 0] destport_clear [P-1 : 0][V-1 : 0];
    
    input   [PV-1 : 0] ivc_num_getting_ovc_grant; 
    input   ssa_ctrl_t  ssa_ctrl_in [P-1: 0];
    input   smart_ctrl_t  smart_ctrl_in [P-1: 0];
    input   ivc_info_t   ivc_info    [P-1 : 0][V-1 : 0];
    input   ctrl_chanel_t ctrl_in  [P-1 : 0];
    
    wire   [PV-1       :   0]  ivc_request_all;
    wire   [PVDSTPw-1  :   0]  dest_port_encoded_all;
    wire   [PVV-1      :   0]  candidate_ovc_all; 
    wire   [PV-1       :   0]  ovc_is_assigned_all;
    
    wire [PV-1 : 0] ovc_avalable_all_masked,hetero_ovc_peresence_all;
    wire [PV-1 : 0] non_vsa_ivc_num_getting_ovc_grant_all;   
    wire [PVDSTPw-1 : 0] destport_clear_all;
    
    genvar i,j;
    generate
    
    for(i=0;i< P;i=i+1) begin :p_
        assign hetero_ovc_peresence_all [(i+1)*V-1 : i*V] = (HETERO_VC >0 )?  ctrl_in[i].hetero_ovc_presence : {V{1'b1}};
        assign ovc_avalable_all_masked [(i+1)*V-1 : i*V] = (SMART_EN)? 
            //TODO for smart, we need to make sure, the hetrro ovc presence in all down stream routers 
            ovc_avalable_all [(i+1)*V-1 : i*V] & ~smart_ctrl_in[i].mask_available_ovc & hetero_ovc_peresence_all[(i+1)*V-1 : i*V] : 
            ovc_avalable_all [(i+1)*V-1 : i*V] & hetero_ovc_peresence_all[(i+1)*V-1 : i*V];
        assign non_vsa_ivc_num_getting_ovc_grant_all [(i+1)*V-1 : i*V] = ssa_ctrl_in[i].ivc_num_getting_ovc_grant | smart_ctrl_in[i].ivc_num_getting_ovc_grant;
        for(j=0;j< V;j=j+1) begin :V_
            assign ivc_request_all[i*V+j] = ivc_info[i][j].ivc_req;
            assign ovc_is_assigned_all[i*V+j] = ivc_info[i][j].ovc_is_assigned;                  
            assign dest_port_encoded_all [(i*V+j+1)*DSTPw-1  :  (i*V+j)*DSTPw]=ivc_info[i][j].dest_port_encoded;
            assign candidate_ovc_all[(i*V+j+1)*V-1  :  (i*V+j)*V]= ivc_info[i][j].candidate_ovc;
            assign destport_clear [i][j]=destport_clear_all [(i*V+j+1)*DSTPw-1  :  (i*V+j)*DSTPw];
        end        
    end//for    
    
    /* verilator lint_off WIDTH */
    if(ROUTE_TYPE == "DETERMINISTIC") begin : dtrmn
    /* verilator lint_on WIDTH */          
        
        vc_alloc_request_gen_determinstic #(
            .P(P),
            .V(V),
            .SELF_LOOP_EN(SELF_LOOP_EN),
            .CAST_TYPE(CAST_TYPE)
        ) vc_request_gen (
            .ovc_avalable_all(ovc_avalable_all_masked),
            .ivc_request_all(ivc_request_all),
            .ovc_is_assigned_all(ovc_is_assigned_all),
            .dest_port_in_all(dest_port_decoded_all),
            .masked_ovc_request_all(masked_ovc_request_all),
            .candidate_ovc_all(candidate_ovc_all)
        );
        
        assign swap_port_presel = {PV{1'bx}};
        assign destport_clear_all={PVDSTPw{1'b0}};
        assign sel = {PV{1'bx}};
        
    end else begin: adptv
        
        if(P==5 && SELF_LOOP_EN == 0 )begin : sl_mesh // combine portsel and available VC mux as proposed in ProNoC paper
            
            mesh_torus_vc_alloc_request_gen_adaptive #(
                .ROUTE_TYPE(ROUTE_TYPE),
                .V(V),
                .DSTPw(DSTPw),
                .SSA_EN(SSA_EN),
                .ESCAP_VC_MASK(ESCAP_VC_MASK),
                .PPSw(PPSw)          
            ) vc_alloc_request_gen (
                .ovc_avalable_all(ovc_avalable_all_masked),
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
                .ssa_ivc_num_getting_ovc_grant_all(non_vsa_ivc_num_getting_ovc_grant_all),
                .reset(reset),
                .clk(clk)
            ); 
            
        end else begin :ml_mesh 
          // there are several local ports connected to one router or self loop is enabled 
          //select the port first then select the available vc
            
            mesh_torus_dynamic_portsel_control #(
                .P(P),
                .ROUTE_TYPE(ROUTE_TYPE),
                .V(V),
                .DSTPw(DSTPw),
                .SSA_EN(SSA_EN),
                .PPSw(PPSw),
                .ESCAP_VC_MASK(ESCAP_VC_MASK)
            ) dynamic_portsel_control (
                .dest_port_coded_all(dest_port_encoded_all),
                .ivc_request_all(ivc_request_all),
                .ovc_is_assigned_all(ovc_is_assigned_all),
                .port_pre_sel(port_pre_sel),
                .swap_port_presel(swap_port_presel),
                .masked_ovc_request_all(masked_ovc_request_all),
                .sel(sel),
                .destport_clear_all(destport_clear_all),
                .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant),
                .ssa_ivc_num_getting_ovc_grant_all(non_vsa_ivc_num_getting_ovc_grant_all),
                .reset(reset),
                .clk(clk)
            );
            
            vc_alloc_request_gen_determinstic #(
                .P(P),
                .V(V),
                .SELF_LOOP_EN(SELF_LOOP_EN)
            ) vc_request_gen (
                .ovc_avalable_all(ovc_avalable_all_masked),
                .ivc_request_all(ivc_request_all),
                .ovc_is_assigned_all(ovc_is_assigned_all),
                .dest_port_in_all(dest_port_decoded_all),
                .masked_ovc_request_all(masked_ovc_request_all),
                .candidate_ovc_all(candidate_ovc_all)
            );
            
        end//  l_mesh   
    end
    endgenerate
    
endmodule


module  vc_alloc_request_gen_determinstic #(    
    parameter P = 5,
    parameter V = 4,
    parameter SELF_LOOP_EN=0,
    parameter CAST_TYPE = "UNICAST" 
)(
    ovc_avalable_all,
    candidate_ovc_all,
    ivc_request_all,
    ovc_is_assigned_all,
    dest_port_in_all,
    masked_ovc_request_all
);

    localparam  
        P_1 = (SELF_LOOP_EN )?  P : P-1,
        PV      =   V       *   P,
        PVV     =   PV      *   V,
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
    if(SELF_LOOP_EN == 0 ) begin :nslp
        //remove available ovc of receiver port 
        for(i=0;i< P;i=i+1) begin :port_loop
            if(i==0) begin : first assign ovc_avalable_perport[i]=ovc_avalable_all [PV-1              :   V]; end
            else if(i==(P-1)) begin : last assign ovc_avalable_perport[i]=ovc_avalable_all [PV-V-1               :   0]; end
            else  begin : midle  assign ovc_avalable_perport[i]={ovc_avalable_all [PV-1  :   (i+1)*V],ovc_avalable_all [(i*V)-1  :   0]}; end
        end
    end else begin :slp
        for(i=0;i< P;i=i+1) begin :port_loop
            assign ovc_avalable_perport[i]=ovc_avalable_all;
        end
    end
    // IVC loop
    for(i=0;i< PV;i=i+1) begin :total_vc_loop
        //separate input/output
        assign ovc_avalable_ivc[i]  =   ovc_avalable_perport[(i/V)];
        assign dest_port_ivc   [i]  =   dest_port_in_all [(i+1)*P_1-1  :   i*P_1   ];
        assign ovc_request_ivc [i]  = (non_assigned_ovc_request_all[i])? candidate_ovc_all  [(i+1)*V-1  :   i*V ]: {V{1'b0}};          
        
        //available ovc multiplexer
        onehot_mux_1D #(
            .W       (V),
            .N      (P_1)
        ) multiplexer (
            .D_in(ovc_avalable_ivc   [i]),
            .Q_out(ovc_avb_muxed      [i]),
            .sel    (dest_port_ivc      [i])
        );  
        
        // mask unavailable ovc from requests
        assign masked_ovc_request_all  [(i+1)*V-1   :   i*V ]     =   ovc_avb_muxed[i] & ovc_request_ivc [i];
        
    end
    endgenerate
endmodule
