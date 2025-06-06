`include "pronoc_def.v"
/**********************************************************************
**    File: packet_injector.sv
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
**    This module is responsible for injecting and ejecting packets 
**    within the NoC router. It allows the simulation of real application 
**    traffic by injecting pre-recorded trace data into the NoC, enabling 
**    performance and functionality testing of NoC components under realistic 
**    conditions.
**
**    It can also be used to verify the NoC's ability to handle various 
**    traffic patterns, including stress testing with synthetic or real 
**    application traces.
**************************************************************/

module packet_injector #(
    parameter NOC_ID=0
) (
    //general
    current_e_addr,
    reset,
    clk,
    //noc port
    chan_in,
    chan_out,
    //control interafce
    pck_injct_in,
    pck_injct_out
);
    
    `NOC_CONF
    
    //general
    input reset,clk;
    input [EAw-1 :0 ] current_e_addr;
    
    // the destination endpoint address
    //NoC interface
    input   smartflit_chanel_t chan_in;
    output  smartflit_chanel_t chan_out;
    //control interafce
    
    input   pck_injct_t pck_injct_in;
    output  pck_injct_t pck_injct_out;
    
    wire  [RAw-1 :0 ] current_r_addr;
    wire  [DSTPw-1 : 0 ] destport;
    reg flit_wr;
    
    assign current_r_addr = chan_in.ctrl_chanel.router_addr;
    
    generate 
    if(CAST_TYPE == "UNICAST") begin : uni
        conventional_routing #(
            .NOC_ID(NOC_ID),
            .TOPOLOGY(TOPOLOGY),
            .ROUTE_NAME(ROUTE_NAME),
            .ROUTE_TYPE(ROUTE_TYPE),
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .RAw(RAw),
            .EAw(EAw),
            .DAw(DAw),
            .DSTPw(DSTPw),
            .LOCATED_IN_NI(1)
        ) routing_module (
            .reset(reset),
            .clk(clk),
            .current_r_addr(current_r_addr),
            .dest_e_addr(pck_injct_in.endp_addr),
            .src_e_addr(current_e_addr),
            .destport(destport)
        );
    end 
    endgenerate
    
    localparam 
        HDR_BYTE_NUM = HDR_MAX_DATw / 8, // = HDR_MAX_DATw / (8 - HDR_MAX_DATw %8)
        HDR_DATA_w_tmp = HDR_BYTE_NUM * 8,
        HDR_DATA_w = 
            (PCK_INJ_Dw < HDR_DATA_w_tmp)? PCK_INJ_Dw :
            (HDR_DATA_w_tmp==0)? 1: HDR_DATA_w_tmp;
    localparam 
        REMAIN_DATw =  PCK_INJ_Dw - HDR_DATA_w,
        REMAIN_DAT_FLIT_I = (REMAIN_DATw / Fpay),
        REMAIN_DAT_FLIT_F = (REMAIN_DATw % Fpay == 0)? 0 : 1,
        REMAIN_DAT_FLIT   = REMAIN_DAT_FLIT_I + REMAIN_DAT_FLIT_F,
        CNTw = log2(REMAIN_DAT_FLIT),
        MIN_PCK_SIZ = REMAIN_DAT_FLIT +1;
    localparam 
        LAST_TMP =PCK_INJ_Dw -  (Fpay*REMAIN_DAT_FLIT_I)-HDR_DATA_w,
        LASTw=(LAST_TMP==0)? Fpay : LAST_TMP;
    
    wire [HDR_DATA_w-1 : 0] hdr_data_in = pck_injct_in.data [HDR_DATA_w-1 : 0];
    wire [Fw-1 : 0] hdr_flit_out;
    
    header_flit_generator #(
        .NOC_ID(NOC_ID),
        .DATA_w(HDR_DATA_w)
    ) the_header_flit_generator (
        .flit_out(hdr_flit_out),
        .vc_num_in(pck_injct_in.vc),
        .class_in(pck_injct_in.class_num),
        .dest_e_addr_in(pck_injct_in.endp_addr),
        .src_e_addr_in(current_e_addr),
        .weight_in(pck_injct_in.init_weight),
        .destport_in(destport),
        .data_in(hdr_data_in),
        .be_in({BEw{1'b1}} )// Be is not used in simulation as we dont sent real data
    );
    
    logic [PCK_SIZw-1 : 0]  counter, counter_next;
    logic [CNTw-1 : 0]  counter2,counter2_next;
    reg tail,head;
    
    wire [Fpay -1 : 0]  remain_dat [REMAIN_DAT_FLIT -1 : 0];
    wire [Fpay-1 : 0] dataIn =  remain_dat[counter2];
    enum  bit [2:0] {HEADER, BODY, TAIL_ST} flit_type,flit_type_next;
    
    wire [V-1 : 0]   wr_vc_send = (flit_wr)?   pck_injct_in.vc : {V{1'b0}};
    wire [V-1 : 0]   vc_fifo_full;
    
    wire noc_ready;
    
    genvar i,k;
    generate 
        for(i=0; i<REMAIN_DAT_FLIT_I; i++) begin :rem
            assign remain_dat [i] = pck_injct_in.data [Fpay*(i+1)+HDR_DATA_w-1   : (Fpay*i)+HDR_DATA_w];
        end
        if(REMAIN_DAT_FLIT_F ) begin :flt
            assign remain_dat [REMAIN_DAT_FLIT_I][LASTw-1 : 0] = pck_injct_in.data [PCK_INJ_Dw-1   : (Fpay*REMAIN_DAT_FLIT_I)+HDR_DATA_w];
        end
    endgenerate
    
    one_hot_mux #(
        .IN_WIDTH (V), 
        .SEL_WIDTH (V), 
        .OUT_WIDTH (1)
    ) one_hot_mux1 (
        .mux_in (~ vc_fifo_full), 
        .mux_out (noc_ready), 
        .sel (pck_injct_in.vc)
    );
    
    always_comb begin 
        counter_next = counter;
        counter2_next =counter2;
        flit_type_next =flit_type;
        tail=1'b0;
        head=1'b0;
        flit_wr=0;
        if(noc_ready)begin 
            case(flit_type) 
                HEADER:begin 
                    if(pck_injct_in.pck_wr)begin 
                        flit_wr=1;
                        counter_next = pck_injct_in.size-1;
                        counter2_next=0;
                        head=1'b1;
                        if(pck_injct_in.size == 1)begin
                            tail=1'b1;
                        end else if (pck_injct_in.size == 2) begin 
                            flit_type_next = TAIL_ST;
                        end else begin 
                            flit_type_next = BODY;
                        end 
                    end
                end
                BODY: begin 
                    flit_wr=1;
                    counter_next = counter -1'b1;
                    counter2_next =counter2 +1'b1;
                    if(counter == 2) begin
                        flit_type_next = TAIL_ST;
                    end
                end
                TAIL_ST: begin
                    flit_type_next = HEADER;
                    flit_wr=1;
                    tail=1'b1;
                end
                default: begin
                    
                end
            endcase
            
        end
    end
    
    logic [V-1 : 0] credit_o, credit_o_next;
    
    //pronoc_register #(.W(3),.RESET_TO(HEADER) ) reg1 (.D_in(flit_type_next ), .Q_out(flit_type), .reset(reset), .clk(clk));
    pronoc_register #(.W(PCK_SIZw)) reg2 (.D_in(counter_next ), .Q_out(counter), .reset(reset), .clk(clk));
    pronoc_register #(.W(CNTw))     reg3 (.D_in(counter2_next ), .Q_out(counter2), .reset(reset), .clk(clk));
    pronoc_register #(.W(V))     reg4 (.D_in(credit_o_next ), .Q_out(credit_o), .reset(reset), .clk(clk));

    always_comb begin
        credit_o_next = credit_o;
        if (chan_in.flit_chanel.flit_wr) credit_o_next =  chan_in.flit_chanel.flit.vc;
        else credit_o_next = {V{1'b0}};
    end
    
    always @(`pronoc_clk_reset_edge)begin 
        if(`pronoc_reset) flit_type<=HEADER;
        else flit_type <= flit_type_next;
    end
    
    injector_ovc_status #(
        .V(V),
        .B(LB),
        .CRDTw(CRDTw)
    ) the_ovc_status (
        .credit_init_val_in ( chan_in.ctrl_chanel.credit_init_val),
        .wr_in(wr_vc_send),
        .credit_in(chan_in.flit_chanel.credit),
        .full_vc(vc_fifo_full),
        .nearly_full_vc( ),
        .empty_vc( ),
        .clk(clk),
        .reset(reset)
    );
    
    wire [HDR_DATA_w-1 : 0]    hdr_data_o;
    hdr_flit_t hdr_flit_i;
    
    header_flit_info  #(
        .NOC_ID (NOC_ID),
        .DATA_w (HDR_DATA_w)
    ) extractor (
        .flit(chan_in.flit_chanel.flit),
        .hdr_flit(hdr_flit_i),
        .data_o(hdr_data_o)
    );
    
    wire [PCK_INJ_Dw-1 : 0]  pck_data_o [V-1 : 0];
    reg  [Fpay-1 : 0] pck_data_o_gen [V-1 : 0][REMAIN_DAT_FLIT : 0];    
    
    reg [PCK_SIZw-1 : 0] rsv_counter [V-1 : 0];
    reg [EAw-1 : 0] sender_endp_addr_reg [V-1 : 0];
    logic [Cw-1 : 0] sender_class_reg [V-1 : 0];
    logic [15:0] h2t_counter [V-1 : 0];
    logic [15:0] h2t_counter_next [V-1 : 0];
    
    `ifdef SIMULATION
    wire [NEw-1 : 0] current_id; 
    wire [NEw-1 : 0] sendor_id; 
    endp_addr_decoder #( .TOPOLOGY(TOPOLOGY), .T1(T1), .T2(T2), .T3(T3), .EAw(EAw),  .NE(NE)) encode1 ( .id(current_id), .code(current_e_addr));
    endp_addr_decoder #( .TOPOLOGY(TOPOLOGY), .T1(T1), .T2(T2), .T3(T3), .EAw(EAw),  .NE(NE)) encode2 ( .id(sendor_id), .code(pck_injct_out.endp_addr[EAw-1 : 0]));
    `endif
    
    wire [NE-1 :0] dest_mcast_all_endp;   
    
    generate 
    if(CAST_TYPE != "UNICAST") begin
        mcast_dest_list_decode #(
            .NOC_ID(NOC_ID)
        ) decode (
            .dest_e_addr(hdr_flit_i.dest_e_addr),
            .dest_o(dest_mcast_all_endp),
            .row_has_any_dest(),
            .is_unicast()
        );
    end
    
    for(i=0; i<V; i++) begin: V_
        always@(*) begin
            h2t_counter_next[i]=h2t_counter[i]+1'b1;
            if(chan_in.flit_chanel.flit.vc[i] & chan_in.flit_chanel.flit_wr & chan_in.flit_chanel.flit.hdr_flag)begin 
                h2t_counter_next[i]= 16'd0; // reset once header flit is received
            end//hdr flit wr
        end//always
        
        always @ (`pronoc_clk_reset_edge )begin 
            if(`pronoc_reset)  begin
                rsv_counter[i]<= {PCK_SIZw{1'b0}};
                h2t_counter[i]<= 16'd0;
                sender_endp_addr_reg [i]<= {EAw{1'b0}};
                sender_class_reg [i]<= {Cw{1'b0}};
            end else begin 
                h2t_counter[i]<=h2t_counter_next[i];
                if(chan_in.flit_chanel.flit.vc[i] & chan_in.flit_chanel.flit_wr ) begin 
                    if(chan_in.flit_chanel.flit.hdr_flag)begin
                        rsv_counter[i]<= {{(PCK_SIZw-1){1'b0}}, 1'b1};
                        sender_endp_addr_reg [i] <= hdr_flit_i.src_e_addr;
                        sender_class_reg [i] <= hdr_flit_i.message_class;
                        `ifdef SIMULATION
                        if(CAST_TYPE == "UNICAST") begin
                            if(hdr_flit_i.dest_e_addr[EAw-1:0] != current_e_addr) begin 
                                $display("%t: ERROR: packet destination address %d does not match receiver endp address %d. %m",$time,hdr_flit_i.dest_e_addr , current_e_addr );
                                $finish;
                            end//if hdr_flit_i
                        end else begin 
                            if(dest_mcast_all_endp[current_id] !=1'b1 ) begin 
                                $display("%t: ERROR: packet destination address %b does not match receiver endp address %d. %m",$time,hdr_flit_i.dest_e_addr , current_e_addr ,current_id );
                                $finish;
                            end
                        end//if hdr_flit_i
                        `endif//SIMULATION
                    end //if hdr_flag
                    else rsv_counter[i]<= rsv_counter[i]+1'b1;
                end//flit wr
            end//reset
        end//always
        
        for (k=0;k< REMAIN_DAT_FLIT+1;k++)begin : K_
            
            always @ (`pronoc_clk_reset_edge )begin 
                if(`pronoc_reset)  begin
                    pck_data_o_gen [i][k] <= {Fpay{1'b0}};
                end else begin
                    if(chan_in.flit_chanel.flit.vc[i] & chan_in.flit_chanel.flit_wr ) begin 
                        if (chan_in.flit_chanel.flit.hdr_flag )begin 
                            if ( k ==0 ) pck_data_o_gen [i][k][HDR_DATA_w-1 : 0] <= hdr_data_o;
                        end else begin 
                            if (rsv_counter[i] == k ) pck_data_o_gen [i][k] <= chan_in.flit_chanel.flit.payload[Fpay-1 : 0];
                        end // else
                    end //if
                end //else
            end// always
            
            if   (k == 0 ) assign pck_data_o [i][HDR_DATA_w-1 : 0] = pck_data_o_gen [i][0][HDR_DATA_w-1 : 0];
            else if (k == REMAIN_DAT_FLIT) assign pck_data_o [i][PCK_INJ_Dw-1 :    (k-1)*Fpay+ HDR_DATA_w] = pck_data_o_gen [i][k][LASTw-1: 0];
            else assign pck_data_o [i][(k)*Fpay+HDR_DATA_w -1 : (k-1)*Fpay+ HDR_DATA_w] = pck_data_o_gen [i][k];
            
        end //for k
        
        `ifdef SIMULATION
        always @(posedge clk) begin 
            if((pck_injct_out.ready[i] == 1'b0 ) & pck_injct_in.vc[i] & pck_injct_in.pck_wr )begin 
                $display("%t: ERROR: a packet injection request is recived in core(%d), vc (%d) while packet injectore was not ready. %m",$time,current_id,i);
                $finish;
            end
        end
        `endif
    
    end//for i
    endgenerate
    
    wire [V-1 : 0] vc_reg;
    wire tail_flag_reg, hdr_flag_reg;
    logic [DISTw-1:   0] distance;
    
    pronoc_register #(.W(V))   register1 (.D_in(chan_in.flit_chanel.flit.vc), .reset(reset ), .clk(clk),.Q_out(vc_reg));
    pronoc_register #(.W(1))   register2 (.D_in(chan_in.flit_chanel.flit.hdr_flag), .reset(reset ), .clk(clk),.Q_out(hdr_flag_reg));
    pronoc_register #(.W(1))   register3 (.D_in(chan_in.flit_chanel.flit.tail_flag & chan_in.flit_chanel.flit_wr ),.reset(reset ), .clk (clk),.Q_out(tail_flag_reg));
    
    wire [Vw-1 : 0] vc_bin;
    
    one_hot_to_bin #(
        .ONE_HOT_WIDTH(V), 
        .BIN_WIDTH(Vw )
    ) one_hot_to_bin (
        .one_hot_code(vc_reg), 
        .bin_code(vc_bin)
    );
    always_comb begin
        pck_injct_out.data  =  pck_data_o[vc_bin];
        pck_injct_out.size  =  rsv_counter[vc_bin];
        pck_injct_out.h2t_delay = h2t_counter[vc_bin];
        pck_injct_out.ready = (flit_type == HEADER)?  ~vc_fifo_full : {V{1'b0}};
        pck_injct_out.endp_addr[EAw-1 : 0] =  sender_endp_addr_reg[vc_bin];
        pck_injct_out.class_num = sender_class_reg[vc_bin];
        pck_injct_out.init_weight = WEIGHT_INIT;
        pck_injct_out.vc = vc_reg;
        pck_injct_out.pck_wr = tail_flag_reg;
        pck_injct_out.distance = distance;
        
        chan_out.flit_chanel.flit.hdr_flag =head;
        chan_out.flit_chanel.flit.tail_flag=tail;
        chan_out.flit_chanel.flit.vc=pck_injct_in.vc;
        chan_out.flit_chanel.flit_wr=flit_wr;
        chan_out.flit_chanel.flit.payload =
            (IS_SINGLE_FLIT )? hdr_flit_out[FPAYw-1 : 0] :
            /* verilator lint_off WIDTH */
            (flit_type==HEADER)? hdr_flit_out[Fpay-1 : 0] : dataIn [Fpay-1 : 0];
            /* verilator lint_on WIDTH */
        chan_out.smart_chanel = {SMART_CHANEL_w{1'b0}};
        chan_out.flit_chanel.congestion = {CONGw{1'b0}};
        chan_out.flit_chanel.credit= credit_o;
        for(int i=0;i<V;i++) chan_out.ctrl_chanel.credit_init_val[i]= LB [CRDTw-1: 0];
        chan_out.ctrl_chanel.credit_release_en={V{1'b0}};
        chan_out.ctrl_chanel.endp_port =1'b1;
        chan_out.ctrl_chanel.hetero_ovc_presence ={V{1'b1}};
    end 
    
    distance_gen the_distance_gen (
        .src_e_addr(sender_endp_addr_reg[vc_bin]),
        .dest_e_addr(current_e_addr),
        .distance(distance)
    );
    
    `ifdef SIMULATION
    //`define MONITOR_RSV_DAT
    always @(posedge clk) begin 
        if((pck_injct_in.vc == {V{1'b0}} ) & pck_injct_in.pck_wr )begin 
            $display("%t: ERROR: a packet injection request is recived while vc is not set. %m",$time);
            $finish;
        end
        if(pck_injct_in.pck_wr && (pck_injct_in.size<MIN_PCK_SIZ[PCK_SIZw-1 : 0])) begin 
            $display("%t: ERROR: requested %d flit packet size is smaller than minimum %d flits to send %d bits of data. %m",$time,pck_injct_in.size,MIN_PCK_SIZ, PCK_INJ_Dw );
            $finish;
        end
        
        `ifdef MONITOR_RSV_DAT
        if(pck_injct_in.pck_wr) begin 
            $display ("pck_inj(%d) send a packet:  size=%d, data=%h, v=%h",current_id,
                pck_injct_in.size, pck_injct_in.data,pck_injct_in.vc);
        end
        
        if(pck_injct_out.pck_wr) begin 
            $display ("pck_inj(%d) got a packet: source=%d, size=%d, data=%h",current_id,
                sendor_id,pck_injct_out.size,pck_injct_out.data);
        end
        `endif //MONITOR_RSV_DAT
    end
    `endif //SIMULATION
    
endmodule


/******************
 *   ovc_status
 *******************/
module injector_ovc_status #(
    parameter V = 4,
    parameter B = 16,
    parameter CRDTw = 4
)(
    input   [V-1 : 0] [CRDTw-1 : 0] credit_init_val_in,
    input   [V-1 : 0] wr_in,
    input   [V-1 : 0] credit_in,
    output  [V-1 : 0] full_vc,
    output  [V-1 : 0] nearly_full_vc,
    output  [V-1 : 0] empty_vc,
    input clk,
    input reset
);
    
    function integer log2;
        input integer number; begin   
            log2=(number <=1) ? 1: 0;    
            while(2**log2<number) begin    
                log2=log2+1;    
            end        
        end   
    endfunction // log2 
    
    localparam  DEPTH_WIDTH =   log2(B+1);
    
    reg  [DEPTH_WIDTH-1 : 0] credit    [V-1 : 0];
    wire  [V-1 : 0] cand_vc_next;
    
    genvar i;
    generate
    for(i=0;i<V;i=i+1) begin : vc_loop
        always @ (`pronoc_clk_reset_edge )begin 
            if(`pronoc_reset) begin
                credit[i]<= credit_init_val_in[i][DEPTH_WIDTH-1:0];
            end else begin
                if(  wr_in[i]  && ~credit_in[i])   credit[i] <= credit[i]-1'b1;
                if( ~wr_in[i]  &&  credit_in[i])   credit[i] <= credit[i]+1'b1;
            end //reset
        end//always
        assign  full_vc[i]   = (credit[i] == {DEPTH_WIDTH{1'b0}});
        assign  nearly_full_vc[i]=  (credit[i] == 1) |  full_vc[i];
        assign  empty_vc[i]  = (credit[i] == credit_init_val_in[i][DEPTH_WIDTH-1:0]);
    end//for
    endgenerate
endmodule


/**************************************
 * 
 *    packet_injector_verilator
 * ***********************************/
module packet_injector_verilator #(
    parameter NOC_ID=0
)(
    //general
    current_e_addr,
    reset,
    clk,
    //noc port
    chan_in,
    chan_out,  
    //control interafce
    pck_injct_in_data,
    pck_injct_in_size,
    pck_injct_in_endp_addr,
    pck_injct_in_class_num,
    pck_injct_in_init_weight,
    pck_injct_in_vc,
    pck_injct_in_pck_wr,
    pck_injct_in_ready,
    
    pck_injct_out_data,
    pck_injct_out_size,
    pck_injct_out_endp_addr,
    pck_injct_out_class_num,
    pck_injct_out_init_weight,
    pck_injct_out_vc,
    pck_injct_out_pck_wr,
    pck_injct_out_ready,
    pck_injct_out_distance,
    pck_injct_out_h2t_delay,
    min_pck_size
    
);
    
    `NOC_CONF 
    
    //general
    input reset,clk;
    input [EAw-1 :0 ] current_e_addr;
    
    // the destination endpoint address
    //NoC interface
    input   smartflit_chanel_t     chan_in;
    output  smartflit_chanel_t     chan_out;    
    //control interafce
    
    input [PCK_INJ_Dw-1 : 0] pck_injct_in_data;
    input [PCK_SIZw-1   : 0] pck_injct_in_size;
    input [DAw-1        : 0] pck_injct_in_endp_addr; 
    input [Cw-1         : 0] pck_injct_in_class_num; 
    input [WEIGHTw-1    : 0] pck_injct_in_init_weight;
    input [V-1          : 0] pck_injct_in_vc;
    input                    pck_injct_in_pck_wr;
    input [V-1          : 0] pck_injct_in_ready;
    
    output [PCK_INJ_Dw-1 : 0] pck_injct_out_data;
    output [PCK_SIZw-1   : 0] pck_injct_out_size;
    output [DAw-1        : 0] pck_injct_out_endp_addr;
    output [Cw-1         : 0] pck_injct_out_class_num;
    output [WEIGHTw-1    : 0] pck_injct_out_init_weight;
    output [V-1          : 0] pck_injct_out_vc;
    output                    pck_injct_out_pck_wr;
    output [V-1          : 0] pck_injct_out_ready;
    output [DISTw-1       : 0] pck_injct_out_distance;
    output [15              : 0] pck_injct_out_h2t_delay;
    output [4              : 0] min_pck_size;
    
    pck_injct_t pck_injct_in;
    pck_injct_t pck_injct_out;
    
    always_comb begin
        pck_injct_in.data         = pck_injct_in_data;
        pck_injct_in.size         = pck_injct_in_size;
        pck_injct_in.endp_addr    = pck_injct_in_endp_addr;
        pck_injct_in.class_num    = pck_injct_in_class_num;
        pck_injct_in.init_weight  = pck_injct_in_init_weight;
        pck_injct_in.vc           = pck_injct_in_vc;
        pck_injct_in.pck_wr       = pck_injct_in_pck_wr;
        pck_injct_in.ready        = pck_injct_in_ready;
    end
    
    assign pck_injct_out_data        = pck_injct_out.data;
    assign pck_injct_out_size        = pck_injct_out.size;
    assign pck_injct_out_endp_addr   = pck_injct_out.endp_addr;
    assign pck_injct_out_class_num   = pck_injct_out.class_num;
    assign pck_injct_out_init_weight = pck_injct_out.init_weight;
    assign pck_injct_out_vc          = pck_injct_out.vc;
    assign pck_injct_out_pck_wr      = pck_injct_out.pck_wr;
    assign pck_injct_out_ready       = pck_injct_out.ready;
    assign pck_injct_out_distance    = pck_injct_out.distance;
    assign pck_injct_out_h2t_delay   = pck_injct_out.h2t_delay;


    packet_injector #(
        .NOC_ID(NOC_ID)
    ) injector (
        .current_e_addr  (current_e_addr ), 
        .reset           (reset          ), 
        .clk             (clk            ), 
        .chan_in         (chan_in        ), 
        .chan_out        (chan_out       ), 
        .pck_injct_in    (pck_injct_in   ), 
        .pck_injct_out   (pck_injct_out  )
    ); 
    
    localparam 
        HDR_BYTE_NUM =    HDR_MAX_DATw / 8, // = HDR_MAX_DATw / (8 - HDR_MAX_DATw %8)
        HDR_DATA_w_tmp   =  HDR_BYTE_NUM * 8,
        HDR_DATA_w = 
        (PCK_INJ_Dw < HDR_DATA_w_tmp)? PCK_INJ_Dw :
        (HDR_DATA_w_tmp==0)? 1: HDR_DATA_w_tmp,
        REMAIN_DATw =  PCK_INJ_Dw - HDR_DATA_w,
        REMAIN_DAT_FLIT_I = (REMAIN_DATw / Fpay),
        REMAIN_DAT_FLIT_F = (REMAIN_DATw % Fpay == 0)? 0 : 1,
        REMAIN_DAT_FLIT   = REMAIN_DAT_FLIT_I + REMAIN_DAT_FLIT_F,
        CNTw = log2(REMAIN_DAT_FLIT),
        MIN_PCK_SIZ = REMAIN_DAT_FLIT +1;
    
    assign  min_pck_size = MIN_PCK_SIZ[4:0];
    
    // `ifdef VERILATOR
    //     logic  endp_is_active   /*verilator public_flat_rd*/ ;
    //
    //     always_comb begin 
    //        endp_is_active  = 1'b0; 
    //         if (chan_out.flit_chanel.flit_wr) endp_is_active=1'b1;
    //         if (chan_out.flit_chanel.credit > {V{1'b0}} ) endp_is_active=1'b1;
    //         if (chan_out.smart_chanel.requests > {SMART_NUM{1'b0}} ) endp_is_active=1'b1;
    //     end    
    // `endif 
endmodule
