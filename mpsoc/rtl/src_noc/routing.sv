`include "pronoc_def.v"
/**********************************************************************
**    File:  routing.v
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
**    look-ahead and conventional routing algorithms for Mesh and Torus NoC
**    
**
**************************************************************/


module conventional_routing #(
    parameter LOCATED_IN_NI = 1 // only needed for mesh and odd-even routing
)(
    reset,
    clk,
    current_r_addr,
    src_e_addr,
    dest_e_addr,
    destport
);

    import pronoc_pkg::*;
    
    input  reset,clk;
    input   [RAw-1   :0] current_r_addr;
    input   [EAw-1   :0] src_e_addr;
    input   [DAw-1   :0] dest_e_addr;
    output  [DSTPw-1 :0] destport;
    
    generate
    if( IS_REGULAR_TOPO | IS_FMESH ) begin : regular_topo
        regular_topo_router_addr_t dest_router_addr, current_router_addr;
        always @(*) begin
            dest_router_addr = regular_topo_router_addr_t'(dest_e_addr);
            current_router_addr = regular_topo_router_addr_t'(current_r_addr);
        end
        regular_topo_conventional_routing #(
            .LOCATED_IN_NI(LOCATED_IN_NI)
        ) the_conventional_routing  (
            .current_router_addr_i(current_router_addr),
            .dest_router_addr_i(dest_router_addr),
            .destport(destport)
        );
    end else if(IS_FATTREE | IS_TREE ) begin : ftree
        wire [LKw-1 :0]    current_rx;
        wire [Lw-1  :0]    current_rl;
        
        fattree_router_addr_decode router_addr_decode
        (
            .r_addr(current_r_addr),
            .rx(current_rx),
            .rl(current_rl)
        );
        if( IS_FATTREE ) begin : fattree
            fattree_conventional_routing the_conventional_routing (
                .reset(reset),
                .clk(clk),
                .current_addr_encoded(current_rx),
                .current_level(current_rl),
                .dest_addr_encoded(dest_e_addr),
                .destport_encoded(destport)
            );
        end else if( IS_TREE )begin : tree
            tree_conventional_routing #(
                .ROUTE_NAME(ROUTE_NAME),
                .K(T1),
                .L(T2)
            ) the_conventional_routing (
                .current_addr_encoded(current_rx),
                .current_level(current_rl),
                .dest_addr_encoded(dest_e_addr),
                .destport_encoded(destport)
            );
        end // tree
    end else if (IS_STAR) begin : star
    /* verilator lint_on WIDTH */
        star_conventional_routing #(
            .NE(T1)
        ) the_conventional_routing  (
            .dest_e_addr(dest_e_addr),
            .destport(destport)
        );
    end else if (IS_MULTI_MESH) begin : multimesh
    /*
        mesh_cluster_route_xyz  the_conventional_routing  (
            .current_router_addr_i(current_r_addr),
            .destination_router_addr_i(dest_e_addr[EAw-1:0]),
            .router_port_out(destport)
        );
    */
    end else if (IS_MESH_3D) begin : M3D_
        regular_topo_endp_addr_t dest_e_addr_3d;
        always @(*) begin
            dest_e_addr_3d = regular_topo_endp_addr_t'(dest_e_addr);
        end
        mesh_3d_route_xyz the_conventional_routing(
            .current_router_addr_i(current_r_addr),
            .destination_endp_addr_i(dest_e_addr_3d),
            .router_port_out(destport)
        );
    end else begin :custom
        custom_conv_routing  #(
            .TOPOLOGY(TOPOLOGY),
            .ROUTE_NAME(ROUTE_NAME),
            .ROUTE_TYPE(ROUTE_TYPE),
            .RAw(RAw),
            .EAw(EAw),
            .DSTPw(DSTPw)
        ) the_conventional_routing (
            .current_r_addr(current_r_addr),
            .dest_e_addr(dest_e_addr),
            .src_e_addr(src_e_addr),
            .destport(destport)
        );
    end //custom
    endgenerate
endmodule


/************************************
*     look_ahead_routing
*************************************/
module look_ahead_routing #(
    parameter P = 5
)(
    current_r_addr,  //current router  address
    neighbors_r_addr,
    dest_e_addr,  // destination endpoint address
    src_e_addr, //   source endpoint address. Only needed for custom topology
    destport_encoded,   // current router destination port number
    lkdestport_encoded, // look ahead destination port number
    reset,
    clk
);
    import pronoc_pkg::*;
    
    localparam
        PRAw= P * RAw,
        PLw = P * Lw,
        PLKw = P * LKw;
    input   [PRAw-1:  0]  neighbors_r_addr;
    input   [RAw-1   :   0]  current_r_addr;
    input   [DAw-1   :   0]  dest_e_addr;
    input   [EAw-1   :   0]  src_e_addr;
    input   [DSTPw-1  :   0]  destport_encoded;
    output  [DSTPw-1  :   0]  lkdestport_encoded;
    input   reset,clk;
    localparam  PP = ( IS_MESH || IS_FMESH || IS_TORUS ) ? 5 : 3;
    logic [RAw-1 : 0]  neighbors_r_addr_array [PP-1 : 0];
    
    genvar i;
    generate
    for (i=0;i<PP;i++)begin :sep 
        assign neighbors_r_addr_array[i] = neighbors_r_addr[(i+1)*RAw-1 : i*RAw];
    end
    if(IS_REGULAR_TOPO | IS_FMESH ) begin : regular_fmesh
        regular_topo_router_addr_t dest_router_addr;
        always @(*) begin
            dest_router_addr = regular_topo_router_addr_t'(dest_e_addr);
        end
        regular_topo_look_ahead_routing lkh_route  (
            .dest_router_addr_i(dest_router_addr),
            .destport_encoded(destport_encoded),
            .neighbors_r_addr(neighbors_r_addr_array),
            .lkdestport_encoded(lkdestport_encoded),
            .reset(reset),
            .clk(clk)
        );
    end else if (IS_FATTREE) begin: fat
        wire  [PLKw-1 : 0]  neighbors_rx;
        wire  [PLw-1 : 0]  neighbors_ry;
        for (i=0; i<P; i=i+1) begin : port
            assign neighbors_rx[(i+1)*LKw-1: i*LKw] = neighbors_r_addr[(i*RAw)+LKw-1 : i*RAw];
            assign neighbors_ry[(i+1)*Lw-1 : i*Lw]  = neighbors_r_addr[(i+1)*RAw-1: (i*RAw)+LKw];
        end//port
        fattree_look_ahead_routing #(
            .P(P)
        ) look_ahead_route (
            .destport_encoded(destport_encoded),
            .dest_addr_encoded(dest_e_addr),
            .neighbors_rx(neighbors_rx),
            .neighbors_ry(neighbors_ry),
            .lkdestport_encoded(lkdestport_encoded),
            .reset(reset),
            .clk(clk)
        );
    end else if ( IS_TREE) begin: tree
        wire  [PLKw-1 : 0]  neighbors_rx_tree;
        wire  [PLw-1 : 0]  neighbors_ry_tree;
        for (i=0; i<P; i=i+1) begin : port
            assign neighbors_rx_tree[(i+1)*LKw-1: i*LKw] = neighbors_r_addr[(i*RAw)+LKw-1 : i*RAw];
            assign neighbors_ry_tree[(i+1)*Lw-1 : i*Lw]  = neighbors_r_addr[(i+1)*RAw-1: (i*RAw)+LKw];
        end//port
        tree_look_ahead_routing #(
            .P(P)
        )  look_ahead_routing (
            .destport_encoded(destport_encoded),
            .dest_addr_encoded(dest_e_addr),
            .neighbors_rx(neighbors_rx_tree),
            .neighbors_ry(neighbors_ry_tree),
            .lkdestport_encoded(lkdestport_encoded),
            .reset(reset),
            .clk(clk)
        );
    end else if (IS_STAR) begin : star
        //look-ahead routing is not needed in star topology as there is only one router
        assign  lkdestport_encoded={DSTPw{1'b0}};
    end else if (IS_MULTI_MESH) begin : multimesh
        assign  lkdestport_encoded={DSTPw{1'b0}};
    end else begin : custom
        custom_lkh_routing  #(
            .TOPOLOGY(TOPOLOGY),
            .ROUTE_NAME(ROUTE_NAME),
            .ROUTE_TYPE(ROUTE_TYPE),
            .RAw(RAw),
            .EAw(EAw),
            .DSTPw(DSTPw)
        )  look_ahead_routing  (
            .current_r_addr(current_r_addr),
            .dest_e_addr(dest_e_addr),
            .src_e_addr(src_e_addr),
            .destport(lkdestport_encoded),
            .reset(reset),
            .clk(clk)
        );
    end
    endgenerate
endmodule

/********************************************************
*               next_router_addr_selector
* Determine the next router address based on the packet destination port
********************************************************/
module next_router_addr_selector_onehot #(
    parameter P = 5,
    parameter RXw = 3,  // The router's x dimension adress width in bits
    parameter RYw = 3  // The router's y dimension adress width in bits
)(
    destport_onehot,
    neighbors_rx,
    neighbors_ry,
    next_rx,
    next_ry
);
    localparam
        PRXw = P * RXw,
        PRYw = P * RYw;
    
    input [P-1   : 0] destport_onehot;
    input [PRXw-1: 0] neighbors_rx;
    input [PRYw-1: 0] neighbors_ry;
    output logic [RXw-1 : 0] next_rx;
    output logic [RYw-1 : 0] next_ry;
    
    wire [RXw-1:0] neighbors_rx_array [P-1: 0];
    wire [RYw-1:0] neighbors_ry_array [P-1: 0];
    genvar i;
    generate for(i=0;i<P;i++) begin :P_
        assign neighbors_rx_array[i] = neighbors_rx[(i*RXw)+:RXw];
        assign neighbors_ry_array[i] = neighbors_ry[(i*RYw)+:RYw];
    end endgenerate
    
    //Onehot mux to select available ovc
    always_comb begin
        next_rx = '0;
        next_ry = '0;
        for (int k = 0; k < P; k++) begin
            next_rx |= (destport_onehot[k]) ? neighbors_rx_array[k] : '0;
            next_ry |= (destport_onehot[k]) ? neighbors_ry_array[k] : '0;
        end
    end//always
endmodule


module next_router_addr_selector_bin #(
    parameter P = 5,
    parameter RXw = 3,  // The router's x dimension adress width in bits
    parameter RYw = 3  // The router's y dimension adress width in bits
) (
    destport_bin,
    neighbors_rx,
    neighbors_ry,
    next_rx,
    next_ry
);
    function integer log2;
    input integer number; begin
        log2=(number <=1) ? 1: 0;
        while(2**log2<number) begin
            log2=log2+1;
        end
    end
    endfunction // log2
    
    localparam
        Pw = log2(P),
        PRXw = P * RXw,
        PRYw = P * RYw;
    
    input [Pw-1 : 0] destport_bin;
    input [PRXw-1: 0] neighbors_rx;
    input [PRYw-1: 0] neighbors_ry;
    output [RXw-1 : 0] next_rx;
    output [RYw-1 : 0] next_ry;
    wire [RXw-1:0] neighbors_rx_array [P-1: 0];
    wire [RYw-1:0] neighbors_ry_array [P-1: 0];
    genvar i;
    generate for(i=0;i<P;i++) begin :P_
        assign neighbors_rx_array[i] = neighbors_rx[(i*RXw)+:RXw];
        assign neighbors_ry_array[i] = neighbors_ry[(i*RYw)+:RYw];
    end endgenerate
    assign next_rx = neighbors_rx_array[destport_bin];
    assign next_ry = neighbors_ry_array[destport_bin];
endmodule

/******************
*   local_route_computation
*   Compute the output port based on the current router address and destination address
*   Used when lookahead routing is not used or in multicast routing
*******************/
module local_route_computation #(
    parameter P = 5,
    parameter SW_LOC = 0 // switch location
)(
    endp_port,
    current_r_addr,
    chan_in,
    chan_out,
    clk,
    reset
);  
    import pronoc_pkg::*;
    input endp_port;
    input   [RAw-1 : 0]  current_r_addr;
    input   flit_chanel_t chan_in;
    input   clk,reset;
    output  flit_chanel_t chan_out;
    
    flit_chanel_t chan_out_tmp;
    wire [DSTPw-1 :0] destport,destport_out;
    always_comb begin 
        chan_out_tmp=chan_in;
        if(chan_in.flit.hdr_flag == 1'b1) begin
            chan_out_tmp.flit [DST_P_MSB : DST_P_LSB] = destport_out;
        end
    end
    
    generate 
    if(IS_UNICAST) begin : uni
        localparam LOCATED_IN_NI=
            (IS_MESH | IS_TORUS | IS_FMESH)? ((SW_LOC==LOCAL) || (SW_LOC > SOUTH) ) : 
            (IS_RING | IS_LINE) ? ((SW_LOC==LOCAL) || (SW_LOC > BACKWARD) )  : 0;
        hdr_flit_t hdr_flit_i;
        wire [DSTPw-1 :0] destport;
        header_flit_info #(
            .DATA_w (0)
        ) extractor (
            .flit(chan_in.flit),
            .hdr_flit(hdr_flit_i),
            .data_o( )
        );
        conventional_routing #(
            .LOCATED_IN_NI(LOCATED_IN_NI) // Only needed for mesh and odd-even routing
        ) conv_route (
            .reset(reset),
            .clk(clk),
            .current_r_addr(current_r_addr),
            .src_e_addr(hdr_flit_i.src_e_addr),
            .dest_e_addr(hdr_flit_i.dest_e_addr),
            .destport(destport)
        );
        if((IS_DETERMINISTIC == 1'b0) && (LOCATED_IN_NI==0) && (IS_REGULAR_TOPO==1'b1)) begin 
            regular_topo_adaptive_lk_dest_encoder encoder(
                .sel({V{1'b1}}),
                .flit_in(chan_in.flit),
                .dest_coded_out(destport_out),
                .vc_num_delayed({V{1'b1}}),
                .lk_dest(destport)
            );
        end else begin 
            assign destport_out = destport;
        end
        assign chan_out = chan_out_tmp;
    end else begin : multi
        multicast_chan_in_process #(
            .SW_LOC(SW_LOC),
            .P(P)
        )multi_cast(
            .endp_port(endp_port),
            .current_r_addr(current_r_addr),
            .chan_in(chan_in),
            .chan_out(chan_out),
            .clk(clk)
        );
    end
    endgenerate
endmodule
