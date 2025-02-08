`include "pronoc_def.v"
/**********************************************************************
**    File:  fattree_noc_top.v
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
**    Fat-Tree NoC Top Module
**
**    This module implements a hierarchical indirect Fat-Tree 
**    Network-on-Chip (NoC) topology. The network is organized 
**    into multiple levels, with each level containing k^(l-1) 
**    routers, where *k* is the radix and *l* is the current level.
**
**    Key Features:
**    - Each router connects to *k* child routers in the level below.
**    - Each parent router is replicated *k* times to ensure 
**      balanced connectivity.
**    - Most routers have 2K ports, except for the top-level routers, 
**      which have only K ports due to reduced fan-out requirements.
**
**************************************************************/

module  fattree_noc_top #(
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
    
    //all routers port 
    smartflit_chanel_t    router_chan_in   [NR-1 :0][MAX_P-1 : 0];
    smartflit_chanel_t    router_chan_out  [NR-1 :0][MAX_P-1 : 0];
    
        localparam
            PV = V * MAX_P,
            PFw = MAX_P * Fw,       
            NRL= NE/K, //number of router in  each layer
            CONG_ALw = CONGw * MAX_P,
            PLKw = MAX_P * LKw,
            PLw = MAX_P * Lw,       
            PRAw = MAX_P * RAw; // {layer , Pos} width
        
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
    
    wire [LKw-1 : 0] current_pos_addr [NR-1 :0];
    wire [Lw-1  : 0] current_layer_addr [NR-1 :0];
    wire [RAw-1 : 0] current_r_addr [NR-1 : 0];
    
    /****************
    *    add roots
    *****************/
    genvar pos,level,port;
    generate 
    for( pos=0; pos<NRL; pos=pos+1) begin : root 
        localparam RID = pos;
        router_top # (
            .NOC_ID(NOC_ID),
            .ROUTER_ID(RID),
            .P(K)
        ) the_router (
            .current_r_id    (RID),
            .current_r_addr  (current_r_addr [RID]), 
            .chan_in         (router_chan_in [RID][K-1 : 0]), 
            .chan_out        (router_chan_out[RID][K-1 : 0]), 
            .router_event    (router_event[RID][K-1 : 0]),
            .clk             (clk), 
            .reset           (reset )
        );  
    end
    
    /****************
    *    add leaves
    *****************/
    for( level=1; level<L; level=level+1) begin :level_lp
        for( pos=0; pos<NRL; pos=pos+1) begin : pos_lp 
            
            localparam RID = NRL*level+pos;
            router_top # (
                .NOC_ID(NOC_ID),
                .ROUTER_ID(RID),
                .P(2*K)
            ) the_router (
                .current_r_id    (RID),
                .current_r_addr  (current_r_addr [RID]),
                .chan_in         (router_chan_in [RID]),
                .chan_out        (router_chan_out[RID]),
                .router_event    (router_event[RID]),
                .clk             (clk            ),
                .reset           (reset          )
            );
            
        end
    end
    
    //connect all down input chanels
    localparam NPOS = powi( K, L-1);
    localparam CHAN_PER_DIRECTION = (K * powi( L , L-1 )); //up or down
    localparam CHAN_PER_LEVEL = 2*(K * powi( K , L-1 )); //up+down
    for (level = 0; level<L-1; level=level+1) begin : level_c
        /* verilator lint_off WIDTH */
        localparam [Lw-1 : 0] LEAVE_L = L-1-level;
        /* verilator lint_on WIDTH */    
        //input chanel are numbered interleavely, the interleaev depends on level
        localparam ROUTERS_PER_NEIGHBORHOOD = powi(K,L-1-(level)); 
        localparam ROUTERS_PER_BRANCH = powi(K,L-1-(level+1)); 
        localparam LEVEL_OFFSET = ROUTERS_PER_NEIGHBORHOOD*K;
        for ( pos = 0; pos < NPOS; pos=pos+1 ) begin : pos_c
            localparam ADRRENCODED=addrencode(pos,K,L,Kw);
            localparam NEIGHBORHOOD = (pos/ROUTERS_PER_NEIGHBORHOOD);
            localparam NEIGHBORHOOD_POS = pos % ROUTERS_PER_NEIGHBORHOOD;
            for ( port = 0; port < K; port=port+1 ) begin : port_c
                localparam LINK = 
                    ((level+1)*CHAN_PER_LEVEL - CHAN_PER_DIRECTION)  //which levellevel
                    +NEIGHBORHOOD* LEVEL_OFFSET   //region in level
                    +port*ROUTERS_PER_BRANCH*K //sub region in region
                    +(NEIGHBORHOOD_POS)%ROUTERS_PER_BRANCH*K //router in subregion
                    +(NEIGHBORHOOD_POS)/ROUTERS_PER_BRANCH; //port on router
                localparam L2= (LINK+CHAN_PER_DIRECTION)/CHAN_PER_LEVEL;
                localparam POS2 = ((LINK+CHAN_PER_DIRECTION) % CHAN_PER_LEVEL)/K;
                localparam PORT2= (((LINK+CHAN_PER_DIRECTION) % CHAN_PER_LEVEL)  %K)+K;
                localparam ID1 =NRL*level+pos;
                localparam ID2 =NRL*L2 + POS2;
                localparam POS_ADR_CODE2= addrencode(POS2,K,L,Kw);
                localparam POS_ADR_CODE1= addrencode(pos,K,L,Kw);
               // $dotfile=$dotfile.node_connection('R',$id1,undef,$port,'R',$connect_id,undef,$connect_port);
                assign  router_chan_in [ID1][port ] = router_chan_out [ID2][PORT2];
                assign  router_chan_in [ID2][PORT2] = router_chan_out [ID1][port ];
                assign current_layer_addr [ID1] = LEAVE_L;
                assign current_pos_addr [ID1] = ADRRENCODED[LKw-1 :0];
                assign current_r_addr [ID1] = {current_layer_addr [ID1],current_pos_addr[ID1]};
                if(level==L-2)begin 
                    assign current_layer_addr [ID2] ={Lw{1'b0}};
                    assign current_pos_addr [ID2] = POS_ADR_CODE2[LKw-1 :0];
                    assign current_r_addr [ID2] = {current_layer_addr [ID2],current_pos_addr[ID2]};
                end
            end
        end
    end 
    
    for ( pos = 0; pos <  NE; pos=pos+1 ) begin : endpoints
        localparam RID= NRL*(L-1)+(pos/K);
        localparam RPORT = pos%K;
        //$dotfile=$dotfile.node_connection('T',$i,undef,undef,'R',$r,undef,$i%($k));
        assign router_chan_in [RID][RPORT] =    chan_in_all [pos];
        assign chan_out_all [pos] = router_chan_out [RID][RPORT];
    end
    endgenerate
endmodule