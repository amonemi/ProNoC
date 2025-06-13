`include "pronoc_def.v"
/**********************************************************************
**    File: tree_noc_top.v
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
**    Description:
**    
**    Tree Topology NoC with Multiple Layers
**
**    This module implements a Tree Network-on-Chip (NoC) topology with 
**    a hierarchical structure consisting of multiple layers. The network 
**    has a single root router with *k* ports, each of which connects to 
**    a child router. These child routers (leaves) have *k+1* ports, 
**    enabling them to connect to their child routers or endpoints. 
**    The tree structure can have *l* layers, where each layer contains 
**    routers that further branch out to create a scalable and efficient network.
**
**    Key Features:
**    - A single root router with *k* ports.
**    - Child routers (leaves) each have *k+1* ports.
**    - The network can have *l* layers, with each layer connected to the 
**      previous layer in a hierarchical manner.
**    - Scalability through hierarchical routing, allowing for efficient 
**      communication in large systems.
**    - Suitable for systems where hierarchical control and scalability are essential.
**
**********************************************************************/

module  tree_noc_top (
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
    
    //all routers port 
    smartflit_chanel_t    router_chan_in   [NR-1 :0][MAX_P-1 : 0];
    smartflit_chanel_t    router_chan_out  [NR-1 :0][MAX_P-1 : 0]; 
    
    function integer addrencode;
        input integer pos,k,n,kw;
        integer pow,i,tmp;begin
            addrencode=0;
            pow=1;
            for (i = 0; i <n; i=i+1 ) begin 
                tmp=(pos/pow);
                tmp=tmp%k;
                tmp=tmp<<i*kw;
                addrencode=addrencode | tmp;
                pow=pow * k;
            end
        end   
    endfunction 
    
    localparam
        PV = V * MAX_P,
        PFw = MAX_P * Fw,
        CONG_ALw = CONGw * MAX_P,
        PLKw = MAX_P * LKw,
        PLw = MAX_P * Lw,
        PRAw = MAX_P * RAw; // {layer , Pos} width   
    
    wire [LKw-1 : 0] current_pos_addr [NR-1 :0];
    wire [Lw-1  : 0] current_layer_addr [NR-1 :0];   
    wire [RAw-1 : 0] current_r_addr [NR-1 : 0];
    router_config_t router_config_in [NR-1 :0];
    
    /****************
    *    add roots
    *****************/
    localparam [Lw-1 : 0] ROOT_L = L-1; 
    localparam ROOT_ID = 0;
    localparam BOUND=(MAX_P > K)? K : MAX_P;
    
    assign current_layer_addr [ROOT_ID] = ROOT_L;
    assign current_pos_addr [ROOT_ID] = {LKw{1'b0}};
    assign current_r_addr[ROOT_ID] = {current_layer_addr [ROOT_ID],current_pos_addr[ROOT_ID]};
    assign router_config_in[ROOT_ID].router_id = ROOT_ID [NRw-1:0];
    assign router_config_in[ROOT_ID].router_addr = {current_layer_addr [ROOT_ID],current_pos_addr[ROOT_ID]};
    router_top # (
        .ROUTER_ID(ROOT_ID),
        .P(K)
    ) root_router (
        .router_config_in(router_config_in[ROOT_ID]),
        .chan_in         (router_chan_in [ROOT_ID][BOUND-1:0]), 
        .chan_out        (router_chan_out[ROOT_ID][BOUND-1:0]), 
        .router_event    (router_event[ROOT_ID][BOUND-1 : 0]),
        .clk             (clk), 
        .reset           (reset)
    );
    
    genvar pos,level;
    
    /****************
    *    add leaves
    *****************/
    generate
    for( level=1; level<L; level=level+1) begin :level_lp
        localparam NPOS1 = powi(K,level); // number of routers in this level
        localparam NRATTOP1 = sum_powi ( K,level); // number of routers at top levels : from root until last level
        for( pos=0; pos<NPOS1; pos=pos+1) begin : pos_lp 
            localparam RID = NRATTOP1+pos;
            assign router_config_in[RID].router_id = RID[NRw-1 : 0];
            router_top # (
                .ROUTER_ID(RID),
                .P(K+1)// leaves have K+1 port number 
            ) the_router (
                .router_config_in(router_config_in[RID]),
                .chan_in (router_chan_in [RID]), 
                .chan_out (router_chan_out[RID]), 
                .router_event (router_event[RID]),
                .clk (clk), 
                .reset (reset)
            );  
        end//pos
    end // level
    
    //connect all up connections
    for (level = 1; level<L; level=level+1) begin : level_c
        localparam  NPOS = powi(K,level); // number of routers in this level
        localparam L1 = L-1-level;
        localparam level2= level - 1;
        localparam L2 = L-1-level2;
        for ( pos = 0; pos < NPOS; pos=pos+1 ) begin : pos_c
            localparam ID1 = sum_powi ( K,level) + pos;
            localparam FATTREE_EQ_POS1 = pos*(K**L1);
            localparam ADR_CODE1=addrencode(FATTREE_EQ_POS1,K,L,Kw);
            localparam POS2 = pos /K ;
            localparam ID2 = sum_powi ( K,level-1) + (pos/K);
            localparam PORT2= pos % K;  
            localparam FATTREE_EQ_POS2 = POS2*(K**L2);
            localparam ADR_CODE2=addrencode(FATTREE_EQ_POS2,K,L,Kw);
            // node_connection('Router[id1][k] to router[id2][pos%k]; 
            if(IS_TREE) begin
            assign  router_chan_in [ID1][K] = router_chan_out [ID2][PORT2];
            assign  router_chan_in [ID2][PORT2] = router_chan_out [ID1][K];  
            end
            assign current_layer_addr [ID1] = L1[Lw-1 : 0];
            assign current_pos_addr [ID1] = ADR_CODE1 [LKw-1 : 0];
            assign router_config_in[ID1].router_addr =  {current_layer_addr [ID1],current_pos_addr[ID1]};
        end// pos
    end //level
    
    // connect endpoints 
    for ( pos = 0; pos <  NE; pos=pos+1 ) begin : endpoints
        //  node_connection T[pos] R[rid][pos %k];
        localparam RID= sum_powi(K,L-1)+(pos/K);
        localparam RPORT = pos%K;
        //$dotfile=$dotfile.node_connection('T',$i,undef,undef,'R',$r,undef,$i%($k));
        assign router_chan_in [RID][RPORT] =    chan_in_all [pos];
        assign chan_out_all [pos] = router_chan_out [RID][RPORT];
    end
    endgenerate
endmodule