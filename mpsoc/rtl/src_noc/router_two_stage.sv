`include "pronoc_def.v"

//`define MONITORE_PATH

/***********************************************************************
 **    File: router.v
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
 **    A two stage router 
 **   stage1: lk-route,sw/VC allocation
 **   stage2: switch-traversal
 **************************************************************/
    
module router_two_stage #(
    parameter NOC_ID=0,
    parameter ROUTER_ID=0,
    parameter P=5
) (
        router_config_in,
        
        chan_in,
        chan_out,
        
        ctrl_in,
        ctrl_out,
        
        //internal router status 
        ivc_info, 
        ovc_info,
        iport_info,
        oport_info,
        
        smart_ctrl_in,
        
        clk,
        reset
);
    
    `NOC_CONF
    
    // The current/neighbor routers addresses/port. These values are fixed in each router and they are supposed to be given as parameter. 
    // However, in order to give an identical RTL code to each router, they are given as input ports. The identical RTL code reduces the
    // compilation time. Note that they wont be implemented as  input ports in the final synthesized code. 
    
    input router_config_t router_config_in;
    
    input   flit_chanel_t chan_in  [P-1 : 0];
    output  flit_chanel_t chan_out [P-1 : 0];
    input   ctrl_chanel_t ctrl_in  [P-1 : 0];
    output  ctrl_chanel_t ctrl_out [P-1 : 0];
    input   clk,reset;    
    
    output  ivc_info_t   ivc_info    [P-1 : 0][V-1 : 0];
    output  ovc_info_t   ovc_info    [P-1 : 0][V-1 : 0];
    output  iport_info_t iport_info  [P-1 : 0];
    output  oport_info_t oport_info  [P-1 : 0]; 
    
    input   smart_ctrl_t   smart_ctrl_in [P-1 : 0];
    
    vsa_ctrl_t   vsa_ctrl    [P-1 : 0];   
    
    localparam
        PV = V * P,
        VV = V*V,
        PVV = PV * V,    
        P_1 = ( SELF_LOOP_EN=="NO")?  P-1 : P,
        PP_1 = P_1 * P,
        PVP_1 = PV * P_1,
        PFw = P*Fw,
        CONG_ALw = CONGw* P,    //  congestion width per router
        W = WEIGHTw,
        WP = W * P, 
        WPP=  WP * P,
        PRAw= P * RAw; 
    
    flit_chanel_t chan_in_tmp  [P-1 : 0];   
    
    wire  [PFw-1 :  0]  flit_in_all;
    wire  [P-1 :  0]  flit_in_wr_all;
    wire  [PV-1 :  0]  credit_out_all;
    wire  [CONG_ALw-1 :  0]  congestion_in_all;
    
    wire  [PFw-1 :  0]  flit_out_all;
    wire  [P-1 :  0]  flit_out_wr_all;
    wire  [PV-1 :  0]  credit_in_all;
    wire  [CONG_ALw-1 :  0]  congestion_out_all;
    
    wire  [PV-1 : 0] credit_release_out;
    
    // old router verilog code
    
    //internal wires
    wire  [PV-1 : 0] ovc_allocated_all;
    wire  [PVV-1 : 0] granted_ovc_num_all;
    wire  [PV-1 : 0] ivc_num_getting_sw_grant;
    wire  [PV-1 : 0] ivc_num_getting_ovc_grant;
    wire  [PVV-1 : 0] spec_ovc_num_all;
    wire  [PV-1 : 0] nonspec_first_arbiter_granted_ivc_all;
    wire  [PV-1 : 0] spec_first_arbiter_granted_ivc_all;
    wire  [PP_1-1 : 0] nonspec_granted_dest_port_all;
    wire  [PP_1-1 : 0] spec_granted_dest_port_all;    
    wire  [PP_1-1 : 0] granted_dest_port_all;
    wire  [P-1 : 0] any_ivc_sw_request_granted_all;
    wire  [P-1 :  0] any_ovc_granted_in_outport_all;    
    wire  [P-1 : 0] granted_dst_is_from_a_single_flit_pck;
    
    // to vc/sw allocator
    wire  [PVP_1-1 :  0] dest_port_all;
    wire  [PV-1 : 0] ovc_is_assigned_all;
    wire  [PV-1 : 0] ivc_request_all;
    wire  [PV-1 : 0] assigned_ovc_not_full_all;
    wire  [PVV-1: 0] masked_ovc_request_all;    
    wire  [PV-1 : 0] vc_weight_is_consumed_all;
    wire  [P-1  : 0] iport_weight_is_consumed_all;
    wire  [PV-1 : 0] vsa_ovc_released_all;  
    wire  [PV-1 : 0] vsa_credit_decreased_all;
    
    // to/from the crossbar
    wire  [PFw-1 : 0] iport_flit_out_all;
    wire  [P-1 : 0] ssa_flit_wr_all;
    logic [PP_1-1 : 0] granted_dest_port_all_delayed;
    wire  [PFw-1 :  0]  crossbar_flit_out_all;
    wire  [P-1   :  0]  crossbar_flit_out_wr_all;
    wire  [PFw-1 :  0]  link_flit_out_all;
    wire  [P-1   :  0]  link_flit_out_wr_all;
    wire  [PV-1  :  0] flit_is_tail_all;
    
    //to weight control
    wire [WP-1 : 0] iport_weight_all;
    wire [WPP-1: 0] oports_weight_all;
    wire refresh_w_counter;
    
    //ctrl port
    wire [PRAw-1  :  0] neighbors_r_addr;
    wire [CRDTw-1 : 0 ] credit_init_val_in  [P-1 : 0][V-1 : 0];
    wire [CRDTw-1 : 0 ] credit_init_val_out [P-1 : 0][V-1 : 0];    
    logic [31:0] current_r_id;
    logic [RAw-1 :  0]  current_r_addr;
    always_comb begin 
        current_r_addr = router_config_in.router_addr;
        current_r_id = 0;
        current_r_id [NRw-1 : 0] = router_config_in.router_id;
    end
    
    router_info_t router_info;
    assign router_info.router_id=current_r_id;
    assign router_info.router_addr=current_r_addr;
    assign router_info.neighbors_r_addr[PRAw-1  :  0] = neighbors_r_addr;
    
    genvar i,j;
    generate
        for (i=0; i<P; i=i+1 ) begin :p_
            
            if(CAST_TYPE == "UNICAST") begin : uni 
                assign chan_in_tmp[i] = chan_in[i];
            end else begin : multi
                multicast_chan_in_process #(
                    .NOC_ID(NOC_ID),
                    .P(P),
                    .SW_LOC(i)
                ) multicast_process (
                    .endp_port(ctrl_in[i].endp_port),
                    .current_r_addr(current_r_addr),
                    .chan_in(chan_in[i]),
                    .chan_out(chan_in_tmp[i]),
                    .clk(clk)
                );
            end
            
            assign  neighbors_r_addr  [(i+1)*RAw-1:  i*RAw] = ctrl_in[i].router_addr;
            assign  flit_in_all       [(i+1)*Fw-1:  i*Fw] = chan_in_tmp[i].flit;
            assign  flit_in_wr_all    [i] = chan_in_tmp[i].flit_wr;   
            assign  credit_in_all     [(i+1)*V-1:  i*V] = chan_in_tmp[i].credit;
            assign  congestion_in_all [(i+1)*CONGw-1:  i*CONGw] = chan_in_tmp[i].congestion; 
            
            assign  ctrl_out[i].router_addr = current_r_addr;
            assign  ctrl_out[i].endp_port =1'b0; 
            assign  ctrl_out[i].hetero_ovc_presence= hetero_ovc_unary(current_r_id,i);
            
            if(IS_LINE | IS_RING |  IS_MESH | IS_FMESH | IS_TORUS) begin 
                localparam ENP_NUM = (i>SOUTH)?  i-SOUTH : LOCAL;
                assign  ctrl_out[i].endp_addr = router_config_in[ (ENP_NUM+1)*EAw-1 : ENP_NUM*EAw];
            end else if (IS_MULTI_MESH) begin
                assign  ctrl_out[i].endp_addr = router_config_in[EAw-1 : 0];
            end //TODO complete it for fattree and bin tree
            assign  chan_out[i].flit=          flit_out_all       [(i+1)*Fw-1:  i*Fw];
            assign  chan_out[i].flit_wr=       flit_out_wr_all    [i];
            assign  chan_out[i].credit=        credit_out_all     [(i+1)*V-1:  i*V] | credit_release_out [(i+1)*V-1:  i*V];         
            assign  chan_out[i].congestion=    congestion_out_all [(i+1)*CONGw-1:  i*CONGw];
            
            assign  iport_info[i].swa_first_level_grant =nonspec_first_arbiter_granted_ivc_all[(i+1)*V-1:  i*V]; 
            assign  iport_info[i].swa_grant = ivc_num_getting_sw_grant[(i+1)*V-1:  i*V];
            assign  iport_info[i].any_ivc_get_swa_grant=    any_ivc_sw_request_granted_all[i]; 
            assign  iport_info[i].ivc_req = ivc_request_all [(i+1)*V-1:  i*V]; 
            
            assign  vsa_ctrl[i].ovc_is_allocated = ovc_allocated_all [(i+1)*V-1:  i*V];
            assign  vsa_ctrl[i].ovc_is_released  = vsa_ovc_released_all[(i+1)*V-1:  i*V];
            assign  vsa_ctrl[i].ivc_num_getting_sw_grant = ivc_num_getting_sw_grant [(i+1)*V-1:  i*V];
            assign  vsa_ctrl[i].ivc_num_getting_ovc_grant=ivc_num_getting_ovc_grant [(i+1)*V-1:  i*V];
            assign  vsa_ctrl[i].ivc_reset=flit_is_tail_all[(i+1)*V-1:  i*V] & ivc_num_getting_sw_grant[(i+1)*V-1:  i*V];
            assign  vsa_ctrl[i].buff_space_decreased =  vsa_credit_decreased_all[(i+1)*V-1:  i*V]; 
            assign  vsa_ctrl[i].ivc_granted_ovc_num = granted_ovc_num_all[(i+1)*VV-1:  i*VV];
            
            if(SELF_LOOP_EN == "NO") begin :nslp
                add_sw_loc_one_hot #(
                    .P(P),
                    .SW_LOC(i)
                )add(
                    .destport_in(granted_dest_port_all[(i+1)*P_1-1:  i*P_1]),
                    .destport_out(iport_info[i].granted_oport_one_hot[P-1 : 0])
                );    
            end else begin :slp
                assign iport_info[i].granted_oport_one_hot[P-1 : 0] = granted_dest_port_all[(i+1)*P_1-1:  i*P_1];
            end
            
            for (j=0;j<V;j++)begin :V_
                
                //credit_release. Only activated for local ports as credit_release_en never be asserted in router to router connection.  
                credit_release_gen #(
                    .NOC_ID(NOC_ID),
                    .CREDIT_NUM(LB)
                ) credit_release_gen (
                    .clk(clk), 
                    .reset(reset), 
                    .en (ctrl_in[i].credit_release_en[j]), 
                    .credit_out(credit_release_out[i*V+j])
                );
                
                assign ctrl_out[i].credit_release_en[j] =1'b0;
                assign credit_init_val_in[i][j]       = ctrl_in[i].credit_init_val[j];
                assign ctrl_out[i].credit_init_val[j] = credit_init_val_out [i][j];        
            end
        end
    endgenerate
    
    inout_ports #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(ROUTER_ID),
        .P(P)
    ) the_inout_ports (
        .router_info(router_info),
        .flit_in_all(flit_in_all),
        .flit_in_wr_all(flit_in_wr_all),
        .credit_out_all(credit_out_all),
        .credit_in_all(credit_in_all),
        .masked_ovc_request_all(masked_ovc_request_all),            
        .granted_dst_is_from_a_single_flit_pck(granted_dst_is_from_a_single_flit_pck),
        .vsa_ovc_allocated_all(ovc_allocated_all), 
        .granted_ovc_num_all(granted_ovc_num_all), 
        .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
        .spec_ovc_num_all(spec_ovc_num_all), 
        .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
        .spec_first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all), 
        .nonspec_granted_dest_port_all(nonspec_granted_dest_port_all), 
        .spec_granted_dest_port_all(spec_granted_dest_port_all), 
        .granted_dest_port_all(granted_dest_port_all), 
        .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all), 
        .any_ovc_granted_in_outport_all(any_ovc_granted_in_outport_all),
        .dest_port_all(dest_port_all), 
        .ovc_is_assigned_all(ovc_is_assigned_all), 
        .ivc_request_all(ivc_request_all), 
        .assigned_ovc_not_full_all(assigned_ovc_not_full_all), 
        .flit_out_all(iport_flit_out_all),
        .congestion_in_all(congestion_in_all),
        .congestion_out_all(congestion_out_all),
        //  .lk_destination_all(lk_destination_all),
        .ssa_flit_wr_all(ssa_flit_wr_all),
        .iport_weight_all(iport_weight_all),
        .oports_weight_all(oports_weight_all),
        .vc_weight_is_consumed_all(vc_weight_is_consumed_all),
        .iport_weight_is_consumed_all(iport_weight_is_consumed_all), 
        .refresh_w_counter(refresh_w_counter), 
        .clk(clk), 
        .reset(reset),
        .ivc_info(ivc_info),
        .ovc_info(ovc_info),
        .oport_info(oport_info),
        .smart_ctrl_in(smart_ctrl_in),
        .ctrl_in(ctrl_in),
        .vsa_ctrl_in(vsa_ctrl),
        .credit_init_val_in (credit_init_val_in),
        .credit_init_val_out (credit_init_val_out),
        .flit_is_tail_all(flit_is_tail_all),            
        .crossbar_flit_out_wr_all(crossbar_flit_out_wr_all),
        .vsa_ovc_released_all(vsa_ovc_released_all),
        .vsa_credit_decreased_all(vsa_credit_decreased_all)
    );
    
    combined_vc_sw_alloc #(
        .NOC_ID(NOC_ID),
        .P(P)
    ) vsa (
        .dest_port_all(dest_port_all), 
        .masked_ovc_request_all(masked_ovc_request_all),            
        .granted_dst_is_from_a_single_flit_pck(granted_dst_is_from_a_single_flit_pck),
        .ovc_allocated_all(ovc_allocated_all), 
        .granted_ovc_num_all(granted_ovc_num_all), 
        .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
        .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
        .spec_first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all), 
        .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
        .nonspec_granted_dest_port_all(nonspec_granted_dest_port_all), 
        .spec_granted_dest_port_all(spec_granted_dest_port_all), 
        .granted_dest_port_all(granted_dest_port_all), 
        .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all), 
        .any_ovc_granted_in_outport_all(any_ovc_granted_in_outport_all),
        .spec_ovc_num_all(spec_ovc_num_all),       
        // .lk_destination_all(lk_destination_all),  
        .vc_weight_is_consumed_all(vc_weight_is_consumed_all),  
        .iport_weight_is_consumed_all(iport_weight_is_consumed_all),  
        .ivc_info(ivc_info),
        .clk(clk), 
        .reset(reset)
    );
    
    pronoc_register #(.W(PP_1)) reg2 (.in(granted_dest_port_all ), .out(granted_dest_port_all_delayed), .reset(reset), .clk(clk));
    
    crossbar #(    
        .NOC_ID(NOC_ID),            
        .TOPOLOGY(TOPOLOGY),
        .V (V),     // vc_num_per_port
        .P (P),     // router port num
        .Fw (Fw),
        .MUX_TYPE (MUX_TYPE),                
        .SSA_EN (SSA_EN),
        .SELF_LOOP_EN(SELF_LOOP_EN)                
    ) the_crossbar (
        .granted_dest_port_all (granted_dest_port_all_delayed),
        .flit_in_all (iport_flit_out_all),                
        .ssa_flit_wr_all (ssa_flit_wr_all),
        .flit_out_all (crossbar_flit_out_all),                
        .flit_out_wr_all (crossbar_flit_out_wr_all)        
    );    
    
    //link reg 
    generate 
    if( ADD_PIPREG_AFTER_CROSSBAR == 1 ) begin :link_reg
        
        reg [PFw-1 : 0] flit_out_all_pipe;
        reg [P-1 : 0] flit_out_wr_all_pipe;
        
        pronoc_register #(.W(PFw)) reg1 (.in(crossbar_flit_out_all    ), .out(flit_out_all_pipe), .reset(reset), .clk(clk));
        pronoc_register #(.W(P)  ) reg2 (.in(crossbar_flit_out_wr_all ), .out(flit_out_wr_all_pipe), .reset(reset), .clk(clk));
        
        assign link_flit_out_all    = flit_out_all_pipe;
        assign link_flit_out_wr_all = flit_out_wr_all_pipe;       
        
    end else begin :no_link_reg
        
        assign    link_flit_out_all     =   crossbar_flit_out_all;
        assign    link_flit_out_wr_all  =   crossbar_flit_out_wr_all;
    end        
        
    /* verilator lint_off WIDTH */ 
    if (SWA_ARBITER_TYPE != "RRA" ) begin : wrra_ 
    /* verilator lint_on WIDTH */ 
        
        wire [WP-1 : 0] contention_all;
        wire [WP-1 : 0] limited_oport_weight_all;
        
        wrra_contention_gen #(
            .WEIGHTw(WEIGHTw),
            .WRRA_CONFIG_INDEX(WRRA_CONFIG_INDEX),
            .V(V),
            .P(P),
            .SELF_LOOP_EN(SELF_LOOP_EN)
        ) contention_gen (
            .limited_oport_weight_all(limited_oport_weight_all),
            .dest_port_all(dest_port_all),
            .ivc_request_all(ivc_request_all),
            .ovc_is_assigned_all(ovc_is_assigned_all), 
            .contention_all(contention_all),
            .iport_weight_all(iport_weight_all),
            .oports_weight_all(oports_weight_all)
        ); 
        
        weights_update #(
            .NOC_ID(NOC_ID),
            .ARBITER_TYPE(SWA_ARBITER_TYPE),
            .V(V),
            .P(P),
            .Fw(Fw),
            .WEIGHTw(WEIGHTw),
            .WRRA_CONFIG_INDEX(WRRA_CONFIG_INDEX),
            .C(C),
            .TOPOLOGY(TOPOLOGY),
            .EAw(EAw),
            .DSTPw(DSTPw),
            .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR)
        )
        updater
        (
            .limited_oports_weight(limited_oport_weight_all),
            .refresh_w_counter(refresh_w_counter),
            .iport_weight_all(iport_weight_all),
            .contention_all(contention_all),
            .flit_in_all(link_flit_out_all),
            .flit_out_all(flit_out_all),
            .flit_out_wr_all(flit_out_wr_all),
            .clk(clk),
            .reset(reset)
        );        
    end // WRRA
    else begin : rra_    
        assign flit_out_all  =  link_flit_out_all;   
        assign refresh_w_counter = 1'b0;
    end
    endgenerate 
    
    assign  flit_out_wr_all = link_flit_out_wr_all;
    
/*********************************************
*
*        Validating Parameters/Simulation
*
*********************************************/
    
`ifdef SIMULATION
    generate 
    if(DEBUG_EN & IS_MESH)begin :dbg
        debug_mesh_edges #(
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .T4(T4),
            .RAw(RAw),
            .P(P)
        ) debug_edges (
            .clk(clk),
            .current_r_addr(current_r_addr),
            .flit_out_wr_all(flit_out_wr_all)
        );
    end// DEBUG  
    
    // for testing the route path
    `ifdef MONITORE_PATH    
    reg[P-1 :0] t1,t2;    
    for (i=0;i<P;i=i+1)begin : lp  
        always @(posedge clk) begin
            if(`pronoc_reset)begin 
                t1[i]<=1'b0;
                t2[i]<=1'b0;             
            end else begin 
                if(flit_out_wr_all[i]>0 && t2[i]==0)begin 
                    $display("%t :Out router (id=%d, addr=%h, port=%d), flitout=%h",$time,current_r_id,current_r_addr,i,flit_out_all[(i+1)*Fw-1 : i*Fw]);
                    t2[i]<=1;
                end
                
                if(flit_in_wr_all[i]>0 && t1[i]==0)begin 
                    $display("%t :In router (id=%d, addr=%h, port=%d), flitin=%h",$time,current_r_id,current_r_addr,i,flit_in_all[(i+1)*Fw-1 : i*Fw]);
                    t1[i]<=1;
                end
            end
        end //always
    end //for
    `endif //MONITORE_PATH 
    endgenerate
    /*
    reg [10 :  0]  counter;
    reg [31 :  0]  flit_counter;
    
    always @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset) begin 
            flit_counter <=0;
            counter <= 0;
        end else begin 
            if(flit_in_wr_all>0 )begin 
                counter <=0;
                flit_counter<=flit_counter+1'b1;
            end else begin 
                counter <= counter+1'b1;
                if( counter == 512 ) $display("%t : total flits received in (x=%d,Y=%d) is %d ",$time,current_r_addr,current_y,flit_counter);
            end
        end
    end
     */
    
    
//TRACE_DUMP_PER_[NOC/ROUTER/PORT] macro definition should be in pronoc_def.v file
    
    
`ifdef TRACE_DUMP_PER_NoC
    pronoc_trace_dump #(
        .NOC_ID(NOC_ID),
        .P(P),
        .TRACE_DUMP_PER("NOC"), //NOC, ROUTER, PORT 
        .CYCLE_REPORT(0) // 1 : enable, 0 : disable    
    ) dump1 (
        .current_r_id(current_r_id),
        .chan_in(chan_in),
        .chan_out(chan_out),
        .clk(clk)
    );
`endif    
`ifdef TRACE_DUMP_PER_ROUTER
    pronoc_trace_dump #(
        .NOC_ID(NOC_ID),
        .P(P),
        .TRACE_DUMP_PER("ROUTER"), //NOC, ROUTER, PORT 
        .CYCLE_REPORT(0) // 1 : enable, 0 : disable    
    ) dump2 (
        .current_r_id(current_r_id),
        .chan_in(chan_in),
        .chan_out(chan_out),
        .clk(clk)
    );
`endif    
`ifdef TRACE_DUMP_PER_PORT
    pronoc_trace_dump #(
        .NOC_ID(NOC_ID),
        .P(P),
        .TRACE_DUMP_PER("PORT"), //NOC, ROUTER, PORT 
        .CYCLE_REPORT(0) // 1 : enable, 0 : disable    
    )dump3 (
        .current_r_id(current_r_id),
        .chan_in(chan_in),
        .chan_out(chan_out),
        .clk(clk)
    );
`endif
`endif //SIMULATION

endmodule


`ifdef SIMULATION
module pronoc_trace_dump #(
    parameter NOC_ID=0,
    parameter P = 6,
    parameter TRACE_DUMP_PER= "ROUTER", //NOC, ROUTER, PORT 
    parameter CYCLE_REPORT=0 // 1 : enable, 0 : disable
)
(
    current_r_id,
    chan_in,
    chan_out,
    clk
);
    
    `NOC_CONF
    
    input  [31:0] current_r_id;
    input   flit_chanel_t chan_in  [P-1 : 0];
    input   flit_chanel_t chan_out [P-1 : 0];
    input   clk;
    
    pronoc_trace_dump_sub #(
        .NOC_ID(NOC_ID),
        .P(P),
        .TRACE_DUMP_PER(TRACE_DUMP_PER), //NOC, ROUTER, PORT 
        .DIRECTION("in"), // in,out
        .CYCLE_REPORT(CYCLE_REPORT) // 1 : enable, 0 : disable
    ) dump_in (
        .current_r_id(current_r_id),
        .chan_in(chan_in),
        .clk(clk)
    );
    
    pronoc_trace_dump_sub #(
        .NOC_ID(NOC_ID),
        .P(P),
        .TRACE_DUMP_PER(TRACE_DUMP_PER), //NOC, ROUTER, PORT 
        .DIRECTION("out"), // in,out
        .CYCLE_REPORT(CYCLE_REPORT) // 1 : enable, 0 : disable
    ) dump_out (
        .current_r_id(current_r_id),
        .chan_in(chan_out),
        .clk(clk)
    );
endmodule

module pronoc_trace_dump_sub #(
    parameter NOC_ID=0,
    parameter P = 6,
    parameter TRACE_DUMP_PER= "ROUTER", //NOC, ROUTER, PORT 
    parameter DIRECTION="in", // in,out
    parameter CYCLE_REPORT=0 // 1 : enable, 0 : disable
)(
    current_r_id,
    chan_in,
    clk
);
    `NOC_CONF
    input  [31:0] current_r_id;
    input   flit_chanel_t chan_in  [P-1 : 0];
    input   clk;
    
    integer out;
    string fname [P-1 : 0];
    
    genvar p;
    generate 
    for (p=0;p<P;p++)begin : _P
        initial begin 
            /* verilator lint_off WIDTH */ 
            if(TRACE_DUMP_PER == "PORT"  ) fname[p] = $sformatf("trace_dump_R%0d_P%0d.out",current_r_id,p);
            if(TRACE_DUMP_PER == "ROUTER") fname[p] = $sformatf("trace_dump_R%0d.out",current_r_id);
            if(TRACE_DUMP_PER == "NOC"   ) fname[p] = $sformatf("trace_dump.out");
            /* verilator lint_on WIDTH */ 
            out = $fopen(fname[p],"w");
            $fclose(out);
        end
        
        always @(posedge clk) begin 
            if(chan_in[p].flit_wr) begin 
                out = $fopen(fname[p],"a");
                if(CYCLE_REPORT) $fwrite(out,"%t:",$time);
                $fwrite(out, "Flit %s: Port %0d, Payload: %h\n",DIRECTION, p, chan_in[p].flit);
                $fclose(out);                
            end
            if(chan_in[p].credit>0) begin 
                out = $fopen(fname[p],"a");
                if(CYCLE_REPORT) $fwrite(out,"%t:",$time);
                $fwrite(out, "credit %s:%h Port %0d\n",DIRECTION, chan_in[p].credit,p);
                $fclose(out);                
            end        
        end    
    end
    endgenerate
endmodule
`endif // SIMULATION




module credit_release_gen #(
    parameter NOC_ID=0,
    parameter CREDIT_NUM=4
)(
    clk,
    reset,
    en,
    credit_out        
);
    
    `NOC_CONF
    
    input  clk, reset;
    input  en;
    output reg credit_out;        
    
    localparam W=log2(CREDIT_NUM +1);
    
    reg [W-1 : 0] counter;
    wire counter_is_zero = counter=={W{1'b0}};    
    wire counter_is_max = counter==CREDIT_NUM;
    wire counter_incr = (en & counter_is_zero ) | (~counter_is_zero & ~counter_is_max);
    
    always @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset) begin 
            counter <= {W{1'b0}};    
            credit_out<=1'b0;
        end else begin 
            if(counter_incr) begin 
                counter<= counter +1'b1;
                credit_out<=1'b1;
            end else begin 
                credit_out<=1'b0;                
            end
        end
    end    
    
endmodule
