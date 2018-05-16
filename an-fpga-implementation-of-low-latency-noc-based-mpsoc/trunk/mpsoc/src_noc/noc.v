
/**********************************************************************
**    File:  noc.v
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
**    the NoC top module. It generate different  topologies by 
**    connecting routers  
**
**************************************************************/


`timescale     1ns/1ps

`define START_LOC(port_num,width)       (width*(port_num+1)-1)
`define END_LOC(port_num,width)            (width*port_num)
`define CORE_NUM(x,y)                         ((y * NX) +    x)
`define SELECT_WIRE(x,y,port,width)    `CORE_NUM(x,y)] [`START_LOC(port,width) : `END_LOC(port,width )


module noc #(
    parameter V = 2, // Number of Virtual channel per port 
    parameter B = 4, // buffer space :flit per VC 
    parameter NX   = 2, // The number of node in x axis of mesh or torus. For ring topology is total number of nodes in ring.
    parameter NY   = 2, // The number of node in y axis of mesh or torus. It is not used in ring topology.
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
    parameter ROUTE_SUBFUNC ="XY",    
    parameter AVC_ATOMIC_EN=1,
    parameter ADD_PIPREG_AFTER_CROSSBAR=0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1: 0] CLASS_SETTING = {CVw{1'b1}}, // shows how each class can use VCs   
    parameter [V-1 : 0] ESCAP_VC_MASK = 4'b1000,  // mask scape vc, valid only for full adaptive
    parameter SSA_EN="NO", // "YES" , "NO" 
    parameter SWA_ARBITER_TYPE = "RRA",//"RRA","WRRA". SWA: Switch Allocator.  RRA: Round Robin Arbiter. WRRA Weighted Round Robin Arbiter          
    parameter WEIGHTw=4 // WRRA weights' max width
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

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;
                      
    /* verilator lint_off WIDTH */                  
    localparam ROUTE_TYPE = (ROUTE_NAME == "XY" || ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
                           (ROUTE_NAME == "DUATO" || ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE";    
                           
    localparam P=  (TOPOLOGY=="RING" || TOPOLOGY=="LINE")? 3 : 5;    
    /* verilator lint_on WIDTH */
                                              

    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end        
      end   
    endfunction // log2 
    
    localparam
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay, //flit width;    
        PFw = P * Fw,
        /* verilator lint_off WIDTH */
        NC = (TOPOLOGY=="RING" || TOPOLOGY=="LINE")? NX : NX*NY,    //number of cores
        /* verilator lint_on WIDTH */
        NCFw = NC * Fw,
        NCV = NC * V,
        CONG_ALw = CONGw * P, // congestion width per router            
        Xw = log2(NX),    // number of node in x axis
        Yw = log2(NY);    // number of node in y axis

    
    input reset,clk;    
    
    output [NCFw-1 : 0] flit_out_all;
    output [NC-1 : 0] flit_out_wr_all;
    input  [NCV-1 : 0] credit_in_all;
    input  [NCFw-1 : 0] flit_in_all;
    input  [NC-1 : 0] flit_in_wr_all;  
    output [NCV-1 : 0] credit_out_all;
                
                    
                    
                    
    wire [PFw-1 : 0] router_flit_in_all [NC-1 :0];
    wire [P-1 : 0] router_flit_in_we_all [NC-1 :0];    
    wire [PV-1 : 0] router_credit_out_all [NC-1 :0];
    
    wire [PFw-1 : 0] router_flit_out_all [NC-1 :0];
    wire [P-1 : 0] router_flit_out_we_all [NC-1 :0];
    wire [PV-1 : 0] router_credit_in_all [NC-1 :0];                    
    wire [CONG_ALw-1: 0] router_congestion_out_all[NC-1 :0];    
    wire [CONG_ALw-1: 0] router_congestion_in_all [NC-1 :0];   
    
    
    wire [Fw-1 : 0] ni_flit_out [NC-1 :0];   
    wire [NC-1 : 0] ni_flit_out_wr; 
    wire [V-1 : 0] ni_credit_in [NC-1 :0];
    wire [Fw-1 : 0] ni_flit_in [NC-1 :0];   
    wire [NC-1 : 0] ni_flit_in_wr;  
    wire [V-1 : 0] ni_credit_out [NC-1 :0];    



genvar x,y;
generate 
    /* verilator lint_off WIDTH */ 
    if( TOPOLOGY == "RING" || TOPOLOGY == "LINE") begin : ring_line 
    /* verilator lint_on WIDTH */ 
        for  (x=0;   x<NX; x=x+1) begin :ring_loop
            router # (
                .V(V),
                .P(P),
                .B(B), 
                .NX(NX),
                .NY(1),
                .C(C),  
                .Fpay(Fpay),    
                .TOPOLOGY(TOPOLOGY),
                .MUX_TYPE(MUX_TYPE),
                .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
                .COMBINATION_TYPE(COMBINATION_TYPE),
                .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
                .ROUTE_TYPE(ROUTE_TYPE),
                .ROUTE_NAME(ROUTE_NAME),  
                .CONGESTION_INDEX(CONGESTION_INDEX),
                .DEBUG_EN(DEBUG_EN),
                .ROUTE_SUBFUNC(ROUTE_SUBFUNC),
                .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
                .CONGw(CONGw),
                .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
                .CVw(CVw),
                .CLASS_SETTING(CLASS_SETTING),   
                .ESCAP_VC_MASK(ESCAP_VC_MASK),
                .SSA_EN(SSA_EN),
                .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
                .WEIGHTw(WEIGHTw)     
                
            )
            the_router
            (
                .current_x(x[Xw-1 :0]),   
                .current_y(1'b0),
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
                assign  router_flit_in_all [`SELECT_WIRE(x,0,1,Fw)] = router_flit_out_all [`SELECT_WIRE((x+1),0,2,Fw)];
                assign  router_credit_in_all [`SELECT_WIRE(x,0,1,V)] = router_credit_out_all [`SELECT_WIRE((x+1),0,2,V)];
                assign  router_flit_in_we_all [x][1] = router_flit_out_we_all [`CORE_NUM((x+1),0)][2];
                assign  router_congestion_in_all [`SELECT_WIRE(x,0,1,CONGw)]  = router_congestion_out_all [`SELECT_WIRE((x+1),0,2,CONGw)];
            end else begin :last_node
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "LINE") begin : line_last_x
                /* verilator lint_on WIDTH */ 
                    assign  router_flit_in_all [`SELECT_WIRE(x,0,1,Fw)] = {Fw{1'b0}};
                    assign  router_credit_in_all [`SELECT_WIRE(x,0,1,V)] = {V{1'b0}};
                    assign  router_flit_in_we_all [x][1] = 1'b0;
                    assign  router_congestion_in_all [`SELECT_WIRE(x,0,1,CONGw)] = {CONGw{1'b0}};                
                end else begin : ring_last_x
                    assign  router_flit_in_all [`SELECT_WIRE(x,0,1,Fw)] =   router_flit_out_all [`SELECT_WIRE(0,0,2,Fw)];
                    assign  router_credit_in_all [`SELECT_WIRE(x,0,1,V)] =   router_credit_out_all [`SELECT_WIRE(0,0,2,V)];
                    assign  router_flit_in_we_all [x][1]  =   router_flit_out_we_all [`CORE_NUM(0,0)][2];
                    assign  router_congestion_in_all [`SELECT_WIRE(x,0,1,CONGw)]  = router_congestion_out_all [`SELECT_WIRE(0,0,2,CONGw)];
                end
            end 
            
            if(x>0)begin :not_first_x
                assign  router_flit_in_all [`SELECT_WIRE(x,0,2,Fw)] = router_flit_out_all [`SELECT_WIRE((x-1),0,1,Fw)];
                assign  router_credit_in_all [`SELECT_WIRE(x,0,2,V)] =  router_credit_out_all [`SELECT_WIRE((x-1),0,1,V)] ;
                assign  router_flit_in_we_all [x][2] =   router_flit_out_we_all [`CORE_NUM((x-1),0)][1];
                assign  router_congestion_in_all[`SELECT_WIRE(x,0,2,CONGw)] =   router_congestion_out_all [`SELECT_WIRE((x-1),0,1,CONGw)];
            end else begin :first_x
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "LINE") begin : line_first_x
                /* verilator lint_on WIDTH */ 
                    assign  router_flit_in_all [`SELECT_WIRE(x,0,2,Fw)] = {Fw{1'b0}};
                    assign  router_credit_in_all [`SELECT_WIRE(x,0,2,V)] = {V{1'b0}};
                    assign  router_flit_in_we_all [x][2] = 1'b0;
                    assign  router_congestion_in_all[`SELECT_WIRE(x,0,2,CONGw)] = {CONGw{1'b0}};
                 end else begin : ring_first_x
                    assign  router_flit_in_all [`SELECT_WIRE(x,0,2,Fw)] = router_flit_out_all [`SELECT_WIRE((NX-1),0,1,Fw)] ;
                    assign  router_credit_in_all [`SELECT_WIRE(x,0,2,V)] = router_credit_out_all [`SELECT_WIRE((NX-1),0,1,V)] ;
                    assign  router_flit_in_we_all [x][2] = router_flit_out_we_all [`CORE_NUM((NX-1),0)][1];
                    assign  router_congestion_in_all[`SELECT_WIRE(x,0,2,CONGw)] = router_congestion_out_all [`SELECT_WIRE((NX-1),0,1,CONGw)];
                end
            end 
            
            // local port connection
            assign    router_flit_in_all [`SELECT_WIRE(x,0,0,Fw)] =    ni_flit_out [x];
            assign    router_credit_in_all [`SELECT_WIRE(x,0,0,V)] =    ni_credit_out [x];
            assign    router_flit_in_we_all [x][0] =    ni_flit_out_wr [x];
            assign    router_congestion_in_all[`SELECT_WIRE(x,0,0,CONGw)] =   {CONGw{1'b0}};              
            
            assign      ni_flit_in [x] = router_flit_out_all [`SELECT_WIRE(x,0,0,Fw)];
            assign      ni_flit_in_wr [x] = router_flit_out_we_all[x][0];
            assign      ni_credit_in [x] = router_credit_out_all [`SELECT_WIRE(x,0,0,V)];
            
            
                    
                            
            assign  flit_out_all [(x+1)*Fw-1 : x*Fw] =   ni_flit_in [x];   
            assign  flit_out_wr_all [x] =   ni_flit_in_wr [x]; 
            assign  ni_credit_out [x] =   credit_in_all [(x+1)*V-1 : x*V];  
            assign  ni_flit_out [x] =   flit_in_all [(x+1)*Fw-1 : x*Fw];
            assign  ni_flit_out_wr [x] =   flit_in_wr_all [x];
            assign  credit_out_all [(x+1)*V-1 : x*V] =   ni_credit_in [x];
            
            
                
       end//x    
    
    
    end else begin :mesh_torus
    for    (y=0;    y<NY;    y=y+1) begin: y_loop
            for    (x=0;    x<NX; x=x+1) begin :x_loop
            
          
        
    
            router # (
                .V(V),
                .P(P),
                .B(B), 
                .NX(NX),
                .NY(NY),
                .C(C),    
                .Fpay(Fpay),    
                .TOPOLOGY(TOPOLOGY),
                .MUX_TYPE(MUX_TYPE),
                .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
                .COMBINATION_TYPE(COMBINATION_TYPE),
                .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
                .ROUTE_TYPE(ROUTE_TYPE),
                .ROUTE_NAME(ROUTE_NAME),  
                .CONGESTION_INDEX(CONGESTION_INDEX),
                .DEBUG_EN(DEBUG_EN),
                .ROUTE_SUBFUNC(ROUTE_SUBFUNC),
                .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
                .CONGw(CONGw),
                .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
                .CVw(CVw),
                .CLASS_SETTING(CLASS_SETTING),   
                .SSA_EN(SSA_EN),
                .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
                .WEIGHTw(WEIGHTw)     
                
            )
            the_router
            (
                .current_x(x[Xw-1 :0]),    
                .current_y(y[Yw-1 :0]),
                .flit_in_all(router_flit_in_all[`CORE_NUM(x,y)]),
                .flit_in_we_all(router_flit_in_we_all[`CORE_NUM(x,y)]),
                .credit_out_all(router_credit_out_all[`CORE_NUM(x,y)]),
                .congestion_in_all(router_congestion_in_all[`CORE_NUM(x,y)]),
            
            
                .flit_out_all(router_flit_out_all[`CORE_NUM(x,y)]),
                .flit_out_we_all(router_flit_out_we_all[`CORE_NUM(x,y)]),
                .credit_in_all(router_credit_in_all[`CORE_NUM(x,y)]),
                .congestion_out_all(router_congestion_out_all[`CORE_NUM(x,y)]),
            
                .clk(clk),
                .reset(reset)
        
            );
    /*
    in [x,y][1] <------         out [x+1        ,y     ][3] ;
    in [x,y][2] <------        out [x        ,y-1][4] ;
    in [x,y][3] <------        out [x-1        ,y     ][1] ;
    in [x,y][4] <------        out [x        ,y+1][2] ;
        
    port num
    local = 0
    east  = 1
    north = 2
    west  = 3
    south = 4
    */    
        
        
            if(x    <    NX-1) begin: not_last_x
                assign    router_flit_in_all [`SELECT_WIRE(x,y,1,Fw)] = router_flit_out_all [`SELECT_WIRE((x+1),y,3,Fw)];
                assign    router_credit_in_all [`SELECT_WIRE(x,y,1,V)] = router_credit_out_all [`SELECT_WIRE((x+1),y,3,V)];
                assign    router_flit_in_we_all [`CORE_NUM(x,y)][1] = router_flit_out_we_all [`CORE_NUM((x+1),y)][3];
                assign    router_congestion_in_all [`SELECT_WIRE(x,y,1,CONGw)]  = router_congestion_out_all [`SELECT_WIRE((x+1),y,3,CONGw)];
            end else begin :last_x
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "MESH") begin :last_x_mesh
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,1,Fw)] =    {Fw{1'b0}};
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,1,V)] =    {V{1'b0}};
                    assign    router_flit_in_we_all [`CORE_NUM(x,y)][1] =    1'b0;
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,1,CONGw)]  = {CONGw{1'b0}};
                /* verilator lint_off WIDTH */ 
                end else if(TOPOLOGY == "TORUS") begin : last_x_torus
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,1,Fw)] =    router_flit_out_all [`SELECT_WIRE(0,y,3,Fw)];
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,1,V)] =    router_credit_out_all [`SELECT_WIRE(0,y,3,V)];
                    assign    router_flit_in_we_all [`CORE_NUM(x,y)][1] =    router_flit_out_we_all [`CORE_NUM(0,y)][3];
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,1,CONGw)]  = router_congestion_out_all [`SELECT_WIRE(0,y,3,CONGw)];
                end //topology
            end 
            
        
            if(y>0) begin : not_first_y
                assign    router_flit_in_all [`SELECT_WIRE(x,y,2,Fw)] =    router_flit_out_all [`SELECT_WIRE(x,(y-1),4,Fw)];
                assign    router_credit_in_all [`SELECT_WIRE(x,y,2,V)] =  router_credit_out_all [`SELECT_WIRE(x,(y-1),4,V)];
                assign    router_flit_in_we_all [`CORE_NUM(x,y)][2] =    router_flit_out_we_all [`CORE_NUM(x,(y-1))][4];
                assign    router_congestion_in_all [`SELECT_WIRE(x,y,2,CONGw)]   =     router_congestion_out_all [`SELECT_WIRE(x,(y-1),4,CONGw)];
            end else begin :first_y
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "MESH") begin : first_y_mesh
                /* verilator lint_on WIDTH */ 
                    assign     router_flit_in_all [`SELECT_WIRE(x,y,2,Fw)] =    {Fw{1'b0}};
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,2,V)] =    {V{1'b0}};
                    assign    router_flit_in_we_all [`CORE_NUM(x,y)][2] =    1'b0;
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,2,CONGw)]   =     {CONGw{1'b0}};
                /* verilator lint_off WIDTH */ 
                end else if(TOPOLOGY == "TORUS") begin :first_y_torus
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,2,Fw)] =    router_flit_out_all [`SELECT_WIRE(x,(NY-1),4,Fw)];
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,2,V)] =  router_credit_out_all [`SELECT_WIRE(x,(NY-1),4,V)];
                    assign    router_flit_in_we_all [`CORE_NUM(x,y)][2] =    router_flit_out_we_all [`CORE_NUM(x,(NY-1))][4];
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,2,CONGw)]   =     router_congestion_out_all [`SELECT_WIRE(x,(NY-1),4,CONGw)];
                end//topology
            end//y>0
            
            
            if(x>0)begin :not_first_x
                assign    router_flit_in_all [`SELECT_WIRE(x,y,3,Fw)] =    router_flit_out_all [`SELECT_WIRE((x-1),y,1,Fw)] ;
                assign    router_credit_in_all [`SELECT_WIRE(x,y,3,V)] =  router_credit_out_all [`SELECT_WIRE((x-1),y,1,V)] ;
                assign    router_flit_in_we_all [`CORE_NUM(x,y)][3] =    router_flit_out_we_all [`CORE_NUM((x-1),y)][1];
                assign    router_congestion_in_all [`SELECT_WIRE(x,y,3,CONGw)]   =     router_congestion_out_all [`SELECT_WIRE((x-1),y,1,CONGw)];
            end else begin :first_x
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "MESH") begin :first_x_mesh
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,3,Fw)] =  {Fw{1'b0}};
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,3,V)] =    {V{1'b0}};
                    assign    router_flit_in_we_all [`CORE_NUM(x,y)][3] =    1'b0;
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,3,CONGw)]   =     {CONGw{1'b0}};
                /* verilator lint_off WIDTH */                
                end else if(TOPOLOGY == "TORUS") begin :first_x_torus
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,3,Fw)] =    router_flit_out_all [`SELECT_WIRE((NX-1),y,1,Fw)] ;
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,3,V)] =  router_credit_out_all [`SELECT_WIRE((NX-1),y,1,V)] ;
                    assign    router_flit_in_we_all [`CORE_NUM(x,y)][3] =    router_flit_out_we_all [`CORE_NUM((NX-1),y)][1];
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,3,CONGw)]   =     router_congestion_out_all [`SELECT_WIRE((NX-1),y,1,CONGw)];
                end//topology
            end    
            
            if(y    <    NY-1) begin : firsty
                assign    router_flit_in_all [`SELECT_WIRE(x,y,4,Fw)] =    router_flit_out_all [`SELECT_WIRE(x,(y+1),2,Fw)];
                assign    router_credit_in_all [`SELECT_WIRE(x,y,4,V)] =     router_credit_out_all [`SELECT_WIRE(x,(y+1),2,V)];
                assign    router_flit_in_we_all [`CORE_NUM(x,y)][4] =    router_flit_out_we_all [`CORE_NUM(x,(y+1))][2];
                assign    router_congestion_in_all [`SELECT_WIRE(x,y,4,CONGw)]   =     router_congestion_out_all [`SELECT_WIRE(x,(y+1),2,CONGw)];
            end else     begin : lasty
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "MESH") begin :ly_mesh
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,4,Fw)] =  {Fw{1'b0}};
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,4,V)] =    {V{1'b0}};
                    assign    router_flit_in_we_all [`CORE_NUM(x,y)][4] =    1'b0;
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,4,CONGw)]   =     {CONGw{1'b0}};    
                /* verilator lint_off WIDTH */ 
                end else if(TOPOLOGY == "TORUS") begin :ly_torus
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_in_all [`SELECT_WIRE(x,y,4,Fw)] =    router_flit_out_all [`SELECT_WIRE(x,0,2,Fw)];
                    assign    router_credit_in_all [`SELECT_WIRE(x,y,4,V)] =     router_credit_out_all [`SELECT_WIRE(x,0,2,V)];
                    assign    router_flit_in_we_all [`CORE_NUM(x,y)][4] =    router_flit_out_we_all [`CORE_NUM(x,0)][2];
                    assign    router_congestion_in_all [`SELECT_WIRE(x,y,4,CONGw)]   =     router_congestion_out_all [`SELECT_WIRE(x,0,2,CONGw)];
                end//topology
            end    
        
        //connection to the ip_core
        
        
            assign        router_flit_in_all [`SELECT_WIRE(x,y,0,Fw)] =    ni_flit_out [`CORE_NUM(x,y)];
            assign        router_credit_in_all [`SELECT_WIRE(x,y,0,V)] =    ni_credit_out [`CORE_NUM(x,y)];
            assign        router_flit_in_we_all [`CORE_NUM(x,y)][0]  =    ni_flit_out_wr [`CORE_NUM(x,y)];
            assign      router_congestion_in_all[`SELECT_WIRE(x,y,0,CONGw)] =   {CONGw{1'b0}};     
            
            
            assign        ni_flit_in [`CORE_NUM(x,y)] = router_flit_out_all [`SELECT_WIRE(x,y,0,Fw)];
            assign        ni_flit_in_wr [`CORE_NUM(x,y)] = router_flit_out_we_all[`CORE_NUM(x,y)][0];
            assign        ni_credit_in [`CORE_NUM(x,y)] = router_credit_out_all [`SELECT_WIRE(x,y,0,V)];
            
            
                    
                            
            assign     flit_out_all [(`CORE_NUM(x,y)+1)*Fw-1 : `CORE_NUM(x,y)*Fw] =    ni_flit_in [`CORE_NUM(x,y)];    
            assign    flit_out_wr_all [`CORE_NUM(x,y)]  =     ni_flit_in_wr [`CORE_NUM(x,y)]; 
            assign     ni_credit_out [`CORE_NUM(x,y)]  =    credit_in_all [(`CORE_NUM(x,y)+1)*V-1 : `CORE_NUM(x,y)*V];  
            assign     ni_flit_out [`CORE_NUM(x,y)]  =     flit_in_all [(`CORE_NUM(x,y)+1)*Fw-1 : `CORE_NUM(x,y)*Fw];
            assign  ni_flit_out_wr [`CORE_NUM(x,y)]  =    flit_in_wr_all [`CORE_NUM(x,y)];
            assign    credit_out_all [(`CORE_NUM(x,y)+1)*V-1 : `CORE_NUM(x,y)*V] =    ni_credit_in [`CORE_NUM(x,y)];
         
    
            end //y
        end //x
    end// mesh_torus        
    
endgenerate

endmodule
