`timescale      1ns/1ps

/**********************************************************************
**	File: class_table.v
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
**	
*************************************/


 module class_ovc_table #(
    parameter C= 4,//number of class 
    parameter V= 4, //VC number per port
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1:   0] CLASS_SETTING = {CVw{1'b1}} // shows how each class can use VCs   


    )
    (
        class_in,
        candidate_ovcs
    );
    
   
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
    
    localparam Cw= (C>1)?  log2(C): 1;
    
    input [Cw-1    :    0]    class_in;
    output[V-1    :    0]    candidate_ovcs;
    
    genvar i;    
    generate 
        if(C == 0 || C == 1) begin: no_class // 
    
          assign  candidate_ovcs={V{1'b1}};
    
        end else begin: width_class
        
           wire [V-1  :   0] class_table [C-1  :   0];
           for(i=0;i<C;i=i+1) begin : class_loop
               assign class_table[i]= CLASS_SETTING[(i+1)*V-1  :   i*V];
           end
           
                      
           assign  candidate_ovcs=class_table[class_in];
        
        
        
        end
     endgenerate
    
        
endmodule


module vc_priority_based_dest_port #(
    parameter P=5,
    parameter V=4

)(
    dest_port,
    vc_pririty
);

    localparam      P_1       =  (P-1),
                    OFFSET      =  V/(P_1);
    
    input   [P_1-1        :   0] dest_port;
    reg     [V-1          :   0] vc_pririty_init;
    output  [V-1          :   0] vc_pririty;
    
    genvar i;
    integer j;  
    generate 
        if(P_1 == V  )begin :b1
            always @(*) begin vc_pririty_init =  dest_port; end
        
        end else if (P_1 > V  )begin :b2
          for (i=0;i<V; i=i+1)begin:yy
            always @(*) begin 
                  vc_pririty_init[i] = | dest_port[((i+1)*(P_1))/V-1:    (i*(P_1))/V ];          
            end
          end
        end else begin :b3
            always @(*) begin //P_1 < V
                vc_pririty_init={V{1'b0}};
                for (j=0;j<P_1; j=j+1)  vc_pririty_init[j+OFFSET] =  dest_port[j];            
           
            end
       
        end
    endgenerate

    assign vc_pririty=(vc_pririty_init==0)? {{(V-1){1'b0}},1'b1}: vc_pririty_init;

endmodule







