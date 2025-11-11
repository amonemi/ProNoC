`include "pronoc_def.v"
/**********************************************************************
**    File:  mesh_cluster.sv
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
**
**    Description:
**    A `mesh_cluster` refers to a group of interconnected routers arranged in a **3D Mesh topology**
**    within a larger **Multi-Mesh NoC** for chiplets. In this architecture, each chiplet functions
**    as an independent cluster of nodes, featuring its own local mesh-based communication network.
**
**    Each router in the `mesh_cluster` drives two I/O channels:
**    1. **Endpoint Channel** – Connects to processing elements (PEs) or memory endpoints.
**    2. **Vertical Link Channel** – Facilitates inter-cluster communication.
**
**    If an endpoint or vertical link is not present in the target Multi-Mesh topology,
**    the corresponding input is tied to **ground**, enabling synthesis optimizations
**    that effectively remove unused logic.
**
***************************************/


module mesh_cluster
    import pronoc_pkg::*;
#(
    parameter
        CLUSTER_ID = 0,
        RID_INIT = 0,
            // The initial value of Router IDs (RIDs) in this mesh cluster.
            // This parameter is used to generate unique RIDs for each router in the cluster.
            // It ensures that RIDs are distinct across multiple meshes when used in a multi-mesh configuration.
        CLUSTER_NX = 2,
            //Total number of nodes in the X dimension (horizontal axis) of the mesh cluster.
        CLUSTER_NY = 2,
            //Total number of nodes in the Y dimension (vertical axis) of the mesh cluster.
        CLUSTER_NZ = 2,
            //Total number of nodes in the Z dimension (depth axis) of the mesh cluster.
        CLUSTER_NE = 8,
            // Total number of endpoints (processing elements)

    localparam
        CLUSTER_NR = CLUSTER_NX * CLUSTER_NY * CLUSTER_NZ,
            // Total number of routers in cluster
        CLUSTER_NVP =
            // Total number of vertical ports per router used for inter-cluster
            // communication i.e. the down ports of the routers on the first
            // layer and the up ports of the routers in the last layer
            (CLUSTER_NX * CLUSTER_NY) * 2,
        CLUSTER_MAX_P = 7
)(
    input logic clk,
    input logic reset,
    input logic [CLUSTER_IDw-1:0] cluster_id,
    // Endpoints ports
    input  smartflit_chanel_t endpoint_chan_in [CLUSTER_NE-1:0],
    output smartflit_chanel_t endpoint_chan_out[CLUSTER_NE-1:0],
    // Inter-Cluster interconnect ports
    input  smartflit_chanel_t inter_cluster_chan_in [CLUSTER_NVP-1:0],
    output smartflit_chanel_t inter_cluster_chan_out[CLUSTER_NVP-1:0],
    // Events
    output router_event_t router_event[CLUSTER_NR-1:0][CLUSTER_MAX_P-1:0]
);
    // Indididual routers interconnect ports
    smartflit_chanel_t router_chan_in [CLUSTER_NZ-1:0][CLUSTER_NY-1:0][CLUSTER_NX-1:0][CLUSTER_MAX_P-1:0];
    smartflit_chanel_t router_chan_out[CLUSTER_NZ-1:0][CLUSTER_NY-1:0][CLUSTER_NX-1:0][CLUSTER_MAX_P-1:0];

    // Unused Input channels are connected to ground
    smartflit_chanel_t is_grounded;
    assign is_grounded = {SMARTFLIT_CHANEL_w{1'b0}};

    multimesh_router_addr_t current_r_addr[CLUSTER_NR-1:0];
    router_config_t router_config_in[CLUSTER_NR-1:0];

    genvar x, y, z;
    generate
    for (z = 0; z < CLUSTER_NZ; z = z + 1) begin: Z_
        for (y = 0; y < CLUSTER_NY; y = y + 1) begin: Y_
            for (x = 0; x < CLUSTER_NX; x = x + 1) begin: X_
                localparam
                    V_DOWN_ID = (y * CLUSTER_NX) + x,
                    V_UP_ID = (y * CLUSTER_NX) + x + (CLUSTER_NX * CLUSTER_NY),
                    RID = z * (CLUSTER_NX * CLUSTER_NY) + (y * CLUSTER_NX) + x,
                    EID = RID,
                    // NOTE: as an optimization, we could disable the Up/Down
                    // ICR also when no VL reaches the router
                    UP_ICR_EN    = (z == 0),
                    DOWN_ICR_EN  = (z == (CLUSTER_NZ-1)),
                    // NOTE: as an optimization, we could disable it if there
                    // is no endpoint connected
                    LOCAL_ICR_EN = 1,
                    // NOTE: as an optimization, we could only enable the ICR
                    // of the 2D ports when an endpoint is connected
                    NORTH_ICR_EN = 1,
                    SOUTH_ICR_EN = 1,
                    WEST_ICR_EN  = 1,
                    EAST_ICR_EN  = 1;

                assign current_r_addr[RID] = '{x:x, y:y, z:z, c:cluster_id};

                depth_first_router #(
                    .ROUTER_ID(RID+RID_INIT),
                    .P(CLUSTER_MAX_P),
                    // NOTE: ICR must be enable for:
                    // (*) The port Up (or Down) when a VL leaves or (reaches)
                    //     the port and the Router Z dimension is 0 or Max_Z ;
                    // (*) The local port, if an endpoint is connected to it ;
                    // (*) Any 2D port (N/S/W/E) where an endpoint is connected
                    //     to it ;
                    .UP_ICR_EN(UP_ICR_EN),
                    .DOWN_ICR_EN(DOWN_ICR_EN),
                    .LOCAL_ICR_EN(LOCAL_ICR_EN),
                    .NORTH_ICR_EN(NORTH_ICR_EN),
                    .SOUTH_ICR_EN(SOUTH_ICR_EN),
                    .WEST_ICR_EN(WEST_ICR_EN),
                    .EAST_ICR_EN(EAST_ICR_EN)
`ifndef DYNAMIC_CLUSTER_INIT
                    ,.CLUSTER_ID(CLUSTER_ID),
                    .CLUSTER_RID(RID)
`endif
                ) the_router(
                    .clk(clk),
                    .reset(reset),
`ifdef DYNAMIC_CLUSTER_INIT
                    // NOTE: The dynamic ICRT has not been integrated for now
                    .program_port(),
`endif
                    .router_config_in(router_config_in[RID]),
                    .chan_in(router_chan_in [z][y][x]),
                    .chan_out(router_chan_out[z][y][x]),
                    .router_event(router_event[RID])
                );
                assign router_config_in[RID].router_addr = current_r_addr[RID];
                assign router_config_in[RID].endp_addrs = current_r_addr[RID];
                assign router_config_in[RID].router_id = RID+RID_INIT;
                assign router_config_in[RID].endp_ids = RID+RID_INIT;
                // **Mesh Interconnect Logic**
`ifndef PITON_EXTRA_MEMS
                assign router_chan_in[z][y][x][EAST] = (x < CLUSTER_NX-1) ?
                    router_chan_out[z][y][x+1][WEST] : is_grounded;
                assign router_chan_in[z][y][x][NORTH] = (y > 0) ?
                    router_chan_out[z][y-1][x][SOUTH] : is_grounded;
    // ProNoC is used standalone, without OpenPiton
    `ifndef PITON_PRONOC
                assign router_chan_in[z][y][x][WEST] =  (x > 0) ?
                    router_chan_out[z][y][x-1][EAST] : is_grounded;
    `else // PITON_PRONOC
                if (CLUSTER_ID == 0) begin
                    // Leave the western connection (x=0) unconnected
                    if (x > 0) begin
                        assign router_chan_in[z][y][x][WEST] =
                            router_chan_out[z][y][x-1][EAST];
                    end
                end else begin
                    assign router_chan_in[z][y][x][WEST] =  (x > 0) ?
                        router_chan_out[z][y][x-1][EAST] : is_grounded;
                end
    `endif // PITON_PRONOC
                assign router_chan_in[z][y][x][SOUTH] = (y < CLUSTER_NY-1) ?
                    router_chan_out[z][y+1][x][NORTH] : is_grounded;
`else // PITON_EXTRA_MEMS
                // Only for Chiplet 0 (Interposer)
                if (CLUSTER_ID == 0) begin
                    // Compared to the code below, this connects the outputs
                    // (coming in) of the endpoints on the edges of the mesh,
                    // to the router's incoming traffic
                    assign router_chan_in[z][y][x][EAST] = (x < CLUSTER_NX-1) ?
                        router_chan_out[z][y][x+1][WEST] :
                        endpoint_chan_in[CLUSTER_NX*CLUSTER_NY+CLUSTER_NX*2+CLUSTER_NY+y];
                    assign router_chan_in[z][y][x][NORTH] = (y > 0) ?
                        router_chan_out[z][y-1][x][SOUTH] :
                        endpoint_chan_in[CLUSTER_NX*CLUSTER_NY+x];
                    assign router_chan_in[z][y][x][WEST] =  (x > 0) ?
                        router_chan_out[z][y][x-1][EAST] :
                        endpoint_chan_in[CLUSTER_NX*CLUSTER_NY+CLUSTER_NX*2+y];
                    assign router_chan_in[z][y][x][SOUTH] = (y < CLUSTER_NY-1) ?
                        router_chan_out[z][y+1][x][NORTH] :
                        endpoint_chan_in[CLUSTER_NX*CLUSTER_NY+CLUSTER_NX+x];
                // Other chiplets
                end else begin
                    assign router_chan_in[z][y][x][EAST] = (x < CLUSTER_NX-1) ?
                        router_chan_out[z][y][x+1][WEST] : is_grounded;
                    assign router_chan_in[z][y][x][NORTH] = (y > 0) ?
                        router_chan_out[z][y-1][x][SOUTH] : is_grounded;
                    assign router_chan_in[z][y][x][WEST] =  (x > 0) ?
                        router_chan_out[z][y][x-1][EAST] : is_grounded;
                    assign router_chan_in[z][y][x][SOUTH] = (y < CLUSTER_NY-1) ?
                        router_chan_out[z][y+1][x][NORTH] : is_grounded;
                end
`endif // PITON_EXTRA_MEMS
                assign router_chan_in[z][y][x][UP] = (z < CLUSTER_NZ-1) ?
                        router_chan_out[z+1][y][x][DOWN] : inter_cluster_chan_in[V_UP_ID];
                assign router_chan_in[z][y][x][DOWN] = (z > 0) ?
                        router_chan_out[z-1][y][x][UP] : inter_cluster_chan_in[V_DOWN_ID];
                //endpoint connections
                assign router_chan_in[z][y][x][LOCAL] =   endpoint_chan_in[EID];
                assign endpoint_chan_out[EID] = router_chan_out[z][y][x][LOCAL];
                //inter_cluster connections
                if (z==0) begin
                    assign inter_cluster_chan_out[V_UP_ID] = router_chan_out[z][y][x][UP];
                end
                if (z==CLUSTER_NZ-1) begin
                    assign inter_cluster_chan_out[V_DOWN_ID] = router_chan_out[z][y][x][DOWN];
                end
            end //X
        end //Y
    end //Z
    endgenerate
`ifndef PITON_EXTRA_MEMS
    `ifdef PITON_PRONOC
    generate
        if (CLUSTER_ID == 0) begin
            // Tile 0-0 W <-> Chipset connections
            assign router_chan_in[0][0][0][WEST] =
                endpoint_chan_in[CLUSTER_NX*CLUSTER_NY*CLUSTER_NZ];
            assign endpoint_chan_out[CLUSTER_NX*CLUSTER_NY*CLUSTER_NZ] =
                router_chan_out[0][0][0][WEST];
        end
    endgenerate
    `endif // PITON_PRONOC
`else // PITON_EXTRA_MEMS
    genvar ex, ey;
    generate
        if (CLUSTER_ID == 0) begin
            // Connect the routers output connections on the edges of the mesh
            // (north and south) to the corresponding endpoints (MCs)
            for (ex = 0; ex < CLUSTER_NX; ex = ex + 1) begin: EX_
                assign endpoint_chan_out[CLUSTER_NX*CLUSTER_NY+ex] =
                    router_chan_out[0][0][ex][NORTH];
                assign endpoint_chan_out[CLUSTER_NX*CLUSTER_NY+CLUSTER_NX+ex] =
                    router_chan_out[0][CLUSTER_NY-1][ex][SOUTH];
            end

            // Connect the routers output connections on the edges of the mesh
            // (west and east) to the corresponding endpoints (MCs)
            for (ey = 0; ey < CLUSTER_NY; ey = ey + 1) begin: EY_
                // NOTE: Chipset is now connected to endpoint
                // CLUSTER_NX * CLUSTER_NY + CLUSTER_NX * 2
                // NOTE: Must be kept in sync with CHIP_SET_ID in chip.sv.pyv
                assign endpoint_chan_out[CLUSTER_NX*CLUSTER_NY+CLUSTER_NX*2+ey] =
                    router_chan_out[0][ey][0][WEST];
                assign endpoint_chan_out[CLUSTER_NX*CLUSTER_NY+CLUSTER_NX*2+CLUSTER_NY+ey] =
                    router_chan_out[0][ey][CLUSTER_NX-1][EAST];
            end
        end
    endgenerate
`endif // PITON_EXTRA_MEMS
endmodule


module mesh_cluster_route_xyz
    import pronoc_pkg::*;
(
    input  multimesh_router_addr_t current_router_addr_i,
    input  multimesh_router_addr_t destination_router_addr_i,
    output logic [DSTPw-1:0] router_port_out
);

    // State type
    typedef enum logic [2:0] {
        MASS  = 3'b001,
        LESS  = 3'b010,
        EQUAL = 3'b100
    } state_t;

    state_t Dx, Dy, Dz;
    assign Dx = (destination_router_addr_i.x >  current_router_addr_i.x) ? MASS  :
                (destination_router_addr_i.x == current_router_addr_i.x) ? EQUAL :
                LESS;
    assign Dy = (destination_router_addr_i.y >  current_router_addr_i.y) ? MASS  :
                (destination_router_addr_i.y == current_router_addr_i.y) ? EQUAL :
                LESS;
    assign Dz = (destination_router_addr_i.z >  current_router_addr_i.z) ? MASS  :
                (destination_router_addr_i.z == current_router_addr_i.z) ? EQUAL :
                LESS;

    always_comb begin
        router_port_out = 0;
        if      (Dx == MASS) router_port_out = EAST;
        else if (Dx == LESS) router_port_out = WEST;
        else if (Dy == MASS) router_port_out = SOUTH;
        else if (Dy == LESS) router_port_out = NORTH;
        else if (Dz == MASS) router_port_out = UP;
        else if (Dz == LESS) router_port_out = DOWN;
        else                 router_port_out = LOCAL;
    end
endmodule


module multi_mesh_ovc_sel
    import pronoc_pkg::*;
#(
    // Input port number. Zero is LOCAL
    parameter SW_LOC = 0
)(
    input  multimesh_router_addr_t current_router_addr_i,
    input  multimesh_router_addr_t global_dst_i,
    input  logic up_dir_sel_i,
    input  logic [DSTPw-1:0] destport_out_i,
    input  logic [V-1:0] vc_num_i,
    output logic [V-1:0] ovc_sel_o
);

    logic [V-1:0] pre_ovc_sel;

    typedef enum logic [1:0] {
        VDIR_UP    = 2'b01,
        VDIR_DOWN  = 2'b10,
        VDIR_EQUAL = 2'b00
    } vdir_t;

    vdir_t vdir;
    assign vdir =
        (global_dst_i.c == current_router_addr_i.c) ? VDIR_EQUAL :
        (up_dir_sel_i) ? VDIR_UP : VDIR_DOWN;

    logic  dest_reached;
    assign dest_reached = global_dst_i.c == current_router_addr_i.c &&
                          global_dst_i.x == current_router_addr_i.x &&
                          global_dst_i.y == current_router_addr_i.y &&
                          global_dst_i.z == current_router_addr_i.z;

    always_comb begin
        // NOTE: The memory controllers on the interposer will inject packets
        // in the NoC using the N/S/W/E ports of the routers (localized on the
        // edges of the 2D-mesh). The packets are injected by default on Z-
        // and stay on this VC until taking an ascending VL or arriving to
        // destination. Conversely, the packets emitted on the (Z-) local port
        // on the interposer, will switch and stay on Z+.

        // Packets injected on local port
        if (SW_LOC == LOCAL) begin
            pre_ovc_sel = (vdir == VDIR_UP)   ? Z_PLUS_VC :
                          (vdir == VDIR_DOWN) ? Z_MIN_VC  :
                          Z_PLUS_VC;
        end
        // Z- to Z+ transition when going up
        else if (destport_out_i == UP && vc_num_i == Z_MIN_VC) begin
            pre_ovc_sel = Z_PLUS_VC;
        end
        else begin
            // Stay on the same VC
            pre_ovc_sel = vc_num_i;
        end
    end

    // If arrived, forward the packet to the local port (Z+)
    assign ovc_sel_o = (dest_reached) ? Z_PLUS_VC : pre_ovc_sel;
endmodule


module multi_mesh_ovc_list_per_ivc
    import pronoc_pkg::*;
#(
    parameter IVC_NUM = 0, // Input port VC number
    parameter P = 7 // Router IO number
)(
    input  logic [Cw-1:0] class_in,
    input  logic [P-1:0]  destport_one_hot,
    input  ctrl_chanel_t  ctrl_in[P-1:0],
    input  logic [V-1:0]  ovc_sel,
    output logic [V-1:0]  ovcs_out
);
    localparam Pw = $clog2(P);
    localparam [V-1:0] ALL_VCS = {V{1'b1}};

    logic [V-1:0] candidate_ovcs_message_class;
    logic [V-1:0] ovc_out_general;
    logic [V-1:0] ovc_presence;
    logic [V-1:0] ovc_list;
    logic [V-1:0] ovc_list_reverse;

    // Destination port decimal
    logic [Pw-1:0] destp;

    ovc_list ovcList(
        .class_in(class_in),
        .ovcs_out(candidate_ovcs_message_class)
    );

    always_comb begin
        destp = '0;
        for (int i = 0; i < P; i++) begin
            if (destport_one_hot[i])
                destp = i[Pw-1:0];
        end
    end

    assign ovc_out_general = ovc_sel;
    assign ovc_presence = (HETERO_VC > 0) ? ctrl_in[destp].hetero_ovc_presence : ALL_VCS;
    assign ovc_list = ovc_out_general & candidate_ovcs_message_class & ovc_presence;
    assign ovc_list_reverse = ~ovc_out_general & candidate_ovcs_message_class & ovc_presence;
    // If the listed VCs are not present in the connected router port, we swap
    // the listed VCs (for example, if the connected port has only one VC (Z-),
    // and ovc_out_general is Z+).
    assign ovcs_out = (ovc_list == {V{1'b0}}) ? ovc_list_reverse : ovc_list;
endmodule


module icr_modifier
    import pronoc_pkg::*;
#(
    parameter logic ICR_EN = 1
`ifndef DYNAMIC_CLUSTER_INIT
    , parameter CLUSTER_ID = 0,
    parameter CLUSTER_RID = 0
`endif
)(
`ifdef DYNAMIC_CLUSTER_INIT
    input  cluster_hid_entry_t     address_table[DYN_ICRT_MAX_ENTRY],
    input  multimesh_router_addr_t local_cluster_endp_addr_down_dir,
    input  logic [CLUSTER_IDw-1:0] current_cluster_id,
`endif
    input  smartflit_chanel_t      chan_in,
    input  multimesh_router_addr_t current_r_addr,
    output smartflit_chanel_t      chan_out
);

    hdr_flit_t hdr_flit_i;
    // Global / Local / ICRT Destination fields
    multimesh_router_addr_t global_dst, local_dst, local_dst_icr;
    // Local destination port, computed to reach the local destination
    logic [DSTPw-1:0] ldestport_o;
    // Final destination port, accounts for ascending / descending vertically
    // and FBITS
    logic [DSTPw-1:0] fdestport_o;
    // Take the FBITS into account (encoded with ProNoC's port)
    logic [DSTPw-1:0] fbits_encoded;
    // Depth-First Multi-mesh routing fields
    logic local_routing_en;
    logic next_chip_vdir;
    logic curr_next_chip_vdir;
    logic up_dir_sel;

    header_flit_info #(
        .DATA_w(0)
    ) extractor(
        .flit(chan_in.flit_chanel.flit),
        .hdr_flit(hdr_flit_i),
        .data_o(/* unused */)
    );

    // Unpacket all the fields from the destination address
    assign {local_routing_en,
            curr_next_chip_vdir,
            fbits_encoded,
            local_dst,
            global_dst} = hdr_flit_i.dest_e_addr[DAw-1:0];

    // Next vertical direction is either the one from the Inter-Chiplet Routing
    // Table, or the previously computed one (local routing)
    assign next_chip_vdir = (ICR_EN && !local_routing_en) ?
                            up_dir_sel : curr_next_chip_vdir;

`ifdef MULTI_MESH_ASSERTIONS
    // synthesis translate_off
    assert property (@(posedge chan_in.flit_chanel.flit.hdr_flag)
            local_routing_en == 1'b0 |-> ICR_EN == 1)
        else
            $fatal("A flit was freshly injected in the NoC on a non-ICR port");
    // synthesis translate_on
`endif // MULTI_MESH_ASSERTIONS

    generate
    if (ICR_EN) begin
        global_id_to_local_cluster_endp #(
`ifndef DYNAMIC_CLUSTER_INIT
            .CLUSTER_ID(CLUSTER_ID),
            .RID(CLUSTER_RID)
`endif
        ) global_to_local(
`ifdef DYNAMIC_CLUSTER_INIT
            .address_table(address_table),
            .local_cluster_endp_addr_down_dir(local_cluster_endp_addr_down_dir),
            .current_cluster_id(current_cluster_id),
`endif
            .dest_address(global_dst),
            .local_cluster_endp_addr(local_dst_icr),
            .up_dir_sel(up_dir_sel)
        );

        // Local routing decision
        mesh_cluster_route_xyz dor(
            .current_router_addr_i(current_r_addr),
            .destination_router_addr_i((local_routing_en) ?
                                       local_dst : local_dst_icr),
            .router_port_out(ldestport_o)
        );
    end else begin
        // Retrieve previously computed local destination
        assign local_dst_icr = local_dst;

        // Local routing decision
        mesh_cluster_route_xyz dor(
            .current_router_addr_i(current_r_addr),
            .destination_router_addr_i(local_dst_icr),
            .router_port_out(ldestport_o)
        );
    end
    endgenerate

    always_comb begin
        chan_out = chan_in;
        // Base value for the final destination port
        fdestport_o = '0;
        // Header flit
        if (chan_in.flit_chanel.flit.hdr_flag == 1'b1) begin
            // Override the endpoint destination address of the header
            // with the new local routing data
            if (ICR_EN && !local_routing_en)
                chan_out.flit_chanel.flit[E_DST_MSB:E_DST_LSB] = {
                    1'b1, // enable local routing
                    next_chip_vdir,
                    fbits_encoded,
                    local_dst_icr,
                    global_dst
                };

            // By default, the next hop is the computed DOR decision
            fdestport_o = ldestport_o;

            // If arrived to a boundary router which is not the global
            // destination, route vertically
            if (ldestport_o == LOCAL && local_dst_icr.c != global_dst.c) begin
                fdestport_o = (next_chip_vdir) ? UP : DOWN;
                // Set to 0 the local_routing field
                chan_out.flit_chanel.flit[E_DST_MSB:E_DST_MSB] = 1'b0;
            end

            // When arrived to destination, route to the FBITS if present,
            // otherwise route to the local port
            chan_out.flit_chanel.flit[DST_P_MSB:DST_P_LSB] =
                (fdestport_o == LOCAL && fbits_encoded != LOCAL) ?
                    fbits_encoded : fdestport_o;
        end
    end
endmodule


module depth_first_router
    import pronoc_pkg::*;
#(
    parameter logic LOCAL_ICR_EN = 1,
    parameter logic UP_ICR_EN    = 1,
    parameter logic DOWN_ICR_EN  = 1,
    parameter logic NORTH_ICR_EN = 1,
    parameter logic SOUTH_ICR_EN = 1,
    parameter logic WEST_ICR_EN  = 1,
    parameter logic EAST_ICR_EN  = 1,

    parameter ROUTER_ID = 0,
`ifndef DYNAMIC_CLUSTER_INIT
    parameter CLUSTER_ID  = 0,
    parameter CLUSTER_RID = 0,
`endif
    parameter P = 7
)(
    input  logic clk,
    input  logic reset,
`ifdef DYNAMIC_CLUSTER_INIT
    input  program_port_t program_port,
`endif
    input  router_config_t router_config_in,
    input  smartflit_chanel_t chan_in [P-1:0],
    output smartflit_chanel_t chan_out[P-1:0],
    output router_event_t router_event[P-1:0]
);

    localparam [P-1:0] ICR_PORT_EN =
        (LOCAL_ICR_EN << LOCAL) +
        (UP_ICR_EN    << UP)    +
        (DOWN_ICR_EN  << DOWN)  +
        (SOUTH_ICR_EN << SOUTH) +
        (NORTH_ICR_EN << NORTH) +
        (WEST_ICR_EN  << WEST)  +
        (EAST_ICR_EN  << EAST);

    smartflit_chanel_t chan_in_wire[P-1:0];

    // Instanciate the regular ProNoC router
    router_top #(
        .ROUTER_ID(ROUTER_ID),
        .P(P)
    ) the_router (
        .router_config_in(router_config_in),
        .chan_in(chan_in_wire),
        .chan_out(chan_out),
        .router_event(router_event),
        .clk(clk),
        .reset(reset)
    );

`ifdef DYNAMIC_CLUSTER_INIT
    cluster_hid_entry_t address_table[DYN_ICRT_MAX_ENTRY];
    multimesh_router_addr_t local_cluster_endp_addr_down_dir;
    logic [CLUSTER_IDw-1:0] current_cluster_id;

    dynamic_hids_per_router dynamic_hids(
        .local_cluster_endp_addr_down_dir(local_cluster_endp_addr_down_dir),
        .address_table(address_table),
        .current_cluster_id(current_cluster_id),
        .program_port(program_port),
        .reset(reset),
        .clk(clk)
    );
`endif

    genvar i;
    generate
    for(i = 0; i < P; i++) begin : P_
        icr_modifier #(
`ifndef DYNAMIC_CLUSTER_INIT
            .CLUSTER_ID(CLUSTER_ID),
            .CLUSTER_RID(CLUSTER_RID),
`endif
            .ICR_EN(ICR_PORT_EN[i])
        ) icr(
`ifdef DYNAMIC_CLUSTER_INIT
            .address_table(address_table),
            .local_cluster_endp_addr_down_dir(local_cluster_endp_addr_down_dir),
            .current_cluster_id(current_cluster_id),
`endif
            .current_r_addr(router_config_in.router_addr),
            .chan_in(chan_in[i]),
            .chan_out(chan_in_wire[i])
        );
    end//P
    endgenerate
endmodule
