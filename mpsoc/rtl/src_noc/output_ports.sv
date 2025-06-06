`include "pronoc_def.v"
/**********************************************************************
**    File: output_ports.sv
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
**    output_ports module: contain output VC (OVC) status registers and credit counters, 
**
**************************************************************/


module output_ports #(
    parameter NOC_ID=0,
    parameter P=5
) (
    vsa_ovc_allocated_all,
    flit_is_tail_all,
    dest_port_all,
    nonspec_granted_dest_port_all,
    credit_in_all,
    nonspec_first_arbiter_granted_ivc_all,
    ivc_num_getting_sw_grant,
    ovc_avalable_all,
    assigned_ovc_not_full_all,
    port_pre_sel,
    congestion_in_all,    
    granted_dst_is_from_a_single_flit_pck,
    granted_ovc_num_all,
    reset,
    clk,
    any_ovc_granted_in_outport_all, 
    vsa_credit_decreased_all,
    vsa_ovc_released_all,
    crossbar_flit_out_wr_all,
    oport_info,
    ovc_info,  
    ivc_info,
    vsa_ctrl_in,
    ssa_ctrl_in,
    smart_ctrl_in,
    credit_init_val_in
);
    `NOC_CONF    
    
    localparam
        PV = V * P,
        VV = V * V,
        PVV = PV * V,
        P_1 = (SELF_LOOP_EN )?  P : P-1,
        VP_1 = V * P_1,
        PP_1 = P_1 * P,
        PVP_1 = PV * P_1;
    
    localparam [V-1 : 0] ADAPTIVE_VC_MASK = ~ ESCAP_VC_MASK;
    localparam  CONG_ALw= CONGw * P;   //  congestion width per router;
    
    input [PV-1 : 0] vsa_ovc_allocated_all;
    input [PV-1 : 0] flit_is_tail_all;   
    input [PVP_1-1 : 0] dest_port_all;
    input [PP_1-1 : 0] nonspec_granted_dest_port_all;
    input [PV-1 : 0] credit_in_all;
    input [PV-1 : 0] nonspec_first_arbiter_granted_ivc_all;
    input [PV-1 : 0] ivc_num_getting_sw_grant;
    output [PV-1 : 0] ovc_avalable_all;
    output [PV-1 : 0] assigned_ovc_not_full_all;
    input reset,clk;
    output [PPSw-1 : 0] port_pre_sel;
    input [CONG_ALw-1 : 0] congestion_in_all; 
    input [PVV-1 : 0] granted_ovc_num_all;    
    input [P-1 : 0] granted_dst_is_from_a_single_flit_pck;
    input [P-1 : 0] crossbar_flit_out_wr_all;
    input [P-1 : 0] any_ovc_granted_in_outport_all;    
    output [PV-1 : 0]  vsa_ovc_released_all;
    output [PV-1 : 0]  vsa_credit_decreased_all;
    output oport_info_t oport_info [P-1:0];
    output ovc_info_t   ovc_info [P-1 : 0][V-1 : 0];
    input  ivc_info_t ivc_info [P-1 : 0][V-1 : 0]; 
    input  vsa_ctrl_t vsa_ctrl_in [P-1: 0];
    input  ssa_ctrl_t ssa_ctrl_in [P-1: 0];
    input  smart_ctrl_t  smart_ctrl_in [P-1: 0];
    input [CRDTw-1 : 0 ] credit_init_val_in [P-1 : 0][V-1 : 0];
    
    wire [PVV-1 : 0] ssa_granted_ovc_num_all;
    logic [PV-1 : 0]    ovc_status;
    logic [PV-1 : 0]    ovc_status_next;
    wire [PV-1 : 0]    assigned_ovc_is_full_all;
    wire [VP_1-1 : 0]    credit_decreased [P-1 : 0];
    wire [P_1-1 : 0]    credit_decreased_gen [PV-1 : 0];
    wire [PV-1 : 0]  credit_increased_all;
    wire [VP_1-1 : 0]    ovc_released [P-1 : 0];
    wire [P_1-1 : 0]    ovc_released_gen [PV-1 : 0];
    wire [VP_1-1 : 0]  credit_in_perport [P-1 : 0];
    wire [VP_1-1 : 0]  full_perport [P-1 : 0];
    wire [VP_1-1 : 0]  nearly_full_perport [P-1 : 0];
    wire [PV-1 : 0]    full_all,nearly_full_all, empty_all;
    wire [PV-1 : 0]    full_all_next,nearly_full_all_next,empty_all_next;
    wire [PV-1 : 0] credit_decreased_all;
    wire [PV-1 : 0] ovc_released_all;
    wire [CREDITw-1 : 0] credit_counter [PV-1 : 0]; 
    wire [PVV-1 : 0] assigned_ovc_num_all;
    wire [PV-1 : 0] ovc_is_assigned_all;

    pronoc_register #(.W(PV)) reg_1 ( .D_in(full_all_next), .reset(reset), .clk(clk), .Q_out(full_all));
    pronoc_register #(.W(PV)) reg_2 ( .D_in(nearly_full_all_next), .reset(reset), .clk(clk), .Q_out(nearly_full_all));
    pronoc_register #(.W(PV)) reg_3 ( .D_in(empty_all_next), .reset(reset), .clk(clk), .Q_out(empty_all));

    integer k;
    genvar i,j;
    generate
        /* verilator lint_off WIDTH */
        if(VC_REALLOCATION_TYPE=="ATOMIC") begin :atomic
        /* verilator lint_on WIDTH */               
            // in atomic architecture an OVC is available if its not allocated and its empty
            assign ovc_avalable_all      = ~ovc_status & empty_all;
        end else begin :nonatomic //NONATOMIC
            /* verilator lint_off WIDTH */
            if(ROUTE_TYPE == "FULL_ADAPTIVE") begin :full_adpt
            /* verilator lint_on WIDTH */
                reg [PV-1 : 0] full_adaptive_ovc_mask,full_adaptive_ovc_mask_next; 
                always_comb begin
                    for(k=0; k<PV; k=k+1) begin
                     //in full adaptive routing, adaptive VCs located in y axies can not be reallocated non-atomicly   
                        if( AVC_ATOMIC_EN== 0) begin :avc_atomic
                            if((((k/V) == NORTH ) || ((k/V) == SOUTH )) && (  ADAPTIVE_VC_MASK[k%V]))  
                                full_adaptive_ovc_mask_next[k] = empty_all_next[k];
                            else 
                                full_adaptive_ovc_mask_next[k] = (OVC_ALLOC_MODE)? ~full_all_next[k] : ~nearly_full_all_next[k];
                        end else begin :avc_nonatomic
                            if(  ADAPTIVE_VC_MASK[k%V])  
                                full_adaptive_ovc_mask_next[k] = empty_all_next[k];
                            else    
                                full_adaptive_ovc_mask_next[k] = (OVC_ALLOC_MODE)? ~full_all_next[k] :~nearly_full_all_next[k];    
                        end                       
                     end // for  
                end//always
                pronoc_register #(.W(PV)) reg2 ( .D_in(full_adaptive_ovc_mask_next), .reset(reset), .clk(clk), .Q_out(full_adaptive_ovc_mask));
                assign ovc_avalable_all   = ~ovc_status & full_adaptive_ovc_mask;
            end else begin : par_adpt //par adaptive
                assign ovc_avalable_all = (OVC_ALLOC_MODE)? ~(ovc_status | full_all) : ~(ovc_status | nearly_full_all);
            end
        end //NONATOMIC    
    endgenerate
    
    assign credit_increased_all = credit_in_all;
    assign assigned_ovc_not_full_all = ~ assigned_ovc_is_full_all;
    //wire [PV-1 : 0] non_smart_ovc_allocated_all = ssa_ovc_allocated_all| vsa_ovc_allocated_all;
    wire [PV-1 : 0] non_smart_ovc_allocated_all;
    generate
    for(i=0;i<P;i=i+1    ) begin :P_
        assign ssa_granted_ovc_num_all[(i+1)*VV-1: i*VV] = ssa_ctrl_in[i].ivc_granted_ovc_num;
        assign credit_decreased_all [(i+1)*V-1 : i*V] = vsa_ctrl_in[i].buff_space_decreased |     ssa_ctrl_in[i].buff_space_decreased | smart_ctrl_in[i].buff_space_decreased;
        assign ovc_released_all [(i+1)*V-1 : i*V] = vsa_ctrl_in[i].ovc_is_released  | ssa_ctrl_in[i].ovc_is_released  | smart_ctrl_in[i].ovc_is_released;
        //assign non_smart_ovc_allocated_all [(i+1)*V-1 : i*V] = ssa_ctrl_in[i].ovc_is_allocated | vsa_ctrl_in[i].ovc_is_allocated;
        assign non_smart_ovc_allocated_all [(i+1)*V-1 : i*V] = vsa_ctrl_in[i].ovc_is_allocated;
        assign oport_info[i].non_smart_ovc_is_allocated = non_smart_ovc_allocated_all [(i+1)*V-1 :i*V];
        assign oport_info[i].any_ovc_granted = any_ovc_granted_in_outport_all [i];  
        
        oport_ovc_sig_gen #(
            .V (V), // vc_num_per_port
            .P (P), // router port num
            .SELF_LOOP_EN(SELF_LOOP_EN)
        )the_oport_ovc_sig_gen (
            .flit_is_tail (flit_is_tail_all    [(i+1)*V-1 :i*V]),
            .assigned_ovc_num (assigned_ovc_num_all [(i+1)*VV-1 :i*VV]),
            .ovc_is_assigned (ovc_is_assigned_all [(i+1)*V-1 :i*V]),
            .granted_dest_port(nonspec_granted_dest_port_all [(i+1)*P_1-1 :i*P_1]),
            .first_arbiter_granted_ivc(nonspec_first_arbiter_granted_ivc_all [(i+1)*V-1 :i*V]),
            .credit_decreased (credit_decreased[i]),
            .ovc_released(ovc_released [i])
        );         
        for(j=0; j<V;  j=j+1)begin : V_
            assign     ovc_info[i][j].avalable= ovc_avalable_all [i*V+j]; 
            assign     ovc_info[i][j].status =ovc_status [i*V+j]; //1 : is allocated 0 : not_allocated
            assign     ovc_info[i][j].credit = credit_counter[i*V+j];//available credit in OVC
            assign     ovc_info[i][j].full =full_all[i*V+j];
            assign     ovc_info[i][j].nearly_full=nearly_full_all[i*V+j];
            assign     ovc_info[i][j].empty=empty_all[i*V+j];
        end
    end//for
    
    for(i=0;i< PV;i=i+1) begin :total_vc_loop2
        for(j=0;j<P;    j=j+1)begin: assign_loop2
            if ( SELF_LOOP_EN==0) begin : nslp  
                if((i/V)<j )begin: jj
                    assign ovc_released_gen [i][j-1] = ovc_released[j][i];
                    assign credit_decreased_gen[i][j-1] = credit_decreased [j][i];
                end else if((i/V)>j) begin: hh
                    assign ovc_released_gen [i][j] = ovc_released[j][i-V];
                    assign credit_decreased_gen[i][j] = credit_decreased[j][i-V];
                end
            end else begin :slp
                assign ovc_released_gen [i][j] = ovc_released[j][i];
                assign credit_decreased_gen[i][j] = credit_decreased [j][i];
            end
        end//j
        assign vsa_ovc_released_all [i] = |ovc_released_gen[i];
        assign vsa_credit_decreased_all [i] = (|credit_decreased_gen[i])|vsa_ovc_allocated_all[i];
    end//i
    
    if ( SELF_LOOP_EN==0) begin : nslp  
        //remove source port from the list 
        for(i=0;i< P;i=i+1) begin :port_loop
            if(i==0)  begin :i0
                assign credit_in_perport [i]=credit_in_all [PV-1     : V];
                assign full_perport [i]=full_all [PV-1     : V];
                assign nearly_full_perport [i]=nearly_full_all [PV-1     : V];
            end else if(i==(P-1)) begin :ip_1
                assign credit_in_perport [i]=credit_in_all [PV-V-1 : 0];
                assign full_perport [i]=full_all [PV-V-1 : 0];
                assign nearly_full_perport [i]=nearly_full_all [PV-V-1 : 0];
            end else begin : els
                assign credit_in_perport [i]={credit_in_all [PV-1 : (i+1)*V],credit_in_all [(i*V)-1 : 0]};
                assign full_perport [i]={full_all [PV-1 : (i+1)*V],full_all [(i*V)-1 : 0]};
                assign nearly_full_perport [i]={nearly_full_all [PV-1 : (i+1)*V],nearly_full_all[(i*V)-1 : 0]};
            end
        end//for
    end else begin: slp
        for(i=0;i< P;i=i+1) begin :port_loop
            assign credit_in_perport [i]=credit_in_all;
            assign full_perport [i]=full_all;
            assign nearly_full_perport [i]=nearly_full_all;
        end
    end
    
    for(i=0; i<PV; i=i+1) begin :PV_
        assign assigned_ovc_num_all[(i+1)*V-1 : i*V] = ivc_info[i/V][i%V].assigned_ovc_num;
        assign ovc_is_assigned_all[i]=ivc_info[i/V][i%V].ovc_is_assigned;
        credit_monitor_per_ovc    #( 
            .NOC_ID(NOC_ID),
            .SW_LOC(i/V)
        ) credit_monitor (
            .credit_init_val_i(credit_init_val_in[i/V][i%V]),
            .credit_counter_o (credit_counter[i]),
            .credit_increased (credit_increased_all[i]),
            .credit_decreased(credit_decreased_all[i]),
            .empty_all_next(empty_all_next[i]),
            .full_all_next(full_all_next[i]),
            .nearly_full_all_next(nearly_full_all_next[i]),
            .reset(reset),
            .clk(clk)
        ); 
        
        full_ovc_predictor #(
            .OVC_ALLOC_MODE(OVC_ALLOC_MODE),
            .PCK_TYPE(PCK_TYPE),
            .V (V), // vc_num_per_port
            .P (P), // router port num
            .SELF_LOOP_EN (SELF_LOOP_EN)
        )sw_mask (
            .ssa_granted_ovc_num(ssa_granted_ovc_num_all[(i+1)*V-1 :i*V]),
            .granted_ovc_num(granted_ovc_num_all[(i+1)*V-1 :i*V]),
            .ovc_is_assigned(ovc_is_assigned_all[i]),
            .assigned_ovc_num (assigned_ovc_num_all[(i+1)*V-1 :i*V]),
            .dest_port (dest_port_all [(i+1)*P_1-1 :i*P_1]),
            .full  (full_perport [i/V]),
            .credit_increased (credit_in_perport [i/V]),
            .nearly_full (nearly_full_perport [i/V]),
            .ivc_getting_sw_grant  (ivc_num_getting_sw_grant[i]),
            .assigned_ovc_is_full  (assigned_ovc_is_full_all[i]),
            .clk (clk),
            .reset  (reset)
        );
        
        always_comb begin
            ovc_status_next[i] = ovc_status[i];
            if(IS_SINGLE_FLIT)  ovc_status_next[i]=1'b0; // donot change VC status for single flit packet
            else begin 
                if(ovc_released_all[i])  ovc_status_next[i] =1'b0;
                //if(ovc_allocated_all[i] & ~granted_dst_is_from_a_single_flit_pck[i/V])    ovc_status_next[i]=1'b1; // donot change VC status for single flit packet
                if((vsa_ctrl_in[i/V].ovc_is_allocated[i%V] & ~granted_dst_is_from_a_single_flit_pck[i/V]) |
                    (ssa_ctrl_in[i/V].ovc_is_allocated[i%V] & ~ssa_ctrl_in[i/V].ovc_single_flit_pck[i%V])|
                    (smart_ctrl_in[i/V].ovc_is_allocated[i%V] & ~smart_ctrl_in[i/V].ovc_single_flit_pck[i%V]))  
                    ovc_status_next[i]=1'b1; // donot change VC status for single flit packet    
            end
        end//always
    end//for
    endgenerate

    pronoc_register #(.W(PV)) reg2 (.D_in(ovc_status_next ), .Q_out(ovc_status), .reset(reset), .clk(clk));
    port_pre_sel_gen #(
        .PPSw(PPSw),
        .P(P),
        .V(V),
        .B(B),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .ROUTE_TYPE(ROUTE_TYPE),
        .ESCAP_VC_MASK(ESCAP_VC_MASK)
    ) port_pre_sel_top (
        .port_pre_sel(port_pre_sel),
        .ovc_status(ovc_status),
        .ovc_avalable_all(ovc_avalable_all),
        .credit_decreased_all(credit_decreased_all),
        .credit_increased_all(credit_increased_all),
        .congestion_in_all(congestion_in_all),
        .reset(reset),
        .clk(clk)
    );
    
    `ifdef SIMULATION
    generate 
    if(DEBUG_EN) begin: debug
        wire [PV-1 : 0] ovc_allocated_all;
        for(i=0;i<P;i=i+1 ) begin :P_
            assign ovc_allocated_all [(i+1)*V-1 : i*V] = vsa_ctrl_in[i].ovc_is_allocated | ssa_ctrl_in[i].ovc_is_allocated | smart_ctrl_in[i].ovc_is_allocated;
        end
        always @ (posedge clk )begin 
            for(k=0;    k<PV; k=k+1'b1) begin 
                if(empty_all[k] & credit_increased_all[k]) begin 
                    $display("%t: ERROR: unexpected credit recived for empty ovc[%d]: %m",$time,k);
                    $finish;
                end
                if(full_all[k] & credit_decreased_all[k]) begin 
                    $display("%t: ERROR: Attempt to send flit to full ovc[%d]: %m",$time,k);
                    $finish;
                end
                if(ovc_released_all[k] & ovc_allocated_all[k]) begin
                    $display("%t: ERROR: simultaneous allocation and release for an OVC[%d]: %m",$time,k);
                    $finish;
                end
                if(ovc_released_all[k]==1'b1 && ovc_status[k]==1'b0) begin 
                    $display("%t: ERROR: Attempt to release an unallocated OVC[%d]: %m",$time,k);
                    $finish;
                end
                if(ovc_allocated_all[k] & ovc_status[k]) begin 
                    $display("%t: ERROR: Attempt to allocate an allocated OVC[%d]: %m",$time,k);
                    $finish;
                end
            end//for
        end//always
        /* verilator lint_off WIDTH */    
        if(CAST_TYPE== "UNICAST") begin : unicast
        /* verilator lint_on WIDTH */
            localparam NUM_WIDTH = log2(PV+1);
            wire [NUM_WIDTH-1 : 0] num1,num2;
            accumulator #(
                .INw(PV),
                .OUTw(NUM_WIDTH),
                .NUM(PV) 
            )cnt1 (
                .in_all(ovc_status),
                .sum_o(num1)
            );
            accumulator #(
                .INw(PV),
                .OUTw(NUM_WIDTH),
                .NUM(PV) 
            ) cnt2 (
                .in_all(ovc_is_assigned_all),
                .sum_o(num2)         
            );
            always @(posedge clk) begin
                if(num1    != num2 )begin 
                    $display("%t: ERROR: number of assigned IVC %d mismatch the number of occupied OVC %d: %m",$time,num1,num2);
                    $finish;
                end
            end
        end //unicast
        check_ovc #(
            .V(V) , // vc_num_per_port
            .P(P), // router port num
            .SELF_LOOP_EN(SELF_LOOP_EN)
        ) test (
            .ovc_status(ovc_status),
            .assigned_ovc_num_all(assigned_ovc_num_all),
            .ovc_is_assigned_all(ovc_is_assigned_all),
            .dest_port_all(dest_port_all),
            .clk(clk),
            .reset(reset)
        );
    end// DEBUG
    endgenerate 
    `endif
endmodule 


/*********************
 *     credit_monitor_per_ovc 
 ********************/
module   credit_monitor_per_ovc  #(
    parameter NOC_ID=0,
    parameter SW_LOC=0
) (
    credit_init_val_i,
    credit_increased,
    credit_decreased,
    credit_counter_o,
    empty_all_next,
    full_all_next,
    nearly_full_all_next,
    reset,
    clk
);
    
    `NOC_CONF
    localparam 
        PORT_B = port_buffer_size(SW_LOC),    
        DEPTHw = log2(PORT_B+1);
    localparam [DEPTHw-1 : 0] Bint = PORT_B [DEPTHw-1 : 0];
    
    input [CRDTw-1 : 0] credit_init_val_i;
    input credit_increased;
    input credit_decreased;    
    output reg [CREDITw-1 : 0]    credit_counter_o ;
    output empty_all_next;
    output full_all_next;
    output nearly_full_all_next; 
    input reset,clk;
    
    reg [DEPTHw-1 : 0]    credit_counter_next;
    reg [DEPTHw-1 : 0]    credit_counter;
    always_comb begin        
        credit_counter_next = credit_counter;
        if(credit_increased    &   ~credit_decreased) begin 
            credit_counter_next = credit_counter+1'b1;
        end else if (~credit_increased  &  credit_decreased)begin    
            credit_counter_next = credit_counter-1'b1;
        end
        credit_counter_o = {CREDITw{1'b0}};
        credit_counter_o [DEPTHw-1 : 0] = credit_counter;        
    end
    assign     empty_all_next = (credit_counter_next == Bint);
    assign     full_all_next = (credit_counter_next == {DEPTHw{1'b0}});
    assign     nearly_full_all_next = (credit_counter_next  <= 1);    
    
    pronoc_register_reset_init #(
        .W(DEPTHw)
    )reg1( 
        .D_in(credit_counter_next),
        .reset(reset),
        .clk(clk),
        .Q_out(credit_counter),
        .reset_to(credit_init_val_i [DEPTHw-1 : 0]) // Bint;
    );
endmodule


/************************************
*        oport_ovc_sig_gen
*************************************/
module oport_ovc_sig_gen #(
    parameter V = 4, // vc_num_per_port
    parameter P = 5, // router port num
    parameter SELF_LOOP_EN = 0
)(
    flit_is_tail,
    assigned_ovc_num,
    ovc_is_assigned,
    granted_dest_port,
    first_arbiter_granted_ivc,
    credit_decreased,
    ovc_released
);
    
    localparam
        VV = V * V,
        P_1 = (SELF_LOOP_EN )?  P : P-1,
        VP_1 = V * P_1;
    
    input [V-1 : 0]  flit_is_tail;
    input [VV-1 : 0] assigned_ovc_num;
    input [V-1 : 0]  ovc_is_assigned;
    input [P_1-1 : 0] granted_dest_port;
    input [V-1 : 0] first_arbiter_granted_ivc;
    output [VP_1-1 : 0] credit_decreased;
    output [VP_1-1 : 0] ovc_released;
    
    wire [V-1 : 0] muxout1;
    wire muxout2;
    wire [VV-1 : 0] assigned_ovc_num_masked;
    genvar i;
    generate 
        for (i=0;i<V;i=i+1)begin: V_
            assign    assigned_ovc_num_masked[(i+1)*V-1 : i*V] = ovc_is_assigned[i]? assigned_ovc_num [(i+1)*V-1 : i*V] : {V{1'b0}};
        end
    endgenerate
    
    // assigned ovc mux 
    onehot_mux_1D #(
        .W  (V),
        .N  (V)
    )ovc_mux (
        .D_in(assigned_ovc_num_masked),
        .Q_out(muxout1),
        .sel (first_arbiter_granted_ivc)
    );
    // tail mux 
    onehot_mux_1D #(
        .W  (1),
        .N  (V)
    )tail_mux (
        .D_in(flit_is_tail),
        .Q_out(muxout2),
        .sel       (first_arbiter_granted_ivc)
    );
    
    one_hot_demux #(
        .IN_WIDTH (V),
        .SEL_WIDTH (P_1)
    ) demux (
        .demux_sel    (granted_dest_port),//selectore
        .demux_in    (muxout1),//repeated
        .demux_out    (credit_decreased)
    );
    
    assign ovc_released = (muxout2)? credit_decreased : {VP_1{1'b0}};
endmodule


/**********************************
*    full_ovc_predictor
*********************************/
module full_ovc_predictor #(
    parameter PCK_TYPE = "MULTI_FLIT",
    parameter V = 4, // vc_num_per_port
    parameter P = 5, // router port num
    parameter OVC_ALLOC_MODE=1'b0,
    parameter SELF_LOOP_EN = 0
)(
    ssa_granted_ovc_num,
    granted_ovc_num,
    ovc_is_assigned,
    assigned_ovc_num,
    dest_port,
    full,
    credit_increased,
    nearly_full,
    ivc_getting_sw_grant,
    assigned_ovc_is_full,
    clk,
    reset
);
    localparam
        P_1 = (SELF_LOOP_EN )?  P : P-1,
        VP_1 = V * P_1;
    input clk,reset;
    input ovc_is_assigned;
    input [V-1 : 0]  assigned_ovc_num,granted_ovc_num,ssa_granted_ovc_num;
    input [P_1-1 : 0] dest_port;
    input [VP_1-1 : 0] full;
    input [VP_1-1 : 0] credit_increased;
    input [VP_1-1 : 0] nearly_full;
    input  ivc_getting_sw_grant;
    output assigned_ovc_is_full;    
    
    wire [VP_1-1 : 0]    full_muxin1,nearly_full_muxin1;
    wire [V-1 : 0]    full_muxout1,nearly_full_muxout1;
    wire                                full_muxout2,nearly_full_muxout2;
    wire   full_reg1,full_reg2;
    wire   full_reg1_next,full_reg2_next;
    
    assign full_muxin1  = full & (~credit_increased);
    assign nearly_full_muxin1 = nearly_full & (~credit_increased);
    // destport mux 
    onehot_mux_1D #(
        .W  (V),
        .N  (P_1)
    )full_mux1 (
        .D_in(full_muxin1),
        .Q_out(full_muxout1),
        .sel    (dest_port)
    );
    onehot_mux_1D #(
        .W  (V),
        .N  (P_1)
    )nearly_full_mux1 (
        .D_in(nearly_full_muxin1),
        .Q_out(nearly_full_muxout1),
        .sel       (dest_port)
    );
    // assigned ovc mux
    onehot_mux_1D #(
        .W (1),
        .N (V)
    ) full_mux2 (
        .D_in(full_muxout1),
        .Q_out(full_muxout2),
        .sel (assigned_ovc_num)
    );
    wire [V-1 : 0]  nearlyfull_sel = (ovc_is_assigned | ~OVC_ALLOC_MODE)? assigned_ovc_num : granted_ovc_num ;// or (granted_ovc_num | ssa_granted_ovc_num) ?    
    onehot_mux_1D #(
        .W (1),
        .N (V)
    ) nearlfull_mux2 (
        .D_in(nearly_full_muxout1),
        .Q_out(nearly_full_muxout2),
        .sel (nearlyfull_sel)
    );
    
    assign full_reg1_next = full_muxout2;
    assign full_reg2_next = nearly_full_muxout2 & ivc_getting_sw_grant;
    assign assigned_ovc_is_full = (PCK_TYPE == "MULTI_FLIT")? full_reg1 | full_reg2: 1'b0;

    pronoc_register #(.W(1)) reg1 (.D_in(full_reg1_next ), .Q_out(full_reg1), .reset(reset), .clk(clk));
    pronoc_register #(.W(1)) reg2 (.D_in(full_reg2_next ), .Q_out(full_reg2), .reset(reset), .clk(clk));

endmodule

`ifdef SIMULATION
module check_ovc #(
    parameter V = 4, // vc_num_per_port
    parameter P = 5, // router port num
    parameter SELF_LOOP_EN=0
)(
    ovc_status,
    assigned_ovc_num_all,
    ovc_is_assigned_all,
    dest_port_all,
    clk,
    reset
);
    localparam
        PV = V *  P,
        PVV = PV * V,
        P_1 = (SELF_LOOP_EN )?  P : P-1,
        PVP_1 = PV * P_1;

    input [PV-1 : 0] ovc_status;
    input [PVV-1 : 0] assigned_ovc_num_all;
    input [PV-1 : 0] ovc_is_assigned_all;
    input [PVP_1-1 : 0] dest_port_all;
    input clk,reset;
    
    wire [V-1 : 0] assigned_ovc_num [PV-1 : 0];
    wire [P_1-1 : 0] destport_sel [PV-1 : 0];
    wire [P-1 : 0]  destport_num [PV-1 : 0];
    wire [PV-1 : 0] ovc_num [PV-1 : 0];
    genvar i;
    generate
    for(i=0; i<PV;i=i+1) begin :lp_pv
        assign assigned_ovc_num [i]= (ovc_is_assigned_all[i])? assigned_ovc_num_all[(i+1)*V-1 : i*V]: {V{1'b0}};
        assign destport_sel [i]= dest_port_all[(i+1)*P_1-1 : i*P_1];
        if(SELF_LOOP_EN==0) begin : nslp
            add_sw_loc_one_hot #(
                .P(P),
                .SW_LOC(i/V)
            ) add_sw_loc (
                .destport_in(destport_sel[i]),
                .destport_out(destport_num[i])
            );
        end else begin :slp
            assign destport_num[i] = destport_sel[i];
        end
        one_hot_demux #(
            .IN_WIDTH (V),
            .SEL_WIDTH (P)
        ) demux (
            .demux_sel (destport_num[i]),//selectore
            .demux_in (assigned_ovc_num[i]),//repeated
            .demux_out (ovc_num[i])
        );
        always @(posedge clk)begin 
            if(ovc_status >0 && ovc_num[i] >0 && (ovc_num[i] & ovc_status)==0) $display ("%t :Error: OVC status%d missmatch:%b & %b, %m  ",$time,i,ovc_num[i] , ovc_status);
        end
    end//for
    endgenerate
endmodule
`endif