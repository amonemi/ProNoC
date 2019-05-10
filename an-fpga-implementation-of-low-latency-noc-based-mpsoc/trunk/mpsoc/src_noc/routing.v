`timescale     1ns/1ps
/**********************************************************************
**	File:  routing.v
**    
**	Copyright (C) 2014-2017  Alireza Monemi
**    
**	This file is part of ProNoC 
**
**	ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**	you can redistribute it and/or modify it under the terms of the GNU
**	Lesser General Public License as published by the Free Software Foundation,
**	either version 2 of the License, or (at your option) any later version.
**
** 	ProNoC is distributed in the hope that it will be useful, but WITHOUT
** 	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
** 	or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
** 	Public License for more details.
**
** 	You should have received a copy of the GNU Lesser General Public
** 	License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
**
**
**	Description: 
**	look-ahead and conventional routing algorithms for Mesh and Torus NoC
**	
**
**************************************************************/



module ni_conventional_routing #(
    parameter TOPOLOGY          =   "MESH", 
    parameter ROUTE_NAME        =   "XY",
    parameter ROUTE_TYPE        =   "DETERMINISTIC", 
    parameter T1                =   4,
    parameter T2                =   4,
    parameter T3                =   4,
    parameter RAw = 3,  
    parameter EAw = 3,   
    parameter DSTPw=4          
)
(   
    reset,
    clk,
    current_r_addr,
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
  
    input  reset,clk;          
    input   [RAw-1   :0] current_r_addr;
    input   [EAw-1   :0] dest_e_addr;
    output  [DSTPw-1 :0] destport;
    
 generate 
    /* verilator lint_off WIDTH */ 
    if(TOPOLOGY == "MESH" || TOPOLOGY == "TORUS"  || TOPOLOGY ==  "RING" || TOPOLOGY ==  "LINE") begin :mesh_torus
    /* verilator lint_on WIDTH */ 
    
    localparam
        NX = T1,
        NY = T2,
        RXw = log2(NX),   
        RYw = log2(NY),  
        EXw = RXw,
        EYw = RYw;
        
        wire   [RXw-1   :   0]  current_rx;
        wire   [RYw-1   :   0]  current_ry;                  
        wire   [EXw-1   :   0]  dest_ex;
        wire   [EYw-1   :   0]  dest_ey;
        
        
        mesh_tori_router_addr_decode #(
        	.TOPOLOGY(TOPOLOGY),
            .T1(T1),
            .T2(T2),
            .T3(T3),
        	.RAw(RAw)
        )
        router_addr_decode
        (
        	.r_addr(current_r_addr),
        	.rx(current_rx),
        	.ry(current_ry),
        	.valid( )
        );
        
        
        
        mesh_tori_endp_addr_decode #(
        	.TOPOLOGY(TOPOLOGY),
        	.T1(T1),
        	.T2(T2),
        	.T3(T3),
        	.EAw(EAw)
        )
        end_addr_decode
        (
        	.e_addr(dest_e_addr),
        	.ex(dest_ex),
        	.ey(dest_ey),
        	.el( ),
        	.valid()
        );        
        
        
        mesh_torus_ni_conventional_routing #(
            .TOPOLOGY(TOPOLOGY),
            .ROUTE_NAME(ROUTE_NAME),
            .ROUTE_TYPE(ROUTE_TYPE),
            .NX(T1),
            .NY(T2),
            .LOCATED_IN_NI(1)
        )
        the_ni_conventional_routing
        (
            .current_x(current_rx),
            .current_y(current_ry),
            .dest_x(dest_ex),
            .dest_y(dest_ey),
            .destport(destport)
        );
    
    end else begin : others
        localparam
            K=T1,
            L=T2,
            Kw = log2(K),
            LKw= L*Kw,
            Lw = log2(L);
    
        wire [LKw-1 :0]    current_rx;
        wire [Lw-1  :0]    current_rl;  
        
        fattree_router_addr_decode #(
            .K(T1),
            .L(T2)
        )
        router_addr_decode
        (
            .r_addr(current_r_addr),
            .rx(current_rx),
            .rl(current_rl)
        );    
        
        /* verilator lint_off WIDTH */ 
        if(TOPOLOGY == "FATTREE" )begin : fat    
        /* verilator lint_on WIDTH */ 
                   
            fattree_conventional_routing #(
                .ROUTE_NAME(ROUTE_NAME),
                .K(T1),
                .L(T2)
            )
            the_conventional_routing
            (
                .reset(reset),
                .clk(clk),
                .current_addr_encoded(current_rx),
                .current_level(current_rl),
                .dest_addr_encoded(dest_e_addr),
                .destport_encoded(destport)
            );    
        
        end else begin : tree 
                          
            tree_conventional_routing #(
                .ROUTE_NAME(ROUTE_NAME),
                .K(T1),
                .L(T2)
            )
            the_conventional_routing
            (
                
                .current_addr_encoded(current_rx),
                .current_level(current_rl),
                .dest_addr_encoded(dest_e_addr),
                .destport_encoded(destport)
            );    
        end
    end
    endgenerate

endmodule




/************************************

     look_ahead_routing

*************************************/

module look_ahead_routing #(
    parameter P         =5,
    parameter T1= 8,
    parameter T2= 8,
    parameter T3= 8,
    parameter T4= 8,
    parameter RAw = 3,  
    parameter EAw = 3,  
    parameter DSTPw=P-1,
    parameter SW_LOC    =0,
    parameter TOPOLOGY  ="MESH",//"MESH","TORUS"
    parameter ROUTE_NAME="XY",// 
    parameter ROUTE_TYPE="DETERMINISTIC"// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
)
(
    current_r_addr,  //current router  address
    neighbors_r_addr,
    dest_e_addr,  // destination router x address          
    destport_encoded,   // current router destination port number       
    lkdestport_encoded, // look ahead destination port number
    reset,
    clk
);
    
     function integer log2;
    input integer number; begin   
       log2=(number <=1) ? 1: 0;    
       while(2**log2<number) begin    
          log2=log2+1;    
       end        
    end   
    endfunction // log2 
 
    localparam 
        PRAw= P * RAw;
    localparam
        //K= T1,
        //L=T2,
            Kw = log2(T1),
            Lw = log2(T2),
            LKw= T2 * Kw,
            PLw = P * Lw,
            PLKw = P * LKw;
   
    input   [PRAw-1:  0]  neighbors_r_addr;
    input   [RAw-1   :   0]  current_r_addr;
    input   [EAw-1   :   0]  dest_e_addr;
    input   [DSTPw-1  :   0]  destport_encoded;
    output  [DSTPw-1  :   0]  lkdestport_encoded;
    input                   reset,clk;
    
    genvar i;
    generate 
    /* verilator lint_off WIDTH */ 
    if(TOPOLOGY == "MESH" || TOPOLOGY == "TORUS"  || TOPOLOGY ==  "RING" || TOPOLOGY ==  "LINE")begin :mesh_torus
    /* verilator lint_on WIDTH */ 
     
       localparam
        NX = T1,
        NY = T2,
        RXw = log2(NX),   
        RYw = log2(NY),  
        EXw = RXw,
        EYw = RYw;
        
        wire   [RXw-1   :   0]  current_rx;
        wire   [RYw-1   :   0]  current_ry;                  
        wire   [EXw-1   :   0]  dest_ex;
        wire   [EYw-1   :   0]  dest_ey;
        
        localparam SL_SW_LOC = ( SW_LOC > P-T3) ? 0 : SW_LOC; //single_local   
         
        mesh_tori_router_addr_decode #(
            .TOPOLOGY(TOPOLOGY),
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .RAw(RAw)
        )
        router_addr_decode
        (
            .r_addr(current_r_addr),
            .rx(current_rx),
            .ry(current_ry),
            .valid( )
        );
        
         mesh_tori_endp_addr_decode #(
            .TOPOLOGY(TOPOLOGY),
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .EAw(EAw)
        )
        end_addr_decode
        (
            .e_addr(dest_e_addr),
            .ex(dest_ex),
            .ey(dest_ey),
            .el( ),
            .valid()
        );
            
     
        mesh_torus_look_ahead_routing #(
           	.NX(T1),
        	.NY(T2),
        	.SW_LOC(SL_SW_LOC),
        	.TOPOLOGY(TOPOLOGY),
        	.ROUTE_NAME(ROUTE_NAME),
        	.ROUTE_TYPE(ROUTE_TYPE)
        )
        look_ahead_route
        (
        	.current_x(current_rx),
        	.current_y(current_ry),
        	.dest_x(dest_ex),
        	.dest_y(dest_ey),
        	.destport_encoded(destport_encoded),
        	.lkdestport_encoded(lkdestport_encoded),
        	.reset(reset),
        	.clk(clk)
        );
    /* verilator lint_off WIDTH */      
    end else if (TOPOLOGY == "FATTREE") begin: fat
    /* verilator lint_on WIDTH */          
    
        wire  [PLKw-1 : 0]  neighbors_rx;
        wire  [PLw-1 : 0]  neighbors_ry;
       
        for (i=0; i<P; i=i+1) begin : port
            assign neighbors_rx[(i+1)*LKw-1: i*LKw] = neighbors_r_addr[(i*RAw)+LKw-1 : i*RAw]; 
            assign neighbors_ry[(i+1)*Lw-1 : i*Lw]  = neighbors_r_addr[(i+1)*RAw-1: (i*RAw)+LKw];
        end//port        
    
        fattree_look_ahead_routing #(
        	.ROUTE_NAME(ROUTE_NAME),
        	.P(P),
        	.K(T1),
        	.L(T2)        	
        )
        look_ahead_route
        (
        	.destport_encoded(destport_encoded),
        	.dest_addr_encoded(dest_e_addr),
        	.neighbors_rx(neighbors_rx),
        	.neighbors_ry(neighbors_ry),
        	.lkdestport_encoded(lkdestport_encoded),
        	.reset(reset),
        	.clk(clk)
        );
    
    /* verilator lint_off WIDTH */      
    end else if (TOPOLOGY == "TREE") begin: tree
    /* verilator lint_on WIDTH */          
            
        wire  [PLKw-1 : 0]  neighbors_rx_tree;
        wire  [PLw-1 : 0]  neighbors_ry_tree;
       
        for (i=0; i<P; i=i+1) begin : port
            assign neighbors_rx_tree[(i+1)*LKw-1: i*LKw] = neighbors_r_addr[(i*RAw)+LKw-1 : i*RAw]; 
            assign neighbors_ry_tree[(i+1)*Lw-1 : i*Lw]  = neighbors_r_addr[(i+1)*RAw-1: (i*RAw)+LKw];
        end//port        
    
    
        tree_look_ahead_routing #(
        	.ROUTE_NAME(ROUTE_NAME),
        	.P(P),
        	.L(T1),
        	.K(T2)
        )
        look_ahead_routing
        (
        	.destport_encoded(destport_encoded),
        	.dest_addr_encoded(dest_e_addr),
        	.neighbors_rx(neighbors_rx_tree),
        	.neighbors_ry(neighbors_ry_tree),
        	.lkdestport_encoded(lkdestport_encoded),
        	.reset(reset),
        	.clk(clk)
        );    
    end    
    endgenerate
endmodule
    
/********************************************************

                    next_router_addr_selector
                    
Determine the next router address based on the packet destination port   

********************************************************/


module next_router_addr_selector_onehot #(
    parameter P = 5,
    parameter RXw = 3,  // The router's x dimention adress width in bits
    parameter RYw = 3  // The router's y dimention adress width in bits
    )
    (
    destport_onehot,
    neighbors_rx,
    neighbors_ry,
    next_rx,
    next_ry     
    );
    
    localparam
        PRXw = P * RXw,
        PRYw = P * RYw; 
    
    input [P-1   :  0]  destport_onehot;
    input [PRXw-1:  0]  neighbors_rx;
    input [PRYw-1:  0]  neighbors_ry;
    output[RXw-1  :    0]  next_rx;
    output[RYw-1  :    0]  next_ry;  
    
    one_hot_mux #(
        .IN_WIDTH(PRXw),
        .SEL_WIDTH(P),
        .OUT_WIDTH(RXw)
    )
    next_x_mux
    (
        .mux_in(neighbors_rx),
        .mux_out(next_rx),
        .sel(destport_onehot)
    );
    
    one_hot_mux #(
        .IN_WIDTH(PRYw),
        .SEL_WIDTH(P),
        .OUT_WIDTH(RYw)
    )
    next_y_mux
    (
        .mux_in(neighbors_ry),
        .mux_out(next_ry),
        .sel(destport_onehot)
    );
        
endmodule    





module next_router_addr_selector_bin #(
    parameter P = 5,
    parameter RXw = 3,  // The router's x dimention adress width in bits
    parameter RYw = 3  // The router's y dimention adress width in bits
    )
    (
    destport_bin,
    neighbors_rx,
    neighbors_ry,
    next_rx,
    next_ry  
    
    );
    
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end        
      end   
    endfunction // log2 
    
    localparam
        Pw = log2(P),
        PRXw = P * RXw,
        PRYw = P * RYw; 
    
    input [Pw-1   :  0]  destport_bin;
    input [PRXw-1:  0]  neighbors_rx;
    input [PRYw-1:  0]  neighbors_ry;
    output[RXw-1  :    0]  next_rx;
    output[RYw-1  :    0]  next_ry;  
        
    binary_mux #(
        .IN_WIDTH(PRXw),
        .OUT_WIDTH(RXw)
    )
    next_x_mux
    (
        .mux_in(neighbors_rx),
        .mux_out(next_rx),
        .sel(destport_bin)
    );
    
    binary_mux  #(
        .IN_WIDTH(PRYw),
        .OUT_WIDTH(RYw)
    )
    next_y_mux
    (
        .mux_in(neighbors_ry),
        .mux_out(next_ry),
        .sel(destport_bin)
    );
        
endmodule    

 


