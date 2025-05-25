`include "pronoc_def.v"
/**********************************************************************
**    File: ovc_list.sv
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
**      This module provides a list of available output VCs for the allocator
*************************************/
module ovc_list (
    class_in,
    ovcs_out
);
    `NOC_CONF
    
    input [Cw-1 : 0] class_in;
    output[V-1 : 0] ovcs_out;
    function automatic logic [V-1:0] get_vc_list_section(input int c);
    begin
        logic [CVw-1 : 0] shiftted = CLASS_SETTING >> c*V;
        return shiftted[V-1 : 0];
    end
    endfunction
    //Masks VCs acording to message classes
    logic [V-1 : 0] class_table [C-1 : 0];
    logic [V-1 : 0] ovc_message_class;
    always_comb begin
        for(int i=0; i<C; i++) class_table[i] = get_vc_list_section(i);
    end
    assign  ovcs_out= (C == 0 || C == 1)? {V{1'b1}} : class_table[class_in];
endmodule


module vc_priority_based_dest_port #(
    parameter P=5,
    parameter V=4
)(
    dest_port,
    vc_pririty
);
    localparam
        P_1 =  (P-1),
        OFFSET =  V/(P_1);
    
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
                vc_pririty_init[i] = | dest_port[((i+1)*(P_1))/V-1: (i*(P_1))/V ];
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
