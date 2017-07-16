`timescale 1ns/1ps

/**********************************************************************
**	File:  route_torus.v
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
**	for 2D torus-based topology
**
**************************************************************/


/********************************************
                    Deterministic
*********************************************/

    /********************************************
                        TRANC
    *********************************************/
module tranc_xy_routing #(
    parameter NX   =    4,
    parameter NY   =    4,
    parameter OUT_BIN =    0   // 1: destination port is in binary format 0: onehot 
    
)
(
    current_x,
    current_y,
    dest_x,
    dest_y,
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
    
    localparam  P           =   5,
                Xw          =   log2(NX),
                Yw          =   log2(NY),
                Pw          =   log2(P),
                DSTw        =   (OUT_BIN)? Pw : P;
    
    
    input   [Xw-1       :   0] current_x;
    input   [Yw-1       :   0] current_y;
    input   [Xw-1       :   0] dest_x;
    input   [Yw-1       :   0] dest_y;
    output  [DSTw -1    :   0] destport;
    
    localparam      LOCAL   =   (OUT_BIN)?  3'd0    : 5'b00001,  
                    EAST    =   (OUT_BIN)?  3'd1    : 5'b00010,   
                    NORTH   =   (OUT_BIN)?  3'd2    : 5'b00100,    
                    WEST    =   (OUT_BIN)?  3'd3    : 5'b01000,  
                    SOUTH   =   (OUT_BIN)?  3'd4    : 5'b10000;    
    
    reg [DSTw-1            :0] destport_next;
    wire tranc_x_plus,tranc_y_plus,tranc_x_min,tranc_y_min;
    wire same_x,same_y;
    
    
    tranc_dir #(
        .NX(NX),
        .NY(NY)
    )
    tranc_dir(
        .tranc_x_plus(tranc_x_plus),
        .tranc_x_min(tranc_x_min),
        .tranc_y_plus(tranc_y_plus),
        .tranc_y_min(tranc_y_min),
        .same_x(same_x),
        .same_y(same_y),
        .current_x(current_x),
        .current_y(current_y),
        .dest_x(dest_x),
        .dest_y(dest_y)
        
    );
        
    always@(*)begin
        if (same_x & same_y) destport_next= LOCAL;
        else    begin 
            if            (tranc_x_plus)     destport_next= EAST;
            else if        (tranc_x_min)    destport_next= WEST;
            else if     (tranc_y_plus)    destport_next= SOUTH;
            else                        destport_next= NORTH;
        end
    end

    assign destport= destport_next;
    
    endmodule

/********************************************
                    Partial adaptive
*********************************************/

    /********************************************
                    TRANC West-First 
    *********************************************/

    
    module tranc_west_first_routing #(
       parameter NX   =   4,
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
                P_1 =   P-1,
                Xw  =   log2(NX),
                Yw  =   log2(NY);

    input  [Xw-1        :0] current_x;
    input  [Yw-1        :0] current_y;
    input  [Xw-1        :0] dest_x;
    input  [Yw-1        :0] dest_y;
    output [P_1-1       :0] destport;
   

        
    localparam LOCAL=   3'd0;  
    localparam EAST =   3'd1; 
    localparam NORTH=   3'd2;  
    localparam WEST =   3'd3;  
    localparam SOUTH=   3'd4;  
        
    wire tranc_x_plus,tranc_y_plus,tranc_x_min,tranc_y_min;
    wire same_x,same_y;
    
    
    tranc_dir #(
        .NX(NX),
        .NY(NY)
    )
    tranc_dir(
        .tranc_x_plus(tranc_x_plus),
        .tranc_x_min(tranc_x_min),
        .tranc_y_plus(tranc_y_plus),
        .tranc_y_min(tranc_y_min),
        .same_x(same_x),
        .same_y(same_y),
        .current_x(current_x),
        .current_y(current_y),
        .dest_x(dest_x),
        .dest_y(dest_y)
        
    );
    
    reg [P-1    :    0]    possible_out_port;
    
    always @(*)begin     
        possible_out_port = 5'd0;
        if(same_x && same_y) begin
            possible_out_port [LOCAL]=1'b1;
        end
        else if       (tranc_x_min) begin 
            possible_out_port [WEST]    = 1'b1;
        end
        else if (tranc_x_plus && tranc_y_min) begin
            possible_out_port [EAST]=1'b1;
            possible_out_port [NORTH]=1'b1;
        end
        else if(tranc_x_plus && tranc_y_plus) begin
            possible_out_port [EAST]=1'b1;
            possible_out_port [SOUTH]=1'b1;
        end
        else if( tranc_x_plus && same_y) begin 
            possible_out_port [EAST]=1'b1;
        end
        else if(same_x && tranc_y_min) begin 
            possible_out_port [NORTH]=1'b1;
        end
        else if(same_x && tranc_y_plus) begin 
            possible_out_port [SOUTH]=1'b1;
        end
    end    
    
    // code the destination port
    wire x,y,a,b;
    assign x = tranc_x_plus;
    assign y = tranc_y_plus;
    assign a = possible_out_port[EAST] | possible_out_port[WEST]; 
    assign b = possible_out_port[NORTH]| possible_out_port[SOUTH];
    assign destport = {x,y,a,b};
    
    
    endmodule
    
    
    
    /********************************************
                    TRANC North-Last 
    *********************************************/

    
    module tranc_north_last_routing #(
       parameter NX   =   4,
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
                P_1 =   P-1,
                Xw  =   log2(NX),
                Yw  =   log2(NY);

    input  [Xw-1        :0] current_x;
    input  [Yw-1        :0] current_y;
    input  [Xw-1        :0] dest_x;
    input  [Yw-1        :0] dest_y;
    output [P_1-1       :0] destport;
   

        
    localparam LOCAL=   3'd0;  
    localparam EAST =   3'd1; 
    localparam NORTH=   3'd2;  
    localparam WEST =   3'd3;  
    localparam SOUTH=   3'd4;  
        
    wire tranc_x_plus,tranc_y_plus,tranc_x_min,tranc_y_min;
    wire same_x,same_y;
    
    
    tranc_dir #(
        .NX(NX),
        .NY(NY)
    )
    tranc_dir(
        .tranc_x_plus(tranc_x_plus),
        .tranc_x_min(tranc_x_min),
        .tranc_y_plus(tranc_y_plus),
        .tranc_y_min(tranc_y_min),
        .same_x(same_x),
        .same_y(same_y),
        .current_x(current_x),
        .current_y(current_y),
        .dest_x(dest_x),
        .dest_y(dest_y)
        
    );
    
    reg [P-1    :   0]  possible_out_port;
    
     // north last routing algorithm does not allow turns from north to east or from north to west.
    
   always @(*)begin     
        possible_out_port       = 5'd0;
        if(same_x &&  same_y) begin 
            possible_out_port [LOCAL]=1'b1;
        end
        else if (tranc_x_min && tranc_y_min) begin 
            possible_out_port   [WEST]= 1'b1;
           // possible_out_port   [NORTH]= 1'b1;
        end 
        else if (tranc_x_min && tranc_y_plus) begin 
            possible_out_port   [WEST]= 1'b1;
            possible_out_port   [SOUTH]= 1'b1;
        end 
        else if (tranc_x_plus &&  tranc_y_min) begin 
            possible_out_port   [EAST]= 1'b1;
           // possible_out_port   [NORTH]= 1'b1;
            
        end
        else if (tranc_x_plus &&  tranc_y_plus) begin 
            possible_out_port   [EAST]= 1'b1;
            possible_out_port   [SOUTH]= 1'b1;
        end
        else if (tranc_x_min && same_y) begin 
            possible_out_port   [WEST]= 1'b1;
        end
        else if (tranc_x_plus && same_y) begin 
            possible_out_port   [EAST]= 1'b1;
        end
        else if (same_x && tranc_y_min) begin 
            possible_out_port   [NORTH]= 1'b1;
        end
        else if (same_x && tranc_y_plus) begin 
            possible_out_port   [SOUTH]= 1'b1;
        end
    end
    
    // code the destination port
    wire x,y,a,b;
    assign x = tranc_x_plus;
    assign y = tranc_y_plus;
    assign a = possible_out_port[EAST] | possible_out_port[WEST]; 
    assign b = possible_out_port[NORTH]| possible_out_port[SOUTH];
    assign destport = {x,y,a,b};
    
    
    endmodule
    
    


    /********************************************
                    TRANC North-Last 
    *********************************************/

    
    module tranc_negetive_first_routing #(
       parameter NX   =   4,
       parameter NY   =   4
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
                P_1 =   P-1,
                Xw  =   log2(NX),
                Yw  =   log2(NY);

    input  [Xw-1        :0] current_x;
    input  [Yw-1        :0] current_y;
    input  [Xw-1        :0] dest_x;
    input  [Yw-1        :0] dest_y;
    output [P_1-1       :0] destport;
   

        
    localparam LOCAL=   3'd0;  
    localparam EAST =   3'd1; 
    localparam NORTH=   3'd2;  
    localparam WEST =   3'd3;  
    localparam SOUTH=   3'd4;  
        
    wire tranc_x_plus,tranc_y_plus,tranc_x_min,tranc_y_min;
    wire same_x,same_y;
    
    
    tranc_dir #(
        .NX(NX),
        .NY(NY)
    )
    tranc_dir(
        .tranc_x_plus(tranc_x_plus),
        .tranc_x_min(tranc_x_min),
        .tranc_y_plus(tranc_y_plus),
        .tranc_y_min(tranc_y_min),
        .same_x(same_x),
        .same_y(same_y),
        .current_x(current_x),
        .current_y(current_y),
        .dest_x(dest_x),
        .dest_y(dest_y)
        
    );
    
    reg [P-1    :   0]  possible_out_port;
    
     // The negetive fist routing algorithm does net allow turns from north to west or from east to south.
    
   always @(*)begin     
        possible_out_port       = 5'd0;
        if(same_x &&  same_y) begin 
            possible_out_port [LOCAL]=1'b1;
        end
        else if (tranc_x_min && tranc_y_min) begin 
            possible_out_port   [WEST]= 1'b1;
           // possible_out_port   [NORTH]= 1'b1;
        end 
        else if (tranc_x_min && tranc_y_plus) begin 
            possible_out_port   [WEST]= 1'b1;
            possible_out_port   [SOUTH]= 1'b1;
        end 
        else if (tranc_x_plus &&  tranc_y_min) begin 
            possible_out_port   [EAST]= 1'b1;
            possible_out_port   [NORTH]= 1'b1;
            
        end
        else if (tranc_x_plus &&  tranc_y_plus) begin 
           // possible_out_port   [EAST]= 1'b1;
            possible_out_port   [SOUTH]= 1'b1;
        end
        else if (tranc_x_min && same_y) begin 
            possible_out_port   [WEST]= 1'b1;
        end
        else if (tranc_x_plus && same_y) begin 
            possible_out_port   [EAST]= 1'b1;
        end
        else if (same_x && tranc_y_min) begin 
            possible_out_port   [NORTH]= 1'b1;
        end
        else if (same_x && tranc_y_plus) begin 
            possible_out_port   [SOUTH]= 1'b1;
        end
    end
    
    // code the destination port
    wire x,y,a,b;
    assign x = tranc_x_plus;
    assign y = tranc_y_plus;
    assign a = possible_out_port[EAST] | possible_out_port[WEST]; 
    assign b = possible_out_port[NORTH]| possible_out_port[SOUTH];
    assign destport = {x,y,a,b};
    
    
    endmodule
    


/***********************************
        fully adaptive

***********************************/

    /************************************

        Duato’s Fully Adaptive

    *************************************/    
    
    
    
    module tranc_duato_routing #(
        parameter NX  =   4,
        parameter NY  =   4
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
                P_1 =   P-1,
                Xw  =   log2(NX),
                Yw  =   log2(NY);

    input  [Xw-1        :0] current_x;
    input  [Yw-1        :0] current_y;
    input  [Xw-1        :0] dest_x;
    input  [Yw-1        :0] dest_y;
    output [P_1-1       :0] destport;
   

        
    localparam LOCAL=   3'd0;  
    localparam EAST =   3'd1; 
    localparam NORTH=   3'd2;  
    localparam WEST =   3'd3;  
    localparam SOUTH=   3'd4;  
    
    
    wire tranc_x_plus,tranc_y_plus,tranc_x_min,tranc_y_min;
    wire same_x,same_y;
    
    
    tranc_dir #(
        .NX(NX),
        .NY(NY)
    )
    tranc_dir(
        .tranc_x_plus(tranc_x_plus),
        .tranc_x_min(tranc_x_min),
        .tranc_y_plus(tranc_y_plus),
        .tranc_y_min(tranc_y_min),
        .same_x(same_x),
        .same_y(same_y),
        .current_x(current_x),
        .current_y(current_y),
        .dest_x(dest_x),
        .dest_y(dest_y)
        
    );
    
    
    reg [P-1    :    0]    possible_out_port;
    
    
    always @(*)begin     
        possible_out_port         = 5'd0;
        if(same_x &&  same_y) begin 
            possible_out_port [LOCAL]=1'b1;
        end
        else if (tranc_x_min && tranc_y_min) begin 
            possible_out_port     [WEST]= 1'b1;
            possible_out_port     [NORTH]= 1'b1;
        end 
        else if (tranc_x_min && tranc_y_plus) begin 
            possible_out_port     [WEST]= 1'b1;
            possible_out_port     [SOUTH]= 1'b1;
        end 
        else if (tranc_x_min &&    same_y) begin 
            possible_out_port     [WEST]= 1'b1;
        end
        else if (tranc_x_plus &&  tranc_y_min) begin 
            possible_out_port     [EAST]= 1'b1;
            possible_out_port     [NORTH]= 1'b1;
            
        end
        else if (tranc_x_plus &&  tranc_y_plus) begin 
            possible_out_port     [EAST]= 1'b1;
            possible_out_port     [SOUTH]= 1'b1;
        end
        else if (tranc_x_plus && same_y) begin 
            possible_out_port     [EAST]= 1'b1;
        end
        else if (same_x && tranc_y_min) begin 
            possible_out_port     [NORTH]= 1'b1;
        end
        else if (same_x && tranc_y_plus) begin 
            possible_out_port     [SOUTH]= 1'b1;
        end
    end
    
    // code the destination port
    wire x,y,a,b;
    assign x = tranc_x_plus;
    assign y = tranc_y_plus;
    assign a = possible_out_port[EAST] | possible_out_port[WEST]; 
    assign b = possible_out_port[NORTH]| possible_out_port[SOUTH];
    assign destport = {x,y,a,b};
    
    
    endmodule
    
    
    
    /****************************************
    
       tranc_dir
    
    
    ****************************************/

module tranc_dir #(
    parameter NX   =    4,
    parameter NY   =    4
)(
    current_x,
    current_y,
    dest_x,
    dest_y,
    tranc_x_plus,
    tranc_x_min,
    tranc_y_plus,
    tranc_y_min,
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

    output reg tranc_x_plus;
    output reg tranc_x_min;
    output reg tranc_y_plus;
    output reg tranc_y_min;
    output     same_x,same_y;
    
    input   [Xw-1       :   0] current_x;
    input   [Yw-1       :   0] current_y;
    input   [Xw-1       :   0] dest_x;
    input   [Yw-1       :   0] dest_y;

    localparam SIGNED_X_WIDTH   =  (Xw<3) ? 4 : Xw+1;
    localparam SIGNED_Y_WIDTH   =  (Yw<3) ? 4 : Yw+1;
    
    wire signed [SIGNED_X_WIDTH-1       :0] xc;//current 
    wire signed [SIGNED_X_WIDTH-1       :0] xd;//destination
    wire signed [SIGNED_Y_WIDTH-1       :0] yc;//current 
    wire signed [SIGNED_Y_WIDTH-1       :0] yd;//destination
    wire signed [SIGNED_X_WIDTH-1       :0] xdiff;
    wire signed [SIGNED_Y_WIDTH-1       :0] ydiff; 
    
    
    assign  xc  ={{(SIGNED_X_WIDTH-Xw){1'b0}}, current_x [Xw-1      :0]};
    assign  yc  ={{(SIGNED_Y_WIDTH-Yw){1'b0}}, current_y [Yw-1      :0]};
    assign  xd  ={{(SIGNED_X_WIDTH-Xw){1'b0}}, dest_x};
    assign  yd  ={{(SIGNED_Y_WIDTH-Yw){1'b0}}, dest_y};
    assign  xdiff   = xd-xc;
    assign  ydiff   = yd-yc;
    
    always@ (*)begin 
        tranc_x_plus    =1'b0;
        tranc_x_min     =1'b0;
        tranc_y_plus    =1'b0;
        tranc_y_min     =1'b0;
        if(xdiff!=0)begin 
            if ((xdiff ==1) || 
                 (xdiff == (-NX+1)) ||
                 ((xc == (NX-4)) && (xd == (NX-2))) ||
                 ((xc >= (NX-2)) && (xd <= (NX-4))) ||
                 ((xdiff> 0) && (xd<= (NX-3)))) 
                    tranc_x_plus    = 1'b1;
            else    tranc_x_min     = 1'b1;
        end
        if(ydiff!=0)begin   
            if ((ydiff ==1) ||
                (ydiff == (-NY+1)) ||
                ((yc == (NY-4)) && (yd == (NY-2))) ||
                ((yc    >= NY-2) && (yd<= NY-4)) ||
                ((ydiff > 0) && (yd<= NY-3)))
                    tranc_y_plus    = 1'b1;
            else    tranc_y_min     = 1'b1;
        end
    end//always
    
    assign same_x = (xdiff == 0);
    assign same_y = (ydiff == 0);
    
    
endmodule


