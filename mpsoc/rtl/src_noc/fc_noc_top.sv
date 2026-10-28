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
**    A fully-connected noc topology
**
***************************************/

module fc_noc_top (
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
    smartflit_chanel_t router_chan_in   [NR-1 : 0][MAX_P-1:0];
    smartflit_chanel_t router_chan_out  [NR-1 : 0][MAX_P-1:0];

    fc_endp_addr_t endp_addr [NE-1:0];
    router_config_t router_config_in [NR-1 : 0];

    genvar r,p;
    generate
    for (r=0; r<NR; r++) begin: R_
                localparam
                    RID =r;
                router_top #(
                    .ROUTER_ID(RID),
                    .P(MAX_P)
                ) the_router (
                    .router_config_in(router_config_in[r]),
                    .chan_in(router_chan_in [r]),
                    .chan_out(router_chan_out[r]),
                    .router_event(router_event[r] ),
                    .clk(clk),
                    .reset(reset)
                );
                assign router_config_in[RID].router_addr=RID;
                assign router_config_in[RID].router_id=RID;
                for (p=0; p<MAX_P; p++) begin P_
                    assign router_chan_in[r][p] = (p<r)?
                        router_chan_out[p][r-1]:
                        router_chan_out[p+1][r];
                end

                //endpoint connections
                for (l=0;l<NE_PER_R_FC;l++) begin L_
                    localparam EID = RID*NE_PER_R_FC+l;
                    localparam LOCALP = l + NR-1;
                    assign endp_addr[EID]='{R:r,L:l};
                    assign router_chan_in [r][LOCALP] = chan_in_all [EID];
                    assign chan_out_all [EID] = router_chan_out [r][LOCALP];
                    assign router_config_in[RID].endp_addrs[(l+1)*EAw -1 :  l*EAw] = EAw'(endp_addr[EID]);
                    assign router_config_in[RID].endp_ids[(l+1)*NEw -1 :  l*NEw] = NEw'(EID);
                end
    end//R
    endgenerate
endmodule



module mesh_3d_route_xyz (
    current_router_addr_i,
    dest_router_addr_i,
    destport
);
    import pronoc_pkg::*;
    input regular_topo_router_addr_t current_router_addr_i;
    input regular_topo_router_addr_t dest_router_addr_i;
    output logic [DSTPw-1 : 0] destport;
    
    // Define state type using typedef
    typedef enum logic [2:0] {
        MASS  = 3'b001,
        LESS  = 3'b010,
        EQUAL = 3'b100
    } state_t;
    state_t Dx,Dy,Dz;
    assign  Dx = (dest_router_addr_i.x > current_router_addr_i.x)? MASS:(dest_router_addr_i.x == current_router_addr_i.x)?EQUAL : LESS;
    assign  Dy = (dest_router_addr_i.y > current_router_addr_i.y)? MASS:(dest_router_addr_i.y == current_router_addr_i.y)?EQUAL : LESS;
    assign  Dz = (dest_router_addr_i.z > current_router_addr_i.z)? MASS:(dest_router_addr_i.z == current_router_addr_i.z)?EQUAL : LESS;
    
    always_comb begin
        destport=0;
        if(Dx==MASS) destport =DSTPw'(EAST);
        else if(Dx==LESS) destport =DSTPw'(WEST);
        else if(Dy==MASS) destport =DSTPw'(SOUTH);
        else if(Dy==LESS) destport =DSTPw'(NORTH);
        else if(Dz==MASS) destport =DSTPw'(UP);
        else if(Dz==LESS) destport =DSTPw'(DOWN);
        else destport =  DSTPw'(LOCAL);
    end
endmodule

