`include "pronoc_def.v"
//`define MONITORE_PATH

/**********************************************************************
 **    File: input_ports.sv
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
 **    NoC router input Port. It consists of input buffer, control FIFO 
 **    and request masking/generation control modules
 **
 **************************************************************/
    
module input_ports #(
    parameter ROUTER_ID=0,
    parameter P=5
)(
    router_info,
    ivc_num_getting_sw_grant,// for non spec ivc_num_getting_first_sw_grant,
    any_ivc_sw_request_granted_all,
    flit_in_all,
    flit_in_wr_all,
    reset_ivc_all,
    flit_is_tail_all,
    ivc_request_all,
    dest_port_all,
    flit_out_all,
    
    assigned_ovc_not_full_all,
    ovc_is_assigned_all,
    sel,
    port_pre_sel,
    swap_port_presel,
    nonspec_first_arbiter_granted_ivc_all,
    credit_out_all,
    
    destport_clear,
    vc_weight_is_consumed_all,
    iport_weight_is_consumed_all,
    iport_weight_all,
    oports_weight_all,
    granted_dest_port_all,
    refresh_w_counter,
    ivc_info,
    vsa_ctrl_in,
    ssa_ctrl_in,
    smart_ctrl_in,
    credit_init_val_out,
    ctrl_in,
    reset,
    clk
);  
    
    import pronoc_pkg::*;
    
    localparam
        PV = V * P,
        VV = V * V,
        PVV = PV * V,    
        P_1 = (SELF_LOOP_EN )?  P : P-1,
        PP_1 = P * P_1, 
        VP_1 = V * P_1,
        PVP_1 = PV * P_1,
        PFw = P*Fw,
        W= WEIGHTw,
        WP= W * P,
        WPP = WP * P,
        PVDSTPw= PV * DSTPw,
        PRAw= P * RAw;    
    
    input   reset,clk;
    input   router_info_t router_info;
    output  [PV-1 : 0] ivc_num_getting_sw_grant;
    input   [P-1 : 0] any_ivc_sw_request_granted_all;
    input   [PFw-1 : 0] flit_in_all;
    input   [P-1 : 0] flit_in_wr_all;
    output  [PV-1 : 0] reset_ivc_all;
    output  [PV-1 : 0] flit_is_tail_all;
    output  [PV-1 : 0] ivc_request_all;
    output  [PV-1 : 0] credit_out_all;
    
    output  [PVP_1-1 : 0] dest_port_all;
    output  [PFw-1 : 0] flit_out_all;
    
    input   [PV-1  : 0] assigned_ovc_not_full_all;
    output  [PV-1  : 0] ovc_is_assigned_all;
    input   [PV-1 : 0] sel;
    input   [PPSw-1 : 0] port_pre_sel;
    input   [PV-1  : 0]  swap_port_presel;
    input   [PV-1 : 0] nonspec_first_arbiter_granted_ivc_all;    
    
    output  [WP-1 : 0] iport_weight_all;
    output  [PV-1 : 0] vc_weight_is_consumed_all;
    output  [P-1 : 0] iport_weight_is_consumed_all;
    input   [PP_1-1 : 0] granted_dest_port_all;
    output  [WPP-1 : 0] oports_weight_all;    
    
    output  ivc_info_t ivc_info [P-1 : 0][V-1 : 0]; 
    input   vsa_ctrl_t  vsa_ctrl_in [P-1: 0];
    input   ssa_ctrl_t  ssa_ctrl_in [P-1: 0];
    input   smart_ctrl_t  smart_ctrl_in [P-1 : 0];
    output  [CRDTw-1 : 0 ] credit_init_val_out [P-1 : 0][V-1 : 0];
    
    input refresh_w_counter;
    
    input   [DSTPw-1 : 0] destport_clear [P-1 : 0][V-1 : 0];
    input   ctrl_chanel_t ctrl_in  [P-1 : 0];
    
    genvar i;
    generate 
    for(i=0;i<P;i=i+1)begin : Port_
        
        input_queue_per_port
        // iport_reg_base
        #(
            .ROUTER_ID(ROUTER_ID),
            .SW_LOC(i),
            .P(P)
        ) the_input_queue_per_port (
            .router_info(router_info),
            .credit_out(credit_out_all [(i+1)*V-1 : i*V]),
            .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant  [(i+1)*V-1 : i*V]),// for non spec ivc_num_getting_first_sw_grant,
            .any_ivc_sw_request_granted(any_ivc_sw_request_granted_all  [i]),
            .flit_in(flit_in_all[(i+1)*Fw-1 : i*Fw]),
            .flit_in_wr(flit_in_wr_all[i]),
            .reset_ivc(reset_ivc_all [(i+1)*V-1 : i*V]),
            .flit_is_tail(flit_is_tail_all  [(i+1)*V-1 : i*V]),
            .ivc_request(ivc_request_all [(i+1)*V-1 : i*V]),    
            .dest_port(dest_port_all [(i+1)*P_1*V-1 : i*P_1*V]),
            .flit_out(flit_out_all [(i+1)*Fw-1 : i*Fw]),
            .assigned_ovc_not_full(assigned_ovc_not_full_all [(i+1)*V-1 : i*V]), 
            .ovc_is_assigned(ovc_is_assigned_all [(i+1)*V-1 : i*V]), 
            .sel(sel [(i+1)*V-1 : i*V]),
            .port_pre_sel(port_pre_sel),
            .swap_port_presel(swap_port_presel[(i+1)*V-1 : i*V]),
            .nonspec_first_arbiter_granted_ivc(nonspec_first_arbiter_granted_ivc_all[(i+1)*V-1 : i*V]),
            .reset(reset),
            .clk(clk),
            .destport_clear(destport_clear [i]),
            .iport_weight(iport_weight_all[(i+1)*W-1 : i*W]),
            .oports_weight(oports_weight_all[(i+1)*WP-1 : i*WP]),
            .vc_weight_is_consumed(vc_weight_is_consumed_all [(i+1)*V-1 : i*V]),
            .iport_weight_is_consumed(iport_weight_is_consumed_all[i]),
            .refresh_w_counter(refresh_w_counter),
            .granted_dest_port(granted_dest_port_all[(i+1)*P_1-1 : i*P_1]),
            .ivc_info(ivc_info[i]),
            .vsa_ctrl_in(vsa_ctrl_in [i]),
            .smart_ctrl_in(smart_ctrl_in [i]),
            .ssa_ctrl_in(ssa_ctrl_in [i]),
            .credit_init_val_out(credit_init_val_out[i]),
            .ctrl_in(ctrl_in)
        );
    end//for
    endgenerate
    
endmodule 


/**************************
    input_queue_per_port
 **************************/
module input_queue_per_port #(
    parameter ROUTER_ID=0,
    parameter P = 5,     // router port num
    parameter SW_LOC = 0
) (
    router_info,
    credit_out,
    ivc_num_getting_sw_grant,// for non spec ivc_num_getting_first_sw_grant,
    any_ivc_sw_request_granted,
    flit_in,
    flit_in_wr,
    reset_ivc,
    flit_is_tail,
    ivc_request,
    dest_port,
    flit_out,
    assigned_ovc_not_full,
    ovc_is_assigned,
    sel,
    port_pre_sel,
    swap_port_presel,
    reset,
    clk,
    nonspec_first_arbiter_granted_ivc,
    destport_clear,
    iport_weight,
    oports_weight,
    vc_weight_is_consumed,
    iport_weight_is_consumed,
    refresh_w_counter,
    granted_dest_port,
    ivc_info,
    smart_ctrl_in,
    vsa_ctrl_in,
    ssa_ctrl_in,
    credit_init_val_out,
    ctrl_in
);
    
    import pronoc_pkg::*;
    
    localparam 
        PORT_B = port_buffer_size(SW_LOC),
        PORT_Bw= log2(PORT_B),
        //PORT_IVC is equal to V if HETERO_VC=0
        PORT_IVC = hetero_ivc_decimal(ROUTER_ID, SW_LOC);
    
    localparam
        VV = V * V,
        VDSTPw = V * DSTPw,
        W = WEIGHTw,
        WP = W * P,
        P_1 = (SELF_LOOP_EN )?  P : P-1,
        VP_1 = V * P_1;
    
    localparam
        OFFSET = ((PORT_B % MIN_PCK_SIZE)>0) ? 1 : 0,
        NON_ATOM_PCKS =  (PORT_B > MIN_PCK_SIZE) ? (PORT_B / MIN_PCK_SIZE) + OFFSET : 1,
        MAX_PCK = // min packet size is two hence the max packet number in buffer is (B/2)
            (IS_VCA_ATOMIC) ?  1 : 
            (OVC_ALLOC_MODE) ? (NON_ATOM_PCKS + 1) : NON_ATOM_PCKS,
        IGNORE_SAME_LOC_RD_WR_WARNING = ((SSA_EN == 1) || (SMART_EN==1) ) ? 1 : 0;
    
    localparam
        ELw = log2(T3),
        Pw  = log2(P),
        PLw = (IS_FMESH) ? Pw : ELw,
        VPLw= V * PLw,
        PRAw= P * RAw;

    
    input reset, clk;
    input   router_info_t router_info;
    output  [V-1 : 0] credit_out;
    output  [V-1 : 0] ivc_num_getting_sw_grant;
    input   any_ivc_sw_request_granted;
    input   [Fw-1 : 0] flit_in;
    input   flit_in_wr;
    output  [V-1 : 0] reset_ivc;
    output  [V-1 : 0] flit_is_tail;
    output  [V-1 : 0] ivc_request;
    output  [VP_1-1 : 0] dest_port;
    output  [Fw-1 : 0] flit_out;
    input   [V-1  : 0] assigned_ovc_not_full;
    output  [V-1  : 0] ovc_is_assigned;
    input   [V-1 : 0] sel;    
    input   [V-1 : 0] nonspec_first_arbiter_granted_ivc;
    
    input   [DSTPw-1 : 0] destport_clear [V-1 : 0];
    output  [WEIGHTw-1 : 0] iport_weight;
    output  [V-1 : 0] vc_weight_is_consumed;
    output  iport_weight_is_consumed;
    input   refresh_w_counter;
    input   [P_1-1 : 0] granted_dest_port; 
    output  [WP-1 : 0] oports_weight;  
    input   [PPSw-1 : 0] port_pre_sel;
    input   [V-1  : 0]  swap_port_presel;
    
    output  ivc_info_t ivc_info [V-1 : 0]; 
    input   smart_ctrl_t  smart_ctrl_in;
    input   vsa_ctrl_t  vsa_ctrl_in;
    input   ssa_ctrl_t  ssa_ctrl_in;
    output  [CRDTw-1 : 0 ] credit_init_val_out [V-1 : 0];
    input   ctrl_chanel_t ctrl_in  [P-1 : 0];

    wire   [RAw-1 : 0] current_r_addr = router_info.router_addr;
    wire   [PRAw-1: 0] neighbors_r_addr = router_info.neighbors_r_addr[PRAw-1: 0];
    
    wire  [DSTPw-1 : 0] dest_port_encoded [V-1 : 0];
    //for multicast
    wire  [DSTPw-1 : 0] dest_port_multi   [V-1 : 0];
    wire  [V-1 : 0] multiple_dest,dst_onhot0;
    wire   [DSTPw-1 : 0] clear_dspt_mulicast  [V-1 : 0];
    
    logic  [V-1 : 0] candidate_ovcs [V-1 : 0];
    
    wire [Cw-1 : 0] class_in;
    wire [DSTPw-1 : 0] destport_in,destport_in_encoded;
    wire [VDSTPw-1 : 0] lk_destination_encoded;
    
    wire [DAw-1 : 0] dest_e_addr_in;
    wire [EAw-1 : 0] dest_e_addr_out [V-1 : 0];
    wire [EAw-1 : 0] src_e_addr_in;
    wire [V-1 : 0] vc_num_in;
    wire [V-1 : 0] hdr_flit_wr;
    wire [VV-1 : 0] assigned_ovc_num;
    logic [V-1 : 0] assigned_ovc_one_hot [V-1 : 0];
    logic [Vw-1 : 0] assigned_onc_bin [V-1 : 0];

    wire [DSTPw-1 : 0] lk_destination_in_encoded;
    wire [WEIGHTw-1  : 0] weight_in;   
    wire [Fw-1 : 0] buffer_out;
    wire hdr_flg_in,tail_flg_in;  
    wire [V-1 : 0] ivc_not_empty;
    wire [Cw-1 : 0] class_out [V-1 : 0];
    wire [VPLw-1 : 0] endp_localp_num;
    
    wire [V-1 : 0] smart_hdr_en;
    wire [ELw-1 : 0] endp_l_in;
    wire [Pw-1 : 0] endp_p_in;
    
    wire [V-1 : 0] rd_hdr_fwft_fifo,wr_hdr_fwft_fifo,rd_hdr_fwft_fifo_delay,wr_hdr_fwft_fifo_delay;
    
    logic [V-1  : 0] ovc_is_assigned_next;
    logic [V-1 : 0] assigned_ovc_num_next [V-1 : 0];
    
    wire odd_column = current_r_addr[0]; 
    wire [P-1 : 0] destport_one_hot [V-1 :0];
    wire [V-1 : 0] mux_out[V-1 : 0];
    
    wire [V-1 : 0] dstport_fifo_not_empty;
    
    logic  [WEIGHTw-1 : 0] iport_weight_next;
    
    assign smart_hdr_en  = (SMART_EN) ? smart_ctrl_in.ivc_num_getting_ovc_grant: {V{1'b0}};
    assign reset_ivc  = smart_ctrl_in.ivc_reset | ssa_ctrl_in.ivc_reset | vsa_ctrl_in.ivc_reset;
    assign ivc_num_getting_sw_grant = ssa_ctrl_in.ivc_num_getting_sw_grant | vsa_ctrl_in.ivc_num_getting_sw_grant;
    assign rd_hdr_fwft_fifo  = (ssa_ctrl_in.ivc_reset | vsa_ctrl_in.ivc_reset | (smart_ctrl_in.ivc_reset  & ~ smart_ctrl_in.ivc_single_flit_pck)) & ~ multiple_dest;
    assign wr_hdr_fwft_fifo  = hdr_flit_wr | (smart_hdr_en & ~ smart_ctrl_in.ivc_single_flit_pck);
    assign ivc_request = ivc_not_empty;
    
    wire  [V-1 : 0] flit_is_tail2;
    
    pronoc_register #(.W(V)) reg1(
        .D_in   (ovc_is_assigned_next), 
        .reset  (reset ), 
        .clk    (clk   ), 
        .Q_out  (ovc_is_assigned   ));
    
    pronoc_register #(.W(V)) reg3(
        .D_in   (rd_hdr_fwft_fifo), 
        .reset  (reset ), 
        .clk    (clk   ), 
        .Q_out  (rd_hdr_fwft_fifo_delay ));
    
    pronoc_register #(.W(V)) reg4(
        .D_in   (wr_hdr_fwft_fifo), 
        .reset  (reset ), 
        .clk    (clk   ), 
        .Q_out  (wr_hdr_fwft_fifo_delay ));
    
    pronoc_register #(.W(WEIGHTw), .RESET_TO(1)) reg5(
        .D_in   (iport_weight_next ), 
        .reset  (reset ), 
        .clk    (clk   ), 
        .Q_out  (iport_weight  ));
    
    pronoc_register #(.W(V)) credit_reg (
        .D_in   (ivc_num_getting_sw_grant & ~ multiple_dest),
        .reset  (reset),
        .clk    (clk),
        .Q_out  (credit_out)); 
    
    always_comb begin 
        iport_weight_next = iport_weight;
        if(hdr_flit_wr != {V{1'b0}})  iport_weight_next = (weight_in=={WEIGHTw{1'b0}})? WEIGHT_INIT : weight_in; // the minimum weight is 1
    end
    
    
    //extract header flit info
    extract_header_flit_info #(
        .DATA_w(0)
    ) header_extractor (
        .flit_in(flit_in),
        .flit_in_wr(flit_in_wr),
        .class_o(class_in),
        .destport_o(destport_in),
        .dest_e_addr_o(dest_e_addr_in),
        .src_e_addr_o(src_e_addr_in),
        .vc_num_o(vc_num_in),
        .hdr_flit_wr_o(hdr_flit_wr),
        .hdr_flg_o(hdr_flg_in),
        .tail_flg_o(tail_flg_in),
        .weight_o(weight_in),
        .be_o( ),
        .data_o( )
    );
    
    genvar i;
    generate
    for (i=0; i<V; i=i+1) begin : O_
        assign assigned_ovc_one_hot [i] = assigned_ovc_num[(i+1)*V-1 : i*V];
        pronoc_register #(.W(V)) reg2(
            .D_in   (assigned_ovc_num_next[i]), 
            .reset  (reset ), 
            .clk    (clk   ), 
            .Q_out  (assigned_ovc_num [(i+1)*V-1 : i*V]  ));
    end
    if (IS_REGULAR_TOPO & IS_MULTI_ENDP_ROUTER & IS_UNICAST) begin 
        mesh_tori_endp_addr_decode endp_addr_decode (
            .e_addr(dest_e_addr_in),
            .ex( ),
            .ey( ),
            .el(endp_l_in),
            .valid( )
        );
    end 
    if ( IS_FMESH & IS_UNICAST ) begin : fmesh
        fmesh_endp_addr_decode  endp_addr_decode (
            .e_addr(dest_e_addr_in),
            .ex(),
            .ey(),
            .ep(endp_p_in),
            .valid()
        );
    
    end
    /* verilator lint_off WIDTH */  
    if(IS_FATTREE & (ROUTE_NAME == "NCA_STRAIGHT_UP")) begin : fat
    /* verilator lint_on WIDTH */  
        
        fattree_destport_up_select #(
            .K(T1),
            .SW_LOC(SW_LOC)
        ) static_sel (
            .destport_in(destport_in),
            .destport_o(destport_in_encoded)
        );
        
    end else begin : other
        assign destport_in_encoded = destport_in;
    end
    
    logic [1:0] ovc_sel_i;
    logic [1:0] ovc_sel_ivc [V-1 : 0];
    if(IS_MULTI_MESH) begin : mmesh_
        multi_mesh_ovc_sel #(
            .SW_LOC(SW_LOC),
            .LOCAL_ADAPT(0)
        )ovc_sel(
            .local_dst_icr(dest_e_addr_in[DAw-1 : DAw/2]),// dest_e_addr_in = {local_dst_icr,global_dst}
            .current_router_addr_i(router_info.router_addr),
            .ovc_sel(ovc_sel_i)
        );
    end // "MULTI_MESH"
    
    always_comb begin
        for (int k=0; k<PORT_IVC; k=k+1) begin
            ivc_info[k].single_flit_pck = 
                ( IS_SINGLE_FLIT ) ? 1'b1  :
                ( MIN_PCK_SIZE == 1 ) ? flit_is_tail[k] & ~ovc_is_assigned[k] :  1'b0; 
            ivc_info[k].ivc_req = ivc_request[k];
            ivc_info[k].class_num = class_out[k];
            ivc_info[k].flit_is_tail = flit_is_tail[k];
            ivc_info[k].assigned_ovc_not_full = assigned_ovc_not_full[k];
            ivc_info[k].candidate_ovc = candidate_ovcs [k];
            ivc_info[k].ovc_is_assigned = ovc_is_assigned[k];
            ivc_info[k].assigned_ovc_num = assigned_ovc_one_hot[k];
            ivc_info[k].dest_port_encoded = dest_port_encoded[k];
            //ivc_info[k].getting_swa_first_arbiter_grant=nonspec_first_arbiter_granted_ivc[k];
            //ivc_info[k].getting_swa_grant=ivc_num_getting_sw_grant[k];
            ivc_info[k].destport_one_hot = {MAX_P{1'b0}};
            ivc_info[k].destport_one_hot[P-1 : 0] = destport_one_hot[k];
            ivc_info[k].assigned_ovc_bin = assigned_onc_bin[k];
            ivc_info[k].dest_e_addr = dest_e_addr_out[k];
        end //for k
        for (int k=PORT_IVC; k<V; k=k+1) begin 
            ivc_info[k] = {IVC_INFO_w{1'b0}};
        end//k
    end

    
    always_comb begin
        ovc_is_assigned_next = {V{1'b0}}; //for single flit mode
        for ( int k=0; k<PORT_IVC; k++) begin
            assigned_ovc_num_next[k]  = assigned_ovc_one_hot [k];
            if( IS_MULTI_FLIT) begin 
                ovc_is_assigned_next[k] = ovc_is_assigned[k];
                if( vsa_ctrl_in.ivc_reset[k] |
                        ssa_ctrl_in.ivc_reset[k] |
                        smart_ctrl_in.ivc_reset[k] 
                    )   ovc_is_assigned_next[k] = 1'b0;
                else if( vsa_ctrl_in.ivc_num_getting_ovc_grant[k] |
                        (ssa_ctrl_in.ivc_num_getting_ovc_grant[k] & ~  ssa_ctrl_in.ivc_single_flit_pck[k])|
                        (smart_ctrl_in.ivc_num_getting_ovc_grant[k] & ~  smart_ctrl_in.ivc_single_flit_pck[k])
                    )   ovc_is_assigned_next[k] = 1'b1;
                if(vsa_ctrl_in.ivc_num_getting_ovc_grant[k] | ssa_ctrl_in.ivc_num_getting_ovc_grant[k] | smart_ctrl_in.ivc_num_getting_ovc_grant[k] ) begin 
                    assigned_ovc_num_next[k] = mux_out[k];
                end
            end// "IS_MULTI_FLIT"
            else begin //single flit mode
                if(vsa_ctrl_in.ivc_num_getting_ovc_grant[k] | ssa_ctrl_in.ivc_num_getting_ovc_grant[k]) begin 
                    assigned_ovc_num_next[k] = mux_out[k];
                end
            end
        end //for k
    end//always 




    for (i=0;i<PORT_IVC; i=i+1) begin: V_
        
        assign credit_init_val_out [i] = PORT_B [CRDTw-1 : 0 ];
        
        one_hot_to_bin #(.ONE_HOT_WIDTH(V),.BIN_WIDTH(Vw)) conv (
            .one_hot_code(assigned_ovc_one_hot[i]), 
            .bin_code(assigned_onc_bin[i])
        );
        
        `ifdef SIMULATION
        //check ivc info
        //assigned ovc must be onehot coded
        //assert property (@(posedge clk) $onehot0(ivc_info[i].assigned_ovc_num));
        always @ (posedge clk )begin 
            if(~ $onehot0(ivc_info[i].assigned_ovc_num)) begin 
                $display ("ERROR: assigned OVC is not ont-hot coded %d,%m",ivc_info[i].assigned_ovc_num);
                $finish;
            end
        end
        `endif
        if(IS_MULTI_MESH==0) begin :ovc_
            ovc_list  OvcList(
                .class_in(class_out[i]),
                .ovcs_out(candidate_ovcs [i])
            );
        end else begin :mmesh_ovc
            fwft_fifo #(
                .DATA_WIDTH(2),
                .MAX_DEPTH (MAX_PCK),
                .IGNORE_SAME_LOC_RD_WR_WARNING(IGNORE_SAME_LOC_RD_WR_WARNING)
            ) ovc_fifo (
                .din (ovc_sel_i),
                .wr_en (wr_hdr_fwft_fifo[i]),   // Write enable
                .rd_en (rd_hdr_fwft_fifo[i]),   // Read the next word
                .dout (ovc_sel_ivc[i]),    // Data out
                .full ( ),
                .nearly_full ( ),
                .recieve_more_than_0 ( ),
                .recieve_more_than_1 ( ),
                .reset (reset),
                .clk (clk)
            );
            /*
            multi_mesh_ovc_list_per_ivc #(
                .IVC_NUM(i), //Input port VC number
                .P(P) //router IO number
            )OvcList(
                .destport_one_hot(destport_one_hot[i]),
                .ctrl_in(ctrl_in),
                .class_in(class_out[i]),
                .ovc_sel(ovc_sel_ivc[i]),
                .ovcs_out(candidate_ovcs [i])
            );
            */
        end
        if( IS_MULTI_FLIT) begin : multi_flit
            
            onehot_mux_1D #(
                .N  (3), 
                .W  (V)
            ) hot_mux (
                .D_in({vsa_ctrl_in.ivc_granted_ovc_num[(i+1)*V-1 : i*V], 
                        ssa_ctrl_in.ivc_granted_ovc_num[(i+1)*V-1 : i*V],
                        smart_ctrl_in.ivc_granted_ovc_num[(i+1)*V-1 : i*V]}), 
                .sel    ({vsa_ctrl_in.ivc_num_getting_ovc_grant[i],ssa_ctrl_in.ivc_num_getting_ovc_grant[i],smart_ctrl_in.ivc_num_getting_ovc_grant[i]}  ),
                .Q_out(mux_out[i]) 
            );
            
            /*
            //tail fifo
            fwft_fifo #(
                .DATA_WIDTH(1),
                .MAX_DEPTH (PORT_B),
                .IGNORE_SAME_LOC_RD_WR_WARNING(IGNORE_SAME_LOC_RD_WR_WARNING)
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
            */
            
        end else begin :single_flit
            //assign flit_is_tail[i]=1'b1;
            
            onehot_mux_1D #(
                .N (2), 
                .W (V)
            ) hot_mux (
                .D_in({vsa_ctrl_in.ivc_granted_ovc_num[(i+1)*V-1 : i*V], ssa_ctrl_in.ivc_granted_ovc_num[(i+1)*V-1 : i*V]}), 
                .sel ({vsa_ctrl_in.ivc_num_getting_ovc_grant[i], ssa_ctrl_in.ivc_num_getting_ovc_grant[i]}),
                .Q_out(mux_out[i]) 
            );
            
        end
        //dest_e_addr_in fifo
        if(SMART_EN) begin : smart_
            
            fwft_fifo #(
                .DATA_WIDTH(EAw),
                .MAX_DEPTH (MAX_PCK),
                .IGNORE_SAME_LOC_RD_WR_WARNING(IGNORE_SAME_LOC_RD_WR_WARNING)
            ) dest_e_addr_fifo (
                .din (dest_e_addr_in),
                .wr_en (wr_hdr_fwft_fifo[i]),   // Write enable
                .rd_en (rd_hdr_fwft_fifo[i]),   // Read the next word
                .dout (dest_e_addr_out[i]),    // Data out
                .full ( ),
                .nearly_full ( ),
                .recieve_more_than_0 ( ),
                .recieve_more_than_1 ( ),
                .reset (reset),
                .clk (clk)
            );
            
        end else begin : no_smart
            assign dest_e_addr_out[i]= {EAw{1'b0}};
        end    
        
        //class_fifo
        if(C>1)begin :cb1
            fwft_fifo #(
                .DATA_WIDTH(Cw),
                .MAX_DEPTH (MAX_PCK),
                .IGNORE_SAME_LOC_RD_WR_WARNING(IGNORE_SAME_LOC_RD_WR_WARNING)
            ) class_fifo (
                .din (class_in),
                .wr_en (wr_hdr_fwft_fifo[i]),   // Write enable
                .rd_en (rd_hdr_fwft_fifo[i]),   // Read the next word
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
        
        if(~IS_UNICAST) begin : muticast
            // for multicast we send one packet to each direction in order. The priority is according to DoR routing dimentions 
            fwft_fifo_with_output_clear #(
                .DATA_WIDTH(DSTPw),
                .MAX_DEPTH (MAX_PCK),
                .IGNORE_SAME_LOC_RD_WR_WARNING(IGNORE_SAME_LOC_RD_WR_WARNING)
            ) dest_fifo (
                .din(destport_in_encoded),
                .wr_en(wr_hdr_fwft_fifo[i]),   // Write enable
                .rd_en(rd_hdr_fwft_fifo[i]),   // Read the next word
                .dout(dest_port_multi[i]),    // Data out
                .full(),
                .nearly_full(),
                .recieve_more_than_0(),
                .recieve_more_than_1(),
                .reset(reset),
                .clk(clk),
                .clear(clear_dspt_mulicast [i])   // clear the  destination port once it got  the entire packet
            );
            
            //TODO remove multiple_dest[i] to see if it works?
            
            assign clear_dspt_mulicast [i] = (reset_ivc[i] & multiple_dest[i]) ? dest_port_encoded[i] : {DSTPw{1'b0}}; 
            
            // a fix priority arbiter. 
            multicast_dst_sel sel_arb(
                .destport_in(dest_port_multi[i]),
                .destport_out(dest_port_encoded[i])
            );

            //check if we have multiple port to send a packet to 
            is_onehot0 #(
                .IN_WIDTH(DSTPw)
            ) one_h (
                .D_in(dest_port_multi[i]),
                .result(dst_onhot0[i])
            );
            assign multiple_dest[i]=~dst_onhot0[i];
            
        end else begin : unicast
            assign multiple_dest[i] = 1'b0;
            
            //lk_dst_fifo
            fwft_fifo #(
                .DATA_WIDTH(DSTPw),
                .MAX_DEPTH (MAX_PCK),
                .IGNORE_SAME_LOC_RD_WR_WARNING(IGNORE_SAME_LOC_RD_WR_WARNING)
            ) lk_dest_fifo (
                .din (lk_destination_in_encoded),
                .wr_en (wr_hdr_fwft_fifo_delay [i]),   // Write enable
                .rd_en (rd_hdr_fwft_fifo_delay [i]),   // Read the next word
                .dout (lk_destination_encoded  [(i+1)*DSTPw-1 : i*DSTPw]),    // Data out
                .full (),
                .nearly_full (),
                .recieve_more_than_0 (),
                .recieve_more_than_1 (),
                .reset (reset),
                .clk (clk)
            );
            
            if( IS_DETERMINISTIC ) begin : dtrmn_dest
                //destport_fifo
                fwft_fifo #(
                    .DATA_WIDTH(DSTPw),
                    .MAX_DEPTH (MAX_PCK),
                    .IGNORE_SAME_LOC_RD_WR_WARNING(IGNORE_SAME_LOC_RD_WR_WARNING)
                ) dest_fifo (
                    .din(destport_in_encoded),
                    .wr_en(wr_hdr_fwft_fifo[i]),   // Write enable
                    .rd_en(rd_hdr_fwft_fifo[i]),   // Read the next word
                    .dout(dest_port_encoded[i]),    // Data out
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
                    .MAX_DEPTH (MAX_PCK),
                    .IGNORE_SAME_LOC_RD_WR_WARNING(IGNORE_SAME_LOC_RD_WR_WARNING)
                ) dest_fifo (
                    .din(destport_in_encoded),
                    .wr_en(wr_hdr_fwft_fifo[i]),   // Write enable
                    .rd_en(rd_hdr_fwft_fifo[i]),   // Read the next word
                    .dout(dest_port_encoded[i]),    // Data out
                    .full(),
                    .nearly_full(),
                    .recieve_more_than_0(),
                    .recieve_more_than_1(),
                    .reset(reset),
                    .clk(clk),
                    .clear(destport_clear[i])   // clear other destination ports once one of them is selected
                );
                
            end//   : adptv_dest
        end//unicast
        
        destp_generator #(
            .P(P),
            .SW_LOC(SW_LOC)
        ) decoder (
            .destport_one_hot (destport_one_hot[i]),
            .dest_port_encoded(dest_port_encoded[i]),
            .dest_port_out(dest_port[(i+1)*P_1-1 : i*P_1]),
            .endp_localp_num(endp_localp_num[(i+1)*PLw-1 : i*PLw]),
            .swap_port_presel(swap_port_presel[i]),
            .port_pre_sel(port_pre_sel),
            .odd_column(odd_column)
        );
        
        if ( IS_REGULAR_TOPO & IS_MULTI_ENDP_ROUTER & IS_UNICAST ) begin : multi_local
            // the router has multiple local ports. Save the destination local port
            fwft_fifo #(
                .DATA_WIDTH(ELw),
                .MAX_DEPTH (MAX_PCK),
                .IGNORE_SAME_LOC_RD_WR_WARNING(IGNORE_SAME_LOC_RD_WR_WARNING)
            ) local_dest_fifo (
                .din(endp_l_in),
                .wr_en(wr_hdr_fwft_fifo[i]),   // Write enable
                .rd_en(rd_hdr_fwft_fifo[i]),   // Read the next word
                .dout(endp_localp_num[(i+1)*PLw-1 : i*PLw]),    // Data out
                .full( ),
                .nearly_full( ),
                .recieve_more_than_0(),
                .recieve_more_than_1(),
                .reset(reset),
                .clk(clk) 
            );
        end else if ( IS_FMESH & IS_UNICAST) begin : fmesh
            
            fwft_fifo #(
                .DATA_WIDTH(Pw),
                .MAX_DEPTH (MAX_PCK),
                .IGNORE_SAME_LOC_RD_WR_WARNING(IGNORE_SAME_LOC_RD_WR_WARNING)
            ) local_dest_fifo (
                .din(endp_p_in),
                .wr_en(wr_hdr_fwft_fifo[i]),   // Write enable
                .rd_en(rd_hdr_fwft_fifo[i]),   // Read the next word
                .dout(endp_localp_num[(i+1)*PLw-1 : i*PLw]),    // Data out
                .full( ),
                .nearly_full( ),
                .recieve_more_than_0(),
                .recieve_more_than_1(),
                .reset(reset),
                .clk(clk) 
            );
            
        end else begin : single_local 
            assign endp_localp_num[(i+1)*PLw-1 : i*PLw] = {PLw{1'b0}}; 
        end
        assign vc_weight_is_consumed[i] = (~IS_RRA);
        
    end//for i
    
    if(~IS_RRA) begin  : wrra
        wire granted_flit_is_tail;
        
        onehot_mux_1D #( 
            .W(1),
            .N(V)
        )onehot_mux(
            .D_in(flit_is_tail),
            .Q_out(granted_flit_is_tail),
            .sel(ivc_num_getting_sw_grant)
        );
        
        weight_control#(
            .ARBITER_TYPE(SWA_ARBITER_TYPE),
            .SW_LOC(SW_LOC),
            .WEIGHTw(WEIGHTw),
            .WRRA_CONFIG_INDEX(WRRA_CONFIG_INDEX),
            .P(P),
            .SELF_LOOP_EN(SELF_LOOP_EN)
        ) wctrl_iport (
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
        
    end else begin :no_wrra
        assign iport_weight_is_consumed=1'b0;
        assign oports_weight = {WP{1'b0}};
    end
    wire [V-1 : 0] flit_buffer_vc_num_rd;
    assign flit_buffer_vc_num_rd = ( IS_COMB_NONSPEC ) ? nonspec_first_arbiter_granted_ivc : ivc_num_getting_sw_grant;
    
    flit_buffer #(
        .B(PORT_B),   // buffer space :flit per VC,
        .V(PORT_IVC)
    ) the_flit_buffer (
        .din(flit_in),     // Data in
        .vc_num_wr(vc_num_in [PORT_IVC-1 : 0]),//write virtual channel
        .vc_num_rd(flit_buffer_vc_num_rd [PORT_IVC-1 : 0]),//read virtual channel
        .wr_en(flit_in_wr),   // Write enable
        .rd_en(any_ivc_sw_request_granted),     // Read the next word
        .dout(buffer_out),    // Data out
        .vc_not_empty(ivc_not_empty [PORT_IVC-1 : 0]),
        .reset(reset),
        .clk(clk),
        .ssa_rd(ssa_ctrl_in.ivc_num_getting_sw_grant[PORT_IVC-1 : 0]),
        .multiple_dest( multiple_dest [PORT_IVC-1 : 0]),
        .sub_rd_ptr_ld(reset_ivc [PORT_IVC-1 : 0]) ,
        .flit_is_tail(flit_is_tail [PORT_IVC-1 : 0])
    );
    
    if(PORT_IVC != V) begin : hetero
        assign ivc_not_empty [V-1 : PORT_IVC]={(V-PORT_IVC){1'b0}};
        assign flit_is_tail [V-1 : PORT_IVC]={(V-PORT_IVC){1'b0}};
        for (i=PORT_IVC;i<V; i=i+1) begin: V_
            assign credit_init_val_out [i] = {CRDTw{1'b0}};
            assign candidate_ovcs [i] = {V{1'b0}};
            assign class_out[i]={Cw{1'b0}};
            assign dest_port_multi[i]={DSTPw{1'b0}};
            assign dest_port_encoded[i]={DSTPw{1'b0}};
            assign lk_destination_encoded [(i+1)*DSTPw-1 : i*DSTPw]={DSTPw{1'b0}};
            assign endp_localp_num[(i+1)*PLw-1 : i*PLw]={PLw{1'b0}};
            assign vc_weight_is_consumed[i]=1'b0;
        end
    end
    
    if( IS_UNICAST ) begin : unicast
        look_ahead_routing #(
            .P(P),
            .SW_LOC(SW_LOC)
        ) lk_routing (
            .current_r_addr(current_r_addr),
            .neighbors_r_addr(neighbors_r_addr),
            .dest_e_addr(dest_e_addr_in),
            .src_e_addr(src_e_addr_in),
            .destport_encoded(destport_in_encoded),
            .lkdestport_encoded(lk_destination_in_encoded),
            .reset(reset),
            .clk(clk)
        );
    end // unicast
    endgenerate
    header_flit_update_lk_route_ovc #(
        .P(P)
    ) the_flit_update (
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
    
    `ifdef SIMULATION
    generate
    if(DEBUG_EN) begin :debg
        
        always @ (posedge clk) begin
            if((|vsa_ctrl_in.ivc_num_getting_sw_grant)  & (|ssa_ctrl_in.ivc_num_getting_sw_grant))begin
                $display("%t: ERROR: VSA/SSA conflict: an input port cannot get both sva and ssa grant at the same time %m",$time);
                $finish;
            end
        end//always
        
        for (i=0;i<V;i=i+1)begin : V_
            always @ (posedge clk) begin
                if(vsa_ctrl_in.ivc_num_getting_ovc_grant[i] | ssa_ctrl_in.ivc_num_getting_ovc_grant[i] | (smart_ctrl_in.ivc_num_getting_ovc_grant[i] & (PCK_TYPE == "MULTI_FLIT"))  )begin 
                    if( ~ $onehot (mux_out[i])) begin 
                        $display("%t: ERROR: granted OVC num is not onehot coded %b: %m",$time,mux_out[i]);
                        $finish;
                    end
                end
                if( ~ $onehot0( {vsa_ctrl_in.ivc_num_getting_ovc_grant[i],ssa_ctrl_in.ivc_num_getting_ovc_grant[i],(smart_ctrl_in.ivc_num_getting_ovc_grant[i]&& (PCK_TYPE == "MULTI_FLIT"))})) begin 
                    $display("%t: ERROR: ivc num %d getting more than one ovc grant from VSA,SSA,SMART: %m",$time,i);
                    $finish;
                end
            end//always
            
            always @(posedge clk) begin
                if((dest_port [(i+1)*P_1-1 : i*P_1] == {P_1{1'b0}})  && (ivc_request[i]==1'b1)) begin 
                    $display ("%t: ERROR: The destination port is not set for an active IVC request: %m \n",$time);
                    $finish;
                end
            end
        end//for
        if (IS_REGULAR_TOPO & IS_UNICAST) begin : mesh_based
            
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
            ) route_ckeck (
                .reset(reset),
                .clk(clk),
                .hdr_flg_in(hdr_flg_in),
                .flit_in_wr(flit_in_wr),
                .vc_num_in(vc_num_in),
                .flit_is_tail(flit_is_tail),
                .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant),
                .current_r_addr(current_r_addr),
                .dest_e_addr_in(dest_e_addr_in),
                .src_e_addr_in(src_e_addr_in),
                .destport_in(destport_in)
            );
        end//mesh
        if (PORT_IVC != V) begin : hetero
            always @(posedge clk) begin
                if (flit_in_wr &  (|(vc_num_in & ~hetero_ovc_unary(router_info.router_id , SW_LOC)))) begin
                    $display("%t: ERROR: Input port supports %0d VCs, but received a flit targeting an out-of-bound VC: %b. Module: %m\n", 
                    $time, PORT_IVC, vc_num_in[V-1 : PORT_IVC]);
                    $finish;
                end
            end
        end // hetero
    end//DEBUG_EN
    
    `ifdef MONITORE_PATH
    genvar j;
    reg[V-1 :0] t1;
    for (j=0;j<V;j=j+1)begin : lp
        always @(posedge clk) begin
            if(`pronoc_reset)begin
                t1[j]<=1'b0;
            end else begin
                if(flit_in_wr >0 && vc_num_in[j] && t1[j]==0)begin
                    $display("%t : Parser:current_r=%h, class_in=%h, destport_in=%h, dest_e_addr_in=%h, src_e_addr_in=%h, vc_num_in=%h,hdr_flit_wr=%h, hdr_flg_in=%h,tail_flg_in=%h ",$time,current_r_addr, class_in, destport_in, dest_e_addr_in, src_e_addr_in, vc_num_in,hdr_flit_wr, hdr_flg_in,tail_flg_in);
                    t1[j]<=1;
                end
            end
        end
    end
    `endif//MONITORE_PATH
    endgenerate
`endif// SIMULATION
endmodule


// decode and mask the destination port according to routing algorithm and topology
module destp_generator #(
    parameter P=5,
    parameter SW_LOC=0
)(
    destport_one_hot,
    dest_port_encoded,
    dest_port_out,
    endp_localp_num,
    swap_port_presel,
    port_pre_sel,
    odd_column
);
    import pronoc_pkg::*;

    localparam
        ELw = log2(T3),
        Pw  = log2(P),
        PLw = (IS_FMESH) ? Pw : ELw;

    localparam P_1 = (SELF_LOOP_EN )?  P : P-1;
    input [DSTPw-1 : 0]  dest_port_encoded;
    input [PLw-1 : 0] endp_localp_num;
    output [P_1-1: 0] dest_port_out;
    output [P-1 : 0] destport_one_hot;
    input  swap_port_presel;
    input  [PPSw-1 : 0] port_pre_sel;
    input odd_column;
    
    generate
    if( ~IS_UNICAST ) begin : muticast
        // destination port is not coded for multicast/broadcast
        if( SELF_LOOP_EN==0) begin : nslp
            remove_sw_loc_one_hot #(
                .P(P),
                .SW_LOC(SW_LOC)
            ) remove_sw_loc (
                .destport_in(dest_port_encoded),
                .destport_out(dest_port_out)
            );
        end else begin : slp
            assign dest_port_out = dest_port_encoded;
        end
    end else if( IS_FATTREE ) begin : fat
        fattree_destp_generator #(
            .K(T1),
            .P(P),
            .SW_LOC(SW_LOC),
            .DSTPw(DSTPw),
            .SELF_LOOP_EN(SELF_LOOP_EN)
            )
        destp_generator
        (
            .dest_port_in_encoded(dest_port_encoded),
            .dest_port_out(dest_port_out)
        );
    end else  if ( IS_TREE ) begin :tree
        tree_destp_generator #(
            .K(T1),
            .P(P),
            .SW_LOC(SW_LOC),
            .DSTPw(DSTPw),
            .SELF_LOOP_EN(SELF_LOOP_EN)
        ) destp_generator (
            .dest_port_in_encoded(dest_port_encoded),
            .dest_port_out(dest_port_out)
        );
    end else if( IS_REGULAR_TOPO ) begin : reqular
        mesh_torus_destp_generator #(
            .TOPOLOGY(TOPOLOGY),
            .ROUTE_NAME(ROUTE_NAME),
            .ROUTE_TYPE(ROUTE_TYPE),
            .P(P),
            .DSTPw(DSTPw),
            .NL(NL),
            .PLw(PLw),
            .PPSw(PPSw),
            .SW_LOC(SW_LOC),
            .SELF_LOOP_EN(SELF_LOOP_EN)
        ) destp_generator (
            .dest_port_coded(dest_port_encoded),
            .endp_localp_num(endp_localp_num),
            .dest_port_out(dest_port_out),
            .swap_port_presel(swap_port_presel),
            .port_pre_sel(port_pre_sel),
            .odd_column(odd_column)// only needed for odd even routing
        );
    end else if ( IS_FMESH ) begin :fmesh
        fmesh_destp_generator  #(
            .ROUTE_NAME(ROUTE_NAME),
            .ROUTE_TYPE(ROUTE_TYPE),
            .P(P),
            .DSTPw(DSTPw),
            .NL(NL),
            .PLw(PLw),
            .PPSw(PPSw),
            .SW_LOC(SW_LOC),
            .SELF_LOOP_EN(SELF_LOOP_EN)
        ) destp_generator (
            .dest_port_coded(dest_port_encoded),
            .endp_localp_num(endp_localp_num),
            .dest_port_out(dest_port_out),
            .swap_port_presel(swap_port_presel),
            .port_pre_sel(port_pre_sel),
            .odd_column(odd_column) // only needed for odd even routing
        );
    end else begin :custom
        custom_topology_destp_decoder #(
            .ROUTE_TYPE(ROUTE_TYPE),
            .DSTPw(DSTPw),
            .P(P),
            .SW_LOC(SW_LOC),
            .SELF_LOOP_EN(SELF_LOOP_EN)
        ) destp_generator (
            .dest_port_in_encoded(dest_port_encoded),
            .dest_port_out(dest_port_out)
        );
    end
    if(SELF_LOOP_EN==0) begin : nslp
        add_sw_loc_one_hot #(
            .P(P),
            .SW_LOC(SW_LOC)
        )add (
            .destport_in(dest_port_out),
            .destport_out(destport_one_hot)
        );
        
    end else begin : slp
        assign destport_one_hot = dest_port_out;
    end
    endgenerate
    
endmodule

/******************
 *   custom_topology_destp_decoder
 * ***************/
module custom_topology_destp_decoder #(
    parameter ROUTE_TYPE="DETERMINISTIC",
    parameter DSTPw=4,
    parameter P=5,
    parameter SW_LOC=0,
    parameter SELF_LOOP_EN=0
)(
    dest_port_in_encoded,
    dest_port_out
);
    
    localparam
        P_1 = (SELF_LOOP_EN )?  P : P-1,
        MAXW =2**DSTPw;
    
    input  [DSTPw-1 : 0] dest_port_in_encoded;
    output [P_1-1 : 0] dest_port_out;
    
    wire [MAXW-1 : 0] dest_port_one_hot;
    
    bin_to_one_hot #(
        .BIN_WIDTH(DSTPw),
        .ONE_HOT_WIDTH(MAXW)
    ) conv (
        .bin_code(dest_port_in_encoded),
        .one_hot_code(dest_port_one_hot)
    );
    
    generate
    if( SELF_LOOP_EN==0) begin : nslp
        remove_sw_loc_one_hot #(
            .P(P),
            .SW_LOC(SW_LOC)
        ) remove_sw_loc (
            .destport_in(dest_port_one_hot[P-1 : 0]),
            .destport_out(dest_port_out)
        );
    end else begin : slp
        assign dest_port_out = dest_port_one_hot;
    end
    endgenerate
    
    `ifdef SIMULATION
    initial begin
        if( ROUTE_TYPE != "DETERMINISTIC") begin
            $display("%t: ERROR: Custom topologies can only support deterministic routing in the current version of ProNoC",$time);
            $finish;
        end
    end
    `endif
endmodule
