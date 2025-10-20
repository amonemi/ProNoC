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

module mesh_3d_noc_top (
    reset,
    clk,
    chan_in_all,
    chan_out_all,
    router_event
);
    import pronoc_pkg::*;
    input   clk,reset;
    //Endpoints ports 
    input   smartflit_chanel_t chan_in_all  [NE-1 : 0];
    output  smartflit_chanel_t chan_out_all [NE-1 : 0];
    //Events
    output  router_event_t  router_event [NR-1 : 0][MAX_P-1 : 0];
    
    //indididual routers interconnect ports
    smartflit_chanel_t router_chan_in   [NZ-1:0][NY-1:0][NX-1:0][MAX_P-1:0];
    smartflit_chanel_t router_chan_out  [NZ-1:0][NY-1:0][NX-1:0][MAX_P-1:0];
    //Unused Input channels are connected to ground
    smartflit_chanel_t is_grounded;
    assign  is_grounded= {SMARTFLIT_CHANEL_w{1'b0}};
    
    mesh3d_router_addr_t current_r_addr [NR-1:0];
    mesh3d_endp_addr_t endp_addr [NE-1:0];
    router_config_t router_config_in [NR-1 : 0];
    
    genvar x,y,z;
    generate
    for (z=0; z<NZ; z=z+1) begin: Z_
        for (y=0; y<NY; y=y+1) begin: Y_
            for (x=0; x<NX; x=x+1) begin: X_
                localparam 
                    RID =z*(NX * NY) + (y * NX) + x;
                assign current_r_addr[RID ]='{x:x,y:y,z:z};
                router_top #(
                    .ROUTER_ID(RID),
                    .P(MAX_P)
                ) the_router (
                    .router_config_in(router_config_in[RID]),
                    .chan_in(router_chan_in [z][y][x]),
                    .chan_out(router_chan_out[z][y][x]),
                    .router_event(router_event[RID] ),
                    .clk(clk),
                    .reset(reset)
                );
                assign router_config_in[RID].router_addr=current_r_addr[RID];
                assign router_config_in[RID].router_id=RID;
                // **Mesh Interconnect Logic**
                assign router_chan_in[z][y][x][EAST]  = (x < NX-1) ?
                    router_chan_out[z][y][x+1][WEST]  : is_grounded;
                assign router_chan_in[z][y][x][NORTH] = (y > 0   ) ?
                    router_chan_out[z][y-1][x][SOUTH] : is_grounded;
                assign router_chan_in[z][y][x][WEST]  =  (x > 0  ) ?
                    router_chan_out[z][y][x-1][EAST]  : is_grounded;
                assign router_chan_in[z][y][x][SOUTH] = (y < NY-1) ?
                    router_chan_out[z][y+1][x][NORTH] : is_grounded;
                assign router_chan_in[z][y][x][UP]    = (z < NZ-1) ?
                    router_chan_out[z+1][y][x][DOWN]  : is_grounded;
                assign router_chan_in[z][y][x][DOWN]  = (z > 0   ) ?
                    router_chan_out[z-1][y][x][UP]    : is_grounded;
                //endpoint connections
                for (l=0;l<NL;l++) begin 
                    localparam EID = RID*NL+l;
                    localparam LOCALP = (l==0) ? l : l + R2R_CHANELS_REGULAR; // first local port is connected to router port 0. The rest are connected at the end  
                    assign endp_addr[EID]='{x:x,y:y,z:z,l:l};
                    assign router_config_in[RID].endp_addrs=current_r_addr[RID];
                    assign router_chan_in [z][y][x][LOCALP] = endpoint_chan_in [EID];
                    assign endpoint_chan_out [EID] = router_chan_out [z][y][x][LOCALP];
                    assign router_config_in[RID].endp_addrs[(l+1)*EAw -1 :  l*EAw] = EAw'(endp_addr[EID]);
                    assign router_config_in[RID].endp_ids[(l+1)*NEw -1 :  l*NEw] = NEw'(EID);
                end
            end//X
        end//Y
    end//Z
    endgenerate
endmodule



module mesh_3d_route_xyz (
    current_router_addr_i,
    destination_endp_addr_i,
    router_port_out
);
    import pronoc_pkg::*;
    input mesh_3d_router_addr_t current_router_addr_i;
    input mesh_3d_endp_addr_t   destination_endp_addr_i;
    output logic [DSTPw-1 : 0] router_port_out;
    
    // Define state type using typedef
    typedef enum logic [2:0] {
        MASS  = 3'b001,
        LESS  = 3'b010,
        EQUAL = 3'b100
    } state_t;
    state_t Dx,Dy,Dz,Dc;
    assign  Dx = (destination_endp_addr_i.x > current_router_addr_i.x)? MASS:(destination_endp_addr_i.x == current_router_addr_i.x)?EQUAL : LESS;
    assign  Dy = (destination_endp_addr_i.y > current_router_addr_i.y)? MASS:(destination_endp_addr_i.y == current_router_addr_i.y)?EQUAL : LESS;
    assign  Dz = (destination_endp_addr_i.z > current_router_addr_i.z)? MASS:(destination_endp_addr_i.z == current_router_addr_i.z)?EQUAL : LESS;
    assign  Dc = (destination_endp_addr_i.c > current_router_addr_i.c)? MASS:(destination_endp_addr_i.c == current_router_addr_i.c)?EQUAL : LESS;
    always_comb begin
        router_port_out=0;
        if(Dx==MASS) router_port_out = EAST;
        else if(Dx==LESS) router_port_out =WEST;
        else if(Dy==MASS) router_port_out =SOUTH;
        else if(Dy==LESS) router_port_out =NORTH;
        else if(Dz==MASS) router_port_out =UP;
        else if(Dz==LESS) router_port_out =DOWN;
        else if(Dc==MASS) router_port_out =UP;
        else if(Dc==LESS) router_port_out =DOWN;
        else router_port_out=(destination_endp_addr_i.l==0) ? LOCAL: DOWN + destination_endp_addr_i.l;
    end
endmodule

