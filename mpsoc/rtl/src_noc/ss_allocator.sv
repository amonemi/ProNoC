`include "pronoc_def.v"
/**********************************************************************
**    File: ss_allocator.v
**    Date:2016-06-19  
**    
**    Copyright (C) 2014-2019  Alireza Monemi
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
**    static straight allocator : The incoming packet targeting output port located in same direction 
**     will be forwarded with one clock cycle latency if the following conditions met in current clock cycle:
**    1) If no ivc is granted in the input port 
**    2) The ss output port is not granted for any other input port 
**    3) Packet destination port match with ss port
**    4) The requested output VC is available in ss port 
**       The ss ports for each input potrt must be different with the rest
**       This result in one clock cycle latency                
***************************************/


module  ss_allocator #(
    parameter NOC_ID=0,
    parameter P=5
)(
    clk,
    reset,  
    flit_in_wr_all,
    flit_in_all,
    any_ovc_granted_in_outport_all ,
    any_ivc_sw_request_granted_all ,
    ovc_avalable_all,
    ivc_info,
    ovc_info,
    ssa_ctrl_o
);
    `NOC_CONF
    localparam
        PV = V * P,
        VV = V * V,
        PVV = PV * V,
        PVDSTPw= PV * DSTPw,
        PFw = P * Fw,
        DISABLED = P;
        
    input [PFw-1 : 0]  flit_in_all;
    input [P-1 : 0]  flit_in_wr_all;
    input [P-1 : 0]  any_ovc_granted_in_outport_all;
    input [P-1 : 0]  any_ivc_sw_request_granted_all;
    input [PV-1 : 0]  ovc_avalable_all;
    input   reset,clk;
    input   ivc_info_t   ivc_info   [P-1 : 0][V-1 : 0];
    input   ovc_info_t   ovc_info   [P-1 : 0][V-1 : 0];
    output  ssa_ctrl_t   ssa_ctrl_o [P-1 : 0]; 
    
    wire [PV-1 : 0] ovc_allocated_all;
    wire [PV-1 : 0] ovc_released_all;
    wire [PVV-1 : 0] granted_ovc_num_all;
    wire [PV-1 : 0] ivc_num_getting_sw_grant_all;
    wire [PV-1 : 0] ivc_num_getting_ovc_grant_all;
    wire [PV-1 : 0] ivc_reset_all;
    wire [PV-1 : 0] single_flit_pck_all,ovc_single_flit_pck_all;
    wire [PV-1 : 0] decreased_credit_in_ss_ovc_all;
    wire [P-1 : 0] ssa_flit_wr_all;
    wire [PV-1 : 0] any_ovc_granted_in_ss_port;
    wire [PV-1 : 0] ovc_avalable_in_ss_port;
    wire [PV-1 : 0] ovc_allocated_in_ss_port;
    wire [PV-1 : 0] ovc_released_in_ss_port;
    wire [PV-1 : 0] decreased_credit_in_ss_ovc;
    wire [PV-1 : 0] ivc_num_getting_sw_grantin_SS_all;
    wire [PV-1 : 0] ivc_request_all;
    wire [PV-1 : 0] assigned_ovc_not_full_all;
    wire [PVDSTPw-1 : 0] dest_port_encoded_all;
    wire [PVV-1 : 0] assigned_ovc_num_all;
    wire [PV-1 : 0] ovc_is_assigned_all;
    wire [MAX_P-1 : 0] destport_one_hot [PV-1 : 0];
    
    genvar i;
    // there is no ssa for local port in 5 and 3 port routers
    generate
    for (i=0; i<PV; i=i+1) begin : V_
        localparam  C_PORT  = i/V;
        localparam  SS_PORT = strieght_port (P,C_PORT);
        assign ivc_request_all[i] = ivc_info[C_PORT][i%V].ivc_req;
        
        //assign assigned_ovc_not_full_all[i] = ivc_info[C_PORT][i%V].assigned_ovc_not_full;
        assign dest_port_encoded_all [(i+1)*DSTPw-1 : i*DSTPw] = ivc_info[C_PORT][i%V].dest_port_encoded;
        assign assigned_ovc_num_all[(i+1)*V-1 : i*V] = ivc_info[C_PORT][i%V].assigned_ovc_num;
        assign ovc_is_assigned_all[i] = ivc_info[C_PORT][i%V].ovc_is_assigned;
        assign destport_one_hot[i] = ivc_info[C_PORT][i%V].destport_one_hot;
        
        if (SS_PORT == DISABLED)begin : no_prefrable
            assign   ovc_allocated_all[i]= 1'b0;
            assign   ovc_released_all [i]= 1'b0;
            assign   granted_ovc_num_all[(i+1)*V-1 : i*V]= {V{1'b0}};
            assign   ivc_num_getting_sw_grant_all [i]= 1'b0;
            assign   ivc_num_getting_ovc_grant_all [i]= 1'b0;
            assign   ivc_reset_all [i]= 1'b0;
            assign   decreased_credit_in_ss_ovc_all[i]=1'b0;
            assign   single_flit_pck_all[i]= 1'b0;
            assign   ovc_single_flit_pck_all [i] =1'b0;
            assign   ivc_num_getting_sw_grantin_SS_all[i]=1'b0;
            assign   assigned_ovc_not_full_all[i]=1'b0;
           // assign   predict_flit_wr_all [i]=1'b0;
        end else begin : ssa
            assign   assigned_ovc_not_full_all[i] = ~ovc_info[SS_PORT][i%V].full;
            assign   any_ovc_granted_in_ss_port[i]=any_ovc_granted_in_outport_all[SS_PORT];
            assign   ovc_avalable_in_ss_port[i]=ovc_avalable_all[(SS_PORT*V)+(i%V)];
            assign   ovc_allocated_all[(SS_PORT*V)+(i%V)]=ovc_allocated_in_ss_port[i];
            assign   ovc_released_all[(SS_PORT*V)+(i%V)]=ovc_released_in_ss_port[i];
            assign   decreased_credit_in_ss_ovc_all[(SS_PORT*V)+(i%V)]=decreased_credit_in_ss_ovc[i]; 
            assign   ivc_num_getting_sw_grantin_SS_all[i]=  ivc_num_getting_sw_grant_all[(SS_PORT*V)+(i%V)];    
            assign   ovc_single_flit_pck_all [i] =  single_flit_pck_all[(SS_PORT*V)+(i%V)];
            
            ssa_per_vc #(
                .NOC_ID(NOC_ID),
                .SS_PORT(SS_PORT),
                .V_GLOBAL(i),
                .P(P)
            ) the_ssa_per_vc (
                .flit_in_wr(flit_in_wr_all[(i/V)]),
                .flit_in(flit_in_all[((i/V)+1)*Fw-1 : (i/V)*Fw]),
                .any_ivc_sw_request_granted(any_ivc_sw_request_granted_all[(i/V)]),
                .any_ovc_granted_in_ss_port(any_ovc_granted_in_ss_port[i]),
                .ovc_avalable_in_ss_port(ovc_avalable_in_ss_port[i]),
                .ivc_request(ivc_request_all[i]),
                .assigned_ovc_not_full(assigned_ovc_not_full_all[i]),
                .destport_encoded(dest_port_encoded_all[(i+1)*DSTPw-1 : i*DSTPw]),
                .assigned_to_ssovc(assigned_ovc_num_all[(i*V)+(i%V)]),
                .ovc_is_assigned(ovc_is_assigned_all[i]),
                .ovc_allocated(ovc_allocated_in_ss_port[i]),
                .ovc_released(ovc_released_in_ss_port[i]),
                .granted_ovc_num(granted_ovc_num_all[(i+1)*V-1 : i*V]),
                .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant_all[i]),
                .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant_all[i]),
                .ivc_reset(ivc_reset_all[i]), 
                .single_flit_pck(single_flit_pck_all[i]),
                .destport_one_hot(destport_one_hot[i]),
                .decreased_credit_in_ss_ovc(decreased_credit_in_ss_ovc[i])
                `ifdef SIMULATION
                ,.clk(clk)
                `endif 
            );
        end//ssa
    end// vc_loop
    
    for(i=0;i<P;i=i+1)begin: P_
        pronoc_register #(.W(1)) reg1 (
            .in(|ivc_num_getting_sw_grantin_SS_all[(i+1)*V-1 : i*V] ),
            .out(ssa_flit_wr_all[i]),
            .reset(reset),
            .clk(clk)
        );
        
        assign ssa_ctrl_o[i].ovc_is_allocated =ovc_allocated_all [(i+1)*V-1 : i*V];
        assign ssa_ctrl_o[i].ovc_is_released = ovc_released_all  [(i+1)*V-1 : i*V];      
        assign ssa_ctrl_o[i].ivc_num_getting_sw_grant = ivc_num_getting_sw_grant_all[(i+1)*V-1 : i*V]; 
        assign ssa_ctrl_o[i].ivc_num_getting_ovc_grant= ivc_num_getting_ovc_grant_all[(i+1)*V-1 : i*V];
        assign ssa_ctrl_o[i].ivc_reset= ivc_reset_all[(i+1)*V-1 : i*V];
        assign ssa_ctrl_o[i].buff_space_decreased = decreased_credit_in_ss_ovc_all[(i+1)*V-1 : i*V];
        assign ssa_ctrl_o[i].ivc_single_flit_pck = single_flit_pck_all [(i+1)*V-1 : i*V];
        assign ssa_ctrl_o[i].ovc_single_flit_pck = ovc_single_flit_pck_all [(i+1)*V-1 : i*V];
        assign ssa_ctrl_o[i].ssa_flit_wr = ssa_flit_wr_all[i] ;
        assign ssa_ctrl_o[i].ivc_granted_ovc_num = granted_ovc_num_all[(i+1)*VV-1 : i*VV];
    end// port_lp
    endgenerate
endmodule

/*************
 *  ssa_per_vc 
 * ***********/
module ssa_per_vc #(
    parameter NOC_ID=0,
    parameter P=5,
    parameter SS_PORT = "WEST",
    parameter V_GLOBAL = 1
) (
    flit_in_wr,
    flit_in,
    any_ovc_granted_in_ss_port,
    any_ivc_sw_request_granted,
    ovc_avalable_in_ss_port,
    ivc_request,
    assigned_ovc_not_full,
    granted_ovc_num,
    ivc_num_getting_sw_grant,
    ivc_num_getting_ovc_grant,
    assigned_to_ssovc,
    ovc_is_assigned,
    destport_encoded,
    ovc_released,
    ovc_allocated,
    decreased_credit_in_ss_ovc,
    single_flit_pck,
    destport_one_hot,
    ivc_reset      
    `ifdef SIMULATION
    ,clk
    `endif
);
    
    `NOC_CONF
    //header packet filds width
    localparam  
        SW_LOC = V_GLOBAL/V,
        V_LOCAL = V_GLOBAL%V;
    /* verilator lint_off WIDTH */ 
    localparam SSA_EN_IN_PORT = ((IS_MESH | IS_TORUS) && (ROUTE_TYPE == "FULL_ADAPTIVE") && (SS_PORT==2 || SS_PORT == 4) && ((1<<V_LOCAL &  ~ESCAP_VC_MASK ) != {V{1'b0}})) ? 1'b0 :1'b1;
    /* verilator lint_on WIDTH */
    
    input [Fw-1 : 0]  flit_in;
    input flit_in_wr;
    input any_ovc_granted_in_ss_port;
    input any_ivc_sw_request_granted;
    input ovc_avalable_in_ss_port;
    input ivc_request; 
    input assigned_ovc_not_full;  
    input [DSTPw-1 : 0]  destport_encoded;//exsited packet destination port
    input assigned_to_ssovc;
    input ovc_is_assigned;
    input [MAX_P-1 : 0]  destport_one_hot;
    output reg [V-1 : 0]  granted_ovc_num;
    output ivc_num_getting_sw_grant;
    output ivc_num_getting_ovc_grant;
    output ovc_released;
    output ovc_allocated;
    output ivc_reset;
    output decreased_credit_in_ss_ovc;
    output single_flit_pck;
`ifdef SIMULATION
    input clk;
`endif
/*
*    1) If no ivc is granted in the input port 
*    2) The ss output port is not granted for any other input port 
*    3) Incomming packet destionation port match with ss port
*    4) In non-atomic Vc reallocation check if IVC is empty 
*    5) The requested output VC is available in ss port 
* The predicted ports for each input potrt must be diffrent with the rest
*/
    wire    [DSTPw-1 : 0] destport_in_encoded;//incomming packet destination port
    wire    [V-1 : 0] vc_num_in;
    wire    hdr_flg;
    wire    tail_flg;
    /* verilator lint_off WIDTH */ 
    assign  single_flit_pck = 
        (PCK_TYPE == "SINGLE_FLIT")? 1'b1 :
        (MIN_PCK_SIZE==1)?  hdr_flg & tail_flg : 1'b0; 
    /* verilator lint_on WIDTH */
    wire   condition_1_2_valid;
    wire [DAw-1 : 0]  dest_e_addr_in;
    extract_header_flit_info #(
        .NOC_ID(NOC_ID),
        .DATA_w(0)    
    ) extractor (
        .flit_in(flit_in),
        .flit_in_wr(flit_in_wr),
        .class_o(),
        .destport_o(destport_in_encoded),
        .src_e_addr_o( ),
        .dest_e_addr_o(dest_e_addr_in ),
        .vc_num_o(vc_num_in),
        .hdr_flit_wr_o( ),
        .hdr_flg_o(hdr_flg),
        .tail_flg_o(tail_flg),
        .weight_o( ),
        .be_o( ),
        .data_o( )
    );
    // check condition 1 & 2
    assign condition_1_2_valid = ~(any_ovc_granted_in_ss_port  | any_ivc_sw_request_granted);
    //check destination port is ss
    wire ss_port_hdr_flit, ss_port_nonhdr_flit;
    
    ssa_check_destport #(   
        .NOC_ID(NOC_ID),
        .SW_LOC(SW_LOC),
        .P(P),  
        .SS_PORT(SS_PORT)
    ) check_destport (
        .destport_encoded(destport_encoded),
        .destport_in_encoded(destport_in_encoded),
        .destport_one_hot(destport_one_hot),
        .ss_port_hdr_flit(ss_port_hdr_flit),
        .dest_e_addr_in(dest_e_addr_in),
        .ss_port_nonhdr_flit(ss_port_nonhdr_flit)
    `ifdef SIMULATION
        ,.clk(clk),
        .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant),
        .hdr_flg(hdr_flg)
    `endif
    );    
    
    // check if ss_ovc is ready
    wire ss_ovc_ready;
    wire assigned_ss_ovc_ready;
    assign assigned_ss_ovc_ready= ss_port_nonhdr_flit & assigned_to_ssovc & assigned_ovc_not_full;
    assign ss_ovc_ready = (ovc_is_assigned)?assigned_ss_ovc_ready : ovc_avalable_in_ss_port; 
    // check if ssa is permited by input port
    wire ssa_permited_by_iport;
    assign ssa_permited_by_iport =  (SSA_EN_IN_PORT)?  
        ss_ovc_ready & (~ivc_request) & condition_1_2_valid :
        1'b0;
    /*********************************
    * check incomming packet conditions 
    *********************************/
    wire ss_vc_wr, decrease_credit_pre,allocate_ss_ovc_pre,release_ss_ovc_pre;
    assign ss_vc_wr = flit_in_wr & vc_num_in[V_LOCAL];
    assign decrease_credit_pre= ~(hdr_flg & (~ss_port_hdr_flit));
    assign allocate_ss_ovc_pre= hdr_flg & ss_port_hdr_flit;
    assign release_ss_ovc_pre= (single_flit_pck)? decrease_credit_pre : tail_flg;
    
    // generate output signals
    assign ivc_reset =  release_ss_ovc_pre & ss_vc_wr & ssa_permited_by_iport  ;
    assign decreased_credit_in_ss_ovc= decrease_credit_pre & ss_vc_wr & ssa_permited_by_iport;
    assign ivc_num_getting_sw_grant= decreased_credit_in_ss_ovc;
    assign ivc_num_getting_ovc_grant= allocate_ss_ovc_pre & ss_vc_wr & ssa_permited_by_iport;
    assign ovc_released = ivc_reset & ~single_flit_pck;
    assign ovc_allocated= ivc_num_getting_ovc_grant & ~single_flit_pck;
    
    always @(*)begin
        granted_ovc_num={V{1'b0}};
        granted_ovc_num[V_LOCAL]= ivc_num_getting_ovc_grant;   
    end   
endmodule



module ssa_check_destport #(
    parameter NOC_ID=0,
    parameter SW_LOC = 0,
    parameter P=5,
    parameter SS_PORT=0
) (
    destport_encoded, //non header flit dest port
    destport_in_encoded, // header flit packet dest port
    ss_port_hdr_flit, // asserted if the header incomming flit goes to ss port
    ss_port_nonhdr_flit, // assert if the body or tail incomming flit goes to ss port
    dest_e_addr_in,
    destport_one_hot    
    `ifdef SIMULATION
    ,clk,
    ivc_num_getting_sw_grant,
    hdr_flg
    `endif  
);
    `NOC_CONF
    `ifdef SIMULATION
    input clk, ivc_num_getting_sw_grant, hdr_flg;
    `endif  
    input [DSTPw-1 : 0] destport_encoded, destport_in_encoded; 
    input [MAX_P-1 : 0] destport_one_hot; // buffered flit destination port
    input [DAw-1 : 0]  dest_e_addr_in;
    output ss_port_hdr_flit, ss_port_nonhdr_flit;
    
    generate
    if(IS_FATTREE) begin : fat
        fattree_ssa_check_destport #(
            .DSTPw(DSTPw),
            .SS_PORT(SS_PORT)
        ) check_destport (
            .destport_encoded(destport_encoded),
            .destport_in_encoded(destport_in_encoded),
            .ss_port_hdr_flit(ss_port_hdr_flit),
            .ss_port_nonhdr_flit(ss_port_nonhdr_flit)
        );
    end else if (IS_MESH | IS_TORUS ) begin : mesh
        mesh_torus_ssa_check_destport #(
            .ROUTE_TYPE(ROUTE_TYPE),
            .SW_LOC(SW_LOC),
            .P(P),
            .DEBUG_EN(DEBUG_EN),
            .DSTPw(DSTPw),
            .SS_PORT(SS_PORT)
        ) destport_check (
            .destport_encoded(destport_encoded),
            .destport_in_encoded(destport_in_encoded),
            .ss_port_hdr_flit(ss_port_hdr_flit),
            .ss_port_nonhdr_flit(ss_port_nonhdr_flit)
            `ifdef SIMULATION
            ,.clk(clk),
            .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant),
            .hdr_flg(hdr_flg)
            `endif
        ); 
    end else if (IS_FMESH) begin :fmesh
        localparam 
            ELw = log2(T3),
            Pw  = log2(P),
            PLw = (IS_FMESH) ? Pw : ELw;
            
        wire [Pw-1 : 0] endp_p_in;
        wire [MAX_P-1 : 0] destport_one_hot_in;
        
        fmesh_endp_addr_decode #(
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .EAw(EAw)
        ) endp_addr_decode (
            .e_addr(dest_e_addr_in),
            .ex(),
            .ey(),
            .ep(endp_p_in),
            .valid()
        );
        
        destp_generator #(
            .TOPOLOGY(TOPOLOGY),
            .ROUTE_NAME(ROUTE_NAME),
            .ROUTE_TYPE(ROUTE_TYPE),
            .T1(T1),
            .NL(T3),
            .P(P),
            .DSTPw(DSTPw),
            .PLw(PLw),
            .PPSw(PPSw),
            .SELF_LOOP_EN (SELF_LOOP_EN),
            .SW_LOC(SW_LOC),
            .CAST_TYPE(CAST_TYPE)
        ) decoder (
            .destport_one_hot (destport_one_hot_in),
            .dest_port_encoded(destport_in_encoded),
            .dest_port_out( ),   
            .endp_localp_num(endp_p_in),
            .swap_port_presel(1'b0),
            .port_pre_sel({PPSw{1'b0}}),
            .odd_column(1'b0)
        );
        
        assign ss_port_nonhdr_flit = destport_one_hot [SS_PORT];
        assign ss_port_hdr_flit    = destport_one_hot_in [SS_PORT]; 
    end else begin : line
        line_ring_ssa_check_destport #(
            .ROUTE_TYPE(ROUTE_TYPE),
            .SW_LOC(SW_LOC),
            .P(P),
            .DEBUG_EN(DEBUG_EN),
            .DSTPw(DSTPw),
            .SS_PORT(SS_PORT)
        ) destport_check (
            .destport_encoded(destport_encoded),
            .destport_in_encoded(destport_in_encoded),
            .ss_port_hdr_flit(ss_port_hdr_flit),
            .ss_port_nonhdr_flit(ss_port_nonhdr_flit)
        );
    end
    endgenerate
endmodule


/**************************
*            add_ss_port
*If no output is granted replace 
*the output port with ss one
**************************/
module add_ss_port #(
    parameter NOC_ID=0,
    parameter SW_LOC=0,
    parameter P=5
)(
    destport_in,
    destport_out 
);
    `NOC_CONF
    localparam SS_PORT = strieght_port(P,SW_LOC);
    localparam DISABLED = P;   
    localparam P_1 = ( SELF_LOOP_EN=="NO")?  P-1 : P;   
    
    input  [P_1-1 : 0] destport_in;
    output [P_1-1 : 0] destport_out; 
    
    generate    
    if(SS_PORT == DISABLED) begin :no_ss
        assign destport_out = destport_in;    
    end else begin : ss 
        reg [P_1-1 : 0] destport_temp; 
        /* verilator lint_off WIDTH */
        if( SELF_LOOP_EN=="YES") begin : slp
        /* verilator lint_on WIDTH */
            always @(*)begin 
                destport_temp=destport_in;
                if(destport_in=={P_1{1'b0}}) destport_temp[SS_PORT]= 1'b1;
            end 
            assign destport_out = destport_temp;
        end else begin : nslp
            localparam SS_PORT_CODE = (SW_LOC>SS_PORT) ? SS_PORT : SS_PORT-1;
            always @(*)begin 
                destport_temp=destport_in;
                if(destport_in=={P_1{1'b0}}) begin 
                    destport_temp[SS_PORT_CODE]= 1'b1;
                end
            end 
            assign destport_out = destport_temp;
        end
    end //ss
    endgenerate
endmodule