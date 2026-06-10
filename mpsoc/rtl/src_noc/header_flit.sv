`include "pronoc_def.v"
/**********************************************************************
**  File:  header_flit.sv
**  Date:2017-07-11   
**    
**  Copyright (C) 2014-2017  Alireza Monemi
**    
**  This file is part of ProNoC 
**
**  ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**  you can redistribute it and/or modify it under the terms of the GNU
**  Lesser General Public License as published by the Free Software Foundation,
**  either version 2 of the License, or (at your option) any later version.
**
**  ProNoC is distributed in the hope that it will be useful, but WITHOUT
**  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
**  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
**  Public License for more details.
**
**  You should have received a copy of the GNU Lesser General Public
**  License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
**
**
**  Description: 
**  This file contains modules related to header flit 
******************************************************************/

/***************
*   header_flit_generator
***************/

module header_flit_generator #(
    parameter DATA_w=9 // header flit can carry Optional data. The data will be placed after control data.  Fpay >= DATA_w + CTRL_BITS_w  
)(
    flit_out,    
    src_e_addr_in,
    dest_e_addr_in,
    destport_in,
    class_in,
    weight_in, 
    vc_num_in,
    be_in,
    data_in    
);
    
    import pronoc_pkg::*;   
    localparam    HDR_FLAG  =   2'b10;        
    localparam 
        Dw = (DATA_w==0)? 1 : DATA_w,      
        DATA_LSB= MSB_BE+1,  
        DATA_MSB= ((DATA_LSB + DATA_w)<FPAYw) ? DATA_LSB + Dw-1 : FPAYw-1;
    
    output   [Fw-1  :   0] flit_out; 
    input    [Cw-1  :   0] class_in;    
    input    [DAw-1 :   0] dest_e_addr_in;
    input    [EAw-1 :   0] src_e_addr_in;
    input    [V-1   :   0] vc_num_in;
    input    [WEIGHTw-1 :   0] weight_in;
    input    [DSTPw-1   :   0] destport_in;
    input    [BEw-1 : 0] be_in;
    input    [Dw-1  :   0] data_in;
    
   // assign flit_out [W+Cw+P_1+Xw+Yw+Xw+Yw-1 :0] = {weight_i,class_i,destport_i,x_dst_i,y_dst_i,x_src_i,y_src_i};
    assign flit_out [E_SRC_MSB : E_SRC_LSB] = src_e_addr_in;
    assign flit_out [E_DST_MSB : E_DST_LSB] = dest_e_addr_in;
    assign flit_out [DST_P_MSB : DST_P_LSB] = destport_in; 
    
    generate
    if(C>1)begin :have_class 
        assign flit_out [CLASS_MSB :CLASS_LSB] = class_in; 
    end 
    
    if(~IS_RRA)begin  : wrra_b
        assign flit_out [WEIGHT_MSB :WEIGHT_LSB] = weight_in;
    end 
    
    if( BYTE_EN ) begin : be_1
        assign flit_out [BE_MSB : BE_LSB] = be_in;
    end
    
    if (DATA_w ==0) begin :no_data
        if(FPAYw>DATA_LSB) begin: dontcare
            assign flit_out [FPAYw-1 : DATA_LSB] = {(FPAYw-DATA_LSB){1'b0}};
        end
    end else begin :have_data
        if (FPAYw > DATA_MSB+1) begin
            assign flit_out [FPAYw-1 : DATA_MSB+1] = {(FPAYw-DATA_MSB-1){1'b0}};
        end
        assign flit_out [DATA_MSB : DATA_LSB] = data_in[DATA_MSB-DATA_LSB : 0]; // we have enough space for adding whole of the data                 
    end    
    endgenerate    
    
    assign flit_out [FPAYw+V-1    :   FPAYw] = vc_num_in;
    assign flit_out [Fw-1        :    Fw-2] = HDR_FLAG;  
    
    `ifdef SIMULATION
    initial begin
        if((DATA_LSB + DATA_w)-1 > FPAYw)begin
            $display("%t: ERROR: The reqired header flit size is %d which is larger than %d payload size   ",$time,(DATA_LSB + DATA_w)-1,FPAYw);
            $finish;
        end
    end
    `endif
endmodule


module extract_header_flit_info # (
    parameter DATA_w = 0
) (
    //inputs
    flit_in,
    flit_in_wr,
    //outputs
    src_e_addr_o,
    dest_e_addr_o,
    destport_o,
    class_o,
    weight_o, 
    data_o,   
    tail_flg_o,
    hdr_flg_o,   
    vc_num_o,  
    hdr_flit_wr_o,
    be_o    
);     
    
    import pronoc_pkg::*;
    
    localparam       
        W = WEIGHTw,
        Dw = (DATA_w==0)? 1 : DATA_w,
        DATA_LSB= MSB_BE+1,               
        DATA_MSB= ((DATA_LSB + DATA_w)<FPAYw) ? DATA_LSB + Dw-1 : FPAYw-1,
        OFFSETw = DATA_MSB - DATA_LSB +1; 
    
    input [Fw-1 : 0] flit_in;
    input flit_in_wr;
    output [EAw-1 : 0] src_e_addr_o;
    output [DAw-1 : 0] dest_e_addr_o;
    output [DSTPw-1 : 0] destport_o;    
    output [Cw-1 : 0] class_o;
    output [W-1  : 0] weight_o;
    output tail_flg_o;
    output hdr_flg_o;    
    output [V-1 : 0] vc_num_o;
    output [V-1 : 0] hdr_flit_wr_o;
    output [BEw-1 : 0] be_o;
    output [Dw-1  :   0] data_o;
    
    wire [OFFSETw-1 : 0 ] offset;
    
    assign src_e_addr_o = flit_in [E_SRC_MSB : E_SRC_LSB];
    assign dest_e_addr_o = flit_in [E_DST_MSB : E_DST_LSB];
    assign destport_o = flit_in [DST_P_MSB : DST_P_LSB];
    
    generate
    if(C>1)begin :have_class 
        assign class_o = flit_in [CLASS_MSB : CLASS_LSB];
    end else begin : no_class
        assign class_o = {Cw{1'b0}};
    end 
    if(~IS_RRA)begin  : wrra_b
        assign weight_o =  flit_in [WEIGHT_MSB : WEIGHT_LSB];    
    end else begin : rra_b
        assign weight_o = {WEIGHTw{1'bX}};        
    end 
    if( BYTE_EN ) begin : be_1
        assign be_o = flit_in [BE_MSB : BE_LSB];    
    end else begin : be_0    
        assign be_o = {BEw{1'bX}};
    end
    assign offset = flit_in [DATA_MSB : DATA_LSB];    
    if(Dw > OFFSETw) begin : if1     
        assign data_o={{(Dw-OFFSETw){1'b0}},offset};
    end else begin : if2 
        assign data_o=offset[Dw-1 : 0];
    end    
    endgenerate          
    
    assign hdr_flg_o  = (IS_MULTI_FLIT) ? flit_in [Fw-1]  : 1'b1;
    assign tail_flg_o = (IS_MULTI_FLIT) ? flit_in [Fw-2]  : 1'b1;
    assign vc_num_o = flit_in [FPAYw+V-1 : FPAYw];
    assign hdr_flit_wr_o= (flit_in_wr & hdr_flg_o )? vc_num_o : {V{1'b0}};
endmodule

module header_flit_info #(
    parameter DATA_w = 0 
)(
    flit,
    hdr_flit,
    data_o
);
    
    import pronoc_pkg::*;
    
    localparam 
        Dw = (DATA_w==0)? 1 : DATA_w;
    
    input flit_t flit;
    output hdr_flit_t hdr_flit;
    output [Dw-1 : 0] data_o;
    
    localparam
        DATA_LSB= MSB_BE+1,
        DATA_MSB= (DATA_LSB + DATA_w)<FPAYw ? DATA_LSB + Dw-1 : FPAYw-1,
        OFFSETw = DATA_MSB - DATA_LSB +1;
    
    always_comb begin
        hdr_flit.src_e_addr  = flit.payload [E_SRC_MSB : E_SRC_LSB];
        hdr_flit.dest_e_addr = flit.payload [E_DST_MSB : E_DST_LSB];
        hdr_flit.destport    = flit.payload [DST_P_MSB : DST_P_LSB];
        hdr_flit.message_class = (C>1)? flit.payload [CLASS_MSB : CLASS_LSB] :  {Cw{1'b0}};
        hdr_flit.weight = (IS_WRRA)? flit.payload [WEIGHT_MSB : WEIGHT_LSB] : {WEIGHTw{1'b0}};
        hdr_flit.be = (BYTE_EN)? flit.payload [BE_MSB : BE_LSB]: {BEw{1'b0}};
    end
    
    wire [OFFSETw-1 : 0 ] offset = flit.payload [DATA_MSB : DATA_LSB];
    generate
    if(Dw > OFFSETw) begin : if1
        assign data_o={{(Dw-OFFSETw){1'b0}},offset};
    end else begin : if2 
        assign data_o=offset[Dw-1 : 0];
    end
    endgenerate
endmodule

/***********************************    
*  flit_update
*  update the header flit look ahead routing and output VC
*********************************/
module header_flit_update_lk_route_ovc #(
    parameter P = 5
)(
    flit_in ,
    flit_out,
    vc_num_in,
    lk_dest_all_in,
    assigned_ovc_num,
    any_ivc_sw_request_granted,
    lk_dest_not_registered,
    sel,
    reset,
    clk
);
    import pronoc_pkg::*;
    
    input [Fw-1 : 0]  flit_in;
    output reg [Fw-1 : 0]  flit_out;
    input [V-1 : 0]  vc_num_in;
    input [DSTPw-1 : 0]  lk_dest_all_in [V-1:0];
    input reset,clk;
    input [V-1 : 0]  assigned_ovc_num[V-1:0];
    input [V-1 : 0]  sel;
    input any_ivc_sw_request_granted;
    input [DSTPw-1 : 0]  lk_dest_not_registered;
    
    wire hdr_flag;
    logic [V-1 : 0]  vc_num_delayed;
    logic [V-1 : 0]  ovc_num; 
    wire [DSTPw-1 : 0]  lk_dest,dest_coded;
    logic [DSTPw-1 : 0]  lk_mux_out;
    always_ff @ (`pronoc_clk_reset_edge) begin
        if (`pronoc_reset) begin
            vc_num_delayed <= '0;
        end else begin
            vc_num_delayed <= vc_num_in;
        end
    end
    assign hdr_flag = (IS_MULTI_FLIT)? flit_in[Fw-1]: 1'b1;
    //One-hot mux
    always_comb begin
        lk_mux_out = '0;
        ovc_num = '0;
        for (int k = 0; k < V; k++) begin
            lk_mux_out |= (vc_num_delayed[k]) ?  lk_dest_all_in[k] :  '0;
            ovc_num |= (vc_num_delayed[k]) ?  assigned_ovc_num[k] :  '0;
        end
    end
    generate 
    if( SSA_EN == 1 ) begin : predict // bypass the lk fifo when no ivc is granted
        logic ivc_any_delayed;
        always_ff @ (`pronoc_clk_reset_edge) begin
            if (`pronoc_reset) begin
                ivc_any_delayed <= 1'b0;
            end else begin
                ivc_any_delayed <= any_ivc_sw_request_granted;
            end
        end
        assign lk_dest = (ivc_any_delayed == 1'b0)? lk_dest_not_registered : lk_mux_out;
    end else begin : no_predict
        assign lk_dest =lk_mux_out;
    end 
    endgenerate
    
    generate 
    if(IS_REGULAR_TOPO & (~IS_DETERMINISTIC))begin :coded
        regular_topo_adaptive_lk_dest_encoder  dest_encoder  (
            .sel(sel),
            .dest_coded_out(dest_coded),
            .vc_num_delayed(vc_num_delayed),
            .lk_dest(lk_dest),
            .flit_in(flit_in)
        );
    end else begin : dtrmn1
        assign dest_coded = lk_dest;
        /*
        regular_topo_dtrmn_dest_encoder #(
            .P(P),
            .DSTPw(DSTPw),
            .Fw(Fw),
            .DST_P_MSB(DST_P_MSB),
            .DST_P_LSB(DST_P_LSB)
        ) dest_encoder  (
            .dest_coded_out(dest_coded),
            .lk_dest(lk_dest),
            .flit_in(flit_in)
        );
         */
    end
    
    always_comb begin 
        flit_out = {flit_in[Fw-1 : Fw-2],ovc_num,flit_in[FPAYw-1 :0]};
        if(hdr_flag & IS_LOOKAHEAD) flit_out[DST_P_MSB : DST_P_LSB]= dest_coded;
    end
    endgenerate
endmodule

/******************
 *  hdr_flit_weight_update
 * ****************/
module hdr_flit_weight_update  (
    new_weight,
    flit_in,
    flit_out    
);
    import pronoc_pkg::*;
    
    input [WEIGHTw-1 : 0] new_weight;
    input [Fw-1 : 0] flit_in;
    output [Fw-1 : 0] flit_out;
    
    assign flit_out =  {flit_in[Fw-1 : WEIGHT_LSB+WEIGHTw ] ,new_weight, flit_in[WEIGHT_LSB-1 : 0] };
endmodule