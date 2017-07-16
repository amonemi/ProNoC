`timescale     1ns/1ps

/**********************************************************************
**	File:  route_mesh.v
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
**	Different routing algorithms (determinstic,partially adaptive and fully adaptive)
**	for 2D mesh-based topology
**
**************************************************************/


/********************************************
                    Deterministic
*********************************************/


    /*****************************************************
                    xy_mesh_routing

    *****************************************************/



module xy_mesh_routing #(
    parameter NX        =    4,
    parameter NY        =    3,
    parameter OUT_BIN =    1    // 1: destination port is in binary format 0: onehot  
)
(
    current_x,    // current router x address
    current_y,    // current router y address
    dest_x,        // destination x address
    dest_y,        // destination y address
    destport    // router output port
        
);
    

    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end        
      end   
    endfunction // log2 

    localparam  P            =    5;    // router port number is always 5 in a mesh topology
    
    localparam  Xw            =    log2(NX),
                Yw            =    log2(NY),
                Pw            =    log2(P),
                DSTw          =    (OUT_BIN)? Pw : P;

    
    
    input  [Xw-1        :0]    current_x;
    input  [Yw-1        :0]    current_y;
    input  [Xw-1        :0]    dest_x;
    input  [Yw-1        :0]    dest_y;
    output [DSTw-1            :0]    destport;

    
    

    localparam  LOCAL    =    (OUT_BIN==1)?    0    :  1 ,//5'b00001
                EAST     =    (OUT_BIN==1)?    1    :  2 ,//5'b00010 
                NORTH    =    (OUT_BIN==1)?    2    :  4 ,//5'b00100    
                WEST     =    (OUT_BIN==1)?    3    :  8 ,//5'b01000  
                SOUTH    =    (OUT_BIN==1)?    4    : 16 ;//5'b10000    
    
    
    reg [DSTw-1            :0]    destport_next;
    
    
        
    assign    destport= destport_next;
    
    always@(*)begin
            destport_next    = LOCAL [DSTw-1    :0];
            if           (dest_x    > current_x)        destport_next    = EAST [DSTw-1    :0];
            else if      (dest_x    < current_x)        destport_next    = WEST [DSTw-1    :0];
            else begin
            if         (dest_y    > current_y)        destport_next    = SOUTH [DSTw-1:0];
            else if      (dest_y    < current_y)        destport_next    = NORTH [DSTw-1    :0];
            end
    end
    
    
endmodule

/********************************************
                    Partial adaptive
The west-first routing algorithm does not allow turns from north to west or from south to west.                    
The north last routing algorithm does not allow turns from north to east or from north to west.
The negetive fist routing algorithm does net allow turns from north to west or from east to south.

                    
*********************************************/

/************************************

                west-first
                 
*************************************/
module west_first_routing #(
        parameter NX    =   4,
        parameter NY    =   4
    )
    (       
        current_x,  // current router x address
        current_y,  // current router y address
        dest_x,     // destination x address
        dest_y,     // destination y address
        destport    // router output port
            
    );
   
   
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
   
    localparam  P   =   5,
                P_1 =    P-1,
                Xw  =   log2(NX),
                Yw  =   log2(NY);

    input  [Xw-1        :0] current_x;
    input  [Yw-1        :0] current_y;
    input  [Xw-1        :0] dest_x;
    input  [Yw-1        :0] dest_y;
    output [P_1-1       :0] destport;
       
    localparam  LOCAL=   3'd0,  
                EAST =   3'd1, 
                NORTH=   3'd2, 
                WEST =   3'd3,  
                SOUTH=   3'd4;  
    
    
    wire x_plus,x_min,y_plus,y_min,same_x,same_y;
    
    mesh_dir #(
        .NX(NX),
        .NY(NY)
    )
    dir(
        .current_x(current_x),
        .current_y(current_y),
        .dest_x(dest_x),
        .dest_y(dest_y),
        .x_plus(x_plus),
        .x_min(x_min),
        .y_plus(y_plus),
        .y_min(y_min),
        .same_x(same_x),
        .same_y(same_y)
        
    );
    
    reg [4  :   0]  possible_out_port;
    
    //The west-first routing algorithm does not allow turns from north to west or from south to west. 
    always @(*)begin    
        possible_out_port = 5'd0;
        if(same_x && same_y) begin
            possible_out_port [LOCAL]=1'b1;
        end
        else if       (x_min) begin 
            possible_out_port [WEST]    = 1'b1;
        end
        else if (x_plus && y_min) begin
            possible_out_port [EAST]=1'b1;
            possible_out_port [NORTH]=1'b1;
        end
        else if(x_plus && y_plus) begin
            possible_out_port [EAST]=1'b1;
            possible_out_port [SOUTH]=1'b1;
        end
        else if( x_plus && same_y) begin 
            possible_out_port [EAST]=1'b1;
        end
        else if(same_x && y_min) begin 
            possible_out_port [NORTH]=1'b1;
        end
        else if(same_x && y_plus) begin 
            possible_out_port [SOUTH]=1'b1;
        end
    end 
    
    // code the destination port
    wire x,y,a,b;
    assign x = x_plus;
    assign y = y_min;
    assign a = possible_out_port[EAST] | possible_out_port[WEST]; 
    assign b = possible_out_port[NORTH]| possible_out_port[SOUTH];
    assign destport = {x,y,a,b};
endmodule 


/************************************
              
             
             north-last
              
              
 *************************************/


module north_last_routing #(
        parameter NX    =   4,
        parameter NY    =   4
    )
    (       
        current_x,  // current router x address
        current_y,  // current router y address
        dest_x,     // destination x address
        dest_y,     // destination y address
        destport    // router output port
            
    );
   
  
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
   
    localparam  P   =   5,
                P_1 =    P-1,
                Xw  =   log2(NX),
                Yw  =   log2(NY);

    input  [Xw-1        :0] current_x;
    input  [Yw-1        :0] current_y;
    input  [Xw-1        :0] dest_x;
    input  [Yw-1        :0] dest_y;
    output [P_1-1       :0] destport;
       
    localparam  LOCAL=   3'd0,  
                EAST =   3'd1, 
                NORTH=   3'd2, 
                WEST =   3'd3,  
                SOUTH=   3'd4;  
    
    
    wire x_plus,x_min,y_plus,y_min,same_x,same_y;
    
    mesh_dir #(
        .NX(NX),
        .NY(NY)
    )
    dir(
        .current_x(current_x),
        .current_y(current_y),
        .dest_x(dest_x),
        .dest_y(dest_y),
        .x_plus(x_plus),
        .x_min(x_min),
        .y_plus(y_plus),
        .y_min(y_min),
        .same_x(same_x),
        .same_y(same_y)
        
    );
    
    reg [4  :   0]  possible_out_port;
    
   // north last routing algorithm does not allow turns from north to east or from north to west.
    
    always @(*)begin   
        possible_out_port   = 5'd0;
        if(same_x &&  same_y) begin 
            possible_out_port [LOCAL]=1'b1;
        end
        else if (x_min && y_min) begin 
            possible_out_port   [WEST]= 1'b1;
            //possible_out_port   [NORTH]= 1'b1;
        end 
        else if (x_min && y_plus) begin 
            possible_out_port   [WEST]= 1'b1;
            possible_out_port   [SOUTH]= 1'b1;
        end         
        else if (x_plus &&  y_min) begin 
            possible_out_port   [EAST]= 1'b1;
            //possible_out_port   [NORTH]= 1'b1;            
        end
        else if (x_plus &&  y_plus) begin 
            possible_out_port   [EAST]= 1'b1;
            possible_out_port   [SOUTH]= 1'b1;
        end
        else if (x_min && same_y) begin 
            possible_out_port   [WEST]= 1'b1;
        end
        else if (x_plus && same_y) begin 
            possible_out_port   [EAST]= 1'b1;
        end
        else if (same_x && y_min) begin 
            possible_out_port   [NORTH]= 1'b1;
        end
        else if (same_x && y_plus) begin 
            possible_out_port   [SOUTH]= 1'b1;
        end
    end
       
   
    // code the destination port
    wire x,y,a,b;
    assign x = x_plus;
    assign y = y_min;
    assign a = possible_out_port[EAST] | possible_out_port[WEST]; 
    assign b = possible_out_port[NORTH]| possible_out_port[SOUTH];
    assign destport = {x,y,a,b};
endmodule 


/****************************

        
        negetive-first
        

******************************/


module negetive_first_routing #(
        parameter NX    =   4,
        parameter NY    =   4
    )
    (       
        current_x,  // current router x address
        current_y,  // current router y address
        dest_x,     // destination x address
        dest_y,     // destination y address
        destport    // router output port
            
    );
   
    
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
   
    localparam  P   =   5,
                P_1 =    P-1,
                Xw  =   log2(NX),
                Yw  =   log2(NY);

    input  [Xw-1        :0] current_x;
    input  [Yw-1        :0] current_y;
    input  [Xw-1        :0] dest_x;
    input  [Yw-1        :0] dest_y;
    output [P_1-1       :0] destport;
       
    localparam  LOCAL=   3'd0,  
                EAST =   3'd1, 
                NORTH=   3'd2, 
                WEST =   3'd3,  
                SOUTH=   3'd4;  
    
    
    wire x_plus,x_min,y_plus,y_min,same_x,same_y;
    
    mesh_dir #(
        .NX(NX),
        .NY(NY)
    )
    dir(
        .current_x(current_x),
        .current_y(current_y),
        .dest_x(dest_x),
        .dest_y(dest_y),
        .x_plus(x_plus),
        .x_min(x_min),
        .y_plus(y_plus),
        .y_min(y_min),
        .same_x(same_x),
        .same_y(same_y)
        
    );
    
    reg [4  :   0]  possible_out_port;
    
 // The negetive fist routing algorithm does net allow turns from north to west or from east to south.
    
    always @(*)begin   
        possible_out_port   = 5'd0;
        if(same_x &&  same_y) begin 
            possible_out_port [LOCAL]=1'b1;
        end
        else if (x_min && y_min) begin 
            possible_out_port   [WEST]= 1'b1;
            //possible_out_port   [NORTH]= 1'b1;
        end 
        else if (x_min && y_plus) begin 
            possible_out_port   [WEST]= 1'b1;
            possible_out_port   [SOUTH]= 1'b1;
        end         
        else if (x_plus &&  y_min) begin 
            possible_out_port   [EAST]= 1'b1;
            possible_out_port   [NORTH]= 1'b1;            
        end
        else if (x_plus &&  y_plus) begin 
            //possible_out_port   [EAST]= 1'b1;
            possible_out_port   [SOUTH]= 1'b1;
        end
        else if (x_min && same_y) begin 
            possible_out_port   [WEST]= 1'b1;
        end
        else if (x_plus && same_y) begin 
            possible_out_port   [EAST]= 1'b1;
        end
        else if (same_x && y_min) begin 
            possible_out_port   [NORTH]= 1'b1;
        end
        else if (same_x && y_plus) begin 
            possible_out_port   [SOUTH]= 1'b1;
        end
    end
      
    // code the destination port
    wire x,y,a,b;
    assign x = x_plus;
    assign y = y_min;
    assign a = possible_out_port[EAST] | possible_out_port[WEST]; 
    assign b = possible_out_port[NORTH]| possible_out_port[SOUTH];
    assign destport = {x,y,a,b};
endmodule 


/****************************************

            odd_even

***************************************/




module odd_even_routing #(
        parameter NX        =    4,
        parameter NY        =    4,
        parameter LOCATED_IN_NI        =    1 // 1: the router locaed inside ni                     
                                                  // 0: the routing module located inside router
    )
    (
        current_x,    // current router x address
        current_y,    // current router y address
        dest_x,        // destination x address
        dest_y,        // destination y address
        destport    // router output port
        
    );

        
    
   
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
    
    localparam     P    =    5,
                P_1 =   P-1,               
                Xw    =    log2(NX),
                Yw    =    log2(NY);

    input  [Xw-1        :0]    current_x;
    input  [Yw-1        :0]    current_y;
    input  [Xw-1        :0]    dest_x;
    input  [Yw-1        :0]    dest_y;
    output [P_1-1         :0]    destport;
    
    
    
    localparam LOCAL   =        3'd0;  
    localparam EAST       =        3'd1; 
    localparam NORTH   =        3'd2;  
    localparam WEST       =        3'd3;  
    localparam SOUTH   =        3'd4;  
    
    wire signed [Xw        :0] xc;//current 
    wire signed [Xw        :0] xd;//destination
    wire signed [Yw        :0] yc;//current 
    wire signed [Yw        :0] yd;//destination
    wire signed [Xw        :0] xdiff;
    wire signed [Yw        :0] ydiff; 
    
    
    assign     xc     ={1'b0, current_x [Xw-1        :0]};
    assign     yc     ={1'b0, current_y [Yw-1        :0]};
    assign    xd    ={1'b0, dest_x};
    assign    yd     ={1'b0, dest_y};
    assign     xdiff    = xd-xc;
    assign    ydiff    = yd-yc;
    
    reg [P-1    :    0]    possible_out_port;
    
    
    
    always @(*)begin     
        possible_out_port = 5'd0;
        if (xdiff == 0 && ydiff == 0) begin 
                possible_out_port [LOCAL]=1'b1;
        end
        else if(xdiff ==0) begin //currently in the same column as destination
            if( ydiff<0) begin 
                possible_out_port [NORTH]=1'b1;
            end else begin 
                possible_out_port [SOUTH]=1'b1;
            end
        end
        else if(ydiff == 0) begin //currently in the same row as destination
            if( xdiff<0) begin 
                possible_out_port [WEST]=1'b1;
            end else begin 
                possible_out_port [EAST]=1'b1;
            end
        end
        else begin 
            if(xdiff>0)begin //east_bound
                if(ydiff == 0) begin
                    possible_out_port [EAST]=1'b1;
                end
                else begin 
                    if(current_x[0] || (LOCATED_IN_NI    == 1)) begin 
                        if( ydiff<0) begin 
                            possible_out_port [NORTH]=1'b1;
                        end else begin 
                            possible_out_port [SOUTH]=1'b1;
                        end
                    end
                    if(dest_x[0] || xdiff!=1) begin // //odd destination column or >= 2 columns to destination
                        possible_out_port [EAST]=1'b1;
                    end 
                end
            end 
            else begin // west_bound
                possible_out_port [WEST]    = 1'b1;
                if(current_x[0]== 1'b0) begin //even column
                    if( ydiff<0) begin 
                        possible_out_port [NORTH]=1'b1;
                    end else begin 
                        possible_out_port [SOUTH]=1'b1;
                    end
                end
            end
        end
        end
        
        
        
    // code the destination port
    wire x,y,a,b;
    assign x = (xdiff > 0);
    assign y = (ydiff < 0);
    assign a = possible_out_port[EAST] | possible_out_port[WEST]; 
    assign b = possible_out_port[NORTH]| possible_out_port[SOUTH];
    assign destport = {x,y,a,b};

    
    
    
endmodule 
    
/***********************************
        fully adaptive

***********************************/
    
    
    /************************************

        Duato’s Fully Adaptive
The packet which can travel in both x & y dimention can not use the reserved VC in y axies
    *************************************/    
    
    
    
module duato_mesh_routing #(
        parameter NX    =    4,
        parameter NY    =    4
    )
    (        
        current_x,    // current router x address
        current_y,    // current router y address
        dest_x,        // destination x address
        dest_y,        // destination y address
        destport    // router output port
        
    );

        
    
  
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
    
    
    localparam     P    =    5,
                P_1 =   P-1,    
                Xw    =    log2(NX),
                Yw    =    log2(NY);

    input  [Xw-1        :0]    current_x;
    input  [Yw-1        :0]    current_y;
    input  [Xw-1        :0]    dest_x;
    input  [Yw-1        :0]    dest_y;
    output [P_1-1        :0]    destport;
    

    
    localparam  LOCAL=   3'd0,  
                EAST =   3'd1, 
                NORTH=   3'd2, 
                WEST =   3'd3,  
                SOUTH=   3'd4;  
    
    
    wire x_plus,x_min,y_plus,y_min,same_x,same_y;
    
    mesh_dir #(
        .NX(NX),
        .NY(NY)
    )
    dir(
        .current_x(current_x),
        .current_y(current_y),
        .dest_x(dest_x),
        .dest_y(dest_y),
        .x_plus(x_plus),
        .x_min(x_min),
        .y_plus(y_plus),
        .y_min(y_min),
        .same_x(same_x),
        .same_y(same_y)
        
    );
        
    
    reg [P-1    :    0]    possible_out_port;
    
    always @(*)begin   
        possible_out_port       = 5'd0;
        if(same_x &&  same_y) begin 
            possible_out_port [LOCAL]=1'b1;
        end
        else if (x_min && y_min) begin 
            possible_out_port   [WEST]= 1'b1;
            possible_out_port   [NORTH]= 1'b1;
        end 
        else if (x_min && y_plus) begin 
            possible_out_port   [WEST]= 1'b1;
            possible_out_port   [SOUTH]= 1'b1;
        end 
        else if (x_plus &&  y_min) begin 
            possible_out_port   [EAST]= 1'b1;
            possible_out_port   [NORTH]= 1'b1;            
        end
        else if (x_plus &&  y_plus) begin 
            possible_out_port   [EAST]= 1'b1;
            possible_out_port   [SOUTH]= 1'b1;
        end
        else if (x_min && same_y) begin 
            possible_out_port   [WEST]= 1'b1;
        end
        else if (x_plus && same_y) begin 
            possible_out_port   [EAST]= 1'b1;
        end
        else if (same_x && y_min) begin 
            possible_out_port   [NORTH]= 1'b1;
        end
        else if (same_x && y_plus) begin 
            possible_out_port   [SOUTH]= 1'b1;
        end
    end
   
    
    // code the destination port
    wire   x,y,a,b;
    assign x = x_plus;
    assign y = y_min;
    assign a = possible_out_port[EAST] | possible_out_port[WEST]; 
    assign b = possible_out_port[NORTH]| possible_out_port[SOUTH];
    assign destport = {x,y,a,b};
    
    
    
endmodule
    
        


        
module mesh_dir #(
    parameter NX   =    4,
    parameter NY   =    4
)(
    current_x,
    current_y,
    dest_x,
    dest_y,
    x_plus,
    x_min,
    y_plus,
    y_min,
    same_x,
    same_y
);

 
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
        
    localparam  Xw          =   log2(NX),
                Yw          =   log2(NY);

    output x_plus;
    output x_min;
    output y_plus;
    output y_min;
    output same_x,same_y;
    
    input   [Xw-1       :   0] current_x;
    input   [Yw-1       :   0] current_y;
    input   [Xw-1       :   0] dest_x;
    input   [Yw-1       :   0] dest_y;

   

    assign same_x = (current_x == dest_x);
    assign same_y = (current_y == dest_y);
    assign x_plus = (dest_x  > current_x);
    assign x_min  = (dest_x  < current_x);
    assign y_plus = (dest_y  > current_y);
    assign y_min  = (dest_y  < current_y);
   
   

endmodule













