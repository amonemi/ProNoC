// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

/**********************************************************************
**    File:  mesh_torus_noc.v
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
**    the NoC top module. It generate one of the mesh, torus, ring, or line  topologies by 
**    connecting routers  
**
**************************************************************/

`define START_LOC(port_num,width)       (width*(port_num+1)-1)
`define END_LOC(port_num,width)            (width*port_num)
`define router_id(x,y)                         ((y * NX) +    x)
`define endp_id(x,y,l)                         ((y * NX) +    x) * NL + l 
`define SELECT_WIRE(x,y,port,width)    `router_id(x,y)] [`START_LOC(port,width) : `END_LOC(port,width )


module mesh_torus_noc #(
    parameter V = 2, // Number of Virtual channel per port 
    parameter B = 4, // buffer space :flit per VC 
    parameter T1   = 2, // The number of node in x axis of mesh or torus. For ring topology is total number of nodes in ring.
    parameter T2   = 2, // The number of node in y axis of mesh or torus. It is not used in ring topology.
    parameter T3  = 1, // Number of local ports connected to one router
    parameter C = 4, // number of message class 
    parameter Fpay = 32, // packet payload width
    parameter MUX_TYPE =    "BINARY",    //"ONE_HOT" or "BINARY"
    parameter VC_REALLOCATION_TYPE =    "NONATOMIC",// "ATOMIC" , "NONATOMIC"
    parameter COMBINATION_TYPE= "COMB_NONSPEC",// "BASELINE", "COMB_SPEC1", "COMB_SPEC2", "COMB_NONSPEC"
    parameter FIRST_ARBITER_EXT_P_EN   =   1,// 1,0    
    parameter TOPOLOGY = "MESH",//"MESH","TORUS","RING" , "LINE"
    parameter ROUTE_NAME =   "XY",//
    parameter CONGESTION_INDEX =   2,
    parameter DEBUG_EN =   0,
    parameter AVC_ATOMIC_EN=1,
    parameter ADD_PIPREG_AFTER_CROSSBAR=0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1: 0] CLASS_SETTING = {CVw{1'b1}}, // shows how each class can use VCs   
    parameter [V-1 : 0] ESCAP_VC_MASK = 4'b1000,  // mask scape vc, valid only for full adaptive
    parameter SSA_EN="NO", // "YES" , "NO" 
    parameter SWA_ARBITER_TYPE = "RRA",//"RRA","WRRA". SWA: Switch Allocator.  RRA: Round Robin Arbiter. WRRA Weighted Round Robin Arbiter          
    parameter WEIGHTw=4, // WRRA weights' max width
    parameter MIN_PCK_SIZE=2 //minimum packet size in flits. The minimum value is 1. 
)(
    reset,
    clk,    
    flit_out_all,
    flit_out_wr_all, 
    credit_in_all,
    flit_in_all,  
    flit_in_wr_all,  
    credit_out_all    
);

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
    

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;
                      
       
    localparam
        PV = V * MAX_P,
        Fw = 2+V+Fpay, //flit width;    
        PFw = MAX_P * Fw,
        NEFw = NE * Fw,
        NEV = NE * V,
        CONG_ALw = CONGw * MAX_P; // congestion width per router    
      
    
    input reset,clk;    
    
    output [NEFw-1 : 0] flit_out_all;
    output [NE-1 : 0] flit_out_wr_all;
    input  [NEV-1 : 0] credit_in_all;
    input  [NEFw-1 : 0] flit_in_all;
    input  [NE-1 : 0] flit_in_wr_all;  
    output [NEV-1 : 0] credit_out_all;                
                    
                    
                   
    wire [PFw-1 : 0] router_flit_in_all [NR-1 :0];
    wire [MAX_P-1 : 0] router_flit_in_we_all [NR-1 :0];    
    wire [PV-1 : 0] router_credit_out_all [NR-1 :0];
    
    wire [PFw-1 : 0] router_flit_out_all [NR-1 :0];
    wire [MAX_P-1 : 0] router_flit_out_we_all [NR-1 :0];
    wire [PV-1 : 0] router_credit_in_all [NR-1 :0];                    
    wire [CONG_ALw-1: 0] router_congestion_out_all[NR-1 :0];    
    wire [CONG_ALw-1: 0] router_congestion_in_all [NR-1 :0];   
    
    
    wire [Fw-1 : 0] ni_flit_out [NE-1 :0];   
    wire [NE-1 : 0] ni_flit_out_wr; 
    wire [V-1 : 0] ni_credit_in [NE-1 :0];
    wire [Fw-1 : 0] ni_flit_in [NE-1 :0];   
    wire [NE-1 : 0] ni_flit_in_wr;  
    wire [V-1 : 0] ni_credit_out [NE-1 :0];   
    
    wire [RAw-1 : 0] current_r_addr [NR-1 : 0];

     // mesh torus            
    localparam
        EAST   =       3'd1, 
        NORTH  =       3'd2,  
        WEST   =       3'd3,  
        SOUTH  =       3'd4;
    //ring line            
    localparam 
        FORWARD =  2'd1,
        BACKWARD=  2'd2;


genvar x,y,l;
generate 
    /* verilator lint_off WIDTH */ 
    if( TOPOLOGY == "RING" || TOPOLOGY == "LINE") begin : ring_line 
    /* verilator lint_on WIDTH */ 
        for  (x=0;   x<NX; x=x+1) begin :ring_loop
             
                       
            assign current_r_addr [x] = x[RAw-1: 0];   
        
            router # (
                .V(V),
                .P(MAX_P),
                .B(B), 
                .T1(T1),
                .T2(1),
                .T3(T3),
                .T4(1),
                .C(C),  
                .Fpay(Fpay),    
                .TOPOLOGY(TOPOLOGY),
                .MUX_TYPE(MUX_TYPE),
                .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
                .COMBINATION_TYPE(COMBINATION_TYPE),
                .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
                .ROUTE_NAME(ROUTE_NAME),  
                .CONGESTION_INDEX(CONGESTION_INDEX),
                .DEBUG_EN(DEBUG_EN),
                .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
                .CONGw(CONGw),
                .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
                .CVw(CVw),
                .CLASS_SETTING(CLASS_SETTING),   
                .ESCAP_VC_MASK(ESCAP_VC_MASK),
                .SSA_EN(SSA_EN),
                .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
                .WEIGHTw(WEIGHTw),     
                .MIN_PCK_SIZE(MIN_PCK_SIZE)
            )
            the_router
            (
                .current_r_addr(current_r_addr [x]),   
                .neighbors_r_addr( ),// not needed for mesh as routers addresses are easy to be predicted

                .flit_in_all(router_flit_in_all[x]),
                .flit_in_we_all(router_flit_in_we_all[x]),
                .credit_out_all(router_credit_out_all[x]),
                .congestion_in_all(router_congestion_in_all[x]),
            
            
                .flit_out_all(router_flit_out_all[x]),
                .flit_out_we_all(router_flit_out_we_all[x]),
                .credit_in_all(router_credit_in_all[x]),
                .congestion_out_all(router_congestion_out_all[x]),
            
                .clk(clk),
                .reset(reset)
        
            );
        
            if(x    <   NX-1) begin: not_last_node            
                assign  router_flit_in_all [`SELECT_WIRE(x,0,FORWARD,Fw)] = router_flit_out_all [`SELECT_WIRE((x+1),0,BACKWARD,Fw)];
                assign  router_credit_in_all [`SELECT_WIRE(x,0,FORWARD,V)] = router_credit_out_all [`SELECT_WIRE((x+1),0,BACKWARD,V)];
                assign  router_flit_in_we_all [x][FORWARD] = router_flit_out_we_all [`router_id((x+1),0)][BACKWARD];
                assign  router_congestion_in_all [`SELECT_WIRE(x,0,FORWARD,CONGw)]  = router_congestion_out_all [`SELECT_WIRE((x+1),0,BACKWARD,CONGw)];
            end else begin :last_node
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "LINE") begin : line_last_x
                /* verilator lint_on WIDTH */ 
                    assign  router_flit_in_all [`SELECT_WIRE(x,0,FORWARD,Fw)] = {Fw{1'b0}};
                    assign  router_credit_in_all [`SELECT_WIRE(x,0,FORWARD,V)] = {V{1'b0}};
                    assign  router_flit_in_we_all [x][FORWARD] = 1'b0;
                    assign  router_congestion_in_all [`SELECT_WIRE(x,0,FORWARD,CONGw)] = {CONGw{1'b0}};                
                end else begin : ring_last_x
                    assign  router_flit_in_all [`SELECT_WIRE(x,0,FORWARD,Fw)] =   router_flit_out_all [`SELECT_WIRE(0,0,BACKWARD,Fw)];
                    assign  router_credit_in_all [`SELECT_WIRE(x,0,FORWARD,V)] =   router_credit_out_all [`SELECT_WIRE(0,0,BACKWARD,V)];
                    assign  router_flit_in_we_all [x][FORWARD]  =   router_flit_out_we_all [`router_id(0,0)][BACKWARD];
                    assign  router_congestion_in_all [`SELECT_WIRE(x,0,FORWARD,CONGw)]  = router_congestion_out_all [`SELECT_WIRE(0,0,BACKWARD,CONGw)];
                end
            end 
            
            if(x>0)begin :not_first_x
                assign  router_flit_in_all [`SELECT_WIRE(x,0,BACKWARD,Fw)] = router_flit_out_all [`SELECT_WIRE((x-1),0,FORWARD,Fw)];
                assign  router_credit_in_all [`SELECT_WIRE(x,0,BACKWARD,V)] =  router_credit_out_all [`SELECT_WIRE((x-1),0,FORWARD,V)] ;
                assign  router_flit_in_we_all [x][BACKWARD] =   router_flit_out_we_all [`router_id((x-1),0)][FORWARD];
                assign  router_congestion_in_all[`SELECT_WIRE(x,0,BACKWARD,CONGw)] =   router_congestion_out_all [`SELECT_WIRE((x-1),0,FORWARD,CONGw)];
            end else begin :first_x
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "LINE") begin : line_first_x
                /* verilator lint_on WIDTH */ 
                    assign  router_flit_in_all [`SELECT_WIRE(x,0,BACKWARD,Fw)] = {Fw{1'b0}};
                    assign  router_credit_in_all [`SELECT_WIRE(x,0,BACKWARD,V)] = {V{1'b0}};
                    assign  router_flit_in_we_all [x][BACKWARD] = 1'b0;
                    assign  router_congestion_in_all[`SELECT_WIRE(x,0,BACKWARD,CONGw)] = {CONGw{1'b0}};
                 end else begin : ring_first_x
                    assign  router_flit_in_all [`SELECT_WIRE(x,0,BACKWARD,Fw)] = router_flit_out_all [`SELECT_WIRE((NX-1),0,FORWARD,Fw)] ;
                    assign  router_credit_in_all [`SELECT_WIRE(x,0,BACKWARD,V)] = router_credit_out_all [`SELECT_WIRE((NX-1),0,FORWARD,V)] ;
                    assign  router_flit_in_we_all [x][BACKWARD] = router_flit_out_we_all [`router_id((NX-1),0)][FORWARD];
                    assign  router_congestion_in_all[`SELECT_WIRE(x,0,BACKWARD,CONGw)] = router_congestion_out_all [`SELECT_WIRE((NX-1),0,FORWARD,CONGw)];
                end
            end            
            
            // connect other local ports
            for  (l=0;   l<NL; l=l+1) begin :locals
                localparam ENDPID = `endp_id(x,0,l); 
                localparam LOCALP = (l==0) ? l : l + R2R_CHANNELS_MESH_TORI; // first local port is connected to router port 0. The rest are connected at the end  
                
                assign router_flit_in_all [`SELECT_WIRE(x,0,LOCALP,Fw)] =    ni_flit_out [ENDPID];
                assign router_credit_in_all [`SELECT_WIRE(x,0,LOCALP,V)] =    ni_credit_out [ENDPID];
                assign router_flit_in_we_all [`router_id(x,0)][LOCALP] =    ni_flit_out_wr [ENDPID];
                assign router_congestion_in_all[`SELECT_WIRE(x,0,LOCALP,CONGw)] =   {CONGw{1'b0}};              
            
                assign ni_flit_in [ENDPID] = router_flit_out_all [`SELECT_WIRE(x,0,LOCALP,Fw)];
                assign ni_flit_in_wr [ENDPID] = router_flit_out_we_all[`router_id(x,0)][LOCALP];
                assign ni_credit_in [ENDPID] = router_credit_out_all [`SELECT_WIRE(x,0,LOCALP,V)];                             
            
                
                assign flit_out_all [(ENDPID+1)*Fw-1 : ENDPID*Fw] =    ni_flit_in [ENDPID];    
                assign flit_out_wr_all [ENDPID]  =     ni_flit_in_wr [ENDPID]; 
                assign ni_credit_out [ENDPID]  =    credit_in_all [(ENDPID+1)*V-1 : ENDPID*V];  
                assign ni_flit_out [ENDPID]  =     flit_in_all [(ENDPID+1)*Fw-1 : ENDPID*Fw];
                assign ni_flit_out_wr [ENDPID]  =    flit_in_wr_all [ENDPID];
                assign credit_out_all [(ENDPID+1)*V-1 : ENDPID*V] =    ni_credit_in [ENDPID];              
                
            end// locals
            
                
       end//x    
    
    
    end else begin :mesh_torus
        for (y=0;    y<NY;    y=y+1) begin: y_loop
            for (x=0;    x<NX; x=x+1) begin :x_loop
            localparam R_ADDR = (y<<NXw) + x;            
            localparam ROUTER_NUM = (y * NX) +    x;
            assign current_r_addr [ROUTER_NUM] = R_ADDR[RAw-1 :0];
             
             
            router # (
                .V(V),
                .P(MAX_P),
                .B(B), 
                .T1(T1),
                .T2(T2),
                .T3(T3),
                .T4(1),
                .C(C),    
                .Fpay(Fpay),    
                .TOPOLOGY(TOPOLOGY),
                .MUX_TYPE(MUX_TYPE),
                .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
                .COMBINATION_TYPE(COMBINATION_TYPE),
                .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
                .ROUTE_NAME(ROUTE_NAME),  
                .CONGESTION_INDEX(CONGESTION_INDEX),
                .DEBUG_EN(DEBUG_EN),
                .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
                .CONGw(CONGw),
                .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
                .CVw(CVw),
                .CLASS_SETTING(CLASS_SETTING),   
                .SSA_EN(SSA_EN),
                .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
                .WEIGHTw(WEIGHTw),
                .MIN_PCK_SIZE(MIN_PCK_SIZE)                
            )
            the_router
            (
                .current_r_addr(current_r_addr [ROUTER_NUM]),    
                .neighbors_r_addr( ),
                .flit_in_all(router_flit_in_all[`router_id(x,y)]),
                .flit_in_we_all(router_flit_in_we_all[`router_id(x,y)]),
                .credit_out_all(router_credit_out_all[`router_id(x,y)]),
                .congestion_in_all(router_congestion_in_all[`router_id(x,y)]),            
            
                .flit_out_all(router_flit_out_all[`router_id(x,y)]),
                .flit_out_we_all(router_flit_out_we_all[`router_id(x,y)]),
                .credit_in_all(router_credit_in_all[`router_id(x,y)]),
                .congestion_out_all(router_congestion_out_all[`router_id(x,y)]),
            
                .clk(clk),
                .reset(reset)
        
            );
    /*
    in [x,y][east] <------  out [x+1 ,y  ][west] ;
    in [x,y][north] <------ out [x   ,y-1][south] ;
    in [x,y][west] <------  out [x-1 ,y  ][east] ;
    in [x,y][south] <------ out [x   ,y+1][north] ;
    */    
        
        
            if(x    <    NX-1) begin: not_last_x
                assign    router_flit_in_all [`SELECT_WIRE(x,y,EAST,Fw)] = router_flit_out_all [`SELECT_WIRE((x+1),y,WEST,Fw)];
                assign    router_credit_in_all [`SELECT_WIRE(x,y,EAST,V)] = router_credit_out_all [`SELECT_WIRE((x+1),y,WEST,V)];
                assign    router_flit_in_we_all [`router_id(x,y)][EAST] = router_flit_out_we_all [`router_id((x+1),y)][WEST];
                assign    router_congestion_in_all [`SELECT_WIRE(x,y,EAST,CONGw)]  = router_congestion_out_all [`SELECT_WIRE((x+1),y,WEST,CONGw)];
            end else begin :last_x
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "MESH") begin :last_x_mesh
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,EAST,Fw)] =    {Fw{1'b0}};
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,EAST,V)] =    {V{1'b0}};
                    assign    router_flit_in_we_all [`router_id(x,y)][EAST] =    1'b0;
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,EAST,CONGw)]  = {CONGw{1'b0}};
                /* verilator lint_off WIDTH */ 
                end else if(TOPOLOGY == "TORUS") begin : last_x_torus
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,EAST,Fw)] =    router_flit_out_all [`SELECT_WIRE(0,y,WEST,Fw)];
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,EAST,V)] =    router_credit_out_all [`SELECT_WIRE(0,y,WEST,V)];
                    assign    router_flit_in_we_all [`router_id(x,y)][EAST] =    router_flit_out_we_all [`router_id(0,y)][WEST];
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,EAST,CONGw)]  = router_congestion_out_all [`SELECT_WIRE(0,y,WEST,CONGw)];
                end //topology
            end 
            
        
            if(y>0) begin : not_first_y
                assign    router_flit_in_all [`SELECT_WIRE(x,y,NORTH,Fw)] =    router_flit_out_all [`SELECT_WIRE(x,(y-1),SOUTH,Fw)];
                assign    router_credit_in_all [`SELECT_WIRE(x,y,NORTH,V)] =  router_credit_out_all [`SELECT_WIRE(x,(y-1),SOUTH,V)];
                assign    router_flit_in_we_all [`router_id(x,y)][NORTH] =    router_flit_out_we_all [`router_id(x,(y-1))][SOUTH];
                assign    router_congestion_in_all [`SELECT_WIRE(x,y,NORTH,CONGw)]   =     router_congestion_out_all [`SELECT_WIRE(x,(y-1),SOUTH,CONGw)];
            end else begin :first_y
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "MESH") begin : first_y_mesh
                /* verilator lint_on WIDTH */ 
                    assign     router_flit_in_all [`SELECT_WIRE(x,y,NORTH,Fw)] =    {Fw{1'b0}};
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,NORTH,V)] =    {V{1'b0}};
                    assign    router_flit_in_we_all [`router_id(x,y)][NORTH] =    1'b0;
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,NORTH,CONGw)]   =     {CONGw{1'b0}};
                /* verilator lint_off WIDTH */ 
                end else if(TOPOLOGY == "TORUS") begin :first_y_torus
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,NORTH,Fw)] =    router_flit_out_all [`SELECT_WIRE(x,(NY-1),SOUTH,Fw)];
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,NORTH,V)] =  router_credit_out_all [`SELECT_WIRE(x,(NY-1),SOUTH,V)];
                    assign    router_flit_in_we_all [`router_id(x,y)][NORTH] =    router_flit_out_we_all [`router_id(x,(NY-1))][SOUTH];
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,NORTH,CONGw)]   =     router_congestion_out_all [`SELECT_WIRE(x,(NY-1),SOUTH,CONGw)];
                end//topology
            end//y>0
            
            
            if(x>0)begin :not_first_x
                assign    router_flit_in_all [`SELECT_WIRE(x,y,WEST,Fw)] =    router_flit_out_all [`SELECT_WIRE((x-1),y,EAST,Fw)] ;
                assign    router_credit_in_all [`SELECT_WIRE(x,y,WEST,V)] =  router_credit_out_all [`SELECT_WIRE((x-1),y,EAST,V)] ;
                assign    router_flit_in_we_all [`router_id(x,y)][WEST] =    router_flit_out_we_all [`router_id((x-1),y)][EAST];
                assign    router_congestion_in_all [`SELECT_WIRE(x,y,WEST,CONGw)]   =     router_congestion_out_all [`SELECT_WIRE((x-1),y,EAST,CONGw)];
            end else begin :first_x
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "MESH") begin :first_x_mesh
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,WEST,Fw)] =  {Fw{1'b0}};
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,WEST,V)] =    {V{1'b0}};
                    assign    router_flit_in_we_all [`router_id(x,y)][WEST] =    1'b0;
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,WEST,CONGw)]   =     {CONGw{1'b0}};
                /* verilator lint_off WIDTH */                
                end else if(TOPOLOGY == "TORUS") begin :first_x_torus
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,WEST,Fw)] =    router_flit_out_all [`SELECT_WIRE((NX-1),y,EAST,Fw)] ;
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,WEST,V)] =  router_credit_out_all [`SELECT_WIRE((NX-1),y,EAST,V)] ;
                    assign    router_flit_in_we_all [`router_id(x,y)][WEST] =    router_flit_out_we_all [`router_id((NX-1),y)][EAST];
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,WEST,CONGw)]   =     router_congestion_out_all [`SELECT_WIRE((NX-1),y,EAST,CONGw)];
                end//topology
            end    
            
            if(y    <    NY-1) begin : firsty
                assign    router_flit_in_all [`SELECT_WIRE(x,y,SOUTH,Fw)] =    router_flit_out_all [`SELECT_WIRE(x,(y+1),NORTH,Fw)];
                assign    router_credit_in_all [`SELECT_WIRE(x,y,SOUTH,V)] =     router_credit_out_all [`SELECT_WIRE(x,(y+1),NORTH,V)];
                assign    router_flit_in_we_all [`router_id(x,y)][SOUTH] =    router_flit_out_we_all [`router_id(x,(y+1))][NORTH];
                assign    router_congestion_in_all [`SELECT_WIRE(x,y,SOUTH,CONGw)]   =     router_congestion_out_all [`SELECT_WIRE(x,(y+1),NORTH,CONGw)];
            end else     begin : lasty
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "MESH") begin :ly_mesh
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,4,Fw)] =  {Fw{1'b0}};
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,4,V)] =    {V{1'b0}};
                    assign    router_flit_in_we_all [`router_id(x,y)][4] =    1'b0;
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,4,CONGw)]   =     {CONGw{1'b0}};    
                /* verilator lint_off WIDTH */ 
                end else if(TOPOLOGY == "TORUS") begin :ly_torus
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,SOUTH,Fw)] =    router_flit_out_all [`SELECT_WIRE(x,0,NORTH,Fw)];
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,SOUTH,V)] =     router_credit_out_all [`SELECT_WIRE(x,0,NORTH,V)];
                    assign    router_flit_in_we_all [`router_id(x,y)][SOUTH] =    router_flit_out_we_all [`router_id(x,0)][NORTH];
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,SOUTH,CONGw)]   =     router_congestion_out_all [`SELECT_WIRE(x,0,NORTH,CONGw)];
                end//topology
            end          
        
        
            // endpoint(s) connection
            // connect other local ports
            for  (l=0;   l<NL; l=l+1) begin :locals
                localparam ENDPID = `endp_id(x,y,l); 
                localparam LOCALP = (l==0) ? l : l + R2R_CHANNELS_MESH_TORI; // first local port is connected to router port 0. The rest are connected at the end  
                
                assign router_flit_in_all [`SELECT_WIRE(x,y,LOCALP,Fw)] =    ni_flit_out [ENDPID];
                assign router_credit_in_all [`SELECT_WIRE(x,y,LOCALP,V)] =    ni_credit_out [ENDPID];
                assign router_flit_in_we_all [`router_id(x,y)][LOCALP] =    ni_flit_out_wr [ENDPID];
                assign router_congestion_in_all[`SELECT_WIRE(x,y,LOCALP,CONGw)] =   {CONGw{1'b0}};              
            
                assign ni_flit_in [ENDPID] = router_flit_out_all [`SELECT_WIRE(x,y,LOCALP,Fw)];
                assign ni_flit_in_wr [ENDPID] = router_flit_out_we_all[`router_id(x,y)][LOCALP];
                assign ni_credit_in [ENDPID] = router_credit_out_all [`SELECT_WIRE(x,y,LOCALP,V)];                             
                            
                assign flit_out_all [(ENDPID+1)*Fw-1 : ENDPID*Fw] =    ni_flit_in [ENDPID];    
                assign flit_out_wr_all [ENDPID]  =     ni_flit_in_wr [ENDPID]; 
                assign ni_credit_out [ENDPID]  =    credit_in_all [(ENDPID+1)*V-1 : ENDPID*V];  
                assign ni_flit_out [ENDPID]  =     flit_in_all [(ENDPID+1)*Fw-1 : ENDPID*Fw];
                assign ni_flit_out_wr [ENDPID]  =    flit_in_wr_all [ENDPID];
                assign credit_out_all [(ENDPID+1)*V-1 : ENDPID*V] =    ni_credit_in [ENDPID];
                              
            end// locals                 
    
            end //y
        end //x
    end// mesh_torus        
    
    endgenerate

endmodule
