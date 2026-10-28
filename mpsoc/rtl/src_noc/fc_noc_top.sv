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

    genvar r,p,le;
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
                for (p=0; p<MAX_P; p++) begin: P_
                    if(p<r) begin
                        assign router_chan_in[r][p] = router_chan_out[p][r-1];
                    end else begin
                        assign router_chan_in[r][p] = router_chan_out[p+1][r];
                    end
                end

                //endpoint connections
                for (le=0;le<NE_PER_R_FC;le++) begin: L_
                    localparam EID = RID*NE_PER_R_FC+le;
                    localparam LOCALP = le + NR-1;
                    always_comb begin
                        endp_addr[EID] = '0;
                        endp_addr[EID].l = Lw_FC'(le);
                        endp_addr[EID].r = RAw_FC'(RID);
                    end
                    assign router_chan_in [r][LOCALP] = chan_in_all [EID];
                    assign chan_out_all [EID] = router_chan_out [r][LOCALP];
                    assign router_config_in[RID].endp_addrs[(le+1)*EAw -1 :  le*EAw] = EAw'(endp_addr[EID]);
                    assign router_config_in[RID].endp_ids[(le+1)*NEw -1 :  le*NEw] = NEw'(EID[NEw-1:0]);
                end
    end//R
    endgenerate
endmodule

