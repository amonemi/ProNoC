`include "pronoc_def.v"
/**********************************************************************
**    File:  noc_top.sv
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
**     Description:
**     This is the top-level NoC (Network-on-Chip) module. It generates various network topologies, 
**     including mesh, torus, ring, line, fattree, bintree or a user-defined custom topology,
**     by interconnecting routers.
**
**************************************************************/

module  noc_top (
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
    
    generate 
    if (IS_MESH | IS_FMESH | IS_TORUS | IS_RING | IS_LINE) begin : tori_noc 
        mesh_torus_noc_top noc_top (
            .reset         (reset        ), 
            .clk           (clk          ), 
            .chan_in_all   (chan_in_all  ), 
            .chan_out_all  (chan_out_all ),
            .router_event  (router_event )
        );
    end else if (IS_FATTREE) begin : fat_
        fattree_noc_top noc_top (
            .reset         (reset        ), 
            .clk           (clk          ), 
            .chan_in_all   (chan_in_all  ), 
            .chan_out_all  (chan_out_all ),
            .router_event  (router_event )
        );
    end else if (IS_TREE) begin : tree_
        tree_noc_top  noc_top ( 
            .reset         (reset        ), 
            .clk           (clk          ), 
            .chan_in_all   (chan_in_all  ), 
            .chan_out_all  (chan_out_all ),
            .router_event  (router_event )
        );
    end else if (IS_STAR) begin : star_
        star_noc_top  noc_top ( 
                .reset         (reset        ), 
                .clk           (clk          ), 
                .chan_in_all   (chan_in_all  ), 
                .chan_out_all  (chan_out_all ),
                .router_event  (router_event )
        );
    end else if (IS_MULTI_MESH) begin : multimesh
    /*
        multi_mesh noc_top ( 
                .reset         (reset        ), 
                .clk           (clk          ), 
                .chan_in_all   (chan_in_all  ), 
                .chan_out_all  (chan_out_all ),
                .router_event  (router_event )
        );
    */
    end else begin :custom_

        custom_noc_top noc_top ( 
            .reset         (reset        ), 
            .clk           (clk          ), 
            .chan_in_all   (chan_in_all  ), 
            .chan_out_all  (chan_out_all ),
            .router_event  (router_event )
        );
    end
    endgenerate
endmodule

/**************************
 * noc_top_v:
 * This module instantiates noc_top and
 * serves as the top module in Verilator simulation.
 * It resolves the Verilator error caused by
 * noc_top being used in another module,
 * preventing it from being defined as the top module.
 **************************/ 
module  noc_top_v  (
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
    
    noc_top  the_top(
        .reset(reset),
        .clk(clk),
        .chan_in_all(chan_in_all),
        .chan_out_all(chan_out_all),
        .router_event  (router_event)
    );
endmodule
