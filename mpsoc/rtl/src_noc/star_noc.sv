`include "pronoc_def.v"
/**********************************************************************
**    File:  star_noc_top.v
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
**    
**    Star Topology NoC
**
**    This module implements a Star Network-on-Chip (NoC) topology.
**    In this design, a single central router connects directly to 
**    multiple endpoints through its ports. All communication between 
**    endpoints is routed through this central hub, enabling simple 
**    and efficient data transfer in small-scale networks.
**
**    Key Features:
**    - Single central router with multiple ports.
**    - All ports are directly connected to endpoints.
**    - Simplified routing with minimal latency for star configurations.
**
**********************************************************************/

module  star_noc_top #(
    parameter NOC_ID=0
) (
        reset,
        clk,    
        chan_in_all,
        chan_out_all,
        router_event
    );
    
    `NOC_CONF
    
    input   clk,reset;
    //Endpoints ports 
    input   smartflit_chanel_t chan_in_all  [NE-1 : 0];
    output  smartflit_chanel_t chan_out_all [NE-1 : 0];
    
    //Events
    output  router_event_t  router_event [NR-1 : 0][MAX_P-1 : 0];
    
    router_top # (
        .NOC_ID(NOC_ID),
        .ROUTER_ID(0),
        .P(NE)
    ) the_router (
        .current_r_id    (0),
        .current_r_addr  (1'b0), 
        .chan_in         (chan_in_all), 
        .chan_out        (chan_out_all), 
        .router_event    (router_event[0]),
        .clk             (clk            ), 
        .reset           (reset          )
    );
    
endmodule

module star_conventional_routing #(
    parameter NE = 8
)(
    dest_e_addr,
    destport
);
    
    function integer log2;
        input integer number; begin
            log2=(number <=1) ? 1: 0;
            while(2**log2<number) begin
                log2=log2+1;
            end
        end
    endfunction // log2 
    
    localparam EAw = log2(NE);      
    
    input   [EAw-1   :0] dest_e_addr;
    output  [EAw-1   :0] destport;
    // the destination endpoint address & connection port number are the same in star topology
    assign destport = dest_e_addr;
endmodule
