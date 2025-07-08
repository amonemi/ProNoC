`include "pronoc_def.v"
/***********************************************************************
 **    File: router_top.v
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
 ** Description:
 *  ProNoC Top-Level Router
 *  This module implements a two-stage NoC router with optional bypass
 *  links for direct connections in the straight direction.
 **************************************************************/
    
module router_top #(
    parameter ROUTER_ID=0,
    parameter P=5
)(
    router_config_in,
    
    chan_in,
    chan_out,
    
    router_event,
    
    clk,
    reset
);
    import pronoc_pkg::*;
    
    localparam DISABLED =P;
    input router_config_t router_config_in;
    
    input smartflit_chanel_t chan_in [P-1 : 0];
    output smartflit_chanel_t chan_out [P-1 : 0];
    
    output router_event_t router_event [P-1 : 0];
    input   clk,reset;
    
    genvar i;
    
    flit_chanel_t r2_chan_in  [P-1 : 0];
    flit_chanel_t r2_chan_out [P-1 : 0];
    
    ivc_info_t ivc_info  [P-1 : 0][V-1 : 0];
    ovc_info_t ovc_info  [P-1 : 0][V-1 : 0];
    iport_info_t iport_info  [P-1 : 0];
    oport_info_t oport_info  [P-1 : 0];
    
    smart_chanel_t smart_chanel_in   [P-1 : 0];
    smart_ctrl_t   smart_ctrl        [P-1 : 0];
    
    ctrl_chanel_t ctrl_in  [P-1 : 0];
    ctrl_chanel_t ctrl_out [P-1 : 0];
    
    always_comb begin 
        for( int k=0; k<P; k++) begin 
            ctrl_in [k] = chan_in[k].ctrl_chanel;
        end
    end
    
    always_comb begin
        for(int k=0; k<P; k++) begin
            router_event[k].flit_wr_i = chan_in[k].flit_chanel.flit_wr;
            router_event[k].bypassed_num = chan_in[k].smart_chanel.bypassed_num;
            router_event[k].pck_wr_i  = chan_in[k].flit_chanel.flit_wr & chan_in[k].flit_chanel.flit.hdr_flag;
            router_event[k].flit_wr_o = chan_out[k].flit_chanel.flit_wr;
            router_event[k].pck_wr_o  = chan_out[k].flit_chanel.flit_wr & chan_out[k].flit_chanel.flit.hdr_flag;
            router_event[k].flit_in_bypassed = chan_out[k].smart_chanel.flit_in_bypassed;
            `ifdef ACTIVE_LOW_RESET_MODE
            router_event[k].active_high_reset = 1'b0;
            `else
            router_event[k].active_high_reset = 1'b1;
            `endif
            router_event[k].empty = ~(|iport_info[k].ivc_req) && (chan_out[k].flit_chanel.flit_wr==1'b0);
        end
    end
    
    
    flit_chanel_t ss_flit_chanel [P-1 : 0]; //flit  bypass link goes to straight port
    
    router_two_stage  #(//r2
        .ROUTER_ID(ROUTER_ID),
        .P(P)
    )router_ref (
        .ivc_info(ivc_info),
        .ovc_info(ovc_info),
        .iport_info(iport_info),
        .oport_info(oport_info),
        .smart_ctrl_in(smart_ctrl),
        .router_config_in(router_config_in),
        .chan_in(r2_chan_in),
        .chan_out(r2_chan_out),
        .ctrl_in(ctrl_in),
        .ctrl_out(ctrl_out),
        .clk(clk),
        .reset(reset)
    );
    
    wire  [V-1  :  0]  credit_out [P-1 : 0];
    smart_chanel_t smart_chanel_out  [P-1 : 0];
    generate
    if(SMART_EN) begin : smart  //smart_bypass is enabled
        smart_chanel_t smart_chanel_new  [P-1 : 0];
        logic [RAw-1 :  0]  current_r_addr;
        wire [V-1 : 0] ovc_locally_requested [P-1 : 0];
        assign current_r_addr = router_config_in.router_addr;
        
        smart_forward_ivc_info #(
            .P(P)
        ) forward_ivc (
            .ivc_info(ivc_info),
            .iport_info(iport_info),
            .oport_info(oport_info),
            .smart_chanel(smart_chanel_new),
            .ovc_locally_requested(ovc_locally_requested),
            .reset(reset),
            .clk(clk)
        );
        
        smart_bypass_chanels #(
            .P(P)
        ) smart_bypass (
            .ivc_info(ivc_info),
            .iport_info(iport_info),
            .oport_info(oport_info),
            .smart_chanel_new(smart_chanel_new),
            .smart_chanel_in(smart_chanel_in),
            .smart_chanel_out(smart_chanel_out),
            .smart_req(),
            .reset(reset),
            .clk(clk)
        );
        
        wire  [RAw-1:  0]  neighbors_r_addr [P-1: 0];
        
        wire  [V-1  :  0]  ivc_smart_en [P-1 : 0];
        for(i=0;i<P;i=i+1)begin : Port_
            localparam SS_PORT = strieght_port(P,i);
            
            if(SS_PORT == DISABLED) begin: smart_dis
                assign smart_ctrl[i]={SMART_CTRL_w{1'b0}};
            end
            else begin :smart_en
                assign neighbors_r_addr [i] = chan_in[i].ctrl_chanel.router_addr;
                //smart allocator
                smart_allocator_per_iport #(
                    .P(P),
                    .SW_LOC(i),
                    .SS_PORT_LOC(SS_PORT)
                ) smart_allocator (
                    .clk(clk),
                    .reset(reset),
                    .current_r_addr_i(current_r_addr),
                    .neighbors_r_addr_i(neighbors_r_addr),
                    .smart_chanel_i(chan_in[i].smart_chanel),
                    .flit_chanel_i(chan_in[i].flit_chanel),
                    .ivc_info (ivc_info[i]),
                    .ss_ovc_info(ovc_info[SS_PORT]),
                    .ovc_locally_requested(ovc_locally_requested[SS_PORT]),
                    .ss_smart_chanel_new (smart_chanel_new[SS_PORT]),
                    .ss_port_link_reg_flit_wr(r2_chan_out[SS_PORT].flit_wr),
                    
                    .smart_ivc_single_flit_pck_o(smart_ctrl[i].ivc_single_flit_pck),
                    .smart_destport_o(smart_ctrl[i].destport),
                    .smart_lk_destport_o(smart_ctrl[i].lk_destport),
                    .smart_hdr_flit_req_o(smart_ctrl[i].hdr_flit_req),
                    .smart_ivc_smart_en_o(ivc_smart_en[i]),
                    .smart_credit_o(smart_ctrl[i].credit_out),
                    .smart_buff_space_decreased_o(smart_ctrl[SS_PORT].buff_space_decreased),
                    .smart_ivc_num_getting_ovc_grant_o(smart_ctrl[i].ivc_num_getting_ovc_grant),
                    .smart_ivc_reset_o(smart_ctrl[i].ivc_reset),
                    .smart_ivc_granted_ovc_num_o(smart_ctrl[i].ivc_granted_ovc_num),
                    .smart_ovc_single_flit_pck_o(smart_ctrl[SS_PORT].ovc_single_flit_pck),
                    .smart_ss_ovc_is_allocated_o(smart_ctrl[SS_PORT].ovc_is_allocated),
                    .smart_ss_ovc_is_released_o (smart_ctrl[SS_PORT].ovc_is_released),
                    .smart_mask_available_ss_ovc_o(smart_ctrl[SS_PORT].mask_available_ovc)
                );
                assign smart_ctrl[i].ivc_smart_en = ivc_smart_en[i];
                assign smart_ctrl[i].smart_en = |ivc_smart_en[i];
                
                `ifdef SIMULATION
                //assign chan_out[i].smart_chanel =(smart_chanel[i].requests[0]) ? smart_chanel_new[i] : take ss shifted smart;    
                smart_chanel_check check (
                    .flit_chanel(chan_out[i].flit_chanel),
                    .smart_chanel(chan_out[i].smart_chanel),
                    .reset(reset),
                    .clk(clk)
                );
                `endif //SIMULATION
                
                smart_credit_manage #(
                    .V(V),
                    .B(B)
                ) smart_credit_manage (
                    .credit_in(r2_chan_out[i].credit),
                    .smart_credit_in(smart_ctrl[i].credit_out),
                    .credit_out( credit_out[i]),
                    .reset(reset),
                    .clk(clk)
                );
                
            end //smart_en
        end//for Port_
    end else begin 
        for(i=0;i<P;i=i+1) begin : Port_
            assign smart_ctrl[i]={SMART_CTRL_w{1'b0}};
        end
    end
    endgenerate

    always_comb begin
        for(int k=0;k<P;k++) begin 
            r2_chan_in[k] = chan_in[k].flit_chanel;
            chan_out[k].flit_chanel = r2_chan_out[k];
            chan_out[k].ctrl_chanel = ctrl_out [k];
            smart_chanel_in[k] =   chan_in[k].smart_chanel;
            chan_out[k].smart_chanel = smart_chanel_out[k];
            if( SMART_EN & (strieght_port(P,k) != DISABLED)) begin
                //mask only flit_wr if smart_en is asserted
                if(smart_ctrl[k].smart_en)r2_chan_in[k].flit_wr = 1'b0;
                // mux out flit channel
                chan_out[k].flit_chanel.credit = credit_out[k] ;
                if(smart_ctrl[strieght_port(P,k)].smart_en) begin
                    chan_out[k].flit_chanel.flit  =  ss_flit_chanel[k].flit;
                    chan_out[k].flit_chanel.flit_wr =  ss_flit_chanel[k].flit_wr;
                end
                chan_out[k].smart_chanel.flit_in_bypassed =smart_ctrl[k].smart_en & chan_in[k].flit_chanel.flit_wr ;
            end
        end
    end

    //r2 demux
    // flit_in_wr demux
    always_comb begin
        for(int k=0;k<P;k++) begin 
            //can replace destport here and remove lk rout from internal router
            //send flit_in to straight out port. Replace lk destport in header flit
            automatic int straight_p= strieght_port(P,k);
            if ((straight_p != DISABLED) & SMART_EN) begin
                ss_flit_chanel[straight_p] = chan_in[k].flit_chanel;
                if(smart_ctrl[k].hdr_flit_req) ss_flit_chanel[straight_p].flit[DST_P_MSB : DST_P_LSB] =  smart_ctrl[k].lk_destport;
            end
        end
    end

/**************************************
*        Validating Parameters 
*        /Simulation
***************************************/
`ifdef SIMULATION
    initial begin
        if((SSA_EN==1)  && (SMART_EN==1))begin
            $display("ERROR: Only one of the SMART or SAA can be enabled at the same time");
            $finish;
        end
        if((SMART_EN==1) && (IS_COMB_NONSPEC==1'b0))begin
            $display("ERROR: SMART only works with non-speculative VSA");
            $finish;
        end
        if((MIN_PCK_SIZE > 1) && (IS_SINGLE_FLIT==1'b1)) begin 
            $display("ERROR: The minimum packet size must be set as one for single-flit packet type NoC");
            $finish;
        end
        if(((SSA_EN==1) || (SMART_EN==1)) && (IS_UNICAST==1'b0)) begin
            $display("ERROR: SMART or SAA do not support muticast/braodcast packets");
            $finish;
        end
    end
    generate 
    `ifdef IVC_DEBUG
    genvar j;
    wire report_active_ivcs = testbench_noc.report_active_ivcs;
    for(i=0; i<P; i=i+1) begin :P1_
        for(j=0; j<V; j=j+1) begin :V_
            always @(posedge report_active_ivcs) begin
                if(ivc_info[i][j].ivc_req)begin 
                    $display("%t : The IVC in router_addr=%h, router_id=%d, port=%d VC=%d is not empty ivc_info:%p",$time,router_config_in.router_addr,router_config_in.router_id,i,j,ivc_info[i][j]);
                end
            end
        end
    end
    `endif
    //header flit info, it is useful for debugin
    // hdr_flit_t hdr_flit_i [P-1 : 0]; // the received packet header flit info
    // hdr_flit_t hdr_flit_o [P-1 : 0]; // the sent packet header flit info
    
    for(i=0; i<P; i=i+1) begin :Port_
        /*
        header_flit_info  in_extract(
            .flit(chan_in[i].flit_chanel.flit),
            .hdr_flit( hdr_flit_i[i]),
            .data_o()
        );

        header_flit_info  out_extract(
            .flit(chan_out[i].flit_chanel.flit),
            .hdr_flit( hdr_flit_o[i]),
            .data_o()
        );
        */
        if(DEBUG_EN) begin :dbg
            check_flit_chanel_type_is_in_order IVC_flit_type_check (
                .clk(clk),
                .reset(reset),
                .hdr_flg_in(chan_in[i].flit_chanel.flit.hdr_flag),
                .tail_flg_in(chan_in[i].flit_chanel.flit.tail_flag),
                .flit_in_wr(chan_in[i].flit_chanel.flit_wr),
                .vc_num_in(chan_in[i].flit_chanel.flit.vc)
            );
            
            check_pck_size check_pck_siz (
                .clk(clk),
                .reset(reset),
                .hdr_flg_in(chan_in[i].flit_chanel.flit.hdr_flag),
                .tail_flg_in(chan_in[i].flit_chanel.flit.tail_flag),
                .flit_in_wr(chan_in[i].flit_chanel.flit_wr),
                .vc_num_in(chan_in[i].flit_chanel.flit.vc),
                .dest_e_addr_in(chan_in[i].flit_chanel.flit.payload[E_DST_MSB : E_DST_LSB])
            );
        end
    end
    endgenerate
    
//`ifdef VERILATOR
//    logic  nb_router_active [P-1 : 0] /*verilator public_flat_rd*/ ;
//    logic  router_is_ideal /*verilator public_flat_rd*/ ;
//    logic  not_ideal_next,not_ideal;
//    integer ii,jj;
//    always_comb begin
//        router_is_ideal = 1'b1;
//        not_ideal_next  = 1'b0;
//        for(ii=0; ii<P; ii=ii+1) begin
//            nb_router_active[ii]= 1'b0;
//            if(chan_out[ii].flit_chanel.flit_wr) nb_router_active[ii]=1'b1;
//            if(chan_out[ii].flit_chanel.credit > {V{1'b0}}) nb_router_active[ii]=1'b1;
//            if(chan_out[ii].smart_chanel.requests > {SMART_NUM{1'b0}}) nb_router_active[ii]=1'b1;
//            
//            for(jj=0; jj<V; jj=jj+1) begin
//                //no active request is in any input queues
//                if(ivc_info[ii][jj].ivc_req)begin
//                    router_is_ideal=1'b0;
//                    not_ideal_next=1'b1;
//                end
//            end
//            //no output flit wr
//            if(r2_chan_out[ii].flit_wr)  router_is_ideal=1'b0;
//        end
//        if(not_ideal) router_is_ideal =1'b0; // delay one clock cycle if the input req exist in last clock cycle bot not on the current one
//    end
//    pronoc_register #(    .W(1)) no_ideal_register(.D_in(not_ideal_next), .reset(reset),  .clk(clk), .Q_out(not_ideal));
//`endif
    
`endif //SIMULATION
    
endmodule
    
/**************************
 * Router_top_v:
 * This module instantiates router_top and
 * serves as the top module in Verilator simulation.
 * It resolves the Verilator error caused by
 * router_top being used in another module (NoC),
 * preventing it from being defined as the top module.
 **************************/ 
    
module router_top_v
#(
    parameter ROUTER_ID=0,
    parameter P=5
)(
    current_r_addr,
    current_r_id,
    
    chan_in,
    chan_out,
    
    router_event,
    
    clk,
    reset
);
    
    import pronoc_pkg::*; 
    
    input  [RAw-1 : 0] current_r_addr;
    input [31:0] current_r_id;
    input   smartflit_chanel_t chan_in [P-1 : 0];
    output  smartflit_chanel_t chan_out [P-1 : 0];
    input   reset,clk;
    
    output router_event_t router_event [P-1 : 0];
    
    router_config_t router_config_in;
    always_comb begin
        router_config_in.router_id= current_r_id [NRw-1 : 0];
        router_config_in.router_addr=current_r_addr;
    end
    router_top #(
        .ROUTER_ID(ROUTER_ID),
        .P(P)
    ) router (
        .router_config_in(router_config_in),
        .chan_in(chan_in),
        .chan_out(chan_out),
        .router_event(router_event),
        .clk(clk),
        .reset(reset)
    );
    
endmodule
