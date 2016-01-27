/**************************************
* Module: agent
* Date:2015-10-07  
* Author: alireza     
*
* Description: 
***************************************/


`timescale   1ns/1ps


`define CORE_NUM(x,y)                       ((y * NX) + x)




module  agent  #(
    parameter NX   = 2, // number of node in x axis
    parameter NY   = 2, // number of node in y axis
    parameter TOPOLOGY =    "MESH",//"MESH","TORUS"
    parameter ROUTE_TYPE   =   "DETERMINISTIC",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter ROUTE_NAME    =   "XY",
    parameter CONGESTION_INDEX =   2,
    parameter DEBUG_EN =   1
    

)(
    reset,
    clk,    
    congestion_in_all,
    port_presel_all
    
);

 localparam     P_SELw=4,
                CONGw= (CONGESTION_INDEX==3)?  3:
                       (CONGESTION_INDEX==5)?  3:
                       (CONGESTION_INDEX==7)?  3:
                       (CONGESTION_INDEX==9)?  3:
                       (CONGESTION_INDEX==10)? 4:
                       (CONGESTION_INDEX==12)? 3:2;


localparam      NC=NX*NY,
                CONGw_ALL= CONGw * NC,
                P_SELw_ALL=P_SELw*NC;
               

input reset,clk;



input [CONGw_ALL-1      :   0] congestion_in_all;
output[P_SELw_ALL-1      :   0] port_presel_all;



// seprated in/out per router
wire [CONGw-1      :   0] congestion_in [NC-1       :   0];
wire [P_SELw-1     :   0] port_presel   [NC-1       :   0];


//i   =   (y * NX) +  x;
//y   =   i/NX
//x   =   i-(y * NX)

genvar i;
generate
for(i=0;i<NC;i=i+1'b1)begin 
   assign congestion_in [i]=congestion_in_all    [(i+1)*CONGw-1     :i*CONGw];
   assign port_presel   [i]=port_presel_all      [(i+1)*P_SELw-1    :i*P_SELw];
      
   
   
 
end
endgenerate




   



endmodule

